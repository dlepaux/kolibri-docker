# kolibri-docker

![CI](https://github.com/dlepaux/kolibri-docker/actions/workflows/ci.yml/badge.svg)
![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)
![Docker Image](https://ghcr-badge.egpl.dev/dlepaux/kolibri-docker/size)

Docker image for [Kolibri](https://learningequality.org/kolibri/), the offline-first education platform by Learning Equality.

Learning Equality does not publish an official Docker image. This repository provides a minimal, automated build from PyPI with auto-provisioning support.

## Image

```
ghcr.io/dlepaux/kolibri-docker:latest
```

**Architecture:** `linux/arm64`

## Usage

```bash
docker run -d \
  --name kolibri \
  -p 8080:8080 \
  -v kolibri_data:/data \
  -e KOLIBRI_FACILITY_NAME="My School" \
  -e KOLIBRI_SUPERUSER_NAME=admin \
  -e KOLIBRI_SUPERUSER_PASSWORD=changeme \
  -e KOLIBRI_LANGUAGE=en \
  ghcr.io/dlepaux/kolibri-docker:latest
```

> **Security**: Change the default superuser password before exposing the instance to any network.

The setup wizard is skipped automatically when `KOLIBRI_FACILITY_NAME` is set.

## Configuration

| Variable | Default | Description |
|----------|---------|-------------|
| `KOLIBRI_HOME` | `/data` | Data directory (database, content, logs) |
| `KOLIBRI_LISTEN_PORT` | `8080` | HTTP listen port |
| `KOLIBRI_FACILITY_NAME` | *(unset)* | Facility name — triggers auto-provisioning |
| `KOLIBRI_FACILITY_PRESET` | `nonformal` | `formal`, `nonformal`, or `informal` |
| `KOLIBRI_SUPERUSER_NAME` | `admin` | Superuser username |
| `KOLIBRI_SUPERUSER_PASSWORD` | `admin` | Superuser password |
| `KOLIBRI_LANGUAGE` | `en` | Default UI language (`en`, `fr`, `tr`, etc.) |

## Auto-provisioning

On first start, if `KOLIBRI_FACILITY_NAME` is set, the entrypoint:

1. Creates the facility with the given name and preset
2. Creates the superuser account
3. Sets the default language
4. Starts Kolibri

Subsequent restarts skip provisioning (idempotent).

## Importing content

Use `kolibri manage` commands to import Khan Academy or other channels:

```bash
docker exec kolibri kolibri manage importchannel network <channel_id>
docker exec kolibri kolibri manage importcontent network <channel_id>
```

Find channel IDs at [Kolibri Content Library](https://kolibri-catalog-en.learningequality.org/).

## Updating Kolibri

1. Update `KOLIBRI_VERSION` in the [Dockerfile](Dockerfile)
2. Push to `main` — CI builds and pushes the new image
3. Pull on the server: `docker compose pull kolibri && docker compose up -d kolibri`

## Running as non-root

The image runs as a non-root user (`kolibri`, uid 999), and the base image is
pinned by digest. `KOLIBRI_HOME` (`/data`) is owned by `kolibri` in the image,
so a **named volume** (`-v kolibri_data:/data`, as shown above) inherits that
ownership automatically — no extra setup.

If you **bind-mount a host directory** instead (`-v /srv/kolibri:/data`), Docker
keeps the host's ownership and Kolibri won't be able to write. Chown it first:

```bash
sudo chown -R 999:999 /srv/kolibri
```

## License

[MIT](license.md)
