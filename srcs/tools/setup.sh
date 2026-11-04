#!/bin/sh
set -eu

ROOT="$(CDPATH= cd -- "$(dirname -- "$0")/../.." && pwd)"
ENV_FILE="$ROOT/srcs/.env"
EXAMPLE_FILE="$ROOT/srcs/.env.example"
SECRETS_DIR="$ROOT/srcs/secrets"

# Create the environment file only when absent.
if [ ! -f "$ENV_FILE" ]; then
    echo "Creating .env from .env.example..."

    cp "$EXAMPLE_FILE" "$ENV_FILE"

    LOGIN="$(id -un)"
    sed -i \
        "s|^DOMAIN_NAME=login\.42\.fr$|DOMAIN_NAME=${LOGIN}.42.fr|" \
        "$ENV_FILE"
fi

# Define the persistent data location if not configured.
if ! grep -q '^DATA_ROOT=' "$ENV_FILE"; then
    printf '\nDATA_ROOT=%s/data\n' "$HOME" >> "$ENV_FILE"
fi

DATA_ROOT="$(sed -n 's/^DATA_ROOT=//p' "$ENV_FILE" | tail -n 1)"

case "$DATA_ROOT" in
    /*) ;;
    *)
        echo "DATA_ROOT must be an absolute path" >&2
        exit 1
        ;;
esac

# Prepare persistent storage.
mkdir -p "$DATA_ROOT/mariadb" "$DATA_ROOT/wordpress"

# Prepare the secrets directory.
mkdir -p "$SECRETS_DIR"
chmod 700 "$SECRETS_DIR"

command -v openssl >/dev/null 2>&1 || {
    echo "OpenSSL is required to generate secrets" >&2
    exit 1
}

umask 077

# Generate each secret only if it does not already exist.
for name in db_password db_root_password wp_admin_password wp_user_password
do
    secret_file="$SECRETS_DIR/$name"

    if [ ! -s "$secret_file" ]; then
        echo "Generating missing secret: $name"
        openssl rand -hex 24 > "$secret_file"
    fi

    chmod 600 "$secret_file"
done

chmod 600 "$ENV_FILE"

echo "Inception environment is ready."
