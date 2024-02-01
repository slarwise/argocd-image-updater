FROM docker.io/golang:1.20 AS builder

RUN mkdir -p /src/argocd-image-updater
WORKDIR /src/argocd-image-updater
# cache dependencies as a layer for faster rebuilds
COPY go.mod go.sum ./
RUN go mod download
COPY . .

RUN mkdir -p dist && \
	make controller

FROM docker.io/alpine:latest

RUN apk update
RUN apk upgrade
RUN apk add ca-certificates git openssh-client python3 py3-pip tini aws-cli
RUN pip3 install --no-cache --upgrade --break-system-packages pip
RUN rm -rf /var/cache/apk/*

RUN mkdir -p /usr/local/bin
RUN mkdir -p /app/config
RUN adduser --home "/app" --disabled-password --uid 1000 argocd

COPY --from=builder /src/argocd-image-updater/dist/argocd-image-updater /usr/local/bin/
COPY hack/git-ask-pass.sh /usr/local/bin/git-ask-pass.sh

USER 1000

ENTRYPOINT ["/sbin/tini", "--", "/usr/local/bin/argocd-image-updater"]
