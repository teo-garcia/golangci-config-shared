// Command golangci-config-path materializes the shared golangci-lint
// configuration so a consumer repo can point `golangci-lint` at it.
//
// With no flags it prints the baseline to stdout, which makes it usable as a
// pipe source. With --out it writes a merged config file, which is the mode the
// template Makefiles use.
//
//	golangci-config-path                                  # print baseline YAML
//	golangci-config-path --out .golangci.yml              # generate config
//	golangci-config-path --out .golangci.yml \
//	    --overlay golangci.overrides.yml                  # generate + override
package main

import (
	"errors"
	"flag"
	"fmt"
	"io"
	"io/fs"
	"os"

	golangciconfig "github.com/teo-garcia/golangci-config-shared"
)

func main() {
	if err := run(os.Args[1:], os.Stdout, os.Stderr); err != nil {
		fmt.Fprintln(os.Stderr, "golangci-config-path:", err)
		os.Exit(1)
	}
}

func run(args []string, stdout, stderr io.Writer) error {
	flags := flag.NewFlagSet("golangci-config-path", flag.ContinueOnError)
	flags.SetOutput(stderr)
	out := flags.String("out", "", "write the merged config to this path instead of stdout")
	overlay := flags.String("overlay", "", "optional repo-local YAML merged onto the shared baseline")
	if err := flags.Parse(args); err != nil {
		return err
	}

	overlayData, err := readOverlay(*overlay)
	if err != nil {
		return err
	}

	if *out == "" {
		merged, err := golangciconfig.Merge(overlayData)
		if err != nil {
			return err
		}
		_, err = stdout.Write(merged)
		return err
	}

	if err := golangciconfig.Write(*out, overlayData); err != nil {
		return err
	}
	fmt.Fprintln(stdout, *out)
	return nil
}

// readOverlay loads the overlay file. A missing overlay is not an error: the
// template ships without one, and `make lint` must still work before a
// consumer decides it needs overrides.
func readOverlay(path string) ([]byte, error) {
	if path == "" {
		return nil, nil
	}
	data, err := os.ReadFile(path)
	if errors.Is(err, fs.ErrNotExist) {
		return nil, nil
	}
	if err != nil {
		return nil, fmt.Errorf("read overlay %s: %w", path, err)
	}
	return data, nil
}
