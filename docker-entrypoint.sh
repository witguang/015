#!/bin/sh
set -eu

# Runtime branding is token-based.  This avoids relying on minifier output or
# replacing unrelated occurrences of the original author's text.
SITE_ADMIN_NAME="${SITE_ADMIN_NAME:-Guang}"
ADMIN_EMAIL="${ADMIN_EMAIL:-admin@example.com}"
STORAGE_LIMIT="${STORAGE_LIMIT:-100GiB}"
CUSTOM_LINK="${CUSTOM_LINK:-https://github.com/witguang/015}"
COPYRIGHT="${COPYRIGHT:-Designed by Guang}"
APP_ROOT="${APP_ROOT:-/app}"

for value in "$SITE_ADMIN_NAME" "$ADMIN_EMAIL" "$STORAGE_LIMIT" "$CUSTOM_LINK" "$COPYRIGHT"; do
  if printf '%s' "$value" | LC_ALL=C grep -q '[[:cntrl:]]'; then
    echo "runtime branding values must not contain control characters" >&2
    exit 1
  fi
  case "$value" in
    *\"*|*\'*|*\\*)
      echo "runtime branding values must not contain quotes or backslashes" >&2
      exit 1
      ;;
  esac
done

escape_sed_replacement() {
  printf '%s' "$1" | sed 's/[\\&|]/\\&/g'
}

sed_script="$(mktemp)"
cleanup() {
  rm -f "$sed_script"
}
trap cleanup EXIT INT TERM

printf 's|__SITE_ADMIN_NAME__|%s|g\n' "$(escape_sed_replacement "$SITE_ADMIN_NAME")" >> "$sed_script"
printf 's|__ADMIN_EMAIL__|%s|g\n' "$(escape_sed_replacement "$ADMIN_EMAIL")" >> "$sed_script"
printf 's|__STORAGE_LIMIT__|%s|g\n' "$(escape_sed_replacement "$STORAGE_LIMIT")" >> "$sed_script"
printf 's|__CUSTOM_LINK__|%s|g\n' "$(escape_sed_replacement "$CUSTOM_LINK")" >> "$sed_script"
printf 's|__COPYRIGHT__|%s|g\n' "$(escape_sed_replacement "$COPYRIGHT")" >> "$sed_script"

for root in "$APP_ROOT/public" "$APP_ROOT/server"; do
  if [ -d "$root" ]; then
    find "$root" -type f \( \
      -name '*.html' -o -name '*.js' -o -name '*.mjs' -o -name '*.json' -o -name '*.css' \
    \) -exec sed -i -f "$sed_script" {} +
  fi
done

# The API already reads these Viper keys from environment variables.  Export
# aliases so the backend's config.yaml remains portable between VPS instances.
export ABOUT_NAME="$SITE_ADMIN_NAME"
export ABOUT_EMAIL="$ADMIN_EMAIL"
export ABOUT_URL="$CUSTOM_LINK"
export UPLOAD_MAXIMUM="$STORAGE_LIMIT"

if [ "$#" -eq 0 ]; then
  set -- /bin/sh "$APP_ROOT/015.sh"
fi

exec "$@"
