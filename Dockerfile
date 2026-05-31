FROM python:3.12-slim-bookworm
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

EXPOSE 8080
VOLUME /data

COPY entrypoint.sh /entrypoint.sh

HEALTHCHECK --interval=30s --timeout=5s --start-period=30s --retries=3 \
    CMD python -c "import urllib.request; urllib.request.urlopen('http://localhost:8080/api/public/info/')" || exit 1

ENTRYPOINT ["/entrypoint.sh"]
CMD ["start", "--foreground"]
