package main

import (
	"fmt"
	"log"
	"net"
	"os"

	"github.com/mdlayher/vsock"
)

const (
	vsockPort = 5000
)

func main() {
	log.Println("Enclave server starting...")

	// Listen on the VSOCK port
	l, err := vsock.Listen(vsockPort)
	if err != nil {
		log.Fatalf("failed to listen on vsock port %d: %v", vsockPort, err)
	}
	defer l.Close()

	log.Printf("Listening on vsock port %d", vsockPort)

	for {
		// Accept a new connection
		conn, err := l.Accept()
		if err != nil {
			log.Printf("failed to accept connection: %v", err)
			continue
		}
		log.Printf("Accepted connection from: %s", conn.RemoteAddr().String())

		// Handle the connection in a new goroutine
		go handleConnection(conn)
	}
}

func handleConnection(conn net.Conn) {
	defer conn.Close()
	defer log.Println("Closing client connection.")

	buf := make([]byte, 1024)
	for {
		// Read data from the connection
		n, err := conn.Read(buf)
		if err != nil {
			if err.Error() != "EOF" {
				log.Printf("failed to read from connection: %v", err)
			}
			return
		}

		message := string(buf[:n])
		log.Printf("Received message: %s", message)

		// Simulate a sensitive operation (e.g., signing)
		response := fmt.Sprintf("ENCLAVE_SIGNED:%s", message)
		log.Printf("Sending response: %s", response)

		// Send the response back
		if _, err := conn.Write([]byte(response)); err != nil {
			log.Printf("failed to write to connection: %v", err)
			return
		}
	}
}
