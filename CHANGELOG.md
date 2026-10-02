# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [1.0.0] - 2026-10-02

### Added
- Initial release of mosquitto-custom Docker image
- Eclipse Mosquitto 2.1.2 base
- mosquitto-go-auth 2.1.0 LDAP authentication plugin
- Multi-architecture support (linux/amd64, linux/arm64)
- GitHub Actions workflow for automated builds
- Example configuration files
- Docker Compose example
- Comprehensive documentation
- Security policy and considerations

### Components
- Eclipse Mosquitto: 2.1.2
- mosquitto-go-auth: 2.1.0
- Go: 1.21
- Base: eclipse-mosquitto:2.1.2

### Security
- LDAP authentication via mosquitto-go-auth plugin
- TLS/SSL support for MQTT and WebSockets
- Configurable ACL support

[1.0.0]: https://github.com/HenryHST/mosquitto-custom/releases/tag/v1.0.0
