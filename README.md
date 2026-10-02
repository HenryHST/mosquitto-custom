# Mosquitto Custom Image

Custom Eclipse Mosquitto MQTT broker with a vendored
[mosquitto-go-auth](third_party/mosquitto-go-auth/) fork (upstream
[iegomez/mosquitto-go-auth](https://github.com/iegomez/mosquitto-go-auth) 3.0.0 +
maintenance / LDAP patches).

## Features

- **Eclipse Mosquitto 2.1.2-alpine** — standalone / Kubernetes image
- **Vendored go-auth** — all upstream backends compiled in; LDAP first-class
- **Multi-architecture** — `linux/amd64` and `linux/arm64`
- **Home Assistant app** — HA users + optional LDAP + advanced go-auth options
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

[![Open your Home Assistant instance and show the add add-on repository dialog with a specific repository URL pre-filled.](https://my.home-assistant.io/badges/supervisor_add_addon_repository.svg)](https://my.home-assistant.io/redirect/supervisor_add_addon_repository/?repository_url=https%3A%2F%2Fgithub.com%2FHenryHST%2Fmosquitto-custom)

Repository URL: `https://github.com/HenryHST/mosquitto-custom`

App: **Mosquitto broker (LDAP)** (`mosquitto_ldap` v1.1.0+)

- Keeps Home Assistant user auth (`files` + `http`)
- Optional LDAP (full filters + ACL attributes)
- `go_auth` UI for cache/hasher/retry + `extra_backends` / `extra_options` for jwt/redis/postgres/…

Docs: [mosquitto_ldap/DOCS.md](mosquitto_ldap/DOCS.md)

## go-auth feature coverage

| Capability | Standalone | HA App |
|------------|------------|--------|
| Plugin source | `third_party/mosquitto-go-auth` | same |
| LDAP | ConfigMap / conf file | Structured options |
| files / http (HA users) | via conf | Built-in |
| jwt, redis, postgres, … | conf examples | `go_auth.extra_*` |
| Global cache / hasher | conf | Structured options |

Examples: [examples/go-auth/](examples/go-auth/), [examples/mosquitto.conf](examples/mosquitto.conf)  
Vendor notes: [third_party/mosquitto-go-auth/README.vendored.md](third_party/mosquitto-go-auth/README.vendored.md)

## Configuration (standalone LDAP)

```conf
auth_plugin /mosquitto/go-auth.so
auth_opt_backends ldap
auth_opt_ldap_url ldap://ldap.example.com:389
auth_opt_ldap_user_dn ou=users,dc=example,dc=com
auth_opt_ldap_group_dn ou=groups,dc=example,dc=com
auth_opt_ldap_bind_dn cn=serviceaccount,ou=users,dc=example,dc=com
auth_opt_ldap_bind_password your_bind_password
auth_opt_ldap_user_filter (&(cn=%s)(memberOf=cn=mqtt_users,ou=groups,dc=example,dc=com))
auth_opt_ldap_superuser_filter (&(cn=%s)(memberOf=cn=mqtt_admins,ou=groups,dc=example,dc=com))
auth_opt_ldap_group_filter (member=%s)
```

## Kubernetes Deployment

- [minilab mosquitto](https://github.com/HenryHST/minilab/tree/main/apps/infra/mosquitto)
- [ADR-0029](https://github.com/HenryHST/minilab/blob/main/docs/adr/0029-mosquitto.md)

Do **not** deploy the Home Assistant app image into the cluster.

## Building Locally

```bash
docker build -t mosquitto-custom:local .
```

HA app (repo-root context):

```bash
docker build \
  -f mosquitto_ldap/Dockerfile \
  --build-arg BUILD_FROM=ghcr.io/home-assistant/amd64-base-debian:trixie \
  --build-arg LIBWEBSOCKET_VERSION=4.5.8 \
  --build-arg MOSQUITTO_VERSION=2.1.2 \
  -t amd64-addon-mosquitto-ldap:local \
  .
```

## Versions

| Component | Standalone | HA App |
|-----------|------------|--------|
| Eclipse Mosquitto | 2.1.2-alpine | 2.1.2 (from source) |
| mosquitto-go-auth | vendored 3.0.0+patches | same |
| Base | `eclipse-mosquitto:2.1.2-alpine` | HA Debian trixie |
| Go (build) | 1.24 | Debian golang |

## Security

See [SECURITY.md](SECURITY.md). Prefer `ldaps://`, never commit bind passwords, avoid plugin debug logs in production.

## License

- Eclipse Mosquitto — EPL-2.0 / EDL-1.0
- mosquitto-go-auth — MIT (`third_party/mosquitto-go-auth`)
- HA app structure — derived from home-assistant/addons (Apache-2.0)

See [LICENSE](LICENSE) and [third_party/NOTICE](third_party/NOTICE).

## Links

- [Eclipse Mosquitto](https://mosquitto.org/)
- [mosquitto-go-auth](https://github.com/iegomez/mosquitto-go-auth)
- [minilab](https://github.com/HenryHST/minilab)
- [Issue #100](https://github.com/HenryHST/minilab/issues/100)
