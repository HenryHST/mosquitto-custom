# Multi-arch Mosquitto with mosquitto-go-auth LDAP plugin (minilab / K8s)
# Based on Eclipse Mosquitto 2.1.2-alpine + vendored mosquitto-go-auth (3.0.0 + patches)
# Supports: linux/amd64, linux/arm64
# Note: Docker Hub publishes 2.1.x only as *-alpine (no plain 2.1.2 tag)
#
# Contract for minilab (ADR-0029 / issue #100):
# - Plugin path: /mosquitto/go-auth.so
# - User: mosquitto (1883:1883)
# - No Home Assistant Supervisor dependencies

ARG MOSQUITTO_VERSION=2.1.2-alpine

# Stage 1: Build mosquitto-go-auth from third_party (musl, matches alpine final image)
FROM golang:1.24-alpine AS builder

ARG TARGETARCH

RUN apk add --no-cache build-base git openssl-dev mosquitto-dev

WORKDIR /build
COPY third_party/mosquitto-go-auth/ ./

RUN make && test -f go-auth.so

# Stage 2: Final image with Mosquitto + plugin
FROM eclipse-mosquitto:${MOSQUITTO_VERSION}

ARG MOSQUITTO_VERSION

LABEL org.opencontainers.image.title="Mosquitto with go-auth LDAP" \
      org.opencontainers.image.description="Eclipse Mosquitto ${MOSQUITTO_VERSION} with vendored mosquitto-go-auth LDAP authentication plugin" \
      org.opencontainers.image.source="https://github.com/HenryHST/mosquitto-custom" \
      org.opencontainers.image.licenses="EPL-2.0 AND MIT"

COPY --from=builder /build/go-auth.so /mosquitto/go-auth.so

RUN chmod 755 /mosquitto/go-auth.so

USER mosquitto

EXPOSE 1883 8883 9001

CMD ["/usr/sbin/mosquitto", "-c", "/mosquitto/config/mosquitto.conf"]
