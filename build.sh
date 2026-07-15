#!/bin/sh

podman buildx build --platform linux/arm/v7 --build-arg MATTERJS_SERVER_VERSION=1.2.6 -t matterjs-server:1.2.6 .
