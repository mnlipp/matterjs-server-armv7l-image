FROM node:22-alpine

WORKDIR /app

# Version of matter-server to install from npm
ARG MATTERJS_SERVER_VERSION

# Install required system dependencies
# Runtime dependencies:
# - iputils-ping: Required for node ping functionality
# - curl: For health checks and general utility
# - bluez: Bluetooth stack for BLE commissioning
# Build dependencies (removed after npm install):
# - python3: Required by node-gyp for native module compilation
# - make, gcc, g++: C/C++ toolchain for native module compilation
# - libbluetooth-dev, libudev-dev: Headers for native BLE/udev bindings
# - libcap2-bin: provides setcap to grant ping CAP_NET_RAW (purged afterwards)
RUN /bin/sh -o pipefail -c '\
    set -x \
    && apk update \
    && apk add --no-cache \
	nodejs \
	npm \
        iputils \
        curl \
        bluez \
        libcap \
    && apk add --no-cache --virtual .build-deps \
        python3 \
        make \
        gcc \
        g++ \
	linux-headers \
        bluez-dev \
        eudev-dev \
    # ping_node runs as the non-root user; CAP_NET_RAW on the binary lets it open
    # an ICMP socket regardless of the host's net.ipv4.ping_group_range.
    && setcap cap_net_raw+ep "$(command -v ping)" \
    # Install matter-server from npm and optimize image size
    && set -x \
    && CXXFLAGS="-std=c++17" npm install --foreground-scripts "matter-server@${MATTERJS_SERVER_VERSION}" \
    # Remove build dependencies (no longer needed after native modules are compiled)
    && apk del --purge \
        python3 \
        make \
        gcc \
        g++ \
        bluez-dev \
        eudev-dev \
        libcap \
    && apk del .build-deps \
    # Remove corepack (not needed at runtime)
    && npm uninstall -g corepack \
    # Clean npm cache
    && npm cache clean --force \
    # Remove CJS builds from Matter packages (we use ESM only)
    && find ./node_modules -type d -name "cjs" \
        -path "*/@matter/*" -exec rm -rf {} + 2>/dev/null || true \
    && find ./node_modules -type d -name "cjs" \
        -path "*/@project-chip/*" -exec rm -rf {} + 2>/dev/null || true \
    # Remove development/documentation files
    && find ./node_modules -type d -name ".github" -exec rm -rf {} + 2>/dev/null || true \
    && find ./node_modules -type d -name ".vscode" -exec rm -rf {} + 2>/dev/null || true \
    && find ./node_modules -type d -name "docs" -exec rm -rf {} + 2>/dev/null || true \
    && find ./node_modules -name "*.md" -delete 2>/dev/null || true \
    && find ./node_modules -name "LICENSE*" -delete 2>/dev/null || true \
    && find ./node_modules -name "CHANGELOG*" -delete 2>/dev/null || true \
    # Clean temp directories
    && rm -rf /tmp/* /var/tmp/* /root/.npm /root/.cache \
    # Initialize data volume with user permissions
    && mkdir /data \
    '

# Environment variables with defaults (all CLI options can be set via env vars)
# See docs/docker.md for full list of available environment variables
ENV LOG_LEVEL=info
ENV STORAGE_PATH=/data

# Data volume for persistent storage
VOLUME ["/data"]

# WebSocket API port
EXPOSE 5580

# Run the matter server directly (all config via environment variables)
ENTRYPOINT ["node", "--enable-source-maps", "/app/node_modules/matter-server/dist/esm/MatterServer.js"]
CMD []
