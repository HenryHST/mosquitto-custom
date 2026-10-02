# Multi-arch Mosquitto with mosquitto-go-auth LDAP plugin
# Based on Eclipse Mosquitto 2.1.2 + iegomez/mosquitto-go-auth
# Supports: linux/amd64, linux/arm64

ARG MOSQUITTO_VERSION=2.1.2
ARG GO_AUTH_VERSION=2.1.0

# Stage 1: Build mosquitto-go-auth plugin
FROM golang:1.21-alpine AS builder

ARG GO_AUTH_VERSION
ARG TARGETARCH

RUN apk add --no-cache git make gcc g++ musl-dev openssl-dev

WORKDIR /build

# Clone mosquitto-go-auth at specified version
RUN git clone --depth 1 --branch ${GO_AUTH_VERSION} https://github.com/iegomez/mosquitto-go-auth.git .

# Build the plugin
RUN make

# Stage 2: Build final image with Mosquitto + plugin
FROM eclipse-mosquitto:${MOSQUITTO_VERSION}

ARG MOSQUITTO_VERSION
ARG GO_AUTH_VERSION

LABEL org.opencontainers.image.title="Mosquitto with go-auth LDAP" \
      org.opencontainers.image.description="Eclipse Mosquitto ${MOSQUITTO_VERSION} with mosquitto-go-auth ${GO_AUTH_VERSION} LDAP authentication plugin" \
      org.opencontainers.image.source="https://github.com/HenryHST/mosquitto-custom" \
      org.opencontainers.image.licenses="EPL-2.0 AND MIT"

# Copy the built plugin from builder stage
COPY --from=builder /build/go-auth.so /mosquitto/go-auth.so

# Ensure plugin is readable
RUN chmod 755 /mosquitto/go-auth.so

# Mosquitto runs as user mosquitto (1883:1883)
USER mosquitto

EXPOSE 1883 8883 9001

CMD ["/usr/sbin/mosquitto", "-c", "/mosquitto/config/mosquitto.conf"]
