#!/usr/bin/with-contenv bashio
# shellcheck shell=bash
# ==============================================================================
# Configures mosquitto (HA users + optional LDAP)
# Derived from home-assistant/addons mosquitto cont-init script.
# ==============================================================================
readonly ACL="/etc/mosquitto/acl"
readonly PW="/etc/mosquitto/pw"
readonly SYSTEM_USER="/data/system_user.json"
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
declare ldap_enabled
declare ldap_url
declare ldap_user_dn
declare ldap_group_dn
declare ldap_bind_dn
declare ldap_bind_password
declare ldap_user_filter
declare ldap_superuser_filter

# Read or create system account data
if ! bashio::fs.file_exists "${SYSTEM_USER}"; then
  discovery_password="$(pwgen 64 1)"
  service_password="$(pwgen 64 1)"

  # Store it for future use
  bashio::var.json \
    homeassistant "^$(bashio::var.json password "${discovery_password}")" \
    addons "^$(bashio::var.json password "${service_password}")" \
    > "${SYSTEM_USER}"
else
  # Read the existing values
  discovery_password=$(bashio::jq "${SYSTEM_USER}" ".homeassistant.password")
  service_password=$(bashio::jq "${SYSTEM_USER}" ".addons.password")
fi

# Set up discovery user
password=$(pw -p "${discovery_password}")
echo "homeassistant:${password}" >> "${PW}"
echo "user homeassistant" >> "${ACL}"

# Set up service user
password=$(pw -p "${service_password}")
echo "addons:${password}" >> "${PW}"
echo "user addons" >> "${ACL}"

# Set username and password for the broker
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

# LDAP options
ldap_enabled="false"
ldap_url=""
ldap_user_dn=""
ldap_group_dn=""
ldap_bind_dn=""
ldap_bind_password=""
ldap_user_filter=""
ldap_superuser_filter=""

if bashio::config.true 'ldap.enabled'; then
  bashio::config.require 'ldap.url'
  bashio::config.require 'ldap.user_dn'
  bashio::config.require 'ldap.user_filter'

  ldap_enabled="true"
  ldap_url=$(bashio::config 'ldap.url')
  ldap_user_dn=$(bashio::config 'ldap.user_dn')
  ldap_group_dn=$(bashio::config 'ldap.group_dn')
  ldap_bind_dn=$(bashio::config 'ldap.bind_dn')
  ldap_bind_password=$(bashio::config 'ldap.bind_password')
  ldap_user_filter=$(bashio::config 'ldap.user_filter')
  ldap_superuser_filter=$(bashio::config 'ldap.superuser_filter')
  bashio::log.info "LDAP authentication backend enabled"
else
  bashio::log.info "LDAP authentication backend disabled"
fi

# Get log options as raw JSON types for tempio
options=$(bashio::addon.config)
log_dest=$(jq -c ".log_dest" <<<"$options")
log_type=$(jq -c ".log_type" <<<"$options")

# Generate mosquitto configuration.
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
  ldap_enabled "^${ldap_enabled}" \
  ldap_url "${ldap_url}" \
  ldap_user_dn "${ldap_user_dn}" \
  ldap_group_dn "${ldap_group_dn}" \
  ldap_bind_dn "${ldap_bind_dn}" \
  ldap_bind_password "${ldap_bind_password}" \
  ldap_user_filter "${ldap_user_filter}" \
  ldap_superuser_filter "${ldap_superuser_filter}" \
  | tempio \
    -template /usr/share/tempio/mosquitto.gtpl \
    -out /etc/mosquitto/mosquitto.conf
