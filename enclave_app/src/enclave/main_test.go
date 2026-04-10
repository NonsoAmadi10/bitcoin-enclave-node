package main

import (
	"net"
	"testing"
	"time"
)

func TestHandleConnectionEchoesSignedMessage(t *testing.T) {
	server, client := net.Pipe()
	done := make(chan struct{})

	go func() {
		handleConnection(server)
		close(done)
	}()

	input := "hello-enclave"
	if _, err := client.Write([]byte(input)); err != nil {
		t.Fatalf("failed writing to client pipe: %v", err)
	}

	buffer := make([]byte, 1024)
	n, err := client.Read(buffer)
	if err != nil {
		t.Fatalf("failed reading from client pipe: %v", err)
	}

	response := string(buffer[:n])
	expected := "ENCLAVE_SIGNED:" + input
	if response != expected {
		t.Fatalf("unexpected response: got %q, want %q", response, expected)
	}

	if err := client.Close(); err != nil {
		t.Fatalf("failed closing client: %v", err)
	}

	select {
	case <-done:
	case <-time.After(2 * time.Second):
		t.Fatal("handleConnection did not exit after client close")
	}
}

func TestHandleConnectionReturnsOnEOF(t *testing.T) {
	server, client := net.Pipe()
	done := make(chan struct{})

	go func() {
		handleConnection(server)
		close(done)
	}()

	if err := client.Close(); err != nil {
		t.Fatalf("failed closing client: %v", err)
	}

	select {
	case <-done:
	case <-time.After(2 * time.Second):
		t.Fatal("handleConnection did not exit on EOF")
	}
}
