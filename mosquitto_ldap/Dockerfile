# Home Assistant app image: Mosquitto + go-auth (HA users + optional LDAP).
# Derived from home-assistant/addons/mosquitto Dockerfile.
# Build context must be the repository root (see .github/workflows/build.yml).
ARG BUILD_FROM
FROM $BUILD_FROM

# Install mosquitto + auth plugin
WORKDIR /usr/src
ARG LIBWEBSOCKET_VERSION
ARG MOSQUITTO_VERSION
COPY third_party/mosquitto-go-auth /usr/src/mosquitto-go-auth
RUN apt-get update \
    && apt-get install -qy --no-install-recommends \
        nginx \
        pwgen \
        build-essential \
        cmake \
        git \
        openssl \
        libssl-dev \
        libc-ares2 \
        libc-ares-dev \
        libcjson1 \
        libcjson-dev \
        libsqlite3-dev \
        xsltproc \
        docbook-xsl \
        golang-go \
    \
    # Compile and install libwebsocket
    #
    # DLWS_WITHOUT_TESTAPPS is just a workaround, see
    # https://github.com/warmcat/libwebsockets/issues/2790 for more
    && git clone --depth 1 -b "v${LIBWEBSOCKET_VERSION}" \
       https://libwebsockets.org/repo/libwebsockets \
    \
    && cd libwebsockets \
    && mkdir build \
    && cd build \
    && cmake -DLWS_WITH_EXTERNAL_POLL=ON -DLWS_WITHOUT_TESTAPPS=ON .. \
    && make install \
    && ldconfig \
    && cd ../.. \
    # Compile and install mosquitto
    && git clone --depth 1 -b "v${MOSQUITTO_VERSION}" \
       https://github.com/eclipse/mosquitto \
    \
    && cd mosquitto \
    # Disable editline used by mosquitto_ctrl
    && sed -i 's/^WITH_EDITLINE=yes/#WITH_EDITLINE=yes/' config.mk \
    # Disable REST API
    && sed -i 's/^WITH_HTTP_API=yes/#WITH_HTTP_API=yes/' config.mk \
    && make WITH_WEBSOCKETS=yes WITH_SRV=yes \
    && make install \
    && cd .. \
    # Build vendored mosquitto-go-auth (Makefile already patched for /usr/include)
    && cd mosquitto-go-auth \
    && make \
    && mkdir -p /usr/share/mosquitto \
    && cp -f go-auth.so /usr/share/mosquitto \
    && cp -f pw /usr/local/bin \
    && cd .. \
    \
    && apt-get purge -y --auto-remove \
        build-essential \
        git \
        cmake \
        libssl-dev \
        libc-ares-dev \
        libcjson-dev \
        libsqlite3-dev \
        xsltproc \
        docbook-xsl \
        golang-go \
    && apt-get clean \
    && rm -fr \
        /etc/logrotate.d \
        /etc/mosquitto/* \
        /etc/nginx/* \
        /usr/share/nginx \
        /usr/src/libwebsockets \
        /usr/src/mosquitto \
        /usr/src/mosquitto-go-auth \
        /var/lib/nginx/html \
        /var/www \
        /var/lib/apt/lists/* \
        /root/.cache \
        /root/go

# Copy rootfs
COPY mosquitto_ldap/rootfs /

WORKDIR /
