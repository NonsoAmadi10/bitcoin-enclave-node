package main

import (
	"bytes"
	"context"
	"encoding/json"
	"flag"
	"fmt"
	"log"
	"os/exec"
	"time"

	"github.com/mdlayher/vsock"
)

const (
	enclaveVsockPort = 5000
)

type EnclaveInfo struct {
	EnclaveID string `json:"EnclaveID"`
}

type AttestationDoc struct {
	PCR0 string `json:"pcr0"`
}

func main() {
	// --- Argument Parsing ---
	eifPath := flag.String("eif-path", "", "Path to the Enclave Image File (.eif)")
	enclaveName := flag.String("enclave-name", "", "Name for the Nitro Enclave")
	cpuCount := flag.Int("cpu-count", 1, "Number of vCPUs for the enclave")
	memoryMib := flag.Int("memory-mib", 256, "Memory (MiB) for the enclave")
	expectedMeasurement := flag.String("expected-measurement", "", "Expected PCR0 measurement for attestation")
	kmsKeyArn := flag.String("kms-key-arn", "", "ARN of the KMS key for secret unwrapping (optional)")
	awsRegion := flag.String("aws-region", "", "AWS region for KMS operations (if KMS key is provided)")
	flag.Parse()

	if *eifPath == "" || *enclaveName == "" || *expectedMeasurement == "" {
		log.Println("Missing required arguments: --eif-path, --enclave-name, --expected-measurement")
		flag.Usage()
		log.Fatalf("Exiting due to missing arguments.")
	}

	// --- Enclave Lifecycle Management ---
	var enclaveID string
	var err error

	// 1. Launch the Enclave
	enclaveID, err = launchEnclave(*eifPath, *enclaveName, *cpuCount, *memoryMib)
	if err != nil {
		log.Fatalf("Failed to launch enclave: %v", err)
	}
	// Ensure enclave is terminated on exit
	defer terminateEnclave(enclaveID)

	log.Println("Giving enclave a moment to start VSOCK server...")
	time.Sleep(10 * time.Second)

	// 2. Get and Verify Attestation Document
	attestationDoc, err := getAttestationDoc(enclaveID)
	if err != nil {
		log.Fatalf("Failed to retrieve attestation document: %v", err)
	}

	if !verifyAttestationDoc(attestationDoc, *expectedMeasurement) {
		log.Fatalf("Attestation document verification failed.")
	}

	// 3. (Optional) KMS Secret Unwrapping
	if *kmsKeyArn != "" {
		log.Printf("KMS key ARN provided (%s) in region %s. Proceeding with secret unwrapping (placeholder).", *kmsKeyArn, *awsRegion)
		// In a real scenario, you'd integrate the AWS SDK for Go here.
	}

	// 4. Communicate with the Enclave
	response, err := communicateWithEnclave("Hello from Parent!")
	if err != nil {
		log.Fatalf("Failed to communicate with enclave: %v", err)
	}
	log.Printf("Parent received final response: %s", response)

	log.Println("Parent application finished.")
}
func launchEnclave(eifPath, enclaveName string, cpuCount, memoryMib int) (string, error) {
	log.Printf("Launching enclave '%s' with EIF: %s", enclaveName, eifPath)
	cmd := exec.Command("nitro-cli", "run-enclave",
		"--eif-path", eifPath,
		"--enclave-name", enclaveName,
		"--cpu-count", fmt.Sprintf("%d", cpuCount),
		"--memory", fmt.Sprintf("%d", memoryMib),
		"--debug-mode",
	)

	var out, stderr bytes.Buffer
	cmd.Stdout = &out
	cmd.Stderr = &stderr
	if err := cmd.Run(); err != nil {
		return "", fmt.Errorf("error launching enclave: %v\n%s", err, stderr.String())
	}

	var info EnclaveInfo
	if err := json.Unmarshal(out.Bytes(), &info); err != nil {
		return "", fmt.Errorf("failed to decode JSON from nitro-cli run-enclave: %v", err)
	}

	log.Printf("Enclave launched successfully with EnclaveID: %s", info.EnclaveID)
	return info.EnclaveID, nil
}

func terminateEnclave(enclaveID string) {
	log.Printf("Terminating enclave with EnclaveID: %s", enclaveID)
	cmd := exec.Command("nitro-cli", "terminate-enclave", "--enclave-id", enclaveID)
	if err := cmd.Run(); err != nil {
		log.Printf("Warning: failed to terminate enclave %s: %v", enclaveID, err)
	} else {
		log.Printf("Enclave %s terminated successfully.", enclaveID)
	}
}

func getAttestationDoc(enclaveID string) (*AttestationDoc, error) {
	log.Printf("Requesting attestation document for EnclaveID: %s", enclaveID)
	cmd := exec.Command("nitro-cli", "get-attestation-document", "--enclave-id", enclaveID, "--decode")

	var out, stderr bytes.Buffer
	cmd.Stdout = &out
	cmd.Stderr = &stderr
	if err := cmd.Run(); err != nil {
		return nil, fmt.Errorf("error getting attestation document: %v\n%s", err, stderr.String())
	}

	var doc AttestationDoc
	if err := json.Unmarshal(out.Bytes(), &doc); err != nil {
		return nil, fmt.Errorf("failed to decode JSON from attestation doc: %v", err)
	}

	log.Println("Attestation document retrieved successfully.")
	return &doc, nil
}

func verifyAttestationDoc(doc *AttestationDoc, expectedPCR0 string) bool {
	log.Println("Verifying attestation document...")
	if doc == nil {
		log.Println("No attestation document provided.")
		return false
	}

	log.Printf("Attestation Doc PCR0: %s", doc.PCR0)
	log.Printf("Expected PCR0:      %s", expectedPCR0)
	if doc.PCR0 == expectedPCR0 {
		log.Println("PCR0 measurement verified successfully.")
		return true
	}

	log.Println("ERROR: PCR0 measurement mismatch!")
	return false
}

func communicateWithEnclave(message string) (string, error) {
	log.Printf("Connecting to enclave via VSOCK on port %d...", enclaveVsockPort)
	
	// The parent connects to CID 3, which is the default CID for the first enclave.
	// This is a simplification for this example. A more robust solution would parse the CID from `nitro-cli run-enclave`.
	const enclaveCID = 3

	ctx, cancel := context.WithTimeout(context.Background(), 5*time.Second)
	defer cancel()

	conn, err := vsock.Dial(ctx, enclaveCID, enclaveVsockPort, nil)
	if err != nil {
		return "", fmt.Errorf("failed to dial vsock: %v", err)
	}
	defer conn.Close()

	log.Printf("Connected to enclave. Sending message: %s", message)
	if _, err := conn.Write([]byte(message)); err != nil {
		return "", fmt.Errorf("failed to write to enclave: %v", err)
	}

	buf := make([]byte, 1024)
	n, err := conn.Read(buf)
	if err != nil {
		return "", fmt.Errorf("failed to read from enclave: %v", err)
	}

	response := string(buf[:n])
	log.Printf("Received from enclave: %s", response)
	return response, nil
}
