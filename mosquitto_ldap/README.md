# Home Assistant App: Mosquitto broker (LDAP)

MQTT broker for Home Assistant with optional LDAP authentication via
[mosquitto-go-auth](https://github.com/iegomez/mosquitto-go-auth).

![Supports aarch64 Architecture][aarch64-shield] ![Supports amd64 Architecture][amd64-shield]

## About

This app is derived from the [official Home Assistant Mosquitto app](https://github.com/home-assistant/addons/tree/master/mosquitto).
It keeps Home Assistant user authentication (`files` + `http` backends) and
adds an optional **LDAP** backend.

For Kubernetes / minilab deployments, use the standalone image
`ghcr.io/henryhst/mosquitto-custom` instead of this app.

[mosquitto]: https://mosquitto.org
[aarch64-shield]: https://img.shields.io/badge/aarch64-yes-green.svg
[amd64-shield]: https://img.shields.io/badge/amd64-yes-green.svg
