package contracts

import (
	"context"
	"fmt"
	"math/big"
	"strings"

	"github.com/ethereum/go-ethereum"
	"github.com/ethereum/go-ethereum/accounts/abi"
	"github.com/ethereum/go-ethereum/common"
	"github.com/ethereum/go-ethereum/ethclient"
)

// RAT ABI (필요한 함수만)
const ratABI = `[
	{
		"inputs": [],
		"name": "getActiveValidators",
		"outputs": [{"internalType": "address[]", "name": "", "type": "address[]"}],
		"stateMutability": "view",
		"type": "function"
	},
	{
		"inputs": [{"internalType": "address", "name": "validator", "type": "address"}],
		"name": "getBLSPublicKey",
		"outputs": [{"internalType": "bytes", "name": "", "type": "bytes"}],
		"stateMutability": "view",
		"type": "function"
	},
	{
		"inputs": [],
		"name": "getValidatorCount",
		"outputs": [{"internalType": "uint256", "name": "", "type": "uint256"}],
		"stateMutability": "view",
		"type": "function"
	},
	{
		"inputs": [{"internalType": "address", "name": "validator", "type": "address"}],
		"name": "isActiveValidator",
		"outputs": [{"internalType": "bool", "name": "", "type": "bool"}],
		"stateMutability": "view",
		"type": "function"
	}
]`

// RATContract RAT 컨트랙트 클라이언트
type RATContract struct {
	client  *ethclient.Client
	address common.Address
	abi     abi.ABI
}

// ValidatorInfo Validator 정보
type ValidatorInfo struct {
	Address      common.Address
	BLSPublicKey []byte
}

// NewRATContract RAT 컨트랙트 클라이언트 생성
func NewRATContract(client *ethclient.Client, address common.Address) (*RATContract, error) {
	parsedABI, err := abi.JSON(strings.NewReader(ratABI))
	if err != nil {
		return nil, fmt.Errorf("failed to parse RAT ABI: %w", err)
	}

	return &RATContract{
		client:  client,
		address: address,
		abi:     parsedABI,
	}, nil
}

// GetActiveValidators 활성 검증자 목록 조회
func (r *RATContract) GetActiveValidators(ctx context.Context) ([]common.Address, error) {
	data, err := r.abi.Pack("getActiveValidators")
	if err != nil {
		return nil, fmt.Errorf("failed to pack getActiveValidators: %w", err)
	}

	msg := ethereum.CallMsg{
		To:   &r.address,
		Data: data,
	}

	result, err := r.client.CallContract(ctx, msg, nil)
	if err != nil {
		return nil, fmt.Errorf("failed to call getActiveValidators: %w", err)
	}

	// Decode result
	var validators []common.Address
	if err := r.abi.UnpackIntoInterface(&validators, "getActiveValidators", result); err != nil {
		return nil, fmt.Errorf("failed to unpack getActiveValidators: %w", err)
	}

	return validators, nil
}

// GetBLSPublicKey 검증자의 BLS 공개키 조회
func (r *RATContract) GetBLSPublicKey(ctx context.Context, validator common.Address) ([]byte, error) {
	data, err := r.abi.Pack("getBLSPublicKey", validator)
	if err != nil {
		return nil, fmt.Errorf("failed to pack getBLSPublicKey: %w", err)
	}

	msg := ethereum.CallMsg{
		To:   &r.address,
		Data: data,
	}

	result, err := r.client.CallContract(ctx, msg, nil)
	if err != nil {
		return nil, fmt.Errorf("failed to call getBLSPublicKey: %w", err)
	}

	// Decode result
	var pubKey []byte
	if err := r.abi.UnpackIntoInterface(&pubKey, "getBLSPublicKey", result); err != nil {
		return nil, fmt.Errorf("failed to unpack getBLSPublicKey: %w", err)
	}

	return pubKey, nil
}

// GetValidatorCount 검증자 수 조회
func (r *RATContract) GetValidatorCount(ctx context.Context) (*big.Int, error) {
	data, err := r.abi.Pack("getValidatorCount")
	if err != nil {
		return nil, fmt.Errorf("failed to pack getValidatorCount: %w", err)
	}

	msg := ethereum.CallMsg{
		To:   &r.address,
		Data: data,
	}

	result, err := r.client.CallContract(ctx, msg, nil)
	if err != nil {
		return nil, fmt.Errorf("failed to call getValidatorCount: %w", err)
	}

	// Decode result
	var count *big.Int
	if err := r.abi.UnpackIntoInterface(&count, "getValidatorCount", result); err != nil {
		return nil, fmt.Errorf("failed to unpack getValidatorCount: %w", err)
	}

	return count, nil
}

// IsActiveValidator 검증자가 활성 상태인지 확인
func (r *RATContract) IsActiveValidator(ctx context.Context, validator common.Address) (bool, error) {
	data, err := r.abi.Pack("isActiveValidator", validator)
	if err != nil {
		return false, fmt.Errorf("failed to pack isActiveValidator: %w", err)
	}

	msg := ethereum.CallMsg{
		To:   &r.address,
		Data: data,
	}

	result, err := r.client.CallContract(ctx, msg, nil)
	if err != nil {
		return false, fmt.Errorf("failed to call isActiveValidator: %w", err)
	}

	// Decode result
	var isActive bool
	if err := r.abi.UnpackIntoInterface(&isActive, "isActiveValidator", result); err != nil {
		return false, fmt.Errorf("failed to unpack isActiveValidator: %w", err)
	}

	return isActive, nil
}

// GetValidatorsWithBLSKeys 모든 검증자와 BLS 공개키 조회
func (r *RATContract) GetValidatorsWithBLSKeys(ctx context.Context) ([]ValidatorInfo, error) {
	validators, err := r.GetActiveValidators(ctx)
	if err != nil {
		return nil, err
	}

	result := make([]ValidatorInfo, 0, len(validators))

	for _, validator := range validators {
		pubKey, err := r.GetBLSPublicKey(ctx, validator)
		if err != nil {
			fmt.Printf("Warning: failed to get BLS key for %s: %v\n", validator.Hex(), err)
			continue
		}

		// BLS 공개키가 등록되어 있는 검증자만 포함
		if len(pubKey) > 0 {
			result = append(result, ValidatorInfo{
				Address:      validator,
				BLSPublicKey: pubKey,
			})
		}
	}

	return result, nil
}
