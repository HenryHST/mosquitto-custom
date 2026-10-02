# Mosquitto Custom Image

Custom Eclipse Mosquitto MQTT broker with [mosquitto-go-auth](https://github.com/iegomez/mosquitto-go-auth) LDAP authentication plugin.

## Features

- **Eclipse Mosquitto 2.1.2-alpine** — standalone / Kubernetes image
- **mosquitto-go-auth 3.0.0** — LDAP authentication plugin
- **Multi-architecture** — `linux/amd64` and `linux/arm64`
- **Home Assistant app** — optional Supervisor app with HA users **and** LDAP
- **Automated builds** — GitHub Actions for standalone + app images

## Quick Start (standalone / minilab)

```bash
docker pull ghcr.io/henryhst/mosquitto-custom:latest
```

```bash
docker run -d \
  --name mosquitto \
  -p 1883:1883 \
  -p 8883:8883 \
  -p 9001:9001 \
  -v $(pwd)/mosquitto.conf:/mosquitto/config/mosquitto.conf \
  ghcr.io/henryhst/mosquitto-custom:latest
```

minilab contract: plugin at `/mosquitto/go-auth.so`, user `1883:1883`, LDAP-only via your ConfigMap. See [ADR-0029](https://github.com/HenryHST/minilab/blob/main/docs/adr/0029-mosquitto.md).

## Home Assistant App

Install as a custom repository (stop the official Mosquitto app first):

[![Open your Home Assistant instance and show the add add-on repository dialog with a specific repository URL pre-filled.](https://my.home-assistant.io/badges/supervisor_add_addon_repository.svg)](https://my.home-assistant.io/redirect/supervisor_add_addon_repository/?repository_url=https%3A%2F%2Fgithub.com%2FHenryHST%2Fmosquitto-custom)

Repository URL: `https://github.com/HenryHST/mosquitto-custom`

App slug: **Mosquitto broker (LDAP)** (`mosquitto_ldap`)

- Keeps Home Assistant user auth (`files` + `http`)
- Optional LDAP backend (`files,http,ldap`)
- Images: `ghcr.io/henryhst/{arch}-addon-mosquitto-ldap`

Full docs: [mosquitto_ldap/DOCS.md](mosquitto_ldap/DOCS.md)

## Configuration (standalone LDAP)

### Basic mosquitto.conf with LDAP Authentication

```conf
# Persistence
persistence true
persistence_location /mosquitto/data/

# Logging
log_dest stdout
log_type error
log_type warning
log_type notice

# Disable anonymous access
allow_anonymous false
per_listener_settings false

# Listeners
listener 1883
protocol mqtt

listener 8883
protocol mqtt
certfile /mosquitto/certs/tls.crt
keyfile /mosquitto/certs/tls.key
require_certificate false

# mosquitto-go-auth plugin
auth_plugin /mosquitto/go-auth.so
auth_opt_backends ldap
auth_opt_log_level info
auth_opt_log_dest stdout

# LDAP Configuration
auth_opt_ldap_url ldap://ldap.example.com:389
auth_opt_ldap_user_dn ou=users,dc=example,dc=com
auth_opt_ldap_group_dn ou=groups,dc=example,dc=com
auth_opt_ldap_bind_dn cn=serviceaccount,ou=users,dc=example,dc=com
auth_opt_ldap_bind_password your_bind_password

# LDAP Filters
auth_opt_ldap_user_filter (&(cn=%s)(memberOf=cn=mqtt_users,ou=groups,dc=example,dc=com))
auth_opt_ldap_superuser_filter (&(cn=%s)(memberOf=cn=mqtt_admins,ou=groups,dc=example,dc=com))
```

## Kubernetes Deployment

For Kubernetes deployment example with Authentik LDAP, see:

- [minilab mosquitto configuration](https://github.com/HenryHST/minilab/tree/main/apps/infra/mosquitto)
- [ADR-0029: Mosquitto](https://github.com/HenryHST/minilab/blob/main/docs/adr/0029-mosquitto.md)

Do **not** deploy the Home Assistant app image into the cluster; use `ghcr.io/henryhst/mosquitto-custom`.

## Building Locally

Standalone:

```bash
docker build -t mosquitto-custom:local .
```

Home Assistant app (amd64 example):

```bash
docker build \
  -f mosquitto_ldap/Dockerfile \
  --build-arg BUILD_FROM=ghcr.io/home-assistant/amd64-base-debian:trixie \
  --build-arg LIBWEBSOCKET_VERSION=4.5.8 \
  --build-arg MOSQUITTO_VERSION=2.1.2 \
  --build-arg MOSQUITTO_AUTH_VERSION=3.0.0 \
  -t amd64-addon-mosquitto-ldap:local \
  mosquitto_ldap
```

## Versions

| Component | Standalone | HA App |
|-----------|------------|--------|
| Eclipse Mosquitto | 2.1.2-alpine | 2.1.2 (from source) |
| mosquitto-go-auth | 3.0.0 | 3.0.0 |
| Base | `eclipse-mosquitto:2.1.2-alpine` | HA Debian trixie |
| Go (build) | 1.22 | Debian golang |

## Security Considerations

- **Use TLS/SSL** for production LDAP connections (`ldaps://`) when LDAP is not on a trusted network
- **Secure credentials** — never commit LDAP bind passwords
- **Network isolation** — run MQTT brokers in isolated networks when possible
- go-auth upstream is [archived](https://github.com/iegomez/mosquitto-go-auth); pin versions carefully

## Available Tags

Standalone (`ghcr.io/henryhst/mosquitto-custom`):

- `latest`, `main`, `v*`, short SHA

HA app (`ghcr.io/henryhst/{amd64\|aarch64}-addon-mosquitto-ldap`):

- `latest`, version from `mosquitto_ldap/config.yaml`

## License

This project combines:

- Eclipse Mosquitto — [EPL-2.0 / EDL-1.0](https://github.com/eclipse/mosquitto/blob/master/LICENSE.txt)
- mosquitto-go-auth — [MIT License](https://github.com/iegomez/mosquitto-go-auth/blob/master/LICENSE)
- HA app derived from [home-assistant/addons](https://github.com/home-assistant/addons) (Apache-2.0)

## Links

- [Eclipse Mosquitto](https://mosquitto.org/)
- [mosquitto-go-auth](https://github.com/iegomez/mosquitto-go-auth)
- [minilab Infrastructure](https://github.com/HenryHST/minilab)
- [Issue #100: Add custom mosquitto image](https://github.com/HenryHST/minilab/issues/100)

## Support

This is a personal infrastructure project. For issues or questions, please open an issue in the [GitHub repository](https://github.com/HenryHST/mosquitto-custom/issues).
