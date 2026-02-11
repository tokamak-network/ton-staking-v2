package main

import (
	"encoding/hex"
	"flag"
	"fmt"
	"math/big"
	"os"
	"strings"

	bls12381 "github.com/consensys/gnark-crypto/ecc/bls12-381"
	"github.com/consensys/gnark-crypto/ecc/bls12-381/fr"
)

// padTo64 left-pads a 48-byte field element to 64 bytes (EIP-2537 format)
func padTo64(b []byte) []byte {
	if len(b) >= 64 {
		return b[:64]
	}
	padded := make([]byte, 64)
	copy(padded[64-len(b):], b)
	return padded
}

// g2ToEIP2537 converts gnark-crypto G2 marshal (192 bytes: X_a1||X_a0||Y_a1||Y_a0, each 48 bytes)
// to EIP-2537 format (256 bytes: X_c0||X_c1||Y_c0||Y_c1, each padded to 64 bytes)
func g2ToEIP2537(data []byte) []byte {
	if len(data) != 192 {
		panic(fmt.Sprintf("unexpected G2 marshal size: %d", len(data)))
	}
	result := make([]byte, 256)
	copy(result[0:64], padTo64(data[48:96]))     // X_a0 → X_c0
	copy(result[64:128], padTo64(data[0:48]))     // X_a1 → X_c1
	copy(result[128:192], padTo64(data[144:192])) // Y_a0 → Y_c0
	copy(result[192:256], padTo64(data[96:144]))   // Y_a1 → Y_c1
	return result
}

func main() {
	privateKeys := flag.String("private-keys", "", "Comma-separated BLS private keys (hex, 0x-prefixed)")
	messageHash := flag.String("message", "", "Message hash to sign (32 bytes hex, 0x-prefixed)")
	flag.Parse()

	if *privateKeys == "" || *messageHash == "" {
		fmt.Fprintln(os.Stderr, "Error: --private-keys and --message flags are required")
		flag.Usage()
		os.Exit(1)
	}

	// Parse message hash
	msgHex := strings.TrimPrefix(*messageHash, "0x")
	msgBytes, err := hex.DecodeString(msgHex)
	if err != nil || len(msgBytes) != 32 {
		fmt.Fprintf(os.Stderr, "Error: invalid message hash (must be 32 bytes hex): %v\n", err)
		os.Exit(1)
	}

	// Parse private keys
	keyStrs := strings.Split(*privateKeys, ",")
	var aggregatedSig *bls12381.G2Affine

	for _, keyStr := range keyStrs {
		keyStr = strings.TrimSpace(keyStr)
		keyHex := strings.TrimPrefix(keyStr, "0x")
		keyBytes, err := hex.DecodeString(keyHex)
		if err != nil || len(keyBytes) != 32 {
			fmt.Fprintf(os.Stderr, "Error: invalid private key (must be 32 bytes hex): %s\n", keyStr)
			os.Exit(1)
		}

		// Convert little-endian private key to big-endian for gnark-crypto
		keyBE := make([]byte, 32)
		for i := range 32 {
			keyBE[i] = keyBytes[31-i]
		}

		// Restore scalar from big-endian bytes
		var scalar fr.Element
		scalar.SetBytes(keyBE)

		// Hash message to G2: H(m) using the same DST as BLS12381.sol
		dst := []byte("BLS_SIG_BLS12381G2_XMD:SHA-256_SSWU_RO_")
		hashG2, err := bls12381.HashToG2(msgBytes, dst)
		if err != nil {
			fmt.Fprintf(os.Stderr, "Error hashing to G2: %v\n", err)
			os.Exit(1)
		}

		// Sign: sig = privKey * H(m)
		var sig bls12381.G2Affine
		sig.ScalarMultiplication(&hashG2, scalar.BigInt(new(big.Int)))

		// Aggregate signatures (G2 point addition)
		if aggregatedSig == nil {
			aggregatedSig = &sig
		} else {
			var sum bls12381.G2Jac
			sum.FromAffine(aggregatedSig)
			var sigJac bls12381.G2Jac
			sigJac.FromAffine(&sig)
			sum.AddAssign(&sigJac)
			aggregatedSig = new(bls12381.G2Affine)
			aggregatedSig.FromJacobian(&sum)
		}
	}

	// Marshal to standard format (192 bytes) then convert to EIP-2537 (256 bytes)
	sigRaw := aggregatedSig.Marshal()
	sigBytes := g2ToEIP2537(sigRaw)

	// Output 0x-prefixed hex for Foundry vm.ffi consumption
	fmt.Printf("0x%s", hex.EncodeToString(sigBytes))
}
