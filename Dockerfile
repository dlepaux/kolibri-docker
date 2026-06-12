# Base pinned by digest (Renovate bumps it). Tag kept for human readability.
FROM python:3.12-slim-bookworm@sha256:76d4b7b6305788c6b4c6a19d6a22a3921bf802e9af4d5e1e5bd771208dba74bf
LABEL org.opencontainers.image.source=https://github.com/dlepaux/kolibri-docker

ARG KOLIBRI_VERSION=0.19.4

# Upgrade base OS packages (security patches) before installing Kolibri.
# Kolibri's own pinned Python deps (Django 3.2 etc.) are upstream-bound and
# not bumpable here — see plan/ for the deferred dependency-modernisation note.
RUN apt-get update \
    && apt-get upgrade -y \
    && rm -rf /var/lib/apt/lists/*

RUN pip install --no-cache-dir kolibri==${KOLIBRI_VERSION}

ENV KOLIBRI_HOME=/data \
    KOLIBRI_LISTEN_PORT=8080

# Run as a non-root user. KOLIBRI_HOME (/data) is owned by it so the database
# and downloaded content are writable; a fresh named volume inherits this
# ownership from the image directory. (Bind mounts keep host ownership — see
# the readme's non-root note.)
RUN groupadd --system --gid 999 kolibri \
    && useradd --system --uid 999 --gid 999 --create-home \
        --home-dir /home/kolibri --shell /usr/sbin/nologin kolibri \
    && mkdir -p /data \
    && chown -R kolibri:kolibri /data

EXPOSE 8080
VOLUME /data

COPY --chown=kolibri:kolibri entrypoint.sh /entrypoint.sh

USER kolibri

HEALTHCHECK --interval=30s --timeout=5s --start-period=30s --retries=3 \
    CMD python -c "import urllib.request; urllib.request.urlopen('http://localhost:8080/api/public/info/')" || exit 1

ENTRYPOINT ["/entrypoint.sh"]
CMD ["start", "--foreground"]
