<div align="center">

# golangci-config-shared

**Shared golangci-lint configuration — linting _and_ formatting — for teo-garcia Go templates**

[![License: MIT](https://img.shields.io/badge/License-MIT-blue.svg)](LICENSE)
[![Go](https://img.shields.io/badge/Go-1.25+-00ADD8?logo=go&logoColor=white)](https://go.dev)
[![golangci-lint](https://img.shields.io/badge/golangci--lint-v2-3776AB?logo=go&logoColor=white)](https://golangci-lint.run)

Part of the [@teo-garcia/templates](https://github.com/teo-garcia/templates) ecosystem

</div>

---

## Why one package for both

golangci-lint v2 owns linting (`run`) and formatting (`fmt`) from a single
config file, the same way `ruff` owns lint + format for the Python templates. So
this package is the Go counterpart of `ruff-config-shared`, not of
`eslint-config-shared` + `prettier-config-shared` split in two.

Test and coverage settings live in the sibling `gotest-config-shared`.

---

## Settings

| Setting | Value |
| --- | --- |
| **Schema version** | `2` |
| **Linter default set** | `standard` (errcheck, govet, ineffassign, staticcheck, unused) |
| **Added linters** | bodyclose, contextcheck, copyloopvar, errorlint, gocritic, gosec, misspell, nilerr, noctx, nolintlint, prealloc, revive, rowserrcheck, sqlclosecheck, unconvert, unparam, usestdlibvars, wastedassign |
| **Formatters** | `gofumpt` (extra rules) + `gci` |
| **Import order** | standard → default → `prefix(github.com/teo-garcia)` |
| **Timeout** | `5m` |
| **Thresholds** | none — `max-issues-per-linter: 0`, `max-same-issues: 0` |

`fieldalignment` is off (it fights readability), `G104` is off (it duplicates
errcheck), and `package-comments` is off (templates are not published
libraries). Test files relax `bodyclose`, `dupl`, `errcheck`, `gosec`, `noctx`,
and `unparam`.

---

## Requirements

- Go 1.25.13+
- golangci-lint v2.12+

---

## Usage

golangci-lint has **no native config inheritance**, so this package provides
it. Add the module as a dependency and generate the config:

```bash
go get github.com/teo-garcia/golangci-config-shared
go run github.com/teo-garcia/golangci-config-shared/cmd/golangci-config-path --out .golangci.yml
```

Gitignore the generated file — it is build output, not source:

```gitignore
.golangci.yml
```

Then point the linter and the formatter at it:

```bash
golangci-lint run --config .golangci.yml ./...   # lint
golangci-lint fmt --config .golangci.yml ./...   # format
golangci-lint fmt --diff --config .golangci.yml ./...  # format check
```

### Repo-specific overrides

Commit a `golangci.overrides.yml` with only what differs, and merge it in:

```bash
golangci-config-path --out .golangci.yml --overlay golangci.overrides.yml
```

Merge semantics: maps merge key-by-key at every depth; scalars **and sequences**
are replaced wholesale. Lists are deliberately not appended so a consumer can
narrow `linters.enable`, not just grow it. A missing overlay file is treated as
empty, so `make lint` works before you have one.

### In a Makefile

```make
GOLANGCI_LINT_VERSION ?= v2.11.0

.golangci.yml: go.mod golangci.overrides.yml
	go run github.com/teo-garcia/golangci-config-shared/cmd/golangci-config-path \
		--out $@ --overlay golangci.overrides.yml

lint-check: .golangci.yml
	golangci-lint run --config .golangci.yml ./...
```

### As a library

```go
import golangciconfig "github.com/teo-garcia/golangci-config-shared"

raw := golangciconfig.Baseline()              // canonical YAML
merged, err := golangciconfig.Merge(overlay)  // baseline + overlay
err = golangciconfig.Write(".golangci.yml", overlay)
```

---

## Scripts

| Command | Description |
| --- | --- |
| `make tools` | Install the pinned golangci-lint into `./bin` |
| `make config-check` | Verify the generated config against golangci-lint's schema |
| `make consumer-check` | Generate and enforce the config from a clean consumer module |
| `make lint-check` | Run linters (self-hosted: uses its own exported config) |
| `make format` | Apply gofumpt + gci |
| `make format-check` | Verify formatting without writing |
| `make test` | Run tests with `-race` |
| `make coverage` | Tests + coverage into `coverage/` |
| `make security` | Scan reachable code with pinned `govulncheck` |
| `make check` | Single local and CI gate |
| `make verify-release VERSION=v0.1.0` | Validate a Go module release tag |

---

## Related Packages

| Package | Description |
| --- | --- |
| `gotest-config-shared` | Go test, coverage, and LCOV settings |
| `teo-ruff-config-shared` | Ruff lint and format settings (Python) |
| `eslint-config-shared` | ESLint settings (TypeScript) |
| `prettier-config-shared` | Prettier settings (TypeScript) |

---

## License

MIT © teo-garcia
