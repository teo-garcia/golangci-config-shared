#!/bin/sh
set -eu

repo_root=$(CDPATH='' cd -- "$(dirname -- "$0")/.." && pwd)
tmp_root=$(mktemp -d "${TMPDIR:-/tmp}/golangci-config-consumer.XXXXXX")
export GOCACHE="$tmp_root/go-build-cache"
export GOLANGCI_LINT_CACHE="$tmp_root/golangci-lint-cache"

cleanup() {
	rm -rf -- "$tmp_root"
}
trap cleanup EXIT HUP INT TERM

cp -R "$repo_root/testdata/consumer" "$tmp_root/consumer"
cd "$tmp_root/consumer"

go mod edit -replace "github.com/teo-garcia/golangci-config-shared=$repo_root"
go get github.com/teo-garcia/golangci-config-shared@v0.0.0
go run github.com/teo-garcia/golangci-config-shared/cmd/golangci-config-path --out .golangci.yml
"$repo_root/bin/golangci-lint" config verify --config .golangci.yml
"$repo_root/bin/golangci-lint" run --config .golangci.yml ./...

cp "$repo_root/testdata/invalid.go" main.go
if "$repo_root/bin/golangci-lint" run --config .golangci.yml ./... >/dev/null 2>&1; then
	echo "consumer lint unexpectedly accepted an unchecked error" >&2
	exit 1
fi
