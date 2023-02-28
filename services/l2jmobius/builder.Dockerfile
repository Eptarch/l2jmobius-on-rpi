FROM alpine:edge AS builder

RUN apk update && apk add --no-cache apache-ant openjdk17-jre-headless unzip

WORKDIR /opt/l2jmobius
COPY ./builder-entrypoint.sh ./builder-entrypoint.sh
