#!/usr/bin/with-contenv bashio
# shellcheck shell=bash
# ==============================================================================
# Configures mosquitto (HA users + optional LDAP + go-auth options)
# Derived from home-assistant/addons mosquitto cont-init script.
# ==============================================================================
readonly ACL="/etc/mosquitto/acl"
readonly PW="/etc/mosquitto/pw"
readonly SYSTEM_USER="/data/system_user.json"
readonly CONF="/etc/mosquitto/mosquitto.conf"
declare cafile
declare certfile
declare discovery_password
declare keyfile
declare log_dest
declare log_type
declare password
declare service_password
declare ssl
declare username
declare backends
declare extra_backends
declare extra_options
declare ldap_enabled

# Read or create system account data
if ! bashio::fs.file_exists "${SYSTEM_USER}"; then
  discovery_password="$(pwgen 64 1)"
  service_password="$(pwgen 64 1)"

  bashio::var.json \
    homeassistant "^$(bashio::var.json password "${discovery_password}")" \
    addons "^$(bashio::var.json password "${service_password}")" \
    > "${SYSTEM_USER}"
else
  discovery_password=$(bashio::jq "${SYSTEM_USER}" ".homeassistant.password")
  service_password=$(bashio::jq "${SYSTEM_USER}" ".addons.password")
fi

password=$(pw -p "${discovery_password}")
echo "homeassistant:${password}" >> "${PW}"
echo "user homeassistant" >> "${ACL}"

password=$(pw -p "${service_password}")
echo "addons:${password}" >> "${PW}"
echo "user addons" >> "${ACL}"

for login in $(bashio::config 'logins|keys'); do
  bashio::config.require.username "logins[${login}].username"
  bashio::config.require.password "logins[${login}].password"

  username=$(bashio::config "logins[${login}].username")
  password=$(bashio::config "logins[${login}].password")

  bashio::log.info "Setting up user ${username}"
  if ! bashio::config.true "logins[${login}].password_pre_hashed"
  then
      password=$(pw -p "${password}")
  else
      bashio::log.info "Using pre-hashed password for ${username}"
  fi
  echo "${username}:${password}" >> "${PW}"
  echo "user ${username}" >> "${ACL}"
done

keyfile="/ssl/$(bashio::config 'keyfile')"
certfile="/ssl/$(bashio::config 'certfile')"
cafile="/ssl/$(bashio::config 'cafile')"
if bashio::fs.file_exists "${certfile}" \
  && bashio::fs.file_exists "${keyfile}";
then
  bashio::log.info "Certificates found: SSL is available"
  ssl="true"
  if ! bashio::fs.file_exists "${cafile}"; then
    cafile="${certfile}"
  fi
else
  bashio::log.info "SSL is not enabled"
  ssl="false"
fi

# Backend list: files + http always; ldap optional; extra_backends appended
backends="files,http"
ldap_enabled="false"
if bashio::config.true 'ldap.enabled'; then
  bashio::config.require 'ldap.url'
  bashio::config.require 'ldap.user_dn'
  bashio::config.require 'ldap.user_filter'
  bashio::config.require 'ldap.bind_dn'
  bashio::config.require 'ldap.bind_password'
  ldap_enabled="true"
  backends="${backends},ldap"
  bashio::log.info "LDAP authentication backend enabled"
else
  bashio::log.info "LDAP authentication backend disabled"
fi

extra_backends=$(bashio::config 'go_auth.extra_backends')
if bashio::var.has_value "${extra_backends}"; then
  backends="${backends},${extra_backends}"
  bashio::log.info "Extra go-auth backends: ${extra_backends}"
fi

if bashio::config.true 'go_auth.check_prefix'; then
  bashio::config.require 'go_auth.prefixes'
fi

if bashio::config.equals 'go_auth.log_dest' 'file'; then
  bashio::config.require 'go_auth.log_file'
fi

options=$(bashio::addon.config)
log_dest=$(jq -c ".log_dest" <<<"$options")
log_type=$(jq -c ".log_type" <<<"$options")

bashio::var.json \
  cafile "${cafile}" \
  certfile "${certfile}" \
  customize "^$(bashio::config 'customize.active')" \
  customize_folder "$(bashio::config 'customize.folder')" \
  keyfile "${keyfile}" \
  log_dest "^${log_dest}" \
  log_type "^${log_type}" \
  require_certificate "^$(bashio::config 'require_certificate')" \
  ssl "^${ssl}" \
  debug "^$(bashio::config 'debug')" \
  auth_backends "${backends}" \
  ldap_enabled "^${ldap_enabled}" \
  ldap_url "$(bashio::config 'ldap.url')" \
  ldap_user_dn "$(bashio::config 'ldap.user_dn')" \
  ldap_group_dn "$(bashio::config 'ldap.group_dn')" \
  ldap_bind_dn "$(bashio::config 'ldap.bind_dn')" \
  ldap_bind_password "$(bashio::config 'ldap.bind_password')" \
  ldap_user_filter "$(bashio::config 'ldap.user_filter')" \
  ldap_superuser_filter "$(bashio::config 'ldap.superuser_filter')" \
  ldap_group_filter "$(bashio::config 'ldap.group_filter')" \
  ldap_acl_topic_pattern_attribute "$(bashio::config 'ldap.acl_topic_pattern_attribute')" \
  ldap_acl_acc_attribute "$(bashio::config 'ldap.acl_acc_attribute')" \
  exhaust_backend_first "^$(bashio::config 'go_auth.exhaust_backend_first')" \
  use_clientid_as_username "^$(bashio::config 'go_auth.use_clientid_as_username')" \
  disable_superuser "^$(bashio::config 'go_auth.disable_superuser')" \
  retry_count "^$(bashio::config 'go_auth.retry_count')" \
  cache "^$(bashio::config 'go_auth.cache')" \
  cache_type "$(bashio::config 'go_auth.cache_type')" \
  cache_reset "^$(bashio::config 'go_auth.cache_reset')" \
  cache_refresh "^$(bashio::config 'go_auth.cache_refresh')" \
  auth_cache_seconds "^$(bashio::config 'go_auth.auth_cache_seconds')" \
  acl_cache_seconds "^$(bashio::config 'go_auth.acl_cache_seconds')" \
  auth_jitter_seconds "^$(bashio::config 'go_auth.auth_jitter_seconds')" \
  acl_jitter_seconds "^$(bashio::config 'go_auth.acl_jitter_seconds')" \
  cache_host "$(bashio::config 'go_auth.cache_host')" \
  cache_port "$(bashio::config 'go_auth.cache_port')" \
  cache_password "$(bashio::config 'go_auth.cache_password')" \
  cache_db "$(bashio::config 'go_auth.cache_db')" \
  hasher "$(bashio::config 'go_auth.hasher')" \
  hasher_iterations "^$(bashio::config 'go_auth.hasher_iterations')" \
  hasher_salt_size "^$(bashio::config 'go_auth.hasher_salt_size')" \
  plugin_log_dest "$(bashio::config 'go_auth.log_dest')" \
  plugin_log_file "$(bashio::config 'go_auth.log_file')" \
  check_prefix "^$(bashio::config 'go_auth.check_prefix')" \
  strip_prefix "^$(bashio::config 'go_auth.strip_prefix')" \
  prefixes "$(bashio::config 'go_auth.prefixes')" \
  | tempio \
    -template /usr/share/tempio/mosquitto.gtpl \
    -out "${CONF}"

# Advanced auth_opt_* injection (minilab pattern: same file as auth_plugin).
# Do not use include_dir for plugin options — Mosquitto may reject them there.
extra_options=$(bashio::config 'go_auth.extra_options')
if bashio::var.has_value "${extra_options}"; then
  bashio::log.info "Injecting go_auth.extra_options after auth_plugin"
  if grep -Eiq '^[[:space:]]*auth_plugin[[:space:]]' <<<"${extra_options}"; then
    bashio::exit.nok "go_auth.extra_options must not set auth_plugin (already configured)"
  fi
  extra_file="$(mktemp)"
  printf '%s\n' "${extra_options}" > "${extra_file}"
  tmp="$(mktemp)"
  awk -v extra_file="${extra_file}" '
    { print }
    /^auth_plugin / {
      while ((getline line < extra_file) > 0) {
        if (line ~ /^[[:space:]]*$/) continue
        print line
      }
      close(extra_file)
    }
  ' "${CONF}" > "${tmp}"
  mv "${tmp}" "${CONF}"
  rm -f "${extra_file}"
fi
