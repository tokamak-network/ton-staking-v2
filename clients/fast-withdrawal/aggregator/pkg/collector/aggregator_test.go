package collector

import (
	"math/big"
	"testing"
	"time"

	"github.com/ethereum/go-ethereum/common"
	"github.com/ethereum/go-ethereum/crypto"
	bls "github.com/herumi/bls-eth-go-binary/bls"
	"github.com/tokamak-network/ton-staking-v2/clients/fast-withdrawal/aggregator/pkg/types"
)

// 테스트용 BLS 키쌍과 서명 생성 헬퍼
type testKeyPair struct {
	SecretKey *bls.SecretKey
	PublicKey *bls.PublicKey
}

func generateTestKeyPairs(count int) []testKeyPair {
	pairs := make([]testKeyPair, count)
	for i := 0; i < count; i++ {
		var sk bls.SecretKey
		sk.SetByCSPRNG()
		pk := sk.GetPublicKey()
		pairs[i] = testKeyPair{
			SecretKey: &sk,
			PublicKey: pk,
		}
	}
	return pairs
}

func signMessage(sk *bls.SecretKey, message []byte) []byte {
	sig := sk.SignByte(message)
	return sig.Serialize()
}

func TestNewBLSAggregator(t *testing.T) {
	agg := NewBLSAggregator()
	if agg == nil {
		t.Fatal("Aggregator is nil")
	}
	t.Log("✅ BLSAggregator created successfully")
}

func TestAggregateSignatures_Success(t *testing.T) {
	agg := NewBLSAggregator()

	// 3개의 검증자 키 생성
	keyPairs := generateTestKeyPairs(3)

	validators := []common.Address{
		common.HexToAddress("0x1111111111111111111111111111111111111111"),
		common.HexToAddress("0x2222222222222222222222222222222222222222"),
		common.HexToAddress("0x3333333333333333333333333333333333333333"),
	}

	// 요청 생성
	testReq := &types.SignatureRequest{
		RequestID: [32]byte{1, 2, 3},
		User:      common.HexToAddress("0x1234567890123456789012345678901234567890"),
		Amount:    big.NewInt(1000000),
		ChainID:   big.NewInt(1),
		Deadline:  uint64(time.Now().Add(10 * time.Minute).Unix()),
	}

	// 서명 메시지 생성
	message := crypto.Keccak256(
		[]byte("TOKAMAK_FAST_WITHDRAWAL"),
		testReq.RequestID[:],
		testReq.User.Bytes(),
		common.LeftPadBytes(testReq.Amount.Bytes(), 32),
		common.LeftPadBytes(testReq.ChainID.Bytes(), 32),
	)

	// 서명 수집
	signatures := make(map[common.Address]*types.SignatureResponse)
	for i, validator := range validators {
		sig := signMessage(keyPairs[i].SecretKey, message)
		signatures[validator] = &types.SignatureResponse{
			RequestID: testReq.RequestID,
			Validator: validator,
			Signature: sig,
			PublicKey: keyPairs[i].PublicKey.Serialize(),
			Timestamp: uint64(time.Now().Unix()),
		}
	}

	// RequestState 생성
	state := &types.RequestState{
		Request:       testReq,
		Signatures:    signatures,
		ValidatorSet:  validators,
		RequiredCount: 3,
		ReceivedCount: 3,
		Completed:     true,
	}

	// 서명 집약
	aggregatedSig, bitmap, err := agg.AggregateSignatures(state)
	if err != nil {
		t.Fatalf("Failed to aggregate signatures: %v", err)
	}

	// 결과 검증
	if len(aggregatedSig) != 96 {
		t.Errorf("Unexpected signature length: %d (expected 96)", len(aggregatedSig))
	}

	// 비트맵 검증 (3개 비트 모두 1)
	expectedBitmap := big.NewInt(7) // 0b111
	if bitmap.Cmp(expectedBitmap) != 0 {
		t.Errorf("Unexpected bitmap: %s (expected 111)", bitmap.Text(2))
	}

	t.Logf("✅ Signatures aggregated successfully")
	t.Logf("   Aggregated signature length: %d bytes", len(aggregatedSig))
	t.Logf("   Bitmap: %s", bitmap.Text(2))
}

func TestAggregateSignatures_NotUnanimous(t *testing.T) {
	agg := NewBLSAggregator()

	validators := []common.Address{
		common.HexToAddress("0x1111111111111111111111111111111111111111"),
		common.HexToAddress("0x2222222222222222222222222222222222222222"),
		common.HexToAddress("0x3333333333333333333333333333333333333333"),
	}

	// 불완전한 서명 (2/3)
	state := &types.RequestState{
		Signatures:    make(map[common.Address]*types.SignatureResponse),
		ValidatorSet:  validators,
		RequiredCount: 3,
		ReceivedCount: 2,
		Completed:     false,
	}

	_, _, err := agg.AggregateSignatures(state)
	if err == nil {
		t.Error("Expected error for non-unanimous signatures")
	}

	t.Log("✅ Non-unanimous signatures correctly rejected")
}

func TestAggregateSignatures_NoSignatures(t *testing.T) {
	agg := NewBLSAggregator()

	state := &types.RequestState{
		Signatures:    make(map[common.Address]*types.SignatureResponse),
		ValidatorSet:  []common.Address{},
		RequiredCount: 0,
		ReceivedCount: 0,
		Completed:     true,
	}

	_, _, err := agg.AggregateSignatures(state)
	if err == nil {
		t.Error("Expected error for empty signatures")
	}

	t.Log("✅ Empty signatures correctly rejected")
}

func TestVerifyAggregatedSignature(t *testing.T) {
	agg := NewBLSAggregator()

	// 3개의 검증자 키 생성
	keyPairs := generateTestKeyPairs(3)

	message := []byte("test message for aggregation")

	// 각 검증자가 서명
	var signatures []*bls.Sign
	publicKeys := make([][]byte, len(keyPairs))

	for i, kp := range keyPairs {
		sig := kp.SecretKey.SignByte(message)
		signatures = append(signatures, sig)
		publicKeys[i] = kp.PublicKey.Serialize()
	}

	// 서명 집약
	var aggregatedSig bls.Sign
	aggregatedSig.Add(signatures[0])
	for i := 1; i < len(signatures); i++ {
		aggregatedSig.Add(signatures[i])
	}

	// 검증
	valid := agg.VerifyAggregatedSignature(message, aggregatedSig.Serialize(), publicKeys)
	if !valid {
		t.Error("Aggregated signature verification failed")
	}

	t.Log("✅ Aggregated signature verified successfully")
}

func TestVerifyAggregatedSignature_WrongMessage(t *testing.T) {
	agg := NewBLSAggregator()

	keyPairs := generateTestKeyPairs(2)
	originalMessage := []byte("original message")
	wrongMessage := []byte("wrong message")

	// 원본 메시지로 서명
	var signatures []*bls.Sign
	publicKeys := make([][]byte, len(keyPairs))

	for i, kp := range keyPairs {
		sig := kp.SecretKey.SignByte(originalMessage)
		signatures = append(signatures, sig)
		publicKeys[i] = kp.PublicKey.Serialize()
	}

	var aggregatedSig bls.Sign
	aggregatedSig.Add(signatures[0])
	for i := 1; i < len(signatures); i++ {
		aggregatedSig.Add(signatures[i])
	}

	// 잘못된 메시지로 검증
	valid := agg.VerifyAggregatedSignature(wrongMessage, aggregatedSig.Serialize(), publicKeys)
	if valid {
		t.Error("Should not verify with wrong message")
	}

	t.Log("✅ Wrong message correctly rejected")
}

func TestVerifyAggregatedSignature_EmptyPublicKeys(t *testing.T) {
	agg := NewBLSAggregator()

	valid := agg.VerifyAggregatedSignature([]byte("message"), []byte("signature"), nil)
	if valid {
		t.Error("Should not verify with empty public keys")
	}

	t.Log("✅ Empty public keys correctly rejected")
}

func TestBitmapWith64PlusValidators(t *testing.T) {
	agg := NewBLSAggregator()

	// 100개의 검증자로 테스트
	validatorCount := 100
	keyPairs := generateTestKeyPairs(validatorCount)

	validators := make([]common.Address, validatorCount)
	for i := 0; i < validatorCount; i++ {
		validators[i] = common.BigToAddress(big.NewInt(int64(i + 1)))
	}

	testReq := &types.SignatureRequest{
		RequestID: [32]byte{1, 2, 3},
		User:      common.HexToAddress("0x1234567890123456789012345678901234567890"),
		Amount:    big.NewInt(1000000),
		ChainID:   big.NewInt(1),
		Deadline:  uint64(time.Now().Add(10 * time.Minute).Unix()),
	}

	message := crypto.Keccak256(
		[]byte("TOKAMAK_FAST_WITHDRAWAL"),
		testReq.RequestID[:],
		testReq.User.Bytes(),
		common.LeftPadBytes(testReq.Amount.Bytes(), 32),
		common.LeftPadBytes(testReq.ChainID.Bytes(), 32),
	)

	signatures := make(map[common.Address]*types.SignatureResponse)
	for i, validator := range validators {
		sig := signMessage(keyPairs[i].SecretKey, message)
		signatures[validator] = &types.SignatureResponse{
			RequestID: testReq.RequestID,
			Validator: validator,
			Signature: sig,
			PublicKey: keyPairs[i].PublicKey.Serialize(),
			Timestamp: uint64(time.Now().Unix()),
		}
	}

	state := &types.RequestState{
		Request:       testReq,
		Signatures:    signatures,
		ValidatorSet:  validators,
		RequiredCount: validatorCount,
		ReceivedCount: validatorCount,
		Completed:     true,
	}

	_, bitmap, err := agg.AggregateSignatures(state)
	if err != nil {
		t.Fatalf("Failed to aggregate 100 signatures: %v", err)
	}

	// 비트맵에 100개의 비트가 모두 1인지 확인
	expectedBitmap := new(big.Int)
	for i := 0; i < validatorCount; i++ {
		expectedBitmap.SetBit(expectedBitmap, i, 1)
	}

	if bitmap.Cmp(expectedBitmap) != 0 {
		t.Errorf("Bitmap mismatch for 100 validators")
	}

	t.Logf("✅ 100 validators aggregated successfully")
	t.Logf("   Bitmap bit length: %d", bitmap.BitLen())
}
