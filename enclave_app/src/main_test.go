package main

import (
	"testing"
)

func TestVerifyAttestationDoc(t *testing.T) {
	t.Run("ValidPCR0", func(t *testing.T) {
		doc := &AttestationDoc{
			PCR0: "expected_hash",
		}
		if !verifyAttestationDoc(doc, "expected_hash") {
			t.Errorf("verifyAttestationDoc() = false, want true")
		}
	})

	t.Run("MismatchedPCR0", func(t *testing.T) {
		doc := &AttestationDoc{
			PCR0: "actual_hash",
		}
		if verifyAttestationDoc(doc, "expected_hash") {
			t.Errorf("verifyAttestationDoc() = true, want false")
		}
	})

	t.Run("NilDocument", func(t *testing.T) {
		if verifyAttestationDoc(nil, "any_hash") {
			t.Errorf("verifyAttestationDoc() with nil doc = true, want false")
		}
	})
}
