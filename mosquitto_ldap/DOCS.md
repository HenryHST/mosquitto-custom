# Home Assistant App: Mosquitto broker (LDAP)

Eclipse Mosquitto MQTT broker with Home Assistant users **and** optional LDAP
via [mosquitto-go-auth](https://github.com/iegomez/mosquitto-go-auth).

Derived from the [official Mosquitto app](https://github.com/home-assistant/addons/tree/master/mosquitto).

## Installation

1. **Stop and uninstall** the official Mosquitto broker app (port 1883 conflict).
2. Settings → Apps → App store → ⋮ → Repositories.
3. Add: `https://github.com/HenryHST/mosquitto-custom`
4. Install **Mosquitto broker (LDAP)**.
5. Start the app. Home Assistant should discover MQTT automatically.

Quick add repository:

[![Open your Home Assistant instance and show the add add-on repository dialog with a specific repository URL pre-filled.](https://my.home-assistant.io/badges/supervisor_add_addon_repository.svg)](https://my.home-assistant.io/redirect/supervisor_add_addon_repository/?repository_url=https%3A%2F%2Fgithub.com%2FHenryHST%2Fmosquitto-custom)

## Authentication backends

Checked in order:

1. **files** — local `logins` plus internal `homeassistant` / `addons` users
2. **http** — Home Assistant users (Supervisor `auth_api`)
3. **ldap** — optional directory (Authentik, Active Directory, OpenLDAP, …)

## Configuration

Base options match the official Mosquitto app (`logins`, TLS certs, `customize`, logging).

### LDAP options

| Option | Description |
|--------|-------------|
| `ldap.enabled` | Enable LDAP backend |
| `ldap.url` | e.g. `ldap://ldap.example.com:389` or `ldaps://…` |
| `ldap.user_dn` | User search base DN |
| `ldap.group_dn` | Group search base DN |
| `ldap.bind_dn` | Bind DN (empty for anonymous bind) |
| `ldap.bind_password` | Bind password |
| `ldap.user_filter` | User filter; `%s` = username |
| `ldap.superuser_filter` | Superuser filter; `%s` = username |

Example (Authentik-style groups):

```yaml
ldap:
  enabled: true
  url: "ldap://ldap.example.com:389"
  user_dn: "ou=users,dc=ldap,dc=example,dc=com"
  group_dn: "ou=groups,dc=ldap,dc=example,dc=com"
  bind_dn: "cn=ldapservice,ou=users,dc=ldap,dc=example,dc=com"
  bind_password: "secret"
  user_filter: "(&(cn=%s)(|(memberOf=cn=mqtt_users,ou=groups,dc=ldap,dc=example,dc=com)(memberOf=cn=mqtt_admins,ou=groups,dc=ldap,dc=example,dc=com)))"
  superuser_filter: "(&(cn=%s)(memberOf=cn=mqtt_admins,ou=groups,dc=ldap,dc=example,dc=com))"
```

Prefer `ldaps://` when LDAP is exposed outside a trusted network.

### Option: `logins` (optional)

Local MQTT users (in addition to HA and LDAP users).

### Option: `customize`

Same as the official app: include extra `*.conf` from `/share/<folder>`.

**Do not** put `auth_opt_*` plugin options in included files when using the built-in LDAP UI options — keep plugin auth in the generated config.

### Home Assistant users

MQTT clients can use Home Assistant credentials. Internal users `homeassistant` and `addons` are reserved.

If you enable ACL files via customize, grant those users `readwrite #` or Home Assistant will break.

## Not for Kubernetes / minilab

This Supervisor app image is **not** a drop-in for
[minilab `apps/infra/mosquitto`](https://github.com/HenryHST/minilab/tree/main/apps/infra/mosquitto).
For K8s, use `ghcr.io/henryhst/mosquitto-custom` (LDAP-only standalone image). See [ADR-0029](https://github.com/HenryHST/minilab/blob/main/docs/adr/0029-mosquitto.md).

## Support

- App issues: [HenryHST/mosquitto-custom](https://github.com/HenryHST/mosquitto-custom/issues)
- Upstream broker docs: [Eclipse Mosquitto](https://mosquitto.org/)
- Auth plugin: [iegomez/mosquitto-go-auth](https://github.com/iegomez/mosquitto-go-auth) (archived)
