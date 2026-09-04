.PHONY: help tools config-check consumer-check lint lint-check format format-check test coverage security verify-release check clean

GOLANGCI_LINT_VERSION ?= v2.12.2
GOVULNCHECK_VERSION ?= v1.7.0
BIN_DIR := $(CURDIR)/bin
CACHE_DIR := $(CURDIR)/.cache
GOLANGCI_LINT := $(BIN_DIR)/golangci-lint
GOVULNCHECK := $(BIN_DIR)/govulncheck
GENERATED_CONFIG := .golangci.yml

export GOCACHE := $(CACHE_DIR)/go-build
export GOLANGCI_LINT_CACHE := $(CACHE_DIR)/golangci-lint

help:
	@grep -E '^[a-zA-Z_-]+:.*?## .*$$' $(MAKEFILE_LIST) | awk 'BEGIN {FS = ":.*?## "}; {printf "\033[36m%-16s\033[0m %s\n", $$1, $$2}'

$(GOLANGCI_LINT):
	GOBIN=$(BIN_DIR) go install github.com/golangci/golangci-lint/v2/cmd/golangci-lint@$(GOLANGCI_LINT_VERSION)

$(GOVULNCHECK):
	GOBIN=$(BIN_DIR) go install golang.org/x/vuln/cmd/govulncheck@$(GOVULNCHECK_VERSION)

tools: $(GOLANGCI_LINT) $(GOVULNCHECK) ## Install pinned validation tools into ./bin

# This package is its own consumer: it lints itself with the config it exports.
$(GENERATED_CONFIG): golangci.yml config.go
	go run ./cmd/golangci-config-path --out $(GENERATED_CONFIG)

config-check: $(GOLANGCI_LINT) $(GENERATED_CONFIG) ## Verify the generated config against the golangci-lint schema
	$(GOLANGCI_LINT) config verify --config $(GENERATED_CONFIG)

consumer-check: $(GOLANGCI_LINT) ## Verify generation and lint behavior from a clean consumer module
	./scripts/check-consumer.sh

lint: lint-check ## Alias for lint-check

lint-check: $(GOLANGCI_LINT) $(GENERATED_CONFIG) ## Run linters
	$(GOLANGCI_LINT) run --config $(GENERATED_CONFIG) ./...

format: $(GOLANGCI_LINT) $(GENERATED_CONFIG) ## Apply formatters
	$(GOLANGCI_LINT) fmt --config $(GENERATED_CONFIG) ./...

format-check: $(GOLANGCI_LINT) $(GENERATED_CONFIG) ## Verify formatting without writing
	$(GOLANGCI_LINT) fmt --diff --config $(GENERATED_CONFIG) ./...

test: ## Run tests
	go test -race ./...

coverage: ## Run tests with coverage into coverage/
	@mkdir -p coverage
	go test -race -covermode=atomic -coverprofile=coverage/coverage.out ./...
	go tool cover -func=coverage/coverage.out
	go tool cover -html=coverage/coverage.out -o coverage/coverage.html

security: $(GOVULNCHECK) ## Fail on reachable known vulnerabilities
	$(GOVULNCHECK) ./...

verify-release: ## Verify VERSION is a Go-compatible semantic release tag
	@printf '%s\n' "$(VERSION)" | grep -Eq '^v(0|1)\.[0-9]+\.[0-9]+$$' || \
		{ echo "VERSION must be a v0.x.y or v1.x.y tag" >&2; exit 1; }

check: config-check lint-check format-check coverage consumer-check security ## Single local and CI gate

clean: ## Remove generated artifacts
	rm -rf bin coverage $(CACHE_DIR) $(GENERATED_CONFIG)
