FROM golang:1.25.3-trixie AS builder

WORKDIR /src

COPY go.* .
RUN go mod download

COPY . .
RUN CGO_ENABLED=0 go build .

FROM debian:trixie-slim

# update ca-certificates
RUN set -x && apt-get update && DEBIAN_FRONTEND=noninteractive apt-get install -y --no-install-recommends \
    ca-certificates && \
    rm -rf /var/lib/apt/lists/*

ARG user=glance
ARG group=glance
ARG uid=10000
ARG gid=10001

# create user
RUN groupadd -g ${gid} ${group} \
    && useradd -l -u ${uid} -g ${gid} -m -s /bin/bash ${user}

USER ${user}

COPY --from=builder --chown=${uid}:${gid} /src/glance /usr/bin/glance
COPY --from=builder --chown=${uid}:${gid} /src/docs/glance.yml /etc/glance/config.yaml

EXPOSE 8080/tcp

ENTRYPOINT ["glance"]
CMD ["--config", "/etc/glance/config.yaml"]