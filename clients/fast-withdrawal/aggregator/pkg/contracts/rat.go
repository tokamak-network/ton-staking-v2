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

// RAT ABI (실제 Solidity 컨트랙트와 일치)
const ratABI = `[
	{
		"inputs": [{"internalType": "address", "name": "systemConfig", "type": "address"}],
		"name": "getActiveValidatorsWithBLS",
		"outputs": [
			{"internalType": "address[]", "name": "validators", "type": "address[]"},
			{"internalType": "bytes[]", "name": "blsKeys", "type": "bytes[]"},
			{"internalType": "uint256", "name": "validBLSCount", "type": "uint256"}
		],
		"stateMutability": "view",
		"type": "function"
	},
	{
		"inputs": [{"internalType": "address", "name": "systemConfig", "type": "address"}],
		"name": "getL2Validators",
		"outputs": [{"internalType": "address[]", "name": "validators", "type": "address[]"}],
		"stateMutability": "view",
		"type": "function"
	},
	{
		"inputs": [
			{"internalType": "address", "name": "validator", "type": "address"},
			{"internalType": "address", "name": "systemConfig", "type": "address"}
		],
		"name": "getValidatorBLSPubKey",
		"outputs": [{"internalType": "bytes", "name": "", "type": "bytes"}],
		"stateMutability": "view",
		"type": "function"
	},
	{
		"inputs": [{"internalType": "address", "name": "systemConfig", "type": "address"}],
		"name": "getValidatorCount",
		"outputs": [{"internalType": "uint256", "name": "", "type": "uint256"}],
		"stateMutability": "view",
		"type": "function"
	},
	{
		"inputs": [
			{"internalType": "address", "name": "validator", "type": "address"},
			{"internalType": "address", "name": "systemConfig", "type": "address"}
		],
		"name": "isValidatorActive",
		"outputs": [{"internalType": "bool", "name": "", "type": "bool"}],
		"stateMutability": "view",
		"type": "function"
	},
	{
		"inputs": [
			{"internalType": "address", "name": "validator", "type": "address"},
			{"internalType": "address", "name": "systemConfig", "type": "address"}
		],
		"name": "hasValidatorBLSKey",
		"outputs": [{"internalType": "bool", "name": "", "type": "bool"}],
		"stateMutability": "view",
		"type": "function"
	}
]`

// RATContract RAT 컨트랙트 클라이언트
type RATContract struct {
	client       *ethclient.Client
	address      common.Address
	systemConfig common.Address
	abi          abi.ABI
}

// ValidatorInfo Validator 정보
type ValidatorInfo struct {
	Address      common.Address
	BLSPublicKey []byte
}

// NewRATContract RAT 컨트랙트 클라이언트 생성
func NewRATContract(client *ethclient.Client, address common.Address, systemConfig common.Address) (*RATContract, error) {
	parsedABI, err := abi.JSON(strings.NewReader(ratABI))
	if err != nil {
		return nil, fmt.Errorf("failed to parse RAT ABI: %w", err)
	}

	return &RATContract{
		client:       client,
		address:      address,
		systemConfig: systemConfig,
		abi:          parsedABI,
	}, nil
}

// GetActiveValidatorsWithBLS 활성 검증자 목록과 BLS 공개키 일괄 조회
func (r *RATContract) GetActiveValidatorsWithBLS(ctx context.Context) ([]ValidatorInfo, error) {
	data, err := r.abi.Pack("getActiveValidatorsWithBLS", r.systemConfig)
	if err != nil {
		return nil, fmt.Errorf("failed to pack getActiveValidatorsWithBLS: %w", err)
	}

	msg := ethereum.CallMsg{
		To:   &r.address,
		Data: data,
	}

	result, err := r.client.CallContract(ctx, msg, nil)
	if err != nil {
		return nil, fmt.Errorf("failed to call getActiveValidatorsWithBLS: %w", err)
	}

	// Decode result: (address[] validators, bytes[] blsKeys, uint256 validBLSCount)
	outputs, err := r.abi.Methods["getActiveValidatorsWithBLS"].Outputs.Unpack(result)
	if err != nil {
		return nil, fmt.Errorf("failed to unpack getActiveValidatorsWithBLS: %w", err)
	}

	validators := outputs[0].([]common.Address)
	blsKeys := outputs[1].([][]byte)

	// BLS 공개키가 등록된 검증자만 포함 (128 bytes)
	validInfos := make([]ValidatorInfo, 0, len(validators))
	for i, v := range validators {
		if len(blsKeys[i]) == 128 {
			validInfos = append(validInfos, ValidatorInfo{
				Address:      v,
				BLSPublicKey: blsKeys[i],
			})
		}
	}

	return validInfos, nil
}

// GetL2Validators 모든 검증자 주소 목록 조회
func (r *RATContract) GetL2Validators(ctx context.Context) ([]common.Address, error) {
	data, err := r.abi.Pack("getL2Validators", r.systemConfig)
	if err != nil {
		return nil, fmt.Errorf("failed to pack getL2Validators: %w", err)
	}

	msg := ethereum.CallMsg{
		To:   &r.address,
		Data: data,
	}

	result, err := r.client.CallContract(ctx, msg, nil)
	if err != nil {
		return nil, fmt.Errorf("failed to call getL2Validators: %w", err)
	}

	outputs, err := r.abi.Methods["getL2Validators"].Outputs.Unpack(result)
	if err != nil {
		return nil, fmt.Errorf("failed to unpack getL2Validators: %w", err)
	}

	return outputs[0].([]common.Address), nil
}

// GetValidatorBLSPubKey 검증자의 BLS 공개키 조회
func (r *RATContract) GetValidatorBLSPubKey(ctx context.Context, validator common.Address) ([]byte, error) {
	data, err := r.abi.Pack("getValidatorBLSPubKey", validator, r.systemConfig)
	if err != nil {
		return nil, fmt.Errorf("failed to pack getValidatorBLSPubKey: %w", err)
	}

	msg := ethereum.CallMsg{
		To:   &r.address,
		Data: data,
	}

	result, err := r.client.CallContract(ctx, msg, nil)
	if err != nil {
		return nil, fmt.Errorf("failed to call getValidatorBLSPubKey: %w", err)
	}

	outputs, err := r.abi.Methods["getValidatorBLSPubKey"].Outputs.Unpack(result)
	if err != nil {
		return nil, fmt.Errorf("failed to unpack getValidatorBLSPubKey: %w", err)
	}

	return outputs[0].([]byte), nil
}

// GetValidatorCount 검증자 수 조회
func (r *RATContract) GetValidatorCount(ctx context.Context) (*big.Int, error) {
	data, err := r.abi.Pack("getValidatorCount", r.systemConfig)
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

	outputs, err := r.abi.Methods["getValidatorCount"].Outputs.Unpack(result)
	if err != nil {
		return nil, fmt.Errorf("failed to unpack getValidatorCount: %w", err)
	}

	return outputs[0].(*big.Int), nil
}

// IsValidatorActive 검증자가 활성 상태인지 확인
func (r *RATContract) IsValidatorActive(ctx context.Context, validator common.Address) (bool, error) {
	data, err := r.abi.Pack("isValidatorActive", validator, r.systemConfig)
	if err != nil {
		return false, fmt.Errorf("failed to pack isValidatorActive: %w", err)
	}

	msg := ethereum.CallMsg{
		To:   &r.address,
		Data: data,
	}

	result, err := r.client.CallContract(ctx, msg, nil)
	if err != nil {
		return false, fmt.Errorf("failed to call isValidatorActive: %w", err)
	}

	outputs, err := r.abi.Methods["isValidatorActive"].Outputs.Unpack(result)
	if err != nil {
		return false, fmt.Errorf("failed to unpack isValidatorActive: %w", err)
	}

	return outputs[0].(bool), nil
}
