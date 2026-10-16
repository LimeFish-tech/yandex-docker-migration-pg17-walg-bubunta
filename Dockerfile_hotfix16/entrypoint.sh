init_cluster() {
    log ">>> Инициализация кластера PostgreSQL в ${PGDATA}..."

    local loc="${POSTGRES_LOCALE:-en_US.UTF-8}"
    if ! locale -a | grep -qi "^${loc%%.*}\.utf8\?$" && ! locale -a | grep -qi "^${loc}$"; then
        die "Локаль '${loc}' не найдена в системе. Доступные: $(locale -a | tr '\n' ' ')"
    fi

    mkdir -p "${PGDATA}"
    chmod 700 "${PGDATA}"

    local pwfile
    pwfile="$(mktemp)"
    trap "rm -f '${pwfile}'" RETURN
    printf '%s\n' "${PG_PASSWORD}" > "${pwfile}"

    "${PG_BIN}/initdb" \
        --username="${PG_USER}" \
        --pwfile="${pwfile}" \
        --auth-local=trust \
        --auth-host=scram-sha-256 \
        --encoding=UTF8 \
        --locale="${loc}" \
        -D "${PGDATA}"

    log ">>> Инициализация завершена с локалью ${loc}."
}
