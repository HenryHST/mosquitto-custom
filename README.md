# Mosquitto Custom Image

Custom Eclipse Mosquitto MQTT broker with [mosquitto-go-auth](https://github.com/iegomez/mosquitto-go-auth) LDAP authentication plugin.

## Features

- **Eclipse Mosquitto 2.1.2-alpine** - Stable MQTT broker
- **mosquitto-go-auth 2.1.0** - LDAP authentication plugin
- **Multi-architecture support** - `linux/amd64` and `linux/arm64`
- **Automated builds** - GitHub Actions workflow for CI/CD

## Quick Start

Pull the image from GitHub Container Registry:

```bash
docker pull ghcr.io/henryhst/mosquitto-custom:latest
```

Run with a custom configuration:

```bash
docker run -d \
  --name mosquitto \
  -p 1883:1883 \
  -p 8883:8883 \
  -p 9001:9001 \
  -v $(pwd)/mosquitto.conf:/mosquitto/config/mosquitto.conf \
  ghcr.io/henryhst/mosquitto-custom:latest
```

## Configuration

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

## Building Locally

Build for your current platform:

```bash
docker build -t mosquitto-custom:local .
```

Build for multiple architectures:

```bash
docker buildx build --platform linux/amd64,linux/arm64 -t mosquitto-custom:local .
```

## Versions

| Component | Version |
|-----------|---------|
| Eclipse Mosquitto | 2.1.2-alpine |
| mosquitto-go-auth | 2.1.0 |
| Base Image | `eclipse-mosquitto:2.1.2-alpine` |
| Go | 1.21 |

## Security Considerations

This image includes the mosquitto-go-auth plugin for LDAP authentication. Note:

- **Use TLS/SSL** for production LDAP connections (`ldaps://`)
- **Secure credentials** - Never commit LDAP bind passwords to version control
- **Network isolation** - Run MQTT brokers in isolated networks when possible
- **Regular updates** - Monitor for security updates to Mosquitto and go-auth

For detailed security review of mosquitto-go-auth, see the [security assessment](https://github.com/HenryHST/minilab/issues/100).

## Available Tags

- `latest` - Latest build from main branch
- `v1.x.x` - Semantic versioned releases
- `main` - Main branch build
- `<sha>` - Specific commit SHA builds

## License

This project combines:
- Eclipse Mosquitto - [EPL-2.0 / EDL-1.0](https://github.com/eclipse/mosquitto/blob/master/LICENSE.txt)
- mosquitto-go-auth - [MIT License](https://github.com/iegomez/mosquitto-go-auth/blob/master/LICENSE)

See individual component repositories for detailed license information.

## Links

- [Eclipse Mosquitto](https://mosquitto.org/)
- [mosquitto-go-auth](https://github.com/iegomez/mosquitto-go-auth)
- [minilab Infrastructure](https://github.com/HenryHST/minilab)
- [Issue #100: Add custom mosquitto image](https://github.com/HenryHST/minilab/issues/100)

## Support

This is a personal infrastructure project. For issues or questions, please open an issue in the [GitHub repository](https://github.com/HenryHST/mosquitto-custom/issues).
