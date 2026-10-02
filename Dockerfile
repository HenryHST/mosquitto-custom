# Multi-arch Mosquitto with mosquitto-go-auth LDAP plugin (minilab / K8s)
# Builds Mosquitto 2.1.2 + vendored go-auth on Debian/glibc.
# Alpine/musl cannot load Go c-shared plugins (runtime.tls_g relocation error).
# Supports: linux/amd64, linux/arm64
#
# Contract for minilab (ADR-0029):
# - Plugin path: /mosquitto/go-auth.so
# - User: mosquitto (1883:1883)
# - Conf default: /mosquitto/config/mosquitto.conf
# - No Home Assistant Supervisor dependencies

ARG MOSQUITTO_VERSION=2.1.2
ARG LWS_VERSION=4.5.8

# Stage 1: Mosquitto + libwebsockets from source (glibc)
FROM debian:bookworm-slim AS mosquitto_builder

ARG MOSQUITTO_VERSION
ARG LWS_VERSION

RUN apt-get update \
    && apt-get install -y --no-install-recommends \
        build-essential \
        cmake \
        ca-certificates \
        wget \
        libssl-dev \
        libcjson-dev \
        libc-ares-dev \
        libsqlite3-dev \
    && rm -rf /var/lib/apt/lists/*

WORKDIR /build

RUN wget -q "https://github.com/warmcat/libwebsockets/archive/v${LWS_VERSION}.tar.gz" -O /tmp/lws.tar.gz \
    && mkdir -p /build/lws \
    && tar --strip=1 -xzf /tmp/lws.tar.gz -C /build/lws \
    && rm /tmp/lws.tar.gz \
    && cd /build/lws \
    && cmake . \
        -DCMAKE_BUILD_TYPE=MinSizeRel \
        -DCMAKE_INSTALL_PREFIX=/usr/local \
        -DLWS_IPV6=ON \
        -DLWS_WITHOUT_BUILTIN_GETIFADDRS=ON \
        -DLWS_WITHOUT_CLIENT=ON \
        -DLWS_WITHOUT_EXTENSIONS=ON \
        -DLWS_WITHOUT_TESTAPPS=ON \
        -DLWS_WITH_HTTP2=OFF \
        -DLWS_WITH_SHARED=OFF \
        -DLWS_WITH_ZIP_FOPS=OFF \
        -DLWS_WITH_ZLIB=OFF \
        -DLWS_WITH_EXTERNAL_POLL=ON \
    && make -j"$(nproc)" \
    && make install

RUN wget -q "https://mosquitto.org/files/source/mosquitto-${MOSQUITTO_VERSION}.tar.gz" \
    && tar xzf "mosquitto-${MOSQUITTO_VERSION}.tar.gz" \
    && cd "mosquitto-${MOSQUITTO_VERSION}" \
    && sed -i 's/^WITH_EDITLINE=yes/#WITH_EDITLINE=yes/' config.mk \
    && sed -i 's/^WITH_HTTP_API=yes/#WITH_HTTP_API=yes/' config.mk \
    && make -j"$(nproc)" \
        CFLAGS="-Wall -O2 -I/usr/local/include" \
        LDFLAGS="-L/usr/local/lib" \
        WITH_WEBSOCKETS=yes \
        WITH_DOCS=no \
    && make install \
    && ldconfig

# Stage 2: go-auth plugin (glibc, matches runtime)
FROM golang:1.25-bookworm AS go_auth_builder

RUN apt-get update \
    && apt-get install -y --no-install-recommends gcc libc6-dev libcjson-dev \
    && rm -rf /var/lib/apt/lists/*

COPY --from=mosquitto_builder /usr/local/include/ /usr/local/include/

WORKDIR /build
COPY third_party/mosquitto-go-auth/ ./

RUN make && test -f go-auth.so

# Stage 3: Runtime
FROM debian:bookworm-slim

ARG MOSQUITTO_VERSION

LABEL org.opencontainers.image.title="Mosquitto with go-auth LDAP" \
      org.opencontainers.image.description="Eclipse Mosquitto ${MOSQUITTO_VERSION} with vendored mosquitto-go-auth LDAP authentication plugin (glibc)" \
      org.opencontainers.image.source="https://github.com/HenryHST/mosquitto-custom" \
      org.opencontainers.image.licenses="EPL-2.0 AND MIT"

RUN apt-get update \
    && apt-get install -y --no-install-recommends \
        ca-certificates \
        libc-ares2 \
        libssl3 \
        libcjson1 \
        libsqlite3-0 \
        openssl \
        tini \
    && rm -rf /var/lib/apt/lists/* \
    && groupadd -g 1883 mosquitto \
    && useradd -u 1883 -g 1883 -s /usr/sbin/nologin -d /mosquitto -M mosquitto \
    && mkdir -p /mosquitto/config /mosquitto/data /mosquitto/log /mosquitto/certs \
    && chown -R mosquitto:mosquitto /mosquitto

COPY --from=mosquitto_builder /usr/local/sbin/mosquitto /usr/sbin/mosquitto
COPY --from=mosquitto_builder /usr/local/lib/libmosquitto.so* /usr/local/lib/
COPY --from=mosquitto_builder /usr/local/bin/mosquitto_passwd /usr/bin/mosquitto_passwd
COPY --from=mosquitto_builder /usr/local/bin/mosquitto_sub /usr/bin/mosquitto_sub
COPY --from=mosquitto_builder /usr/local/bin/mosquitto_pub /usr/bin/mosquitto_pub
COPY --from=go_auth_builder /build/go-auth.so /mosquitto/go-auth.so

RUN chmod 755 /mosquitto/go-auth.so \
    && ldconfig

USER mosquitto

EXPOSE 1883 8883 9001

ENTRYPOINT ["/usr/bin/tini", "--"]
CMD ["/usr/sbin/mosquitto", "-c", "/mosquitto/config/mosquitto.conf"]
