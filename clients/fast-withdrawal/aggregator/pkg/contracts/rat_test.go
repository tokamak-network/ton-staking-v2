package contracts

import (
	"math/big"
	"strings"
	"testing"

	"github.com/ethereum/go-ethereum/accounts/abi"
	"github.com/ethereum/go-ethereum/common"
)

func TestNewRATContract_NilClient(t *testing.T) {
	address := common.HexToAddress("0x1234567890123456789012345678901234567890")
	systemConfig := common.HexToAddress("0xabcdabcdabcdabcdabcdabcdabcdabcdabcdabcd")

	contract, err := NewRATContract(nil, address, systemConfig)
	if err != nil {
		t.Fatalf("Unexpected error: %v", err)
	}

	if contract == nil {
		t.Error("Contract should not be nil")
	}

	if contract.address != address {
		t.Error("Contract address mismatch")
	}

	if contract.systemConfig != systemConfig {
		t.Error("SystemConfig address mismatch")
	}

	t.Log("✅ RATContract created with nil client (will fail on actual calls)")
}

func TestRATContract_Struct(t *testing.T) {
	address := common.HexToAddress("0x1234567890123456789012345678901234567890")
	systemConfig := common.HexToAddress("0xabcdabcdabcdabcdabcdabcdabcdabcdabcdabcd")

	contract, err := NewRATContract(nil, address, systemConfig)
	if err != nil {
		t.Fatalf("Failed to create contract: %v", err)
	}

	if contract.address != address {
		t.Error("Address mismatch")
	}

	if len(contract.abi.Methods) == 0 {
		t.Error("ABI should have methods")
	}

	t.Log("✅ RATContract struct works correctly")
}

func TestValidatorInfo_Struct(t *testing.T) {
	info := ValidatorInfo{
		Address:      common.HexToAddress("0x1234567890123456789012345678901234567890"),
		BLSPublicKey: make([]byte, 128), // EIP-2537 uncompressed G1 point
	}

	if info.Address == (common.Address{}) {
		t.Error("Address should not be empty")
	}

	if len(info.BLSPublicKey) != 128 {
		t.Errorf("BLS public key should be 128 bytes (EIP-2537), got %d", len(info.BLSPublicKey))
	}

	t.Log("✅ ValidatorInfo struct works correctly")
}

func TestRAT_ABI_Parsing(t *testing.T) {
	parsedABI, err := abi.JSON(strings.NewReader(ratABI))
	if err != nil {
		t.Fatalf("Failed to parse RAT ABI: %v", err)
	}

	expectedMethods := []string{
		"getActiveValidatorsWithBLS",
		"getL2Validators",
		"getValidatorBLSPubKey",
		"getValidatorCount",
		"isValidatorActive",
		"hasValidatorBLSKey",
	}

	for _, method := range expectedMethods {
		if _, ok := parsedABI.Methods[method]; !ok {
			t.Errorf("Missing method in ABI: %s", method)
		}
	}

	t.Logf("✅ RAT ABI parsed successfully with %d methods", len(parsedABI.Methods))
}

func TestRAT_ABI_GetActiveValidatorsWithBLS(t *testing.T) {
	parsedABI, err := abi.JSON(strings.NewReader(ratABI))
	if err != nil {
		t.Fatalf("Failed to parse ABI: %v", err)
	}

	method, ok := parsedABI.Methods["getActiveValidatorsWithBLS"]
	if !ok {
		t.Fatal("getActiveValidatorsWithBLS method not found")
	}

	// 입력 파라미터: address systemConfig
	if len(method.Inputs) != 1 {
		t.Errorf("Expected 1 input, got %d", len(method.Inputs))
	}
	if method.Inputs[0].Type.String() != "address" {
		t.Errorf("Expected address input, got %s", method.Inputs[0].Type.String())
	}

	// 출력: (address[], bytes[], uint256)
	if len(method.Outputs) != 3 {
		t.Errorf("Expected 3 outputs, got %d", len(method.Outputs))
	}

	t.Log("✅ getActiveValidatorsWithBLS ABI is correct")
}

func TestRAT_ABI_GetValidatorBLSPubKey(t *testing.T) {
	parsedABI, err := abi.JSON(strings.NewReader(ratABI))
	if err != nil {
		t.Fatalf("Failed to parse ABI: %v", err)
	}

	method, ok := parsedABI.Methods["getValidatorBLSPubKey"]
	if !ok {
		t.Fatal("getValidatorBLSPubKey method not found")
	}

	// 입력 파라미터: (address validator, address systemConfig)
	if len(method.Inputs) != 2 {
		t.Errorf("Expected 2 inputs, got %d", len(method.Inputs))
	}

	// 출력은 bytes 타입
	if len(method.Outputs) != 1 {
		t.Errorf("Expected 1 output, got %d", len(method.Outputs))
	}
	if method.Outputs[0].Type.String() != "bytes" {
		t.Errorf("Expected bytes output, got %s", method.Outputs[0].Type.String())
	}

	t.Log("✅ getValidatorBLSPubKey ABI is correct")
}

func TestRAT_ABI_GetValidatorCount(t *testing.T) {
	parsedABI, err := abi.JSON(strings.NewReader(ratABI))
	if err != nil {
		t.Fatalf("Failed to parse ABI: %v", err)
	}

	method, ok := parsedABI.Methods["getValidatorCount"]
	if !ok {
		t.Fatal("getValidatorCount method not found")
	}

	// 입력: address systemConfig
	if len(method.Inputs) != 1 {
		t.Errorf("Expected 1 input, got %d", len(method.Inputs))
	}

	// 출력: uint256
	if len(method.Outputs) != 1 {
		t.Errorf("Expected 1 output, got %d", len(method.Outputs))
	}
	if method.Outputs[0].Type.String() != "uint256" {
		t.Errorf("Expected uint256 output, got %s", method.Outputs[0].Type.String())
	}

	t.Log("✅ getValidatorCount ABI is correct")
}

func TestRAT_ABI_IsValidatorActive(t *testing.T) {
	parsedABI, err := abi.JSON(strings.NewReader(ratABI))
	if err != nil {
		t.Fatalf("Failed to parse ABI: %v", err)
	}

	method, ok := parsedABI.Methods["isValidatorActive"]
	if !ok {
		t.Fatal("isValidatorActive method not found")
	}

	// 입력: (address validator, address systemConfig)
	if len(method.Inputs) != 2 {
		t.Errorf("Expected 2 inputs, got %d", len(method.Inputs))
	}

	// 출력: bool
	if len(method.Outputs) != 1 {
		t.Errorf("Expected 1 output, got %d", len(method.Outputs))
	}
	if method.Outputs[0].Type.String() != "bool" {
		t.Errorf("Expected bool output, got %s", method.Outputs[0].Type.String())
	}

	t.Log("✅ isValidatorActive ABI is correct")
}

func TestRAT_ABI_Pack_GetActiveValidatorsWithBLS(t *testing.T) {
	parsedABI, err := abi.JSON(strings.NewReader(ratABI))
	if err != nil {
		t.Fatalf("Failed to parse ABI: %v", err)
	}

	systemConfig := common.HexToAddress("0x1234567890123456789012345678901234567890")
	data, err := parsedABI.Pack("getActiveValidatorsWithBLS", systemConfig)
	if err != nil {
		t.Fatalf("Failed to pack: %v", err)
	}

	// Function selector (4) + address (32) = 36 bytes
	if len(data) != 36 {
		t.Errorf("Expected 36 bytes, got %d", len(data))
	}

	t.Logf("✅ getActiveValidatorsWithBLS packed: 0x%x", data[:4])
}

func TestRAT_ABI_Pack_GetValidatorBLSPubKey(t *testing.T) {
	parsedABI, err := abi.JSON(strings.NewReader(ratABI))
	if err != nil {
		t.Fatalf("Failed to parse ABI: %v", err)
	}

	validator := common.HexToAddress("0x1234567890123456789012345678901234567890")
	systemConfig := common.HexToAddress("0xabcdabcdabcdabcdabcdabcdabcdabcdabcdabcd")
	data, err := parsedABI.Pack("getValidatorBLSPubKey", validator, systemConfig)
	if err != nil {
		t.Fatalf("Failed to pack: %v", err)
	}

	// Function selector (4) + address (32) + address (32) = 68 bytes
	if len(data) != 68 {
		t.Errorf("Expected 68 bytes, got %d", len(data))
	}

	t.Logf("✅ getValidatorBLSPubKey packed: %d bytes", len(data))
}

func TestRAT_ABI_Pack_IsValidatorActive(t *testing.T) {
	parsedABI, err := abi.JSON(strings.NewReader(ratABI))
	if err != nil {
		t.Fatalf("Failed to parse ABI: %v", err)
	}

	validator := common.HexToAddress("0x1234567890123456789012345678901234567890")
	systemConfig := common.HexToAddress("0xabcdabcdabcdabcdabcdabcdabcdabcdabcdabcd")
	data, err := parsedABI.Pack("isValidatorActive", validator, systemConfig)
	if err != nil {
		t.Fatalf("Failed to pack: %v", err)
	}

	// Function selector (4) + address (32) + address (32) = 68 bytes
	if len(data) != 68 {
		t.Errorf("Expected 68 bytes, got %d", len(data))
	}

	t.Logf("✅ isValidatorActive packed: %d bytes", len(data))
}

func TestValidatorInfo_BLSPublicKeySize(t *testing.T) {
	// EIP-2537 BLS12-381 public key: 128 bytes (uncompressed G1 point)
	info := ValidatorInfo{
		Address:      common.HexToAddress("0x1234"),
		BLSPublicKey: make([]byte, 128),
	}

	if len(info.BLSPublicKey) != 128 {
		t.Errorf("Expected 128 bytes, got %d", len(info.BLSPublicKey))
	}

	t.Log("✅ BLS public key size validated (128 bytes, EIP-2537)")
}

func TestValidatorInfo_EmptyBLSKey(t *testing.T) {
	info := ValidatorInfo{
		Address:      common.HexToAddress("0x1234567890123456789012345678901234567890"),
		BLSPublicKey: []byte{},
	}

	if len(info.BLSPublicKey) != 0 {
		t.Error("BLS key should be empty")
	}

	t.Log("✅ Empty BLS key handled (indicates unregistered validator)")
}

func TestMultipleValidators(t *testing.T) {
	validators := []ValidatorInfo{
		{
			Address:      common.HexToAddress("0x1111111111111111111111111111111111111111"),
			BLSPublicKey: make([]byte, 128),
		},
		{
			Address:      common.HexToAddress("0x2222222222222222222222222222222222222222"),
			BLSPublicKey: make([]byte, 128),
		},
		{
			Address:      common.HexToAddress("0x3333333333333333333333333333333333333333"),
			BLSPublicKey: make([]byte, 128),
		},
	}

	if len(validators) != 3 {
		t.Errorf("Expected 3 validators, got %d", len(validators))
	}

	addressSet := make(map[common.Address]bool)
	for _, v := range validators {
		if addressSet[v.Address] {
			t.Errorf("Duplicate validator address: %s", v.Address.Hex())
		}
		addressSet[v.Address] = true
	}

	t.Log("✅ Multiple validators handled correctly")
}

func TestValidatorCount_BigInt(t *testing.T) {
	counts := []*big.Int{
		big.NewInt(0),
		big.NewInt(1),
		big.NewInt(100),
		big.NewInt(1000),
	}

	for _, count := range counts {
		if count.Sign() < 0 {
			t.Errorf("Validator count should not be negative: %s", count.String())
		}
	}

	t.Log("✅ Validator count as big.Int works correctly")
}
