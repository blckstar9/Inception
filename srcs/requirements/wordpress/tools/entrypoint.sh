#!/bin/sh
set -eu

: "${MYSQL_DATABASE:?Missing database name}"
: "${MYSQL_USER:?Missing database user}"
: "${WORDPRESS_URL:?Missing WordPress URL}"
: "${WORDPRESS_TITLE:?Missing WordPress title}"
: "${WORDPRESS_ADMIN_USER:?Missing administrator username}"
: "${WORDPRESS_ADMIN_EMAIL:?Missing administrator email}"
: "${WORDPRESS_USER:?Missing WordPress username}"
: "${WORDPRESS_USER_EMAIL:?Missing WordPress user email}"

DB_PASSWORD="$(cat /run/secrets/db_password)"
ADMIN_PASSWORD="$(cat /run/secrets/wp_admin_password)"
USER_PASSWORD="$(cat /run/secrets/wp_user_password)"

export WP_CLI_CACHE_DIR=/tmp/wp-cli-cache

mkdir -p /run/php /var/www/html "$WP_CLI_CACHE_DIR"
chown -R www-data:www-data /var/www/html "$WP_CLI_CACHE_DIR"

# Download WordPress only if it is not already present.
if [ ! -f /var/www/html/wp-includes/version.php ]; then
    echo "Downloading WordPress..."

    runuser -u www-data -- wp core download \
        --path=/var/www/html \
        --locale=fr_FR
fi

# Create wp-config.php only once.
if [ ! -f /var/www/html/wp-config.php ]; then
    echo "Creating WordPress configuration..."

    runuser -u www-data -- wp config create \
        --path=/var/www/html \
        --dbname="$MYSQL_DATABASE" \
        --dbuser="$MYSQL_USER" \
        --dbpass="$DB_PASSWORD" \
        --dbhost=mariadb:3306 \
        --skip-check

    chmod 640 /var/www/html/wp-config.php
fi

# Wait until the MariaDB database accepts connections.
echo "Waiting for MariaDB..."

attempt=0

until MYSQL_PWD="$DB_PASSWORD" mariadb \
    -h mariadb \
    -u "$MYSQL_USER" \
    "$MYSQL_DATABASE" \
    -e "SELECT 1" >/dev/null 2>&1; do

    attempt=$((attempt + 1))

    if [ "$attempt" -ge 60 ]; then
        echo "MariaDB connection failed" >&2
        exit 1
    fi

    sleep 2
done

# Install WordPress only if it is not already installed.
if ! runuser -u www-data -- wp core is-installed \
    --path=/var/www/html >/dev/null 2>&1; then

    echo "Installing WordPress..."

    runuser -u www-data -- wp core install \
        --path=/var/www/html \
        --url="$WORDPRESS_URL" \
        --title="$WORDPRESS_TITLE" \
        --admin_user="$WORDPRESS_ADMIN_USER" \
        --admin_password="$ADMIN_PASSWORD" \
        --admin_email="$WORDPRESS_ADMIN_EMAIL" \
        --skip-email
fi

# Create the second user only if absent.
if ! runuser -u www-data -- wp user get \
    "$WORDPRESS_USER" \
    --path=/var/www/html \
    --field=ID >/dev/null 2>&1; then

    echo "Creating the regular WordPress user..."

    runuser -u www-data -- wp user create \
        "$WORDPRESS_USER" \
        "$WORDPRESS_USER_EMAIL" \
        --path=/var/www/html \
        --role=subscriber \
        --user_pass="$USER_PASSWORD"
fi

echo "WordPress initialization complete."

exec "$@"
