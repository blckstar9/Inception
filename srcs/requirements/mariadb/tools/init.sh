#!/bin/sh
set -eu

: "${MYSQL_DATABASE:?MYSQL_DATABASE is required}"
: "${MYSQL_USER:?MYSQL_USER is required}"

# Only allow simple SQL identifiers.
case "$MYSQL_DATABASE" in
    *[!a-zA-Z0-9_]*)
        echo "Invalid database name" >&2
        exit 1
        ;;
esac

case "$MYSQL_USER" in
    *[!a-zA-Z0-9_]*)
        echo "Invalid database username" >&2
        exit 1
        ;;
esac

if [ "$MYSQL_USER" = "root" ]; then
    echo "The WordPress database user cannot be root" >&2
    exit 1
fi

# Read passwords from Docker secrets.
DB_PASSWORD="$(cat /run/secrets/db_password)"
ROOT_PASSWORD="$(cat /run/secrets/db_root_password)"

[ -n "$DB_PASSWORD" ] || {
    echo "Database password is empty" >&2
    exit 1
}

[ -n "$ROOT_PASSWORD" ] || {
    echo "Root password is empty" >&2
    exit 1
}

# Convert password bytes to hexadecimal to avoid SQL injection.
DB_PASSWORD_HEX="$(printf '%s' "$DB_PASSWORD" | od -An -tx1 -v | tr -d '[:space:]')"
ROOT_PASSWORD_HEX="$(printf '%s' "$ROOT_PASSWORD" | od -An -tx1 -v | tr -d '[:space:]')"

install -d -o mysql -g mysql /run/mysqld
install -d -o mysql -g mysql /var/lib/mysql
chown -R mysql:mysql /var/lib/mysql

# Initialize the MariaDB system tables if absent.
if [ ! -d /var/lib/mysql/mysql ]; then
	mariadb-install-db \
    --user=mysql \
    --datadir=/var/lib/mysql \
    --skip-test-db
fi

# Run the WordPress-specific setup only once.
if [ ! -f /var/lib/mysql/.inception-initialized ]; then
	# Configure the database without starting a background server.
    mariadbd --user=mysql \
        --datadir=/var/lib/mysql \
        --skip-networking \
        --bootstrap <<SQL
FLUSH PRIVILEGES;
CREATE DATABASE IF NOT EXISTS \`${MYSQL_DATABASE}\`;

SET @db_password = CONVERT(0x${DB_PASSWORD_HEX} USING utf8mb4);
SET @root_password = CONVERT(0x${ROOT_PASSWORD_HEX} USING utf8mb4);

SET @query = CONCAT(
    'CREATE USER IF NOT EXISTS ''${MYSQL_USER}''@''%'' IDENTIFIED BY ',
    QUOTE(@db_password)
);
PREPARE statement FROM @query;
EXECUTE statement;
DEALLOCATE PREPARE statement;

SET @query = CONCAT(
    'ALTER USER ''${MYSQL_USER}''@''%'' IDENTIFIED BY ',
    QUOTE(@db_password)
);
PREPARE statement FROM @query;
EXECUTE statement;
DEALLOCATE PREPARE statement;

GRANT ALL PRIVILEGES ON \`${MYSQL_DATABASE}\`.* TO '${MYSQL_USER}'@'%';

SET @query = CONCAT(
    'ALTER USER ''root''@''localhost'' IDENTIFIED BY ',
    QUOTE(@root_password)
);
PREPARE statement FROM @query;
EXECUTE statement;
DEALLOCATE PREPARE statement;
SQL


    touch /var/lib/mysql/.inception-initialized
    chown mysql:mysql /var/lib/mysql/.inception-initialized

    echo "Inception MariaDB initialization complete."
fi

# Start MariaDB as the main container process.
exec mariadbd --user=mysql --console
