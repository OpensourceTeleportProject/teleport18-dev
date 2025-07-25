# Sync with devbox.json.
GOLANG_VERSION ?= go1.24.4
GOLANGCI_LINT_VERSION ?= v2.1.5

# NOTE: Remember to update engines.node in package.json to match the major version.
NODE_VERSION ?= 22.14.0

# Run lint-rust check locally before merging code after you bump this.
RUST_VERSION ?= 1.81.0
WASM_PACK_VERSION ?= 0.12.1
LIBBPF_VERSION ?= 1.2.2
LIBPCSCLITE_VERSION ?= 1.9.9-teleport

DEVTOOLSET ?= devtoolset-12

# Protogen related versions.
BUF_VERSION ?= v1.50.1
# Keep in sync with api/proto/buf.yaml (and buf.lock).
GOGO_PROTO_TAG ?= v1.3.2
NODE_GRPC_TOOLS_VERSION ?= 1.12.4
NODE_PROTOC_TS_VERSION ?= 5.0.1
PROTOC_VERSION ?= 26.1