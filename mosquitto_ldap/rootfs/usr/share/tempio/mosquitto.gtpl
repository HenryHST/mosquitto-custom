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
# max_queued_messages is effectively the upper limit of
# the number of entities on Home Assistant if startup
# is busy and cannot read messages fast enough
max_queued_messages 8192

# Authentication plugin
auth_plugin /usr/share/mosquitto/go-auth.so
# Restore pre-7.0 behaviour: allow '/' in client ids and usernames.
# The addon's ACL file does not use pattern substitution (%c/%u), so
# mosquitto 2.1's broker-side rejection of +, #, / is not needed here.
auth_plugin_deny_special_chars false
{{ if .ldap_enabled }}
auth_opt_backends files,http,ldap
{{ else }}
auth_opt_backends files,http
{{ end }}
auth_opt_hasher pbkdf2
auth_opt_cache true
auth_opt_auth_cache_seconds 300
auth_opt_auth_jitter_seconds 30
auth_opt_acl_cache_seconds 300
auth_opt_acl_jitter_seconds 30
auth_opt_log_level {{ if .debug }}debug{{ else }}error{{ end }}

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
# LDAP backend (optional; checked after files and http)
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
{{ end }}

{{ if .customize }}
include_dir /share/{{ .customize_folder }}
{{ end }}

listener 1883
protocol mqtt

listener 1884
protocol websockets

{{ if .ssl }}

# Follow SSL listener if a certificate exists
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
