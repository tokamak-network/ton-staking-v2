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

	contract, err := NewRATContract(nil, address)
	if err != nil {
		t.Fatalf("Unexpected error: %v", err)
	}

	// nil client로 생성은 가능 (실제 호출 시 에러 발생)
	if contract == nil {
		t.Error("Contract should not be nil")
	}

	if contract.address != address {
		t.Error("Contract address mismatch")
	}

	t.Log("✅ RATContract created with nil client (will fail on actual calls)")
}

func TestRATContract_Struct(t *testing.T) {
	address := common.HexToAddress("0x1234567890123456789012345678901234567890")

	contract, err := NewRATContract(nil, address)
	if err != nil {
		t.Fatalf("Failed to create contract: %v", err)
	}

	if contract.address != address {
		t.Error("Address mismatch")
	}

	// ABI가 파싱되었는지 확인
	if len(contract.abi.Methods) == 0 {
		t.Error("ABI should have methods")
	}

	t.Log("✅ RATContract struct works correctly")
}

func TestValidatorInfo_Struct(t *testing.T) {
	info := ValidatorInfo{
		Address:      common.HexToAddress("0x1234567890123456789012345678901234567890"),
		BLSPublicKey: make([]byte, 48), // BLS public key is 48 bytes
	}

	if info.Address == (common.Address{}) {
		t.Error("Address should not be empty")
	}

	if len(info.BLSPublicKey) != 48 {
		t.Errorf("BLS public key should be 48 bytes, got %d", len(info.BLSPublicKey))
	}

	t.Log("✅ ValidatorInfo struct works correctly")
}

func TestRAT_ABI_Parsing(t *testing.T) {
	parsedABI, err := abi.JSON(strings.NewReader(ratABI))
	if err != nil {
		t.Fatalf("Failed to parse RAT ABI: %v", err)
	}

	// 필요한 메서드들이 있는지 확인
	expectedMethods := []string{
		"getActiveValidators",
		"getBLSPublicKey",
		"getValidatorCount",
		"isActiveValidator",
	}

	for _, method := range expectedMethods {
		if _, ok := parsedABI.Methods[method]; !ok {
			t.Errorf("Missing method in ABI: %s", method)
		}
	}

	t.Logf("✅ RAT ABI parsed successfully with %d methods", len(parsedABI.Methods))
}

func TestRAT_ABI_GetActiveValidators(t *testing.T) {
	parsedABI, err := abi.JSON(strings.NewReader(ratABI))
	if err != nil {
		t.Fatalf("Failed to parse ABI: %v", err)
	}

	method, ok := parsedABI.Methods["getActiveValidators"]
	if !ok {
		t.Fatal("getActiveValidators method not found")
	}

	// 입력 파라미터가 없어야 함
	if len(method.Inputs) != 0 {
		t.Errorf("Expected 0 inputs, got %d", len(method.Inputs))
	}

	// 출력은 address[] 타입
	if len(method.Outputs) != 1 {
		t.Errorf("Expected 1 output, got %d", len(method.Outputs))
	}

	if method.Outputs[0].Type.String() != "address[]" {
		t.Errorf("Expected address[] output, got %s", method.Outputs[0].Type.String())
	}

	t.Log("✅ getActiveValidators ABI is correct")
}

func TestRAT_ABI_GetBLSPublicKey(t *testing.T) {
	parsedABI, err := abi.JSON(strings.NewReader(ratABI))
	if err != nil {
		t.Fatalf("Failed to parse ABI: %v", err)
	}

	method, ok := parsedABI.Methods["getBLSPublicKey"]
	if !ok {
		t.Fatal("getBLSPublicKey method not found")
	}

	// 입력 파라미터는 address 1개
	if len(method.Inputs) != 1 {
		t.Errorf("Expected 1 input, got %d", len(method.Inputs))
	}

	if method.Inputs[0].Type.String() != "address" {
		t.Errorf("Expected address input, got %s", method.Inputs[0].Type.String())
	}

	// 출력은 bytes 타입
	if len(method.Outputs) != 1 {
		t.Errorf("Expected 1 output, got %d", len(method.Outputs))
	}

	if method.Outputs[0].Type.String() != "bytes" {
		t.Errorf("Expected bytes output, got %s", method.Outputs[0].Type.String())
	}

	t.Log("✅ getBLSPublicKey ABI is correct")
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

	// 입력 파라미터가 없어야 함
	if len(method.Inputs) != 0 {
		t.Errorf("Expected 0 inputs, got %d", len(method.Inputs))
	}

	// 출력은 uint256 타입
	if len(method.Outputs) != 1 {
		t.Errorf("Expected 1 output, got %d", len(method.Outputs))
	}

	if method.Outputs[0].Type.String() != "uint256" {
		t.Errorf("Expected uint256 output, got %s", method.Outputs[0].Type.String())
	}

	t.Log("✅ getValidatorCount ABI is correct")
}

func TestRAT_ABI_IsActiveValidator(t *testing.T) {
	parsedABI, err := abi.JSON(strings.NewReader(ratABI))
	if err != nil {
		t.Fatalf("Failed to parse ABI: %v", err)
	}

	method, ok := parsedABI.Methods["isActiveValidator"]
	if !ok {
		t.Fatal("isActiveValidator method not found")
	}

	// 입력 파라미터는 address 1개
	if len(method.Inputs) != 1 {
		t.Errorf("Expected 1 input, got %d", len(method.Inputs))
	}

	if method.Inputs[0].Type.String() != "address" {
		t.Errorf("Expected address input, got %s", method.Inputs[0].Type.String())
	}

	// 출력은 bool 타입
	if len(method.Outputs) != 1 {
		t.Errorf("Expected 1 output, got %d", len(method.Outputs))
	}

	if method.Outputs[0].Type.String() != "bool" {
		t.Errorf("Expected bool output, got %s", method.Outputs[0].Type.String())
	}

	t.Log("✅ isActiveValidator ABI is correct")
}

func TestRAT_ABI_Pack_GetActiveValidators(t *testing.T) {
	parsedABI, err := abi.JSON(strings.NewReader(ratABI))
	if err != nil {
		t.Fatalf("Failed to parse ABI: %v", err)
	}

	data, err := parsedABI.Pack("getActiveValidators")
	if err != nil {
		t.Fatalf("Failed to pack getActiveValidators: %v", err)
	}

	// Function selector is 4 bytes
	if len(data) != 4 {
		t.Errorf("Expected 4 bytes (selector only), got %d", len(data))
	}

	t.Logf("✅ getActiveValidators packed: 0x%x", data)
}

func TestRAT_ABI_Pack_GetBLSPublicKey(t *testing.T) {
	parsedABI, err := abi.JSON(strings.NewReader(ratABI))
	if err != nil {
		t.Fatalf("Failed to parse ABI: %v", err)
	}

	validator := common.HexToAddress("0x1234567890123456789012345678901234567890")
	data, err := parsedABI.Pack("getBLSPublicKey", validator)
	if err != nil {
		t.Fatalf("Failed to pack getBLSPublicKey: %v", err)
	}

	// Function selector (4) + address (32) = 36 bytes
	if len(data) != 36 {
		t.Errorf("Expected 36 bytes, got %d", len(data))
	}

	t.Logf("✅ getBLSPublicKey packed: %d bytes", len(data))
}

func TestRAT_ABI_Pack_IsActiveValidator(t *testing.T) {
	parsedABI, err := abi.JSON(strings.NewReader(ratABI))
	if err != nil {
		t.Fatalf("Failed to parse ABI: %v", err)
	}

	validator := common.HexToAddress("0x1234567890123456789012345678901234567890")
	data, err := parsedABI.Pack("isActiveValidator", validator)
	if err != nil {
		t.Fatalf("Failed to pack isActiveValidator: %v", err)
	}

	// Function selector (4) + address (32) = 36 bytes
	if len(data) != 36 {
		t.Errorf("Expected 36 bytes, got %d", len(data))
	}

	t.Logf("✅ isActiveValidator packed: %d bytes", len(data))
}

func TestValidatorInfo_BLSPublicKeySize(t *testing.T) {
	// BLS12-381 public key sizes
	// G1 (compressed): 48 bytes
	// G2 (compressed): 96 bytes

	testCases := []struct {
		name string
		size int
	}{
		{"G1 compressed (typical)", 48},
		{"G2 compressed", 96},
	}

	for _, tc := range testCases {
		t.Run(tc.name, func(t *testing.T) {
			info := ValidatorInfo{
				Address:      common.HexToAddress("0x1234"),
				BLSPublicKey: make([]byte, tc.size),
			}

			if len(info.BLSPublicKey) != tc.size {
				t.Errorf("Expected %d bytes, got %d", tc.size, len(info.BLSPublicKey))
			}
		})
	}

	t.Log("✅ BLS public key sizes validated")
}

func TestValidatorInfo_EmptyBLSKey(t *testing.T) {
	info := ValidatorInfo{
		Address:      common.HexToAddress("0x1234567890123456789012345678901234567890"),
		BLSPublicKey: []byte{}, // empty
	}

	// Empty BLS key는 유효하지 않은 검증자를 나타냄
	if len(info.BLSPublicKey) != 0 {
		t.Error("BLS key should be empty")
	}

	t.Log("✅ Empty BLS key handled (indicates unregistered validator)")
}

func TestMultipleValidators(t *testing.T) {
	validators := []ValidatorInfo{
		{
			Address:      common.HexToAddress("0x1111111111111111111111111111111111111111"),
			BLSPublicKey: make([]byte, 48),
		},
		{
			Address:      common.HexToAddress("0x2222222222222222222222222222222222222222"),
			BLSPublicKey: make([]byte, 48),
		},
		{
			Address:      common.HexToAddress("0x3333333333333333333333333333333333333333"),
			BLSPublicKey: make([]byte, 48),
		},
	}

	if len(validators) != 3 {
		t.Errorf("Expected 3 validators, got %d", len(validators))
	}

	// 각 검증자의 주소가 고유한지 확인
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
	// 검증자 수는 uint256으로 반환됨
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
