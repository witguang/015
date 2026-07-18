#!/bin/sh

PUBLIC_DIR="${PUBLIC_DIR:-/app/public}"

# Branding images are image-wide assets. Enable them automatically when they
# were included by the Nuxt build; no per-VPS configuration is required.
export SITE_ICON="${SITE_ICON:-/logo.png}"
if [ -f "$PUBLIC_DIR/background.jpg" ]; then
    export SITE_BG_URL="${SITE_BG_URL:-/background.jpg}"
    export SITE_ENABLE_BG="${SITE_ENABLE_BG:-true}"
fi
if [ -f "$PUBLIC_DIR/welcome.jpg" ]; then
    export ABOUT_BG_URL="${ABOUT_BG_URL:-/welcome.jpg}"
fi

/bin/backend & node /app/server/index.mjs
