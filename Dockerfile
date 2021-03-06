FROM alpine:edge

ADD scripts/ /scripts/

EXPOSE 3478 3478/udp


# Build and install coturn
RUN apk update \
    && apk upgrade \
    && apk add --no-cache ca-certificates curl git \
    && update-ca-certificates \
    \
# Install coturn dependencies
    && apk add --no-cache \
    libevent \
    libcrypto1.1 libssl1.1 \
    libpq mariadb-connector-c sqlite-libs \
    hiredis \
    # mongo-c-driver dependencies
    snappy zlib \
    \
# Install tools for building
    && apk add --no-cache --virtual .tool-deps \
    coreutils autoconf g++ libtool make \
    # mongo-c-driver building dependencies
    cmake \
    \
# Install coturn build dependencies
    && apk add --no-cache --virtual .build-deps \
    linux-headers \
    libevent-dev \
    openssl-dev \
    postgresql-dev mariadb-connector-c-dev sqlite-dev \
    hiredis-dev \
    # mongo-c-driver build dependencies
    snappy-dev zlib-dev \
    \
 # Download and prepare mongo-c-driver sources
    && cd /tmp/ \
    && git clone https://github.com/mongodb/mongo-c-driver.git \
    && cd /tmp/mongo-c-driver/ \
    && git checkout 1.17.0 \
    && /usr/bin/python3.8 build/calc_release_version.py > VERSION_CURRENT \
 # Build mongo-c-driver from sources
    && mkdir -p /tmp/build/mongo-c-driver/ && cd /tmp/build/mongo-c-driver/ \
    && cmake -DCMAKE_BUILD_TYPE=Release \
            -DCMAKE_INSTALL_PREFIX=/usr \
            -DCMAKE_INSTALL_LIBDIR=lib \
            -DENABLE_BSON:STRING=ON \
            -DENABLE_MONGOC:BOOL=ON \
            -DENABLE_SSL:STRING=OPENSSL \
            -DENABLE_AUTOMATIC_INIT_AND_CLEANUP:BOOL=OFF \
            -DENABLE_MAN_PAGES:BOOL=OFF \
            -DENABLE_TESTS:BOOL=OFF \
            -DENABLE_EXAMPLES:BOOL=OFF \
            -DCMAKE_SKIP_RPATH=ON \
            /tmp/mongo-c-driver \
    && make \
 # Install mongo-c-driver
    && make install \
 # Download and prepare Coturn sources
    && curl -fL -o /tmp/coturn.tar.gz \ 
    https://github.com/coturn/coturn/archive/4.5.1.3.tar.gz \
    && tar -xzf /tmp/coturn.tar.gz -C /tmp/ \
    && cd /tmp/coturn-* \
 # Build Coturn from sources
    && ./configure --prefix=/usr \
            --turndbdir=/var/lib/coturn \
            --disable-rpath \
            --sysconfdir=/etc/coturn \
            # No documentation included to keep image size smaller
            --mandir=/tmp/coturn/man \
            --docsdir=/tmp/coturn/docs \
            --examplesdir=/tmp/coturn/examples \
    && make \
 # Install and configure Coturn
    && make install \
 # Preserve license file
    && mkdir -p /usr/share/licenses/coturn/ \
    && cp /tmp/coturn/docs/LICENSE /usr/share/licenses/coturn/ \
 # Remove default config file
    && rm -f /etc/coturn/turnserver.conf.default \
 # Cleanup unnecessary stuff
    && apk del .tool-deps .build-deps \
    && rm -rf /var/cache/apk/* \
            /tmp/*

RUN ["chmod", "+x", "/scripts/detect_external_ip.sh"]
RUN /scripts/detect_external_ip.sh

RUN ["chmod", "+x", "/scripts/docker_entrypoint.sh"]
ENTRYPOINT ["/scripts/docker_entrypoint.sh"]

CMD ["-n", "--log-file=stdout", "--external-ip=$(REAL_EXTERNAL_IP)"]