FROM ubuntu:24.04

LABEL maintainer="you@example.com" \
      description="Ubuntu 24.04 + PostgreSQL 17 + WAL-G"

ENV DEBIAN_FRONTEND=noninteractive \
    LANG=en_US.UTF-8 \
    LC_ALL=en_US.UTF-8 \
    PGDATA=/var/lib/postgresql/17/main

# Базовые пакеты
RUN apt-get update && apt-get install -y --no-install-recommends \
        ca-certificates \
        curl \
        gnupg \
        lsb-release \
        locales \
        tini \
        wget \
    && locale-gen en_US.UTF-8 \
    && rm -rf /var/lib/apt/lists/*

# Репозиторий PGDG (в Ubuntu 24.04 только PostgreSQL 16, нам нужен 17)
RUN install -d /usr/share/postgresql-common/pgdg \
    && curl -fsSL https://www.postgresql.org/media/keys/ACCC4CF8.asc \
        -o /usr/share/postgresql-common/pgdg/apt.postgresql.org.asc \
    && echo "deb [signed-by=/usr/share/postgresql-common/pgdg/apt.postgresql.org.asc] \
        http://apt.postgresql.org/pub/repos/apt $(lsb_release -cs)-pgdg main" \
        > /etc/apt/sources.list.d/pgdg.list

# PostgreSQL 17
RUN apt-get update && apt-get install -y --no-install-recommends \
        postgresql-17 \
        postgresql-client-17 \
    && rm -rf /var/lib/apt/lists/*

# WAL-G
ARG WALG_VERSION=v3.0.8
ARG WALG_ASSET=wal-g-pg-24.04-amd64
RUN set -eux; \
    cd /tmp; \
    curl -fsSLO "https://github.com/wal-g/wal-g/releases/download/${WALG_VERSION}/${WALG_ASSET}"; \
    curl -fsSLO "https://github.com/wal-g/wal-g/releases/download/${WALG_VERSION}/${WALG_ASSET}.sha256"; \
    sha256sum -c "${WALG_ASSET}.sha256"; \
    install -m 0755 "${WALG_ASSET}" /usr/local/bin/wal-g; \
    rm -f "${WALG_ASSET}" "${WALG_ASSET}.sha256"; \
    wal-g --version

# Каталоги данных
RUN mkdir -p /var/lib/postgresql/17/main /var/run/postgresql \
    && chown -R postgres:postgres /var/lib/postgresql /var/run/postgresql \
    && chmod 700 /var/lib/postgresql/17/main

# Entrypoint и конфиг
COPY entrypoint.sh /usr/local/bin/entrypoint.sh
COPY postgresql.conf.template /etc/postgresql/17/main/postgresql.conf.template
RUN chmod +x /usr/local/bin/entrypoint.sh

EXPOSE 5432
VOLUME ["/var/lib/postgresql/17/main"]

USER postgres
ENTRYPOINT ["/usr/bin/tini", "--", "/usr/local/bin/entrypoint.sh"]
CMD ["postgres"]
