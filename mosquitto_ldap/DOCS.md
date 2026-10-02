# Home Assistant App: Mosquitto broker (LDAP)

Eclipse Mosquitto MQTT broker with Home Assistant users **and** optional LDAP
via a vendored [mosquitto-go-auth](../third_party/mosquitto-go-auth/) fork
(upstream [iegomez/mosquitto-go-auth](https://github.com/iegomez/mosquitto-go-auth) 3.0.0 + maintenance patches).

Derived from the [official Mosquitto app](https://github.com/home-assistant/addons/tree/master/mosquitto).

## Installation

1. **Stop and uninstall** the official Mosquitto broker app (port 1883 conflict).
2. Settings → Apps → App store → ⋮ → Repositories.
3. Add: `https://github.com/HenryHST/mosquitto-custom`
4. Install **Mosquitto broker (LDAP)** (`1.1.0+`).
5. Start the app. Home Assistant should discover MQTT automatically.

[![Open your Home Assistant instance and show the add add-on repository dialog with a specific repository URL pre-filled.](https://my.home-assistant.io/badges/supervisor_add_addon_repository.svg)](https://my.home-assistant.io/redirect/supervisor_add_addon_repository/?repository_url=https%3A%2F%2Fgithub.com%2FHenryHST%2Fmosquitto-custom)

## Authentication backends

Checked in order (unless `go_auth.exhaust_backend_first` is enabled):

1. **files** — local `logins` plus internal `homeassistant` / `addons` users
2. **http** — Home Assistant users (Supervisor `auth_api`)
3. **ldap** — optional directory (Authentik, Active Directory, OpenLDAP, lldap, …)
4. **extra** — optional backends from `go_auth.extra_backends` (jwt, redis, postgres, …)

### Feature coverage (go-auth)

| Area | Structured UI | Advanced (`extra_options`) |
|------|---------------|----------------------------|
| files + http (HA) | yes (fixed) | — |
| LDAP (full options) | yes | yes |
| Global cache / hasher / retry / prefixes | yes | yes |
| postgres, jwt, redis, mysql, mongo, grpc, js | via `extra_backends` + `extra_options` | yes |

The compiled plugin includes **all** upstream backends; only configuration differs.

## Configuration

### LDAP options

| Option | Description |
|--------|-------------|
| `ldap.enabled` | Enable LDAP backend |
| `ldap.url` | e.g. `ldap://…` or `ldaps://…` |
| `ldap.user_dn` / `ldap.group_dn` | Search bases |
| `ldap.bind_dn` / `ldap.bind_password` | Service bind (required when LDAP enabled) |
| `ldap.user_filter` / `ldap.superuser_filter` | `%s` = username |
| `ldap.group_filter` | Default `(member=%s)`; used for ACL group search |
| `ldap.acl_topic_pattern_attribute` | Optional LDAP attribute with topic patterns |
| `ldap.acl_acc_attribute` | Optional access level attribute (bitmask) |

When ACL attributes are set, `ldap.group_dn` is required. Without them, authenticated LDAP users get full pub/sub (upstream behaviour).

### go_auth options

| Option | Description |
|--------|-------------|
| `exhaust_backend_first` | Per-backend superuser then ACL before next backend |
| `use_clientid_as_username` | Use client id as username for checks |
| `disable_superuser` | Disable all superuser checks |
| `retry_count` | Retries when a backend errors |
| `cache` / `cache_type` | `go-cache` or `redis` (+ host/port/password/db) |
| `hasher` | `pbkdf2` (default), `bcrypt`, `argon2id` |
| `log_dest` / `log_file` | Plugin log destination (`stdout`/`stderr`/`file`) |
| `check_prefix` / `strip_prefix` / `prefixes` | Backend prefix routing |
| `extra_backends` | Comma list appended after files,http[,ldap] |
| `extra_options` | Raw `auth_opt_*` lines injected after `auth_plugin` |

**Guardrails for `extra_options`:**

- Do **not** set `auth_plugin` again.
- Keep internal users `homeassistant` / `addons` unrestricted if you customize ACLs.
- Never set plugin `log_level` to `debug` in production (may log secrets).

### Example: LDAP + Redis cache

```yaml
ldap:
  enabled: true
  url: "ldap://ldap.example.com:389"
  user_dn: "ou=users,dc=ldap,dc=example,dc=com"
  group_dn: "ou=groups,dc=ldap,dc=example,dc=com"
  bind_dn: "cn=ldapservice,ou=users,dc=ldap,dc=example,dc=com"
  bind_password: "secret"
  user_filter: "(&(cn=%s)(memberOf=cn=mqtt_users,ou=groups,dc=ldap,dc=example,dc=com))"
  superuser_filter: "(&(cn=%s)(memberOf=cn=mqtt_admins,ou=groups,dc=ldap,dc=example,dc=com))"
go_auth:
  cache: true
  cache_type: redis
  cache_host: "core-redis"
  cache_port: "6379"
```

### Example: Advanced JWT backend

```yaml
go_auth:
  extra_backends: "jwt"
  extra_options: |
    auth_opt_jwt_mode remote
    auth_opt_jwt_host auth.example.com
    auth_opt_jwt_port 443
    auth_opt_jwt_with_tls true
    auth_opt_jwt_getuser_uri /auth
    auth_opt_jwt_superuser_uri /superuser
    auth_opt_jwt_aclcheck_uri /acl
```

## Not for Kubernetes / minilab

Use standalone image `ghcr.io/henryhst/mosquitto-custom` with ConfigMap LDAP
([ADR-0029](https://github.com/HenryHST/minilab/blob/main/docs/adr/0029-mosquitto.md)).
Do not deploy this Supervisor image into the cluster.

## Test plan

1. Install app with LDAP disabled — HA user MQTT login works.
2. Enable LDAP with a known directory — LDAP user connects; wrong password fails.
3. Set `go_auth.extra_options` with a harmless `auth_opt_log_level info` — config loads; reject if `auth_plugin` is injected.
4. Optional: redis cache against an in-network Redis.

## Support

- [HenryHST/mosquitto-custom](https://github.com/HenryHST/mosquitto-custom/issues)
- Vendored plugin notes: [third_party/mosquitto-go-auth/README.vendored.md](../third_party/mosquitto-go-auth/README.vendored.md)
