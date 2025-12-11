// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "forge-std/Test.sol";

// 각 컨트랙트를 개별 import하여 error 충돌 방지
import {SeigManagerV1_4} from "../../src/stake/managers/SeigManagerV1_4.sol";
import {DepositManagerV1_2} from "../../src/stake/managers/DepositManagerV1_2.sol";
import {Layer2ManagerV1_2} from "../../src/layer2/Layer2ManagerV1_2.sol";
import {L1BridgeRegistryV1_2} from "../../src/layer2/L1BridgeRegistryV1_2.sol";

/// @title E2EMainnetForkTest
/// @notice Ethereum Mainnet Fork 기반 E2E 테스트
/// @dev 기존 메인넷 컨트랙트 fork + 신규 V3 컨트랙트 배포 + 프록시 업그레이드

interface IProxy {
    function upgradeTo(address newImplementation) external;
    function setImplementation(address newImplementation) external;
    function implementation() external view returns (address);
    function setProxyPause(bool _pause) external;
}

interface ITON {
    function totalSupply() external view returns (uint256);
    function balanceOf(address account) external view returns (uint256);
    function approve(address spender, uint256 amount) external returns (bool);
    function transfer(address to, uint256 amount) external returns (bool);
}

interface IWTON {
    function totalSupply() external view returns (uint256);
    function balanceOf(address account) external view returns (uint256);
    function approve(address spender, uint256 amount) external returns (bool);
    function swapFromTON(uint256 tonAmount) external returns (bool);
    function swapToTON(uint256 wtonAmount) external returns (bool);
}

interface ISeigManagerProxy {
    function upgradeTo(address newImplementation) external;
    function setImplementation(address newImplementation) external;
    function implementation() external view returns (address);
}

interface IDepositManagerProxy {
    function deposit(address layer2, uint256 amount) external returns (bool);
    function requestWithdrawal(address layer2, uint256 amount) external returns (bool);
}

interface ILayer2Registry {
    function numLayer2s() external view returns (uint256);
    function layer2ByIndex(uint256 index) external view returns (address);
}

interface ILayer2 {
    function operator() external view returns (address);
}

/// @notice ValidatorPool 인터페이스 (import 충돌 방지)
interface IValidatorPoolV1 {
    function validatorCount() external view returns (uint256);
    function totalDeposits() external view returns (uint256);
    function registerValidator(address systemConfig) external;
    function getValidatorInfo(address systemConfig) external view returns (
        uint256 deposit,
        uint256 rewardDebt,
        uint256 registeredAt,
        bool isActive
    );
}

/// @notice RAT 인터페이스 (import 충돌 방지)
interface IRAT {
    function currentTestId() external view returns (uint256);
    function createTest(address[] calldata validators) external returns (uint256);
    function respondToTest(uint256 testId, bool response) external;
}

contract E2EMainnetForkTest is Test {
    // ==========================================
    // Mainnet Contract Addresses
    // ==========================================

    // TON & WTON
    address constant TON = 0x2be5e8c109e2197D077D13A82dAead6a9b3433C5;
    address constant WTON = 0xc4A11aaf6ea915Ed7Ac194161d2fC9384F15bff2;

    // Proxies (업그레이드 대상)
    address constant SEIG_MANAGER_PROXY = 0x0b55a0f463b6DEFb81c6063973763951712D0E5F;
    address constant DEPOSIT_MANAGER_PROXY = 0x0b58ca72b12F01FC05F8f252e226f3E2089BD00E;
    address constant LAYER2_MANAGER_PROXY = 0xD6Bf6B2b7553c8064Ba763AD6989829060FdFC1D;
    address constant L1_BRIDGE_REGISTRY_PROXY = 0x39d43281A4A5e922AB0DCf89825D73273D8C5BA4;
    address constant LAYER2_REGISTRY_PROXY = 0x7846c2248A7B4dE77E9C2Bae7FBB93bfC286837B;

    // 현재 구현체
    address constant SEIG_MANAGER_V1_3 = 0xce18C6F84F10881eA47A43AF7311A29bb116F628;

    // Layer2s
    address constant TOKAMAK1 = 0xf3B17FDB808c7d0Df9ACd24dA34700ce069007DF;
    address constant DXM_CORP = 0x44e3605d0ed58FD125E9C47D1bf25a4406c13b57;
    address constant DSRV = 0x2B67D8D4E61b68744885E243EfAF988f1Fc66E2D;

    // ==========================================
    // New V3 Contracts (배포할 것들)
    // ==========================================
    SeigManagerV1_4 public seigManagerV1_4;
    DepositManagerV1_2 public depositManagerV1_2;
    Layer2ManagerV1_2 public layer2ManagerV1_2;
    L1BridgeRegistryV1_2 public l1BridgeRegistryV1_2;

    // ==========================================
    // Test State
    // ==========================================
    address public owner;
    address public testUser;
    uint256 constant RAY = 1e27;

    function setUp() public {
        // Mainnet Fork (RPC URL 필요)
        // vm.createSelectFork(vm.envString("MAINNET_RPC_URL"));

        // 또는 특정 블록에서 fork
        // vm.createSelectFork(vm.envString("MAINNET_RPC_URL"), 18500000);

        owner = address(this);
        testUser = address(0x9999);

        // 테스트용 ETH 지급
        vm.deal(owner, 100 ether);
        vm.deal(testUser, 100 ether);
    }

    // ==========================================
    // Fork 없이 로컬 테스트 (Mock 기반)
    // ==========================================

    /// @notice V3 컨트랙트 배포 테스트
    function test_deployV3Contracts() public {
        // SeigManagerV1_4 배포
        seigManagerV1_4 = new SeigManagerV1_4();
        assertTrue(address(seigManagerV1_4) != address(0), "SeigManagerV1_4 deployed");

        // DepositManagerV1_2 배포
        depositManagerV1_2 = new DepositManagerV1_2();
        assertTrue(address(depositManagerV1_2) != address(0), "DepositManagerV1_2 deployed");

        // Layer2ManagerV1_2 배포
        layer2ManagerV1_2 = new Layer2ManagerV1_2();
        assertTrue(address(layer2ManagerV1_2) != address(0), "Layer2ManagerV1_2 deployed");

        // L1BridgeRegistryV1_2 배포
        l1BridgeRegistryV1_2 = new L1BridgeRegistryV1_2();
        assertTrue(address(l1BridgeRegistryV1_2) != address(0), "L1BridgeRegistryV1_2 deployed");
    }

    /// @notice V3 파라미터 설정 테스트
    function test_v3ParameterConfiguration() public {
        seigManagerV1_4 = new SeigManagerV1_4();

        // V3 파라미터 확인 (초기값)
        assertEq(seigManagerV1_4.daoDistributionRatio(), 0, "Initial d should be 0");
        assertEq(seigManagerV1_4.minStakingRatio(), 0, "Initial theta should be 0");
        assertEq(seigManagerV1_4.validatorDistributionRatio(), 0, "Initial alpha should be 0");
        assertEq(seigManagerV1_4.halfSaturationPoint(), 0, "Initial k should be 0");
    }
}

/// @title E2EMainnetForkLiveTest
/// @notice 실제 Mainnet Fork 테스트 (RPC URL 필요)
/// @dev forge test --match-contract E2EMainnetForkLiveTest --fork-url $MAINNET_RPC_URL
contract E2EMainnetForkLiveTest is Test {
    // Mainnet Addresses
    address constant TON = 0x2be5e8c109e2197D077D13A82dAead6a9b3433C5;
    address constant WTON = 0xc4A11aaf6ea915Ed7Ac194161d2fC9384F15bff2;
    address constant SEIG_MANAGER_PROXY = 0x0b55a0f463b6DEFb81c6063973763951712D0E5F;
    address constant DEPOSIT_MANAGER_PROXY = 0x0b58ca72b12F01FC05F8f252e226f3E2089BD00E;
    address constant LAYER2_MANAGER_PROXY = 0xD6Bf6B2b7553c8064Ba763AD6989829060FdFC1D;
    address constant L1_BRIDGE_REGISTRY_PROXY = 0x39d43281A4A5e922AB0DCf89825D73273D8C5BA4;
    address constant LAYER2_REGISTRY = 0x7846c2248A7B4dE77E9C2Bae7FBB93bfC286837B;

    address constant TOKAMAK1 = 0xf3B17FDB808c7d0Df9ACd24dA34700ce069007DF;

    // New V3 implementations
    SeigManagerV1_4 public newSeigManager;
    DepositManagerV1_2 public newDepositManager;
    Layer2ManagerV1_2 public newLayer2Manager;
    L1BridgeRegistryV1_2 public newL1BridgeRegistry;

    // Proxy owner (impersonate)
    address public proxyOwner;

    uint256 constant RAY = 1e27;

    modifier onlyFork() {
        // Fork 환경에서만 실행
        if (block.chainid != 1) {
            return;
        }
        _;
    }

    function setUp() public onlyFork {
        // Proxy owner 찾기 (실제 메인넷에서는 DAO 또는 멀티시그)
        // 테스트에서는 impersonate
    }

    /// @notice 현재 메인넷 상태 확인
    function test_checkCurrentMainnetState() public onlyFork {
        // TON 총 공급량
        uint256 tonSupply = ITON(TON).totalSupply();
        emit log_named_uint("TON Total Supply", tonSupply);
        assertTrue(tonSupply > 0, "TON supply should be > 0");

        // WTON 총 공급량
        uint256 wtonSupply = IWTON(WTON).totalSupply();
        emit log_named_uint("WTON Total Supply", wtonSupply);
        assertTrue(wtonSupply > 0, "WTON supply should be > 0");

        // Layer2 수
        uint256 numLayer2s = ILayer2Registry(LAYER2_REGISTRY).numLayer2s();
        emit log_named_uint("Number of Layer2s", numLayer2s);
        assertTrue(numLayer2s > 0, "Should have Layer2s");
    }

    /// @notice V3 컨트랙트 배포
    function test_deployV3Implementations() public onlyFork {
        // 1. SeigManagerV1_4 배포
        newSeigManager = new SeigManagerV1_4();
        emit log_named_address("SeigManagerV1_4 deployed at", address(newSeigManager));

        // 2. DepositManagerV1_2 배포
        newDepositManager = new DepositManagerV1_2();
        emit log_named_address("DepositManagerV1_2 deployed at", address(newDepositManager));

        // 3. Layer2ManagerV1_2 배포
        newLayer2Manager = new Layer2ManagerV1_2();
        emit log_named_address("Layer2ManagerV1_2 deployed at", address(newLayer2Manager));

        // 4. L1BridgeRegistryV1_2 배포
        newL1BridgeRegistry = new L1BridgeRegistryV1_2();
        emit log_named_address("L1BridgeRegistryV1_2 deployed at", address(newL1BridgeRegistry));

        assertTrue(address(newSeigManager) != address(0));
        assertTrue(address(newDepositManager) != address(0));
        assertTrue(address(newLayer2Manager) != address(0));
        assertTrue(address(newL1BridgeRegistry) != address(0));
    }

    /// @notice 프록시 업그레이드 테스트
    function test_upgradeSeigManagerProxy() public onlyFork {
        // 1. 새 구현체 배포
        newSeigManager = new SeigManagerV1_4();

        // 2. 현재 구현체 확인
        address currentImpl = ISeigManagerProxy(SEIG_MANAGER_PROXY).implementation();
        emit log_named_address("Current implementation", currentImpl);

        // 3. 프록시 owner impersonate (실제로는 DAO vote 필요)
        // 주의: 실제 owner 주소를 찾아야 함
        // vm.prank(proxyOwner);
        // ISeigManagerProxy(SEIG_MANAGER_PROXY).upgradeTo(address(newSeigManager));

        // 4. 업그레이드 후 확인
        // address newImpl = ISeigManagerProxy(SEIG_MANAGER_PROXY).implementation();
        // assertEq(newImpl, address(newSeigManager), "Implementation should be upgraded");
    }

    /// @notice V3 마이그레이션 테스트
    function test_v3Migration() public onlyFork {
        // 1. 새 구현체 배포 및 업그레이드 (위 테스트 참조)

        // 2. V3 파라미터 설정
        // SeigManagerV1_4(SEIG_MANAGER_PROXY).setDaoDistributionRatio(0.1e27);  // d = 10%
        // SeigManagerV1_4(SEIG_MANAGER_PROXY).setMinStakingRatio(0.1e27);       // θ = 10%
        // SeigManagerV1_4(SEIG_MANAGER_PROXY).setValidatorDistributionRatio(0.2e27); // α = 20%
        // SeigManagerV1_4(SEIG_MANAGER_PROXY).setHalfSaturationPoint(1000e27); // k = 1000

        // 3. ValidatorPool 설정
        // SeigManagerV1_4(SEIG_MANAGER_PROXY).setValidatorPool(address(validatorPool));

        // 4. V3 마이그레이션 실행
        // SeigManagerV1_4(SEIG_MANAGER_PROXY).migrateToV3();

        // 5. 마이그레이션 상태 확인
        // assertTrue(SeigManagerV1_4(SEIG_MANAGER_PROXY).v3Migrated());
    }

    /// @notice 시뇨리지 분배 테스트
    function test_seigniorageDistribution() public onlyFork {
        // 1. 블록 진행
        vm.roll(block.number + 100);

        // 2. updateSeigniorage 호출
        // (bool success,) = TOKAMAK1.call(abi.encodeWithSignature("updateSeigniorage()"));
        // assertTrue(success, "updateSeigniorage should succeed");

        // 3. 분배 결과 확인
        // - DAO 분배량
        // - ValidatorPool 분배량
        // - 시퀀서 분배량
    }

    /// @notice 스테이킹 E2E 플로우 테스트
    function test_stakingE2EFlow() public onlyFork {
        address testUser = address(0x9999);
        uint256 stakeAmount = 100e18; // 100 TON

        // 1. 테스트 유저에게 TON 전송 (whale에서)
        address tonWhale = 0x2be5e8c109e2197D077D13A82dAead6a9b3433C5; // TON contract itself or a whale
        // vm.prank(tonWhale);
        // ITON(TON).transfer(testUser, stakeAmount);

        // 2. TON -> WTON 스왑
        // vm.startPrank(testUser);
        // ITON(TON).approve(WTON, stakeAmount);
        // IWTON(WTON).swapFromTON(stakeAmount);

        // 3. WTON 스테이킹
        // uint256 wtonAmount = stakeAmount * 1e9; // WTON은 27 decimals
        // IWTON(WTON).approve(DEPOSIT_MANAGER_PROXY, wtonAmount);
        // IDepositManager(DEPOSIT_MANAGER_PROXY).deposit(TOKAMAK1, wtonAmount);
        // vm.stopPrank();

        // 4. 스테이킹 확인
        // 5. 시뇨리지 분배
        // 6. 보상 확인
    }
}

/// @title E2ELocalSimulationTest
/// @notice Fork 없이 로컬에서 전체 플로우 시뮬레이션
contract E2ELocalSimulationTest is Test {
    // 로컬 배포 컨트랙트들
    SeigManagerV1_4 public seigManager;
    DepositManagerV1_2 public depositManager;
    Layer2ManagerV1_2 public layer2Manager;
    L1BridgeRegistryV1_2 public l1BridgeRegistry;

    address public owner;
    address public dao;
    address public layer2_1;
    address public operator1;

    uint256 constant RAY = 1e27;

    function setUp() public {
        owner = address(this);
        dao = address(0x4001);
        layer2_1 = address(0x5001);
        operator1 = address(0x6001);
    }

    /// @notice V3 컨트랙트 배포 플로우
    function test_v3DeploymentFlow() public {
        // 1. SeigManagerV1_4 배포
        seigManager = new SeigManagerV1_4();
        assertFalse(seigManager.v3Migrated(), "Should not be migrated initially");

        // 2. DepositManagerV1_2 배포
        depositManager = new DepositManagerV1_2();

        // 3. Layer2ManagerV1_2 배포
        layer2Manager = new Layer2ManagerV1_2();

        // 4. L1BridgeRegistryV1_2 배포
        l1BridgeRegistry = new L1BridgeRegistryV1_2();

        emit log("V3 contracts deployed successfully");
    }

    /// @notice V3 파라미터 구조 검증
    function test_v3ParameterStructure() public {
        seigManager = new SeigManagerV1_4();

        // V3 스토리지 변수들 확인
        assertEq(seigManager.daoDistributionRatio(), 0, "d");
        assertEq(seigManager.minStakingRatio(), 0, "theta");
        assertEq(seigManager.validatorDistributionRatio(), 0, "alpha");
        assertEq(seigManager.halfSaturationPoint(), 0, "k");
        assertEq(seigManager.stakedSeigFactor(), 0, "lambda");
        assertEq(seigManager.totalEffectiveBridgedTON(), 0, "totalEffectiveBridgedTON");
        assertEq(seigManager.bridgedTONRewardPerUint(), 0, "bridgedTONRewardPerUint");
        assertEq(seigManager.validatorPool(), address(0), "validatorPool");
        assertEq(seigManager.currentPeriodId(), 0, "currentPeriodId");
        assertFalse(seigManager.v3Migrated(), "v3Migrated");
    }

    /// @notice L1BridgeRegistryV1_2 구조 검증
    function test_l1BridgeRegistryStructure() public {
        l1BridgeRegistry = new L1BridgeRegistryV1_2();
        // L1BridgeRegistryV1_2는 TVL 변경 감지 기능이 추가됨
        assertTrue(address(l1BridgeRegistry) != address(0), "L1BridgeRegistryV1_2 deployed");
    }

    /// @notice DepositManagerV1_2 구조 검증
    function test_depositManagerStructure() public {
        depositManager = new DepositManagerV1_2();
        // DepositManagerV1_2는 V3 시뇨리지 분배 지원
        assertTrue(address(depositManager) != address(0), "DepositManagerV1_2 deployed");
    }

    /// @notice Layer2ManagerV1_2 구조 검증
    function test_layer2ManagerStructure() public {
        layer2Manager = new Layer2ManagerV1_2();
        // Layer2ManagerV1_2는 Bridged TON 추적 기능 추가
        assertTrue(address(layer2Manager) != address(0), "Layer2ManagerV1_2 deployed");
    }

    /// @notice 쌍곡선 함수 E2E 검증
    /// @dev hyperbolicSaturation은 내부 halfSaturationPoint 상태 변수를 사용
    ///      초기화되지 않은 상태(k=0)에서는 y(x) = L (x>0일 때)
    function test_hyperbolicSaturationE2E() public {
        seigManager = new SeigManagerV1_4();

        uint256 L = 1000e27;  // 최대 분배량

        // 초기 halfSaturationPoint = 0 상태 확인
        assertEq(seigManager.halfSaturationPoint(), 0, "Initial k should be 0");

        // x = 0: y = 0 (항상)
        uint256 y0 = seigManager.hyperbolicSaturation(0, L);
        assertEq(y0, 0, "y(0) = 0");

        // halfSaturationPoint = 0일 때, x > 0이면:
        // y = L * x / (0 + x) = L * x / x = L
        uint256 yAny = seigManager.hyperbolicSaturation(500e27, L);
        assertEq(yAny, L, "When k=0, y(x>0) = L");

        // 함수가 올바르게 배포되었는지 확인
        assertTrue(address(seigManager) != address(0), "SeigManager deployed");

        emit log("Hyperbolic saturation function (uninitialized state) verified");
    }
}
