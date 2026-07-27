#!/bin/sh
set -e

KOLIBRI_UID="${KOLIBRI_UID:-999}"
KOLIBRI_GID="${KOLIBRI_GID:-999}"

# /data is a persisted volume: it outlives every image rebuild, and its
# ownership is stamped by whoever created it. An image that changes its runtime
# uid therefore inherits a volume it cannot write. That is not hypothetical —
# on 2026-06-12 this image went root -> uid 999 against a volume created at uid
# 1000, and Kolibri crash-looped on /data/logs/kolibri.txt for six weeks before
# anyone opened the URL. A build-time `chown /data` cannot prevent it: the
# volume mounts straight over the image's directory.
#
# So PID 1 starts as root, reconciles ownership, then drops to KOLIBRI_UID for
# the server itself. Root is held for the reconcile only. Skipped entirely when
# the container is already started as a non-root user (compose `user:`).
if [ "$(id -u)" = 0 ]; then
    # -quit stops at the first offender, so the common case (nothing to fix) is
    # a short walk rather than a full-tree chown on every Sablier wake.
    if [ -n "$(find /data \( ! -uid "$KOLIBRI_UID" -o ! -gid "$KOLIBRI_GID" \) -print -quit)" ]; then
        echo "Reclaiming /data for ${KOLIBRI_UID}:${KOLIBRI_GID} (found foreign ownership)..."
        find /data \( ! -uid "$KOLIBRI_UID" -o ! -gid "$KOLIBRI_GID" \) \
            -exec chown "${KOLIBRI_UID}:${KOLIBRI_GID}" {} +
    fi

    exec setpriv --reuid="$KOLIBRI_UID" --regid="$KOLIBRI_GID" --clear-groups "$0" "$@"
fi

# Auto-provision on first run if facility name is set
if [ -n "$KOLIBRI_FACILITY_NAME" ]; then
    # provisiondevice fails if facility already exists, so we catch and continue
    echo "Provisioning Kolibri..."
    kolibri manage provisiondevice \
        --facility "$KOLIBRI_FACILITY_NAME" \
        --preset "${KOLIBRI_FACILITY_PRESET:-nonformal}" \
        --superusername "${KOLIBRI_SUPERUSER_NAME:-admin}" \
        --superuserpassword "${KOLIBRI_SUPERUSER_PASSWORD:-admin}" \
        --language_id "${KOLIBRI_LANGUAGE:-en}" \
        --verbosity 0 \
        --noinput 2>&1 || echo "Provisioning skipped (facility may already exist)."
fi

# Set default language
if [ -n "$KOLIBRI_LANGUAGE" ]; then
    kolibri language setdefault "$KOLIBRI_LANGUAGE" 2>/dev/null || true
fi

exec kolibri "$@"
