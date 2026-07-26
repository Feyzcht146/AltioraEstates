#!/bin/sh
set -e

PGPASS_FILE="/tmp/pgpassfile"
SERVERS_FILE="/tmp/servers.json"

echo "${PG_HOST}:${PG_PORT}:${PG_DB}:${PG_USER}:${PG_PASSWORD}" > "$PGPASS_FILE"
chmod 600 "$PGPASS_FILE"

cat > "$SERVERS_FILE" <<EOF
{
    "Servers": {
        "1": {
            "Name": "${PG_SERVER_NAME:-Altiora}",
            "Group": "Servers",
            "Host": "${PG_HOST}",
            "Port": ${PG_PORT},
            "MaintenanceDB": "${PG_DB}",
            "Username": "${PG_USER}",
            "SSLMode": "prefer",
            "PassFile": "${PGPASS_FILE}"
        }
    }
}
EOF

export PGADMIN_SERVER_JSON_FILE="$SERVERS_FILE"

exec /entrypoint.sh