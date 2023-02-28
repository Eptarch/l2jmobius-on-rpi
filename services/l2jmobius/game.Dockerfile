FROM alpine:edge

RUN apk update && apk add --no-cache bash openjdk17-jre-headless tree

WORKDIR /opt/l2jmobius/game/
