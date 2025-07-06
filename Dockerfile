FROM ubuntu:20.04

RUN apt-get update && apt-get install -y \
    ca-certificates dumb-init libfido2-1 && \
    apt-get clean && rm -rf /var/lib/apt/lists/*

COPY build/teleport /usr/local/bin/teleport
COPY build/tctl /usr/local/bin/tctl
COPY build/tsh /usr/local/bin/tsh
COPY build/tbot /usr/local/bin/tbot

ENTRYPOINT ["/usr/bin/dumb-init", "teleport", "start", "-c", "/etc/teleport/teleport.yaml"]
