user root
{{ if .log_dest }}
# custom log_dest
{{ range .log_dest }}log_dest {{ . }}
{{ end }}
{{ else }}
log_dest stdout
{{ end }}
{{ if .debug }}
log_type all
{{ else if .log_type }}
{{ range .log_type }}log_type {{ . }}
{{ end }}
{{ else }}
log_type error
log_type warning
log_type notice
log_type information
{{ end }}
log_timestamp_format %Y-%m-%d %H:%M:%S
persistence true
persistence_location /data/

# Limits
max_queued_messages 8192

# Authentication plugin
auth_plugin /usr/share/mosquitto/go-auth.so
auth_plugin_deny_special_chars false
auth_opt_backends {{ .auth_backends }}
auth_opt_hasher {{ .hasher }}
{{ if eq .hasher "pbkdf2" }}
auth_opt_hasher_iterations {{ .hasher_iterations }}
auth_opt_hasher_salt_size {{ .hasher_salt_size }}
{{ end }}
auth_opt_cache {{ .cache }}
auth_opt_cache_type {{ .cache_type }}
{{ if .cache_reset }}
auth_opt_cache_reset true
{{ end }}
{{ if .cache_refresh }}
auth_opt_cache_refresh true
{{ end }}
auth_opt_auth_cache_seconds {{ .auth_cache_seconds }}
auth_opt_acl_cache_seconds {{ .acl_cache_seconds }}
auth_opt_auth_jitter_seconds {{ .auth_jitter_seconds }}
auth_opt_acl_jitter_seconds {{ .acl_jitter_seconds }}
{{ if eq .cache_type "redis" }}
auth_opt_cache_host {{ .cache_host }}
auth_opt_cache_port {{ .cache_port }}
{{ if .cache_password }}
auth_opt_cache_password {{ .cache_password }}
{{ end }}
auth_opt_cache_db {{ .cache_db }}
{{ end }}
auth_opt_log_level {{ if .debug }}debug{{ else }}error{{ end }}
auth_opt_log_dest {{ .plugin_log_dest }}
{{ if eq .plugin_log_dest "file" }}
auth_opt_log_file {{ .plugin_log_file }}
{{ end }}
{{ if .exhaust_backend_first }}
auth_opt_exhaust_backend_first true
{{ end }}
{{ if .use_clientid_as_username }}
auth_opt_use_clientid_as_username true
{{ end }}
{{ if .disable_superuser }}
auth_opt_disable_superuser true
{{ end }}
auth_opt_retry_count {{ .retry_count }}
{{ if .check_prefix }}
auth_opt_check_prefix true
auth_opt_strip_prefix {{ .strip_prefix }}
auth_opt_prefixes {{ .prefixes }}
{{ end }}

# Files backend (local logins + homeassistant/addons system users)
auth_opt_files_password_path /etc/mosquitto/pw
auth_opt_files_acl_path /etc/mosquitto/acl

# HTTP backend (Home Assistant users via Supervisor auth_api)
auth_opt_http_host 127.0.0.1
auth_opt_http_port 80
auth_opt_http_getuser_uri /authentication
auth_opt_http_superuser_uri /superuser
auth_opt_http_aclcheck_uri /acl

{{ if .ldap_enabled }}
# LDAP backend (optional; checked after files and http unless exhaust_backend_first)
auth_opt_ldap_url {{ .ldap_url }}
auth_opt_ldap_user_dn {{ .ldap_user_dn }}
auth_opt_ldap_group_dn {{ .ldap_group_dn }}
{{ if .ldap_bind_dn }}
auth_opt_ldap_bind_dn {{ .ldap_bind_dn }}
{{ end }}
{{ if .ldap_bind_password }}
auth_opt_ldap_bind_password {{ .ldap_bind_password }}
{{ end }}
auth_opt_ldap_user_filter {{ .ldap_user_filter }}
{{ if .ldap_superuser_filter }}
auth_opt_ldap_superuser_filter {{ .ldap_superuser_filter }}
{{ end }}
{{ if .ldap_group_filter }}
auth_opt_ldap_group_filter {{ .ldap_group_filter }}
{{ end }}
{{ if .ldap_acl_topic_pattern_attribute }}
auth_opt_ldap_acl_topic_pattern_attribute {{ .ldap_acl_topic_pattern_attribute }}
{{ end }}
{{ if .ldap_acl_acc_attribute }}
auth_opt_ldap_acl_acc_attribute {{ .ldap_acl_acc_attribute }}
{{ end }}
{{ end }}

{{ if .customize }}
include_dir /share/{{ .customize_folder }}
{{ end }}

listener 1883
protocol mqtt

listener 1884
protocol websockets

{{ if .ssl }}

listener 8883
protocol mqtt
{{ if .cafile }}
cafile {{ .cafile }}
{{ else }}
cafile {{ .certfile }}
{{ end }}
certfile {{ .certfile }}
keyfile {{ .keyfile }}
require_certificate {{ .require_certificate }}

listener 8884
protocol websockets
{{ if .cafile }}
cafile {{ .cafile }}
{{ else }}
cafile {{ .certfile }}
{{ end }}
certfile {{ .certfile }}
keyfile {{ .keyfile }}
require_certificate {{ .require_certificate }}

{{ end }}
