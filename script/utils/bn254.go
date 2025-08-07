package main

import (
	"encoding/json"
	"errors"
	"fmt"
	"math/big"
	"os"

	bn254 "github.com/consensys/gnark-crypto/ecc/bn254"
)

// Error types for precompile compatibility
var (
	ErrInvalidPointFormat = errors.New("invalid point format for precompile")
	ErrPointNotInSubgroup = errors.New("point not in correct subgroup")
	ErrInvalidFieldOrder  = errors.New("number not in valid field order")
)

// FieldModulus is the BN254 field modulus
var FieldModulus = func() *big.Int {
	n, _ := new(big.Int).SetString("21888242871839275222246405745257275088696311157297823662689037894645226208583", 10)
	return n
}()

// Precompile format constants
const (
	G1PointSize = 64  // 32 bytes for x, 32 bytes for y
	G2PointSize = 128 // 64 bytes for x, 64 bytes for y
)

// ValidateFieldOrder checks if a number is in the correct field
func ValidateFieldOrder(n *big.Int) bool {
	return n.Cmp(FieldModulus) < 0
}

var (
	g1Gen bn254.G1Affine
	g2Gen bn254.G2Affine
)

// Initialize generators
func init() {
	_, _, g1Gen, g2Gen = bn254.Generators()
}

// PrivateKey represents a BLS private key
type PrivateKey struct {
	ScalarBytes []byte
	scalar      *big.Int
}

// PublicKey represents a BLS public key
type PublicKey struct {
	PointBytes []byte
	G1Point    *bn254.G1Affine
	G2Point    *bn254.G2Affine
}

// Signature represents a BLS signature
type Signature struct {
	SigBytes []byte
	sig      *bn254.G1Affine
}

func (s *Signature) GetG1Point() *bn254.G1Affine {
	return s.sig
}

// GenerateKeyPair creates a new random private key and the corresponding public key
func GenerateKeyPair(sk *big.Int) (*PrivateKey, *PublicKey, error) {
	// Compute the public key in G2
	pkG2Point := new(bn254.G2Affine).ScalarMultiplication(&g2Gen, sk)
	// Compute the public key in G1
	pkG1Point := new(bn254.G1Affine).ScalarMultiplication(&g1Gen, sk)

	// Create private key
	privateKey := &PrivateKey{
		scalar:      sk,
		ScalarBytes: sk.Bytes(),
	}

	// Create public key
	publicKey := &PublicKey{
		G1Point:    pkG1Point,
		G2Point:    pkG2Point,
		PointBytes: pkG2Point.Marshal(), // Keep G2 point as the default for backward compatibility
	}

	return privateKey, publicKey, nil
}

func main() {
	// Parse args
	arg1 := os.Args[1]
	n := new(big.Int)
	n.SetString(arg1, 10)

	// Generate key pair
	_, pubKey, err := GenerateKeyPair(n)
	if err != nil {
		fmt.Println("Error generating key pair:", err)
		return
	}

	g1X := pubKey.G1Point.X.String()
	g1Y := pubKey.G1Point.Y.String()
	g2X := pubKey.G2Point.X.A0.String()
	g2X1 := pubKey.G2Point.X.A1.String()
	g2Y := pubKey.G2Point.Y.A0.String()
	g2Y1 := pubKey.G2Point.Y.A1.String()

	// Create file
	file, err := os.Create("script/BLSConfig.json")
	if err != nil {
		fmt.Println("Error creating file:", err)
		return
	}
	defer file.Close()

	// Create an encoder and write JSON to file
	encoder := json.NewEncoder(file)
	encoder.SetIndent("", "  ")
	if err := encoder.Encode(map[string]string{
		"g1X":  g1X,
		"g1Y":  g1Y,
		"g2X":  g2X,
		"g2X1": g2X1,
		"g2Y":  g2Y,
		"g2Y1": g2Y1,
	}); err != nil {
		fmt.Println("Error encoding JSON:", err)
	}

}
