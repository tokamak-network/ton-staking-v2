// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "forge-std/Test.sol";
import "forge-std/console.sol";

// V3 Implementations
import {SeigManagerV1_4} from "../../src/stake/managers/SeigManagerV1_4.sol";
import {DepositManagerV1_2} from "../../src/stake/managers/DepositManagerV1_2.sol";
import {Layer2ManagerV1_2} from "../../src/layer2/Layer2ManagerV1_2.sol";
import {L1BridgeRegistryV1_2} from "../../src/layer2/L1BridgeRegistryV1_2.sol";

// V3 New Contracts
import {RAT} from "../../src/validator/RAT.sol";
import {RATProxy} from "../../src/validator/RATProxy.sol";
import {ValidatorRewardV1} from "../../src/validator/ValidatorRewardV1.sol";
import {ValidatorRewardProxy} from "../../src/validator/ValidatorRewardProxy.sol";

// Interfaces
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";

/// @notice Proxy interface
interface IProxy {
    function upgradeTo(address impl) external;
    function implementation() external view returns (address);
}

/// @notice SeigManager interface for testing
interface ISeigManagerForTest {
    function ton() external view returns (address);
    function wton() external view returns (address);
    function stakeOf(address layer2, address account) external view returns (uint256);
}

/// @notice AccessControl interface for checking owner
interface IAccessControl {
    function hasRole(bytes32 role, address account) external view returns (bool);
    function DEFAULT_ADMIN_ROLE() external view returns (bytes32);
}

/**
 * @title DeployV3ForkTest
 * @notice 메인넷 포크에서 V3 배포 테스트
 * @dev forge test --match-contract DeployV3ForkTest --fork-url $MAINNET_RPC_URL -vvv
 */
contract DeployV3ForkTest is Test {
    // ==========================================
    // Mainnet Addresses
    // ==========================================

    address constant TON = 0x2be5e8c109e2197D077D13A82dAead6a9b3433C5;
    address constant WTON = 0xc4A11aaf6ea915Ed7Ac194161d2fC9384F15bff2;

    address constant SEIG_MANAGER_PROXY = 0x0b55a0f463b6DEFb81c6063973763951712D0E5F;
    address constant DEPOSIT_MANAGER_PROXY = 0x0b58ca72b12F01FC05F8f252e226f3E2089BD00E;
    address constant LAYER2_MANAGER_PROXY = 0xD6Bf6B2b7553c8064Ba763AD6989829060FdFC1D;
    address constant L1_BRIDGE_REGISTRY_PROXY = 0x39d43281A4A5e922AB0DCf89825D73273D8C5BA4;

    // Known operators
    address constant TOKAMAK1 = 0xf3B17FDB808c7d0Df9ACd24dA34700ce069007DF;

    // ==========================================
    // Deployed Addresses
    // ==========================================

    address public seigManagerV1_4Impl;
    address public depositManagerV1_2Impl;
    address public layer2ManagerV1_2Impl;
    address public l1BridgeRegistryV1_2Impl;

    address public ratProxy;
    address public ratImpl;
    address public validatorPoolProxy;
    address public validatorPoolImpl;

    address public proxyOwner;
    address public deployer;

    // ==========================================
    // Setup
    // ==========================================

    function setUp() public {
        // Skip if not forked
        if (block.chainid != 1) {
            return;
        }

        deployer = makeAddr("deployer");
        vm.deal(deployer, 100 ether);

        // Find proxy owner (check DEFAULT_ADMIN_ROLE)
        bytes32 adminRole = IAccessControl(SEIG_MANAGER_PROXY).DEFAULT_ADMIN_ROLE();

        // Try known addresses
        address[] memory candidates = new address[](3);
        candidates[0] = 0xDD9f0cCc044B0781289Ee318e5971b0139602C26; // DAO Committee
        candidates[1] = 0x15280a52E79FD4aB35F4B9Acbb376DCD72b44Fd1; // Another known admin
        candidates[2] = TOKAMAK1;

        for (uint i = 0; i < candidates.length; i++) {
            if (IAccessControl(SEIG_MANAGER_PROXY).hasRole(adminRole, candidates[i])) {
                proxyOwner = candidates[i];
                break;
            }
        }

        console.log("Proxy Owner found:", proxyOwner);
    }

    // ==========================================
    // Tests
    // ==========================================

    /// @notice 현재 메인넷 상태 확인
    function test_checkMainnetState() public view {
        if (block.chainid != 1) {
            console.log("Skipping: Not mainnet fork");
            return;
        }

        console.log("=== Mainnet State ===");
        console.log("TON:", TON);
        console.log("WTON:", WTON);
        console.log("SeigManager Proxy:", SEIG_MANAGER_PROXY);
        console.log("SeigManager Impl:", IProxy(SEIG_MANAGER_PROXY).implementation());
        console.log("DepositManager Proxy:", DEPOSIT_MANAGER_PROXY);
        console.log("DepositManager Impl:", IProxy(DEPOSIT_MANAGER_PROXY).implementation());
        console.log("Proxy Owner:", proxyOwner);
    }

    /// @notice V3 구현체 배포 테스트
    function test_deployImplementations() public {
        if (block.chainid != 1) {
            console.log("Skipping: Not mainnet fork");
            return;
        }

        vm.startPrank(deployer);

        // Deploy implementations
        seigManagerV1_4Impl = address(new SeigManagerV1_4());
        depositManagerV1_2Impl = address(new DepositManagerV1_2());
        layer2ManagerV1_2Impl = address(new Layer2ManagerV1_2());
        l1BridgeRegistryV1_2Impl = address(new L1BridgeRegistryV1_2());

        vm.stopPrank();

        assertTrue(seigManagerV1_4Impl != address(0), "SeigManagerV1_4 deployed");
        assertTrue(depositManagerV1_2Impl != address(0), "DepositManagerV1_2 deployed");
        assertTrue(layer2ManagerV1_2Impl != address(0), "Layer2ManagerV1_2 deployed");
        assertTrue(l1BridgeRegistryV1_2Impl != address(0), "L1BridgeRegistryV1_2 deployed");

        console.log("SeigManagerV1_4:", seigManagerV1_4Impl);
        console.log("DepositManagerV1_2:", depositManagerV1_2Impl);
        console.log("Layer2ManagerV1_2:", layer2ManagerV1_2Impl);
        console.log("L1BridgeRegistryV1_2:", l1BridgeRegistryV1_2Impl);
    }

    /// @notice RAT/ValidatorReward 프록시 배포 및 초기화 테스트
    function test_deployV3Contracts() public {
        if (block.chainid != 1) {
            console.log("Skipping: Not mainnet fork");
            return;
        }

        vm.startPrank(deployer);

        // Deploy RAT
        ratImpl = address(new RAT());
        // NOTE: ratTriggerProbability should be determined based on game theory formula:
        // C_off ≥ (c_m · N) / π_a
        bytes memory ratInitData = abi.encodeWithSelector(
            RAT.initialize.selector,
            SEIG_MANAGER_PROXY,
            WTON,
            TON,
            LAYER2_MANAGER_PROXY,
            deployer,
            0.01e27 // 1% for testing
        );
        ratProxy = address(new RATProxy(ratImpl, deployer, ratInitData));

        // Deploy ValidatorReward
        // NOTE: treasury 제거됨 - SeigManager.dao() 사용
        validatorPoolImpl = address(new ValidatorRewardV1());
        bytes memory validatorRewardInitData = abi.encodeWithSelector(
            ValidatorRewardV1.initialize.selector,
            SEIG_MANAGER_PROXY,
            WTON,
            ratProxy,   // RAT contract for validator info
            deployer    // owner
        );
        validatorPoolProxy = address(new ValidatorRewardProxy(validatorPoolImpl, deployer, validatorRewardInitData));

        vm.stopPrank();

        // Verify RAT
        assertEq(RAT(ratProxy).seigManager(), SEIG_MANAGER_PROXY, "RAT seigManager set");
        assertEq(RAT(ratProxy).wton(), WTON, "RAT wton set");
        assertEq(RAT(ratProxy).ton(), TON, "RAT ton set");
        assertEq(RAT(ratProxy).owner(), deployer, "RAT owner set");

        // Verify ValidatorReward
        assertEq(ValidatorRewardV1(validatorPoolProxy).seigManager(), SEIG_MANAGER_PROXY, "VR seigManager set");
        assertEq(ValidatorRewardV1(validatorPoolProxy).wton(), WTON, "VR wton set");
        assertEq(ValidatorRewardV1(validatorPoolProxy).owner(), deployer, "VR owner set");

        console.log("RAT Proxy:", ratProxy);
        console.log("ValidatorReward Proxy:", validatorPoolProxy);
    }

    /// @notice 프록시 업그레이드 테스트 (owner impersonation)
    function test_upgradeProxies() public {
        if (block.chainid != 1 || proxyOwner == address(0)) {
            console.log("Skipping: Not mainnet fork or no owner found");
            return;
        }

        // Deploy new implementations
        vm.startPrank(deployer);
        seigManagerV1_4Impl = address(new SeigManagerV1_4());
        depositManagerV1_2Impl = address(new DepositManagerV1_2());
        layer2ManagerV1_2Impl = address(new Layer2ManagerV1_2());
        l1BridgeRegistryV1_2Impl = address(new L1BridgeRegistryV1_2());
        vm.stopPrank();

        // Record old implementations
        address oldSeigImpl = IProxy(SEIG_MANAGER_PROXY).implementation();
        address oldDepositImpl = IProxy(DEPOSIT_MANAGER_PROXY).implementation();

        console.log("Old SeigManager impl:", oldSeigImpl);
        console.log("Old DepositManager impl:", oldDepositImpl);

        // Upgrade as owner
        vm.startPrank(proxyOwner);

        IProxy(SEIG_MANAGER_PROXY).upgradeTo(seigManagerV1_4Impl);
        IProxy(DEPOSIT_MANAGER_PROXY).upgradeTo(depositManagerV1_2Impl);
        IProxy(LAYER2_MANAGER_PROXY).upgradeTo(layer2ManagerV1_2Impl);
        IProxy(L1_BRIDGE_REGISTRY_PROXY).upgradeTo(l1BridgeRegistryV1_2Impl);

        vm.stopPrank();

        // Verify upgrades
        assertEq(IProxy(SEIG_MANAGER_PROXY).implementation(), seigManagerV1_4Impl, "SeigManager upgraded");
        assertEq(IProxy(DEPOSIT_MANAGER_PROXY).implementation(), depositManagerV1_2Impl, "DepositManager upgraded");
        assertEq(IProxy(LAYER2_MANAGER_PROXY).implementation(), layer2ManagerV1_2Impl, "Layer2Manager upgraded");
        assertEq(IProxy(L1_BRIDGE_REGISTRY_PROXY).implementation(), l1BridgeRegistryV1_2Impl, "L1BridgeRegistry upgraded");

        console.log("New SeigManager impl:", IProxy(SEIG_MANAGER_PROXY).implementation());
        console.log("New DepositManager impl:", IProxy(DEPOSIT_MANAGER_PROXY).implementation());
    }

    /// @notice 전체 배포 플로우 테스트
    function test_fullDeploymentFlow() public {
        if (block.chainid != 1 || proxyOwner == address(0)) {
            console.log("Skipping: Not mainnet fork or no owner found");
            return;
        }

        console.log("=== Full V3 Deployment Flow ===");

        // Step 1: Deploy implementations
        vm.startPrank(deployer);

        seigManagerV1_4Impl = address(new SeigManagerV1_4());
        depositManagerV1_2Impl = address(new DepositManagerV1_2());
        layer2ManagerV1_2Impl = address(new Layer2ManagerV1_2());
        l1BridgeRegistryV1_2Impl = address(new L1BridgeRegistryV1_2());

        console.log("Step 1: Implementations deployed");

        // Step 2: Deploy V3 contracts
        ratImpl = address(new RAT());
        // NOTE: ratTriggerProbability - determined by game theory formula C_off ≥ (c_m · N) / π_a
        bytes memory ratInitData = abi.encodeWithSelector(
            RAT.initialize.selector,
            SEIG_MANAGER_PROXY, WTON, TON, LAYER2_MANAGER_PROXY, deployer, 0.01e27 // 1% for testing
        );
        ratProxy = address(new RATProxy(ratImpl, deployer, ratInitData));

        // NOTE: treasury 제거됨 - SeigManager.dao() 사용
        validatorPoolImpl = address(new ValidatorRewardV1());
        bytes memory validatorRewardInitData = abi.encodeWithSelector(
            ValidatorRewardV1.initialize.selector,
            SEIG_MANAGER_PROXY, WTON, ratProxy, deployer
        );
        validatorPoolProxy = address(new ValidatorRewardProxy(validatorPoolImpl, deployer, validatorRewardInitData));

        console.log("Step 2: V3 contracts deployed");

        vm.stopPrank();

        // Step 3: Upgrade existing proxies (as owner)
        vm.startPrank(proxyOwner);

        IProxy(SEIG_MANAGER_PROXY).upgradeTo(seigManagerV1_4Impl);
        IProxy(DEPOSIT_MANAGER_PROXY).upgradeTo(depositManagerV1_2Impl);
        IProxy(LAYER2_MANAGER_PROXY).upgradeTo(layer2ManagerV1_2Impl);
        IProxy(L1_BRIDGE_REGISTRY_PROXY).upgradeTo(l1BridgeRegistryV1_2Impl);

        console.log("Step 3: Proxies upgraded");

        vm.stopPrank();

        // Step 4: Configure V3 parameters
        vm.startPrank(deployer);

        RAT(ratProxy).setRatTriggerProbability(0.01e27);
        RAT(ratProxy).setSlashingPenalty(100e27);
        RAT(ratProxy).setValidatorBuffer(100e27);
        RAT(ratProxy).setMinimumThreshold(1000e27);
        RAT(ratProxy).setEvidenceSubmissionPeriod(1 hours);

        // ValidatorReward는 별도 파라미터 설정 불필요
        // (RAT에서 검증자 정보를 조회하고 SeigManager에서 호출)

        console.log("Step 4: V3 parameters configured");

        vm.stopPrank();

        // Verify final state
        assertEq(RAT(ratProxy).ratTriggerProbability(), 0.01e27, "RAT probability set");
        assertEq(RAT(ratProxy).slashingPenalty(), 100e27, "RAT slashing penalty set");
        assertEq(ValidatorRewardV1(validatorPoolProxy).seigManager(), SEIG_MANAGER_PROXY, "VR seigManager set");

        console.log("=== Deployment Complete ===");
        console.log("RAT Proxy:", ratProxy);
        console.log("ValidatorReward Proxy:", validatorPoolProxy);
    }

    /// @notice 업그레이드 후 기존 상태 보존 확인
    function test_statePreservationAfterUpgrade() public {
        if (block.chainid != 1 || proxyOwner == address(0)) {
            console.log("Skipping: Not mainnet fork or no owner found");
            return;
        }

        // Record state before upgrade
        ISeigManagerForTest seigManager = ISeigManagerForTest(SEIG_MANAGER_PROXY);
        address oldTon = seigManager.ton();
        address oldWton = seigManager.wton();

        console.log("Before upgrade - TON:", oldTon);
        console.log("Before upgrade - WTON:", oldWton);

        // Deploy and upgrade
        vm.prank(deployer);
        seigManagerV1_4Impl = address(new SeigManagerV1_4());

        vm.prank(proxyOwner);
        IProxy(SEIG_MANAGER_PROXY).upgradeTo(seigManagerV1_4Impl);

        // Verify state preserved
        assertEq(seigManager.ton(), oldTon, "TON address preserved");
        assertEq(seigManager.wton(), oldWton, "WTON address preserved");

        console.log("After upgrade - TON:", seigManager.ton());
        console.log("After upgrade - WTON:", seigManager.wton());
        console.log("State preserved after upgrade!");
    }
}
