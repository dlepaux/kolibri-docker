#!/bin/sh
set -e

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
