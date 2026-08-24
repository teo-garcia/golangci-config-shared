.PHONY: help tools lint lint-check format format-check test coverage check clean

GOLANGCI_LINT_VERSION ?= v2.11.0
BIN_DIR := $(CURDIR)/bin
GOLANGCI_LINT := $(BIN_DIR)/golangci-lint
GENERATED_CONFIG := .golangci.yml

help:
	@grep -E '^[a-zA-Z_-]+:.*?## .*$$' $(MAKEFILE_LIST) | awk 'BEGIN {FS = ":.*?## "}; {printf "\033[36m%-16s\033[0m %s\n", $$1, $$2}'

$(GOLANGCI_LINT):
	GOBIN=$(BIN_DIR) go install github.com/golangci/golangci-lint/v2/cmd/golangci-lint@$(GOLANGCI_LINT_VERSION)

tools: $(GOLANGCI_LINT) ## Install the pinned golangci-lint into ./bin

# This package is its own consumer: it lints itself with the config it exports.
$(GENERATED_CONFIG): golangci.yml config.go
	go run ./cmd/golangci-config-path --out $(GENERATED_CONFIG)

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

check: lint-check format-check test ## Single CI gate: lint + format + test

clean: ## Remove generated artifacts
	rm -rf bin coverage $(GENERATED_CONFIG)
