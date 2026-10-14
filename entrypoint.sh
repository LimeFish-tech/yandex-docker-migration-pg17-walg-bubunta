#!/bin/bash
set -euo pipefail

PGDATA="${PGDATA:-/var/lib/postgresql/17/main}"
PG_BIN="/usr/lib/postgresql/17/bin"

# Подставляем переменные окружения в конфиг
if [ -f /etc/postgresql/17/main/postgresql.conf.template ]; then
    envsubst < /etc/postgresql/17/main/postgresql.conf.template > "${PGDATA}/postgresql.conf"
fi

# Инициализация кластера при первом запуске
if [ ! -s "${PGDATA}/PG_VERSION" ]; then
    echo ">>> Инициализация кластера PostgreSQL..."
    "${PG_BIN}/initdb" \
        --username="${POSTGRES_USER:-postgres}" \
        --pwfile=<(echo "${POSTGRES_PASSWORD:-postgres}") \
        --auth-local=trust \
        --auth-host=scram-sha-256 \
        --encoding=UTF8 \
        --locale=en_US.UTF-8
fi

# Временный запуск для создания базы
"${PG_BIN}/pg_ctl" -D "${PGDATA}" -o "-c config_file=${PGDATA}/postgresql.conf" -w start

if [ -n "${POSTGRES_DB:-}" ]; then
    if ! "${PG_BIN}/psql" -U "${POSTGRES_USER:-postgres}" -lqt | cut -d'|' -f1 | grep -qw "${POSTGRES_DB}"; then
        "${PG_BIN}/createdb" -U "${POSTGRES_USER:-postgres}" "${POSTGRES_DB}"
    fi
fi

"${PG_BIN}/pg_ctl" -D "${PGDATA}" -m fast stop

echo ">>> Запуск PostgreSQL..."
exec "${PG_BIN}/postgres" -D "${PGDATA}" -c config_file="${PGDATA}/postgresql.conf"
