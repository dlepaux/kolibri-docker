# Base pinned by digest (Renovate bumps it). Tag kept for human readability.
FROM python:3.14-slim-bookworm@sha256:82bc3c539b8813ada9d68c63b40158fa002f7f33de9bf3312a3dfdc0620dff56
LABEL org.opencontainers.image.source=https://github.com/dlepaux/kolibri-docker

ARG KOLIBRI_VERSION=0.19.4

# Upgrade base OS packages (security patches) before installing Kolibri.
# Kolibri's own pinned Python deps (Django 3.2 etc.) are upstream-bound and
# not bumpable here — see plan/ for the deferred dependency-modernisation note.
RUN apt-get update \
    && apt-get upgrade -y \
    && rm -rf /var/lib/apt/lists/*

RUN pip install --no-cache-dir kolibri==${KOLIBRI_VERSION}

ARG KOLIBRI_UID=999
ARG KOLIBRI_GID=999

ENV KOLIBRI_HOME=/data \
    KOLIBRI_LISTEN_PORT=8080 \
    KOLIBRI_UID=${KOLIBRI_UID} \
    KOLIBRI_GID=${KOLIBRI_GID}

# The server runs as this non-root user. The build-time chown below only covers
# a *fresh* named volume, which inherits ownership from this image directory —
# it does nothing for a volume that already exists, because the mount hides the
# image's /data entirely. Pre-existing volumes are reconciled at runtime by
# entrypoint.sh; see the comment there for the outage that proved it necessary.
RUN groupadd --system --gid ${KOLIBRI_GID} kolibri \
    && useradd --system --uid ${KOLIBRI_UID} --gid ${KOLIBRI_GID} --create-home \
        --home-dir /home/kolibri --shell /usr/sbin/nologin kolibri \
    && mkdir -p /data \
    && chown -R kolibri:kolibri /data

EXPOSE 8080
VOLUME /data

COPY --chown=kolibri:kolibri entrypoint.sh /entrypoint.sh

# Deliberately no `USER kolibri`: PID 1 needs root to reconcile the ownership of
# a pre-existing /data volume, then drops to ${KOLIBRI_UID} via setpriv before
# exec'ing Kolibri. The server process is never root. Requires the default
# CAP_CHOWN/CAP_SETUID/CAP_SETGID — do not add `cap_drop: [ALL]` without also
# passing `user: "999:999"`, which skips the reconcile.

HEALTHCHECK --interval=30s --timeout=5s --start-period=30s --retries=3 \
    CMD python -c "import urllib.request; urllib.request.urlopen('http://localhost:8080/api/public/info/')" || exit 1

ENTRYPOINT ["/entrypoint.sh"]
CMD ["start", "--foreground"]
