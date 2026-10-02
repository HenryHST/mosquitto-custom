# Changelog

## [1.0.0] - 2026-10-02

### Added

- Home Assistant app based on the official Mosquitto broker app
- Home Assistant user auth (`files` + `http` / `auth_api`) retained
- Optional LDAP backend via mosquitto-go-auth (`files,http,ldap`)
- Prebuilt multi-arch images: `ghcr.io/henryhst/{arch}-addon-mosquitto-ldap`

### Components

- Eclipse Mosquitto 2.1.2
- mosquitto-go-auth 3.0.0
- libwebsockets 4.5.8

### Notes

- Derived from [home-assistant/addons mosquitto](https://github.com/home-assistant/addons/tree/master/mosquitto)
- Standalone K8s image remains `ghcr.io/henryhst/mosquitto-custom` (minilab)
