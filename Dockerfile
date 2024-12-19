ARG ALPINE_VERSION=3.20

#################################################################
####################### build #################################
#################################################################
FROM golang:alpine as build

ARG CADDY_VERSION

WORKDIR /build

# Build the app with Go
RUN apk update && apk add git
RUN go install github.com/caddyserver/xcaddy/cmd/xcaddy@latest
# FIXME: use args
RUN xcaddy build v${CADDY_VERSION} --output caddy --with github.com/greenpau/caddy-security 

##################################################################
####################### service ##################################
##################################################################
FROM alpine:${ALPINE_VERSION}

ARG BUILD_DATE
ARG CADDY_VERSION

RUN apk add --no-cache \
	ca-certificates \
	libcap \
	mailcap

RUN set -eux; \
	mkdir -p \
		/config/caddy \
		/data/caddy \
		/etc/caddy \
		/usr/share/caddy \
	; \
	wget -O /etc/caddy/Caddyfile "https://github.com/caddyserver/dist/raw/33ae08ff08d168572df2956ed14fbc4949880d94/config/Caddyfile"; \
	wget -O /usr/share/caddy/index.html "https://github.com/caddyserver/dist/raw/33ae08ff08d168572df2956ed14fbc4949880d94/welcome/index.html"

WORKDIR /srv
COPY --from=build /build/caddy caddy

ENV XDG_CONFIG_HOME /config
ENV XDG_DATA_HOME /data

LABEL org.opencontainers.image.version="v${CADDY_VERSION}"
LABEL org.opencontainers.image.title="Caddy Security"
LABEL org.opencontainers.image.description="a powerful, enterprise-ready, open source web server with automatic HTTPS written in Go"
LABEL org.opencontainers.image.url=https://caddyserver.com
LABEL org.opencontainers.image.documentation=https://caddyserver.com/docs
LABEL org.opencontainers.image.vendor=jamowei
LABEL org.opencontainers.image.licenses=MIT
LABEL org.opencontainers.image.source="https://github.com/jamowei/caddy-security"
LABEL org.opencontainers.image.created=${BUILD_DATE}

EXPOSE 80
EXPOSE 443
EXPOSE 443/udp
EXPOSE 2019

CMD ["./caddy", "run", "--config", "/etc/caddy/Caddyfile", "--adapter", "caddyfile"]