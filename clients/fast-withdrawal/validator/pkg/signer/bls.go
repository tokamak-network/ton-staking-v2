package signer

import (
	"encoding/hex"
	"fmt"
	"math/big"

	"github.com/ethereum/go-ethereum/common"
	"github.com/ethereum/go-ethereum/crypto"
	bls "github.com/herumi/bls-eth-go-binary/bls"
)

func init() {
	// BLS12-381 초기화
	if err := bls.Init(bls.BLS12_381); err != nil {
		panic(fmt.Sprintf("failed to init BLS: %v", err))
	}
	if err := bls.SetETHmode(bls.EthModeDraft07); err != nil {
		panic(fmt.Sprintf("failed to set ETH mode: %v", err))
	}
}

// BLSSigner BLS12-381 서명 생성
type BLSSigner struct {
	privateKey bls.SecretKey
	publicKey  bls.PublicKey
}

// NewBLSSigner BLS 개인키로 Signer 생성
func NewBLSSigner(privateKeyHex string) (*BLSSigner, error) {
	// "0x" 접두사 제거
	if len(privateKeyHex) >= 2 && privateKeyHex[:2] == "0x" {
		privateKeyHex = privateKeyHex[2:]
	}

	privKeyBytes, err := hex.DecodeString(privateKeyHex)
	if err != nil {
		return nil, fmt.Errorf("invalid private key hex: %w", err)
	}

	// BLS secret key는 32 bytes
	if len(privKeyBytes) != 32 {
		return nil, fmt.Errorf("private key must be 32 bytes, got %d", len(privKeyBytes))
	}

	// SecretKey 생성
	// keygen(gnark-crypto)이 little-endian hex로 출력하므로
	// EthModeDraft07에서 Deserialize가 big-endian을 기대할 수 있음.
	// 양쪽 엔디안 모두 시도하여 호환성 보장.
	var privKey bls.SecretKey

	// 방법 1: 원본 바이트로 Deserialize (little-endian)
	if err := privKey.Deserialize(privKeyBytes); err != nil {
		// 방법 2: 바이트 순서 반전 후 시도 (big-endian → little-endian)
		reversed := make([]byte, 32)
		for i := range 32 {
			reversed[i] = privKeyBytes[31-i]
		}
		if err := privKey.Deserialize(reversed); err != nil {
			return nil, fmt.Errorf("failed to deserialize secret key (tried both endians): %w", err)
		}
	}

	// PublicKey 생성 (G1)
	pubKey := *privKey.GetPublicKey()

	return &BLSSigner{
		privateKey: privKey,
		publicKey:  pubKey,
	}, nil
}

// GenerateKey 새로운 BLS 키 쌍 생성
func GenerateKey() (*BLSSigner, error) {
	var privKey bls.SecretKey
	privKey.SetByCSPRNG()

	pubKey := *privKey.GetPublicKey()

	return &BLSSigner{
		privateKey: privKey,
		publicKey:  pubKey,
	}, nil
}

// Sign BLS 서명 생성 (G2 signature)
// message: 서명할 메시지 (32 bytes hash)
// returns: 256 bytes uncompressed G2 signature
func (bs *BLSSigner) Sign(message []byte) ([]byte, error) {
	// BLS 서명 생성
	sig := bs.privateKey.SignByte(message)

	// Serialize to uncompressed (256 bytes for EIP-2537)
	return sig.Serialize(), nil
}

// PublicKey BLS 공개키 반환 (G1, 128 bytes uncompressed)
func (bs *BLSSigner) PublicKey() []byte {
	return bs.publicKey.Serialize()
}

// PublicKeyCompressed 압축된 공개키 반환 (48 bytes)
func (bs *BLSSigner) PublicKeyCompressed() []byte {
	// herumi BLS는 compress 지원
	bytes := bs.publicKey.Serialize()
	// 앞 48 bytes만 반환 (압축 형식)
	if len(bytes) >= 48 {
		return bytes[:48]
	}
	return bytes
}

// PrivateKeyHex 개인키를 hex string으로 반환
func (bs *BLSSigner) PrivateKeyHex() string {
	return hex.EncodeToString(bs.privateKey.Serialize())
}

// GenerateProofOfPossession PoP 서명 생성 (Rogue key attack 방지)
// validatorAddr: 검증자 Ethereum 주소
// chainID: L1 체인 ID
func (bs *BLSSigner) GenerateProofOfPossession(
	validatorAddr common.Address,
	chainID *big.Int,
) ([]byte, error) {
	// PoP 메시지 생성 (Solidity와 동일한 방식)
	// message = keccak256("BLS_POP", chainID, validatorAddr, publicKey)
	pubKey := bs.PublicKey()

	message := crypto.Keccak256(
		[]byte("BLS_POP"),
		chainID.Bytes(),
		validatorAddr.Bytes(),
		pubKey,
	)

	// BLS 서명
	return bs.Sign(message)
}

// VerifySignature 서명 검증 (테스트용)
func VerifySignature(message []byte, signature []byte, publicKey []byte) bool {
	// PublicKey 파싱
	var pubKey bls.PublicKey
	if err := pubKey.Deserialize(publicKey); err != nil {
		return false
	}

	// Signature 파싱
	var sig bls.Sign
	if err := sig.Deserialize(signature); err != nil {
		return false
	}

	// Verify
	return sig.VerifyByte(&pubKey, message)
}
