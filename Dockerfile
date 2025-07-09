# ───────────────────────────────────────────────────────────────────────────────
# 1) Builder 스테이지: Teleport 소스코드 컴파일 (Go 1.21 설치 포함)
# ───────────────────────────────────────────────────────────────────────────────
FROM ubuntu:20.04 AS builder

ENV DEBIAN_FRONTEND=noninteractive
WORKDIR /workspace

# 1-1) 필수 빌드 도구 + CA 인증서 + Clang 설치
RUN apt-get update && \
    apt-get install -y --no-install-recommends \
      build-essential \
      ca-certificates \
      clang \
      curl \
      git \
      wget && \
    apt-get clean && rm -rf /var/lib/apt/lists/*

# CC, CXX 환경변수로 Clang 사용 설정
ENV CC=clang
ENV CXX=clang++

# 1-2) 공식 Go 1.21 설치
RUN curl -fsSL https://go.dev/dl/go1.21.0.linux-amd64.tar.gz \
      | tar -C /usr/local -xz && \
    ln -s /usr/local/go/bin/go   /usr/local/bin/go && \
    ln -s /usr/local/go/bin/gofmt /usr/local/bin/gofmt && \
    go version

# 1-3) Python 설치
RUN apt-get update && \
    apt-get install -y --no-install-recommends python3-pip && \
    apt-get clean && rm -rf /var/lib/apt/lists/*

# 1-4) Node.js 22.x (Nodesource) & pnpm
RUN apt-get update && \
    apt-get install -y --no-install-recommends curl ca-certificates && \
    curl -fsSL https://deb.nodesource.com/setup_22.x | bash - && \
    apt-get install -y nodejs && \
    npm install -g corepack && \
    corepack enable && \
    corepack prepare pnpm@10.12.4 --activate && \
    apt-get clean && rm -rf /var/lib/apt/lists/*

# 1-5) Rust & wasm-pack + Binaryen
RUN apt-get update && \
    apt-get install -y --no-install-recommends \
      pkg-config \
      libfido2-dev \
      libssl-dev && \
    apt-get clean && rm -rf /var/lib/apt/lists/* && \
    curl https://sh.rustup.rs -sSf | sh -s -- -y

# Rust 설치 후 cargo 바이너리 경로 추가
ENV PATH="/root/.cargo/bin:${PATH}"

RUN cargo install wasm-pack --locked --version 0.12.1 && \
    cd /tmp && \
    curl -LO https://github.com/WebAssembly/binaryen/releases/download/version_123/binaryen-version_123-x86_64-linux.tar.gz && \
    tar -xzf binaryen-version_123-x86_64-linux.tar.gz && \
    mv binaryen-version_123/bin/* /usr/local/bin && \
    rm -rf /tmp/binaryen-version_123*

# 1-6) 호스트의 Teleport 소스 전체를 컨테이너에 복사
COPY . /workspace/teleport
WORKDIR /workspace/teleport

# 1-7) 모든 쉘 스크립트의 CRLF → LF 변환
RUN find build.assets -type f -name '*.sh' \
    -exec sed -i 's/\r$//' {} \;

# 1-8) semver 검사 우회
RUN sed -i 's/^validate-semver:/validate-semver: ; true/' version.mk

# 1-9) 빌드 실행
RUN make clean && \
    make full

# ───────────────────────────────────────────────────────────────────────────────
# 2) Runtime 스테이지: 최소한의 실행 환경
# ───────────────────────────────────────────────────────────────────────────────
FROM ubuntu:20.04

# 2-1) 런타임 의존성
RUN apt-get update && \
    apt-get install -y --no-install-recommends \
      ca-certificates \
      dumb-init \
      libfido2-1 && \
    apt-get clean && rm -rf /var/lib/apt/lists/*

# 2-2) 빌더 스테이지에서 나온 바이너리 복사
COPY --from=builder /workspace/teleport/build/teleport /usr/local/bin/teleport
COPY --from=builder /workspace/teleport/build/tctl      /usr/local/bin/tctl
COPY --from=builder /workspace/teleport/build/tsh       /usr/local/bin/tsh
COPY --from=builder /workspace/teleport/build/tbot      /usr/local/bin/tbot

# 2-3) 엔트리포인트
ENTRYPOINT ["/usr/bin/dumb-init", "teleport", "start", "-c", "/etc/teleport/teleport.yaml"]
