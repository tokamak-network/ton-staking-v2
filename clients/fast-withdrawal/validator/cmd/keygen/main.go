package main

import (
	"crypto/rand"
	"encoding/hex"
	"flag"
	"fmt"
	"math/big"
	"os"

	bls12381 "github.com/consensys/gnark-crypto/ecc/bls12-381"
	"github.com/consensys/gnark-crypto/ecc/bls12-381/fr"
	"github.com/ethereum/go-ethereum/common"
	"github.com/ethereum/go-ethereum/crypto"
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

// g1ToEIP2537 converts gnark-crypto G1 marshal (96 bytes: X||Y, each 48 bytes)
// to EIP-2537 format (128 bytes: X_padded||Y_padded, each 64 bytes)
func g1ToEIP2537(data []byte) []byte {
	if len(data) != 96 {
		panic(fmt.Sprintf("unexpected G1 marshal size: %d", len(data)))
	}
	result := make([]byte, 128)
	copy(result[0:64], padTo64(data[0:48]))
	copy(result[64:128], padTo64(data[48:96]))
	return result
}

// g2ToEIP2537 converts gnark-crypto G2 marshal (192 bytes: X_a1||X_a0||Y_a1||Y_a0, each 48 bytes)
// to EIP-2537 format (256 bytes: X_c0||X_c1||Y_c0||Y_c1, each padded to 64 bytes)
// gnark uses a0+a1*u ordering in marshal as a1||a0, EIP-2537 expects c0||c1 where c0=a0, c1=a1
func g2ToEIP2537(data []byte) []byte {
	if len(data) != 192 {
		panic(fmt.Sprintf("unexpected G2 marshal size: %d", len(data)))
	}
	result := make([]byte, 256)
	copy(result[0:64], padTo64(data[48:96]))     // X_a0 → X_c0
	copy(result[64:128], padTo64(data[0:48]))    // X_a1 → X_c1
	copy(result[128:192], padTo64(data[144:192])) // Y_a0 → Y_c0
	copy(result[192:256], padTo64(data[96:144]))  // Y_a1 → Y_c1
	return result
}

func main() {
	validatorAddr := flag.String("validator", "", "Validator Ethereum address (required)")
	chainID := flag.Int64("chain-id", 900, "L1 chain ID")
	flag.Parse()

	if *validatorAddr == "" {
		fmt.Fprintln(os.Stderr, "Error: --validator flag is required")
		flag.Usage()
		os.Exit(1)
	}

	addr := common.HexToAddress(*validatorAddr)
	chain := big.NewInt(*chainID)

	// 1. Generate random BLS private key (scalar in Fr)
	var scalar fr.Element
	_, err := scalar.SetRandom()
	if err != nil {
		fmt.Fprintf(os.Stderr, "Error generating random scalar: %v\n", err)
		os.Exit(1)
	}
	_ = rand.Reader // ensure crypto/rand is used by gnark internally

	// Get private key bytes (32 bytes, little-endian for herumi compatibility)
	privKeyBytes := scalar.Marshal()
	// gnark-crypto Marshal() returns big-endian, herumi expects little-endian
	privKeyLE := make([]byte, 32)
	for i := range 32 {
		privKeyLE[i] = privKeyBytes[31-i]
	}

	// 2. Compute public key: pubKey = privKey * G1
	_, _, g1Gen, _ := bls12381.Generators()
	var pubKeyG1 bls12381.G1Affine
	pubKeyG1.ScalarMultiplication(&g1Gen, scalar.BigInt(new(big.Int)))

	// Marshal to standard format (96 bytes) then convert to EIP-2537 (128 bytes)
	pubKeyRaw := pubKeyG1.Marshal()
	pubKeyBytes := g1ToEIP2537(pubKeyRaw)

	// 3. Generate Proof of Possession (PoP)
	// popMessage = keccak256(abi.encodePacked("BLS_POP", chainId, validatorAddress, publicKey))
	// Note: chainId is uint256 in Solidity (32 bytes, left-padded)
	chainIDBytes := common.LeftPadBytes(chain.Bytes(), 32)
	popMessage := crypto.Keccak256(
		[]byte("BLS_POP"),
		chainIDBytes,
		addr.Bytes(),
		pubKeyBytes,
	)

	// Hash message to G2 and sign: popSig = privKey * HashToG2(popMessage)
	// DST must match Solidity BLS12381.sol: "BLS_SIG_BLS12381G2_XMD:SHA-256_SSWU_RO_"
	popG2, err := bls12381.HashToG2(popMessage, []byte("BLS_SIG_BLS12381G2_XMD:SHA-256_SSWU_RO_"))
	if err != nil {
		fmt.Fprintf(os.Stderr, "Error hashing to G2: %v\n", err)
		os.Exit(1)
	}
	var popSig bls12381.G2Affine
	popSig.ScalarMultiplication(&popG2, scalar.BigInt(new(big.Int)))

	// Marshal to standard format (192 bytes) then convert to EIP-2537 (256 bytes)
	popRaw := popSig.Marshal()
	popBytes := g2ToEIP2537(popRaw)

	// 4. Self-verification: verify PoP using gnark pairing
	if err := verifyPoP(pubKeyG1, popSig, popMessage); err != nil {
		fmt.Fprintf(os.Stderr, "Error: PoP self-verification failed: %v\n", err)
		os.Exit(1)
	}

	// 5. Output
	fmt.Printf("BLS_PRIVATE_KEY=0x%s\n", hex.EncodeToString(privKeyLE))
	fmt.Printf("BLS_PUBLIC_KEY=0x%s\n", hex.EncodeToString(pubKeyBytes))
	fmt.Printf("BLS_POP=0x%s\n", hex.EncodeToString(popBytes))
}

// verifyPoP verifies the proof of possession using pairing check:
// e(G1, popSig) == e(pubKey, HashToG2(message))
func verifyPoP(pubKey bls12381.G1Affine, popSig bls12381.G2Affine, message []byte) error {
	_, _, g1Gen, _ := bls12381.Generators()

	hashG2, err := bls12381.HashToG2(message, []byte("BLS_SIG_BLS12381G2_XMD:SHA-256_SSWU_RO_"))
	if err != nil {
		return fmt.Errorf("hash to G2 failed: %w", err)
	}

	// Pairing check: e(-G1, popSig) * e(pubKey, H(m)) == 1
	var negG1 bls12381.G1Affine
	negG1.Neg(&g1Gen)

	ok, err := bls12381.PairingCheck(
		[]bls12381.G1Affine{negG1, pubKey},
		[]bls12381.G2Affine{popSig, hashG2},
	)
	if err != nil {
		return fmt.Errorf("pairing check failed: %w", err)
	}
	if !ok {
		return fmt.Errorf("pairing check returned false")
	}

	return nil
}
