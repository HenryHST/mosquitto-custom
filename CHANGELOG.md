# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [1.1.0] - 2026-10-02

### Added
- Vendored `third_party/mosquitto-go-auth` (upstream 3.0.0 + maintenance/LDAP patches)
- HA app: full LDAP ACL options + `go_auth` global/advanced configuration
- Examples under `examples/go-auth/`

### Changed
- Standalone and HA images build the plugin from the vendored tree (no upstream git clone)
- HA app version `1.1.0`

## [1.0.0] - 2026-10-02

### Added
- Initial release of mosquitto-custom Docker image
- Eclipse Mosquitto 2.1.2-alpine base
- mosquitto-go-auth 3.0.0 LDAP authentication plugin
- Multi-architecture support (linux/amd64, linux/arm64)
- Home Assistant app `mosquitto_ldap` (HA users + optional LDAP)
- GitHub Actions workflow for standalone + app image builds
- Example configuration files
- Docker Compose example
- Comprehensive documentation
- Security policy and considerations

### Components
- Eclipse Mosquitto: 2.1.2-alpine (standalone) / 2.1.2 (HA app)
- mosquitto-go-auth: vendored 3.0.0 + patches
- Go: 1.24 (standalone build; go-auth 3.0.0 requirement)
- Base: eclipse-mosquitto:2.1.2-alpine

### Security
- LDAP authentication via mosquitto-go-auth plugin
- TLS/SSL support for MQTT and WebSockets
- Configurable ACL support

[1.1.0]: https://github.com/HenryHST/mosquitto-custom/releases/tag/v1.1.0
[1.0.0]: https://github.com/HenryHST/mosquitto-custom/releases/tag/v1.0.0
