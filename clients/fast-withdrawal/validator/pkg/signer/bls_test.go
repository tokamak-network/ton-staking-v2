package signer

import (
	"encoding/hex"
	"math/big"
	"testing"

	"github.com/ethereum/go-ethereum/common"
	"github.com/ethereum/go-ethereum/crypto"
)

func TestGenerateKey(t *testing.T) {
	signer, err := GenerateKey()
	if err != nil {
		t.Fatalf("Failed to generate key: %v", err)
	}

	pubKey := signer.PublicKey()
	// herumi BLS는 압축 형식 (48 bytes)
	if len(pubKey) != 48 {
		t.Errorf("Expected public key length 48, got %d", len(pubKey))
	}

	t.Logf("Generated BLS key pair")
	t.Logf("Private key: 0x%s", signer.PrivateKeyHex())
	t.Logf("Public key: 0x%s", hex.EncodeToString(pubKey))
}

func TestNewBLSSigner(t *testing.T) {
	// 테스트용 개인키 (32 bytes)
	privateKeyHex := "0x1234567890abcdef1234567890abcdef1234567890abcdef1234567890abcdef"

	signer, err := NewBLSSigner(privateKeyHex)
	if err != nil {
		t.Fatalf("Failed to create signer: %v", err)
	}

	pubKey := signer.PublicKey()
	// herumi BLS는 압축 형식 (48 bytes)
	if len(pubKey) != 48 {
		t.Errorf("Expected public key length 48, got %d", len(pubKey))
	}

	// 압축된 공개키 테스트
	pubKeyCompressed := signer.PublicKeyCompressed()
	if len(pubKeyCompressed) != 48 {
		t.Errorf("Expected compressed public key length 48, got %d", len(pubKeyCompressed))
	}
}

func TestSign(t *testing.T) {
	signer, err := GenerateKey()
	if err != nil {
		t.Fatalf("Failed to generate key: %v", err)
	}

	// 테스트 메시지
	message := crypto.Keccak256([]byte("test message"))

	// 서명 생성
	signature, err := signer.Sign(message)
	if err != nil {
		t.Fatalf("Failed to sign: %v", err)
	}

	// herumi BLS는 압축 형식 (96 bytes)
	if len(signature) != 96 {
		t.Errorf("Expected signature length 96, got %d", len(signature))
	}

	// 서명 검증
	pubKey := signer.PublicKey()
	if !VerifySignature(message, signature, pubKey) {
		t.Error("Signature verification failed")
	}

	t.Logf("Signature verified successfully")
}

func TestProofOfPossession(t *testing.T) {
	signer, err := GenerateKey()
	if err != nil {
		t.Fatalf("Failed to generate key: %v", err)
	}

	validatorAddr := common.HexToAddress("0x1234567890123456789012345678901234567890")
	chainID := big.NewInt(1) // Ethereum mainnet

	// PoP 생성
	pop, err := signer.GenerateProofOfPossession(validatorAddr, chainID)
	if err != nil {
		t.Fatalf("Failed to generate PoP: %v", err)
	}

	// herumi BLS는 압축 형식 (96 bytes)
	if len(pop) != 96 {
		t.Errorf("Expected PoP length 96, got %d", len(pop))
	}

	// PoP 메시지 재생성
	pubKey := signer.PublicKey()
	message := crypto.Keccak256(
		[]byte("BLS_POP"),
		chainID.Bytes(),
		validatorAddr.Bytes(),
		pubKey,
	)

	// PoP 검증
	if !VerifySignature(message, pop, pubKey) {
		t.Error("PoP verification failed")
	}

	t.Logf("PoP verified successfully")
}

func TestInvalidPrivateKey(t *testing.T) {
	tests := []struct {
		name    string
		privKey string
		wantErr bool
	}{
		{
			name:    "invalid hex",
			privKey: "not_hex",
			wantErr: true,
		},
		{
			name:    "wrong length",
			privKey: "0x1234",
			wantErr: true,
		},
		{
			name:    "valid",
			privKey: "0x1234567890abcdef1234567890abcdef1234567890abcdef1234567890abcdef",
			wantErr: false,
		},
	}

	for _, tt := range tests {
		t.Run(tt.name, func(t *testing.T) {
			_, err := NewBLSSigner(tt.privKey)
			if (err != nil) != tt.wantErr {
				t.Errorf("NewBLSSigner() error = %v, wantErr %v", err, tt.wantErr)
			}
		})
	}
}
