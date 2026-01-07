// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "forge-std/Test.sol";
import {MockWTON} from "../../src/mocks/MockWTON.sol";
import {MockTON} from "../../src/mocks/MockTON.sol";
import {MockCoinage} from "../../src/mocks/MockCoinage.sol";

/// @title MockSeigManagerV3Distribution
/// @notice V3 시뇨리지 분배 테스트를 위한 Mock
/// @dev 백서 V2 분배 로직 구현
contract MockSeigManagerV3Distribution {
    uint256 internal constant RAY = 1e27;
    uint256 internal constant WEI_UNIT = 1e18;

    // ==========================================
    // 스토리지
    // ==========================================

    address public owner;
    address public dao;
    address public validatorReward;
    address public layer2Manager;
    MockWTON public wton;

    // V2→V3 전환 파라미터
    uint256 public stakedSeigFactor;      // λ: 지분 시뇨리지 비율
    uint256 public relativeSeigRate;      // r: 상대 시뇨리지 비율

    // V3 파라미터
    uint256 public daoDistributionRatio;  // d: DAO 분배 비율
    uint256 public minStakingRatio;       // θ: 최소 스테이킹 비율
    uint256 public validatorDistributionRatio; // α: 검증자 분배 비율
    uint256 public halfSaturationPoint;   // k: 반포화점

    bool public v3Migrated;

    // L2별 정보
    struct BridgedTONInfo {
        uint256 currentBridgedTON;      // B_i
        uint256 effectiveBridgedTON;    // B̃_i
        uint256 stakedAmount;           // S_i
        bool isEligible;
        bool isPaused;                  // 슬래싱으로 일시 중지
    }

    mapping(address => BridgedTONInfo) public bridgedTONInfo;
    uint256 public totalEffectiveBridgedTON;

    // 분배 결과 추적
    uint256 public lastStakerSeig;
    uint256 public lastDaoSeig;
    uint256 public lastValidatorSeig;
    uint256 public lastSequencerSeig;
    uint256 public lastUndistributed;

    // 이벤트
    event SeigniorageDistributed(
        uint256 totalSeig,
        uint256 stakerSeig,
        uint256 daoSeig,
        uint256 validatorSeig,
        uint256 sequencerSeig,
        uint256 undistributed
    );

    event EligibilityChanged(address indexed layer2, bool eligible, string reason);

    constructor(address _wton) {
        owner = msg.sender;
        wton = MockWTON(_wton);

        // 기본값 설정 (V2 호환)
        stakedSeigFactor = RAY;           // λ = 1 (V2 모드)
        relativeSeigRate = 0;             // r = 0
        daoDistributionRatio = 0.1e27;    // d = 10%
        minStakingRatio = 0.1e27;         // θ = 10%
        validatorDistributionRatio = 0.3e27; // α = 30%
        halfSaturationPoint = 1000e27;    // k = 1000 WTON
    }

    // ==========================================
    // 설정 함수
    // ==========================================

    function setDAO(address _dao) external {
        dao = _dao;
    }

    function setValidatorReward(address _reward) external {
        validatorReward = _reward;
    }

    function setLayer2Manager(address _manager) external {
        layer2Manager = _manager;
    }

    function setStakedSeigFactor(uint256 lambda) external {
        require(lambda <= RAY, "lambda > 1");
        stakedSeigFactor = lambda;
    }

    function setRelativeSeigRate(uint256 rate) external {
        require(rate <= RAY, "rate > 1");
        relativeSeigRate = rate;
    }

    function setDaoDistributionRatio(uint256 ratio) external {
        require(ratio < RAY, "ratio >= 1");
        daoDistributionRatio = ratio;
    }

    function setMinStakingRatio(uint256 ratio) external {
        require(ratio <= RAY, "ratio > 1");
        minStakingRatio = ratio;
    }

    function setValidatorDistributionRatio(uint256 ratio) external {
        require(ratio < RAY, "ratio >= 1");
        validatorDistributionRatio = ratio;
    }

    function setHalfSaturationPoint(uint256 k) external {
        require(k > 0, "k = 0");
        halfSaturationPoint = k;
    }

    function migrateToV3() external {
        v3Migrated = true;
    }

    // ==========================================
    // L2 관리
    // ==========================================

    function registerL2(address layer2, uint256 bridgedTON, uint256 stakedAmount) external {
        BridgedTONInfo storage info = bridgedTONInfo[layer2];
        info.currentBridgedTON = bridgedTON;
        info.stakedAmount = stakedAmount;
        info.isPaused = false;

        _updateEligibility(layer2);

        if (info.isEligible) {
            totalEffectiveBridgedTON += info.effectiveBridgedTON;
        }
    }

    function updateStakedAmount(address layer2, uint256 newStaked) external {
        BridgedTONInfo storage info = bridgedTONInfo[layer2];
        info.stakedAmount = newStaked;

        uint256 oldEffective = info.effectiveBridgedTON;
        _updateEligibility(layer2);
        uint256 newEffective = info.effectiveBridgedTON;

        totalEffectiveBridgedTON = totalEffectiveBridgedTON + newEffective - oldEffective;
    }

    function updateBridgedTON(address layer2, uint256 newBridgedTON) external {
        BridgedTONInfo storage info = bridgedTONInfo[layer2];
        info.currentBridgedTON = newBridgedTON;

        uint256 oldEffective = info.effectiveBridgedTON;
        _updateEligibility(layer2);
        uint256 newEffective = info.effectiveBridgedTON;

        totalEffectiveBridgedTON = totalEffectiveBridgedTON + newEffective - oldEffective;
    }

    /// @notice L2 일시 중지 (슬래싱 시 호출)
    function pauseL2(address layer2) external {
        BridgedTONInfo storage info = bridgedTONInfo[layer2];
        require(!info.isPaused, "already paused");

        info.isPaused = true;
        totalEffectiveBridgedTON -= info.effectiveBridgedTON;
        info.effectiveBridgedTON = 0;
        info.isEligible = false;

        emit EligibilityChanged(layer2, false, "paused by slashing");
    }

    // ==========================================
    // 자격 검증 (백서 공식 8)
    // ==========================================

    /// @notice 백서 공식 (8): S_i ≥ θ · B_i
    function checkCurrentEligibility(address layer2) public view returns (bool eligible, uint256 required, uint256 actual) {
        BridgedTONInfo memory info = bridgedTONInfo[layer2];

        if (info.isPaused) return (false, 0, 0);

        // θ · B_i
        required = rmul(info.currentBridgedTON, minStakingRatio);
        actual = info.stakedAmount;

        eligible = actual >= required;
    }

    function _updateEligibility(address layer2) internal {
        BridgedTONInfo storage info = bridgedTONInfo[layer2];

        if (info.isPaused) {
            info.isEligible = false;
            info.effectiveBridgedTON = 0;
            return;
        }

        (bool eligible, uint256 required, uint256 actual) = checkCurrentEligibility(layer2);

        bool wasEligible = info.isEligible;
        info.isEligible = eligible;
        info.effectiveBridgedTON = eligible ? info.currentBridgedTON : 0;

        if (wasEligible != eligible) {
            emit EligibilityChanged(
                layer2,
                eligible,
                eligible ? "met staking requirement" : "insufficient staking"
            );
        }
    }

    // ==========================================
    // 시뇨리지 분배 (V2→V3 전환 지원)
    // ==========================================

    /// @notice 시뇨리지 분배 시뮬레이션
    /// @param totalSeig 총 시뇨리지 (A)
    /// @param totalStaked 전체 스테이킹량 (S)
    /// @param totalSupply 전체 TON 공급량 (T)
    function distributeSeigniorage(
        uint256 totalSeig,
        uint256 totalStaked,
        uint256 totalSupply
    ) external returns (
        uint256 stakerSeig,
        uint256 daoSeig,
        uint256 validatorSeig,
        uint256 sequencerSeig,
        uint256 undistributed
    ) {
        // ========================================
        // Step 1: 스테이커 지분 시뇨리지 (λ 적용)
        // S_staked = λ · A · (S / T)
        // ========================================
        uint256 S_staked = rmul(
            rmul(totalSeig, stakedSeigFactor),
            rdiv(totalStaked, totalSupply)
        );

        // A₁ = A - S_staked
        uint256 A1 = totalSeig - S_staked;

        // ========================================
        // Step 2: 스테이커 추가 시뇨리지 (r 적용)
        // S_relative = A₁ · r
        // ========================================
        uint256 S_relative = rmul(A1, relativeSeigRate);

        // A₂ = A₁ - S_relative (V3 분배 재원)
        uint256 A2 = A1 - S_relative;

        // 스테이커 총 시뇨리지
        stakerSeig = S_staked + S_relative;

        // ========================================
        // Step 3: V3 분배 (A₂ 기준)
        // ========================================
        if (v3Migrated && A2 > 0) {
            (daoSeig, validatorSeig, sequencerSeig, undistributed) = _distributeV3(A2);
        } else {
            // V3 미마이그레이션: A₂ 전체 DAO로
            daoSeig = A2;
        }

        // 결과 저장
        lastStakerSeig = stakerSeig;
        lastDaoSeig = daoSeig;
        lastValidatorSeig = validatorSeig;
        lastSequencerSeig = sequencerSeig;
        lastUndistributed = undistributed;

        // 분배 실행 (WTON 민트)
        if (daoSeig > 0 && dao != address(0)) {
            wton.mint(dao, daoSeig);
        }
        if (validatorSeig > 0 && validatorReward != address(0)) {
            wton.mint(validatorReward, validatorSeig);
        }
        if (sequencerSeig > 0 && layer2Manager != address(0)) {
            wton.mint(layer2Manager, sequencerSeig);
        }

        emit SeigniorageDistributed(
            totalSeig,
            stakerSeig,
            daoSeig,
            validatorSeig,
            sequencerSeig,
            undistributed
        );
    }

    /// @notice V3 분배 로직 (백서 공식 적용)
    function _distributeV3(uint256 A2) internal view returns (
        uint256 daoSeig,
        uint256 validatorSeig,
        uint256 sequencerSeig,
        uint256 undistributed
    ) {
        // ========================================
        // DAO 고정 분배 (백서 공식 7)
        // S_DAO = d · A₂
        // ========================================
        uint256 S_DAO = rmul(A2, daoDistributionRatio);

        // ========================================
        // L2 분배 가능량
        // L = (1 - d) · A₂
        // ========================================
        uint256 L = A2 - S_DAO;

        // ========================================
        // 쌍곡선 포화 함수 (백서 공식 11)
        // y(x) = L · (x / (k + x))
        // ========================================
        uint256 x = totalEffectiveBridgedTON;
        uint256 y = 0;

        if (x > 0) {
            y = hyperbolicSaturation(x, L);
        }

        // 검증자: α · y(x)
        validatorSeig = rmul(y, validatorDistributionRatio);

        // 시퀀서: (1 - α) · y(x)
        sequencerSeig = y - validatorSeig;

        // 미분배분 DAO 귀속: L - y(x)
        undistributed = L - y;

        // 총 DAO = S_DAO + 미분배분
        daoSeig = S_DAO + undistributed;
    }

    // ==========================================
    // 쌍곡선 포화 함수 (백서 공식 11)
    // ==========================================

    /// @notice y(x) = L · (x / (k + x))
    function hyperbolicSaturation(uint256 x, uint256 L) public view returns (uint256) {
        if (x == 0) return 0;

        uint256 k = halfSaturationPoint;
        // y = L * x / (k + x)
        return (L * x) / (k + x);
    }

    // ==========================================
    // 수학 함수 (DSMath)
    // ==========================================

    function rmul(uint256 x, uint256 y) internal pure returns (uint256) {
        return (x * y) / RAY;
    }

    function rdiv(uint256 x, uint256 y) internal pure returns (uint256) {
        return (x * RAY) / y;
    }
}


/// @title SeigniorageDistributionTest
/// @notice 시뇨리지 분배 단위 테스트
/// @dev 4가지 핵심 검증:
///   1. V2→V3 전환 구조 검증
///   2. DAO/검증자/시퀀서/스테이커 분배 검증
///   3. 시퀀서 슬래싱 시 시뇨리지 미발행 검증
///   4. 검증자 담보금 부족 시 시뇨리지 미발행 검증
contract SeigniorageDistributionTest is Test {
    MockSeigManagerV3Distribution public seigManager;
    MockWTON public wton;
    MockTON public ton;

    address public dao = address(0x1);
    address public validatorReward = address(0x2);
    address public layer2Manager = address(0x3);

    address public layer2_1 = address(0x10);
    address public layer2_2 = address(0x20);
    address public layer2_3 = address(0x30);

    uint256 internal constant RAY = 1e27;

    function setUp() public {
        ton = new MockTON();
        wton = new MockWTON();
        wton.setTON(address(ton));

        seigManager = new MockSeigManagerV3Distribution(address(wton));
        seigManager.setDAO(dao);
        seigManager.setValidatorReward(validatorReward);
        seigManager.setLayer2Manager(layer2Manager);
    }

    // ==========================================
    // 1. V2→V3 전환 구조 검증
    // ==========================================

    /// @notice λ = 1 (V2 모드): 전체 시뇨리지가 스테이커에게
    function test_transition_lambda1_v2Mode() public {
        seigManager.setStakedSeigFactor(RAY); // λ = 1
        seigManager.setRelativeSeigRate(0);   // r = 0

        uint256 totalSeig = 1000e27;
        uint256 totalStaked = 500e27;
        uint256 totalSupply = 1000e27;

        (uint256 stakerSeig, uint256 daoSeig, , , ) = seigManager.distributeSeigniorage(
            totalSeig, totalStaked, totalSupply
        );

        // λ = 1: S_staked = 1 * 1000 * (500/1000) = 500
        // A₁ = 1000 - 500 = 500
        // S_relative = 0
        // A₂ = 500 (V3 미마이그레이션이면 DAO로)
        assertEq(stakerSeig, 500e27, "Staker should get 50% in V2 mode");
        assertEq(daoSeig, 500e27, "DAO should get A2 when not migrated");
    }

    /// @notice λ = 0.5 (전환 중): 지분 시뇨리지 50% 감소
    function test_transition_lambda05_midTransition() public {
        seigManager.setStakedSeigFactor(0.5e27); // λ = 0.5
        seigManager.setRelativeSeigRate(0);

        uint256 totalSeig = 1000e27;
        uint256 totalStaked = 500e27;
        uint256 totalSupply = 1000e27;

        (uint256 stakerSeig, uint256 daoSeig, , , ) = seigManager.distributeSeigniorage(
            totalSeig, totalStaked, totalSupply
        );

        // λ = 0.5: S_staked = 0.5 * 1000 * (500/1000) = 250
        // A₁ = 1000 - 250 = 750
        // A₂ = 750
        assertEq(stakerSeig, 250e27, "Staker should get 25% with lambda=0.5");
        assertEq(daoSeig, 750e27, "DAO should get A2 when not migrated");
    }

    /// @notice λ = 0 (V3 완전 모드): 지분 시뇨리지 없음
    function test_transition_lambda0_v3Mode() public {
        seigManager.setStakedSeigFactor(0); // λ = 0
        seigManager.setRelativeSeigRate(0);
        seigManager.migrateToV3();

        // L2 등록 (자격 충족)
        seigManager.registerL2(layer2_1, 500e27, 100e27); // B=500, S=100 (θ=10%, 필요=50)

        uint256 totalSeig = 1000e27;
        uint256 totalStaked = 100e27;
        uint256 totalSupply = 1000e27;

        (uint256 stakerSeig, uint256 daoSeig, uint256 validatorSeig, uint256 sequencerSeig, ) =
            seigManager.distributeSeigniorage(totalSeig, totalStaked, totalSupply);

        // λ = 0: S_staked = 0
        assertEq(stakerSeig, 0, "Staker should get 0 with lambda=0");

        // A₂ = 1000이 V3 분배
        assertTrue(daoSeig > 0, "DAO should get distribution");
        assertTrue(validatorSeig > 0, "Validators should get distribution");
        assertTrue(sequencerSeig > 0, "Sequencers should get distribution");
    }

    // ==========================================
    // 2. DAO/검증자/시퀀서/스테이커 분배 검증
    // ==========================================

    /// @notice V3 분배: d=10%, α=30% 검증
    function test_v3Distribution_daoValidatorSequencer() public {
        seigManager.setStakedSeigFactor(0);           // λ = 0
        seigManager.setDaoDistributionRatio(0.1e27);  // d = 10%
        seigManager.setValidatorDistributionRatio(0.3e27); // α = 30%
        seigManager.setHalfSaturationPoint(500e27);   // k = 500
        seigManager.migrateToV3();

        // L2 등록: x = 500 (k와 동일)
        seigManager.registerL2(layer2_1, 500e27, 100e27);

        uint256 totalSeig = 1000e27;
        uint256 totalStaked = 0;
        uint256 totalSupply = 1000e27;

        (uint256 stakerSeig, uint256 daoSeig, uint256 validatorSeig, uint256 sequencerSeig, uint256 undistributed) =
            seigManager.distributeSeigniorage(totalSeig, totalStaked, totalSupply);

        // A₂ = 1000 (λ=0이므로)
        // S_DAO = d * A₂ = 0.1 * 1000 = 100
        // L = (1 - d) * A₂ = 0.9 * 1000 = 900

        // x = 500, k = 500
        // y(x) = L * (x / (k + x)) = 900 * (500 / 1000) = 450
        uint256 expectedY = 450e27;

        // 검증자: α * y = 0.3 * 450 = 135
        uint256 expectedValidator = 135e27;

        // 시퀀서: (1 - α) * y = 0.7 * 450 = 315
        uint256 expectedSequencer = 315e27;

        // 미분배: L - y = 900 - 450 = 450
        // 총 DAO = S_DAO + 미분배 = 100 + 450 = 550

        assertEq(stakerSeig, 0, "Staker seig should be 0");
        assertEq(validatorSeig, expectedValidator, "Validator seig mismatch");
        assertEq(sequencerSeig, expectedSequencer, "Sequencer seig mismatch");
        assertEq(daoSeig, 100e27 + 450e27, "DAO seig mismatch (S_DAO + undistributed)");
    }

    /// @notice 스테이커 + V3 분배 혼합
    function test_mixedDistribution_stakerAndV3() public {
        seigManager.setStakedSeigFactor(0.5e27);      // λ = 0.5
        seigManager.setRelativeSeigRate(0.1e27);      // r = 10%
        seigManager.setDaoDistributionRatio(0.1e27);  // d = 10%
        seigManager.setValidatorDistributionRatio(0.3e27); // α = 30%
        seigManager.setHalfSaturationPoint(1000e27);
        seigManager.migrateToV3();

        seigManager.registerL2(layer2_1, 1000e27, 200e27);

        uint256 totalSeig = 1000e27;
        uint256 totalStaked = 500e27;
        uint256 totalSupply = 1000e27;

        (uint256 stakerSeig, uint256 daoSeig, uint256 validatorSeig, uint256 sequencerSeig, ) =
            seigManager.distributeSeigniorage(totalSeig, totalStaked, totalSupply);

        // S_staked = λ * A * (S/T) = 0.5 * 1000 * 0.5 = 250
        // A₁ = 1000 - 250 = 750
        // S_relative = A₁ * r = 750 * 0.1 = 75
        // stakerSeig = 250 + 75 = 325
        assertEq(stakerSeig, 325e27, "Staker seig mismatch");

        // A₂ = A₁ - S_relative = 750 - 75 = 675
        // 이 중 일부가 DAO, 검증자, 시퀀서로
        assertTrue(daoSeig > 0, "DAO should receive seig");
        assertTrue(validatorSeig > 0, "Validators should receive seig");
        assertTrue(sequencerSeig > 0, "Sequencers should receive seig");

        // 총합 검증
        uint256 total = stakerSeig + daoSeig + validatorSeig + sequencerSeig;
        assertEq(total, totalSeig, "Total distribution should equal totalSeig");
    }

    // ==========================================
    // 3. 시퀀서 슬래싱 시 시뇨리지 미발행 검증
    // ==========================================

    /// @notice 슬래싱된 L2는 시뇨리지 분배에서 제외
    function test_slashedSequencer_noSeigniorage() public {
        seigManager.setStakedSeigFactor(0);
        seigManager.setHalfSaturationPoint(500e27);
        seigManager.migrateToV3();

        // 두 L2 등록
        seigManager.registerL2(layer2_1, 500e27, 100e27);
        seigManager.registerL2(layer2_2, 500e27, 100e27);

        // layer2_1 슬래싱 (일시 중지)
        seigManager.pauseL2(layer2_1);

        // 분배 전 상태 확인
        (,,,bool isEligible1, bool isPaused1) = seigManager.bridgedTONInfo(layer2_1);
        (,,,bool isEligible2, bool isPaused2) = seigManager.bridgedTONInfo(layer2_2);

        assertFalse(isEligible1, "Slashed L2 should not be eligible");
        assertTrue(isPaused1, "Slashed L2 should be paused");
        assertTrue(isEligible2, "Non-slashed L2 should be eligible");
        assertFalse(isPaused2, "Non-slashed L2 should not be paused");

        // 유효 Bridged TON 확인
        uint256 totalEffective = seigManager.totalEffectiveBridgedTON();
        assertEq(totalEffective, 500e27, "Only non-slashed L2 should contribute");

        // 분배 실행
        (,, uint256 validatorSeig, uint256 sequencerSeig, ) =
            seigManager.distributeSeigniorage(1000e27, 0, 1000e27);

        // 슬래싱된 L2는 분배에서 완전 제외
        // x = 500 (layer2_2만), k = 500
        // y(x) = L * (500 / 1000) = L/2
        assertTrue(validatorSeig > 0, "Validators should get seig");
        assertTrue(sequencerSeig > 0, "Non-slashed sequencer should get seig");
    }

    /// @notice 모든 L2가 슬래싱되면 시뇨리지 전액 DAO로
    function test_allSequencersSlashed_allToDao() public {
        seigManager.setStakedSeigFactor(0);
        seigManager.setDaoDistributionRatio(0.1e27);
        seigManager.migrateToV3();

        seigManager.registerL2(layer2_1, 500e27, 100e27);
        seigManager.pauseL2(layer2_1);

        uint256 totalSeig = 1000e27;

        (, uint256 daoSeig, uint256 validatorSeig, uint256 sequencerSeig, ) =
            seigManager.distributeSeigniorage(totalSeig, 0, totalSeig);

        // x = 0이면 y(x) = 0
        // 모든 A₂가 DAO로
        assertEq(validatorSeig, 0, "No validators should get seig when all slashed");
        assertEq(sequencerSeig, 0, "No sequencers should get seig when all slashed");
        assertEq(daoSeig, 1000e27, "All seig should go to DAO");
    }

    // ==========================================
    // 4. 검증자 담보금 부족 시 시뇨리지 미발행 검증
    // ==========================================

    /// @notice 담보금 부족 (S_i < θ · B_i) 시 시뇨리지 미수령
    function test_insufficientStaking_noSeigniorage() public {
        seigManager.setStakedSeigFactor(0);
        seigManager.setMinStakingRatio(0.1e27); // θ = 10%
        seigManager.setHalfSaturationPoint(500e27);
        seigManager.migrateToV3();

        // layer2_1: 자격 충족 (S=100 >= θ*B = 10% * 500 = 50)
        seigManager.registerL2(layer2_1, 500e27, 100e27);

        // layer2_2: 자격 미달 (S=40 < θ*B = 10% * 500 = 50)
        seigManager.registerL2(layer2_2, 500e27, 40e27);

        // 자격 확인
        (bool eligible1, uint256 required1, uint256 actual1) = seigManager.checkCurrentEligibility(layer2_1);
        (bool eligible2, uint256 required2, uint256 actual2) = seigManager.checkCurrentEligibility(layer2_2);

        assertTrue(eligible1, "Layer2_1 should be eligible");
        assertFalse(eligible2, "Layer2_2 should NOT be eligible");
        assertEq(required1, 50e27, "Required staking for L2_1");
        assertEq(required2, 50e27, "Required staking for L2_2");
        assertEq(actual1, 100e27, "Actual staking for L2_1");
        assertEq(actual2, 40e27, "Actual staking for L2_2");

        // 유효 Bridged TON 확인
        uint256 totalEffective = seigManager.totalEffectiveBridgedTON();
        assertEq(totalEffective, 500e27, "Only eligible L2 should contribute");
    }

    /// @notice 담보금 감소로 자격 상실 시 시뇨리지 중단
    function test_stakingDecrease_loseEligibility() public {
        seigManager.setStakedSeigFactor(0);
        seigManager.setMinStakingRatio(0.1e27);
        seigManager.migrateToV3();

        // 초기: 자격 충족
        seigManager.registerL2(layer2_1, 500e27, 100e27);

        (bool eligible1, , ) = seigManager.checkCurrentEligibility(layer2_1);
        assertTrue(eligible1, "Should be eligible initially");

        uint256 effectiveBefore = seigManager.totalEffectiveBridgedTON();
        assertEq(effectiveBefore, 500e27, "Effective should be 500");

        // 담보금 감소 (슬래싱 등으로)
        seigManager.updateStakedAmount(layer2_1, 40e27);

        (bool eligible2, , ) = seigManager.checkCurrentEligibility(layer2_1);
        assertFalse(eligible2, "Should lose eligibility after staking decrease");

        uint256 effectiveAfter = seigManager.totalEffectiveBridgedTON();
        assertEq(effectiveAfter, 0, "Effective should be 0 after losing eligibility");
    }

    /// @notice 담보금 증가로 자격 회복 시 시뇨리지 재개
    function test_stakingIncrease_regainEligibility() public {
        seigManager.setStakedSeigFactor(0);
        seigManager.setMinStakingRatio(0.1e27);
        seigManager.migrateToV3();

        // 초기: 자격 미달
        seigManager.registerL2(layer2_1, 500e27, 40e27);

        (bool eligible1, , ) = seigManager.checkCurrentEligibility(layer2_1);
        assertFalse(eligible1, "Should NOT be eligible initially");

        // 담보금 증가
        seigManager.updateStakedAmount(layer2_1, 100e27);

        (bool eligible2, , ) = seigManager.checkCurrentEligibility(layer2_1);
        assertTrue(eligible2, "Should regain eligibility after staking increase");

        uint256 effectiveAfter = seigManager.totalEffectiveBridgedTON();
        assertEq(effectiveAfter, 500e27, "Effective should be restored");
    }

    // ==========================================
    // 통합 시나리오 테스트
    // ==========================================

    /// @notice 통합 시나리오: 슬래싱 + 담보금 부족 복합
    function test_combined_slashingAndInsufficientStaking() public {
        seigManager.setStakedSeigFactor(0);
        seigManager.setMinStakingRatio(0.1e27);
        seigManager.setDaoDistributionRatio(0.1e27);
        seigManager.setValidatorDistributionRatio(0.3e27);
        seigManager.setHalfSaturationPoint(300e27);
        seigManager.migrateToV3();

        // 3개 L2 등록
        seigManager.registerL2(layer2_1, 300e27, 50e27);  // 자격 충족 (50 >= 30)
        seigManager.registerL2(layer2_2, 300e27, 50e27);  // 자격 충족
        seigManager.registerL2(layer2_3, 300e27, 20e27);  // 자격 미달 (20 < 30)

        // layer2_1 슬래싱
        seigManager.pauseL2(layer2_1);

        // 유효 Bridged TON: layer2_2만 (300)
        uint256 totalEffective = seigManager.totalEffectiveBridgedTON();
        assertEq(totalEffective, 300e27, "Only L2_2 should be effective");

        // 분배
        (,, uint256 validatorSeig, uint256 sequencerSeig, ) =
            seigManager.distributeSeigniorage(1000e27, 0, 1000e27);

        // x = 300, k = 300
        // y(x) = L * (300 / 600) = L/2
        assertTrue(validatorSeig > 0, "Validators should receive seig");
        assertTrue(sequencerSeig > 0, "Sequencer (L2_2 only) should receive seig");
    }
}
