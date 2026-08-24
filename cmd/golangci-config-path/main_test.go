package main

import (
	"bytes"
	"os"
	"path/filepath"
	"strings"
	"testing"

	"gopkg.in/yaml.v3"
)

func TestRunPrintsBaselineToStdout(t *testing.T) {
	t.Parallel()

	var stdout, stderr bytes.Buffer
	if err := run(nil, &stdout, &stderr); err != nil {
		t.Fatalf("run returned error: %v", err)
	}

	cfg := decode(t, stdout.Bytes())
	if got := cfg["version"]; got != "2" {
		t.Errorf("printed config version = %v, want \"2\"", got)
	}
	if stderr.Len() != 0 {
		t.Errorf("stderr = %q, want empty", stderr.String())
	}
}

func TestRunWritesFileAndEchoesPath(t *testing.T) {
	t.Parallel()

	path := filepath.Join(t.TempDir(), ".golangci.yml")
	var stdout, stderr bytes.Buffer
	if err := run([]string{"--out", path}, &stdout, &stderr); err != nil {
		t.Fatalf("run returned error: %v", err)
	}

	if got := strings.TrimSpace(stdout.String()); got != path {
		t.Errorf("stdout = %q, want the written path %q", got, path)
	}

	data, err := os.ReadFile(path)
	if err != nil {
		t.Fatalf("config was not written: %v", err)
	}
	if got := decode(t, data)["version"]; got != "2" {
		t.Errorf("written config version = %v, want \"2\"", got)
	}
}

func TestRunAppliesOverlay(t *testing.T) {
	t.Parallel()

	dir := t.TempDir()
	overlayPath := filepath.Join(dir, "golangci.overrides.yml")
	if err := os.WriteFile(overlayPath, []byte("run:\n  timeout: 42s\n"), 0o600); err != nil {
		t.Fatalf("seed overlay: %v", err)
	}
	outPath := filepath.Join(dir, ".golangci.yml")

	var stdout, stderr bytes.Buffer
	err := run([]string{"--out", outPath, "--overlay", overlayPath}, &stdout, &stderr)
	if err != nil {
		t.Fatalf("run returned error: %v", err)
	}

	data, err := os.ReadFile(outPath)
	if err != nil {
		t.Fatalf("config was not written: %v", err)
	}
	run, _ := decode(t, data)["run"].(map[string]any)
	if got := run["timeout"]; got != "42s" {
		t.Errorf("run.timeout = %v, want 42s from the overlay", got)
	}
}

// The template ships without an overlay file, so `make lint` must not break
// when the configured overlay path does not exist yet.
func TestRunTreatsMissingOverlayAsEmpty(t *testing.T) {
	t.Parallel()

	dir := t.TempDir()
	var stdout, stderr bytes.Buffer
	args := []string{
		"--out", filepath.Join(dir, ".golangci.yml"),
		"--overlay", filepath.Join(dir, "does-not-exist.yml"),
	}

	if err := run(args, &stdout, &stderr); err != nil {
		t.Fatalf("missing overlay should be tolerated, got error: %v", err)
	}
}

func TestRunFailsOnUnknownFlag(t *testing.T) {
	t.Parallel()

	var stdout, stderr bytes.Buffer
	if err := run([]string{"--nope"}, &stdout, &stderr); err == nil {
		t.Fatal("run accepted an unknown flag")
	}
}

func decode(t *testing.T, data []byte) map[string]any {
	t.Helper()
	cfg := map[string]any{}
	if err := yaml.Unmarshal(data, &cfg); err != nil {
		t.Fatalf("output is not valid YAML: %v", err)
	}
	return cfg
}
