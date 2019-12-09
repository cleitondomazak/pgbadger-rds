FROM alpine:edge

WORKDIR /src

ENV PGBADGER_DATA=/data
ENV PGBADGER_LOGS=/pg_logs
ENV PGBADGER_VERSION=10.1

RUN mkdir -p /data /opt /pg_logs
RUN wget --no-check-certificate -O - https://github.com/darold/pgbadger/archive/v${PGBADGER_VERSION}.tar.gz | tar -zxvf - -C /opt
RUN mv /opt/pgbadger-${PGBADGER_VERSION}/pgbadger /usr/local/bin/pgbadger
RUN chmod +x /usr/local/bin/pgbadger

WORKDIR /opt

#install rdspgbadger
RUN apk add --update \
    python \
    coreutils \
    perl

# add aws cli
RUN wget --no-check-certificate "https://s3.amazonaws.com/aws-cli/awscli-bundle.zip"
RUN unzip awscli-bundle.zip
RUN ./awscli-bundle/install -i /usr/local/aws -b /usr/local/bin/aws
RUN rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/*

COPY entrypoint.sh /entrypoint.sh
RUN chmod +x /entrypoint.sh

VOLUME $PGBADGER_DATA
VOLUME $PGBADGER_LOGS

ENTRYPOINT ["/entrypoint.sh"]
