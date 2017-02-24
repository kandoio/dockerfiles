FROM alpine:3.4

RUN apk add --no-cache --virtual .fetch-deps \
    ca-certificates \
    openssl \
    tar \
  && wget -O /tmp/oauth2_proxy.tar.gz https://github.com/bitly/oauth2_proxy/releases/download/v2.1/oauth2_proxy-2.1.linux-amd64.go1.6.tar.gz \
  && tar -xvf /tmp/oauth2_proxy.tar.gz -C /tmp/ \
  && rm /tmp/oauth2_proxy.tar.gz \
  && mv /tmp/oauth2*/oauth2_proxy /oauth2_proxy \
  && rm -rf /tmp/oauth2* \
  && apk del .fetch-deps

ENTRYPOINT ["/oauth2_proxy"]
