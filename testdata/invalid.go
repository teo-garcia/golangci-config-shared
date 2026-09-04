package main

import "os"

func main() {
	os.WriteFile("unchecked.txt", []byte("unchecked"), 0o600)
}
