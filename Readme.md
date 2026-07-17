# matterjs-server for armv7l

matterjs-server does not provide an image for armv7l. Here's how to build one.

## Base image

Using node-22 because it is LTS.

## Sample service

```
[Unit]
Description=Podman container-matterjs-server.service
Documentation=man:podman-generate-systemd(1)
Wants=network-online.target
After=network-online.target
RequiresMountsFor=%t/containers

[Service]
Environment=PODMAN_SYSTEMD_UNIT=%n
Restart=on-failure
TimeoutSec=900
TimeoutStopSec=70
ExecStartPre=/bin/rm -f %t/%n.ctr-id
ExecStart=/usr/bin/podman run \
	--cidfile=%t/%n.ctr-id \
	--cgroups=no-conmon \
	--rm \
	--sdnotify=conmon \
	-d \
	--replace \
	--name=matterjs-server \
	--network=host \
	-v /var/lib/matterjs-server:/data \
	-v /run/dbus:/run/dbus:ro \
	-e TZ=Europe/Berlin \
	-e BLUETOOTH_ADAPTER=0 \
	-e NOBLE_BINDINGS=dbus \
	ghcr.io/mnlipp/matterjs-server/matterjs-server:1.2.6-1
ExecStop=/usr/bin/podman stop --ignore --cidfile=%t/%n.ctr-id
ExecStopPost=/usr/bin/podman rm -f --ignore --cidfile=%t/%n.ctr-id
Type=notify
NotifyAccess=all
```
