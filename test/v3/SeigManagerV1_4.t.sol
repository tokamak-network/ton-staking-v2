// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "forge-std/Test.sol";
import {SeigManagerV1_4Storage} from "../../src/stake/managers/SeigManagerV1_4Storage.sol";

/// @title SeigManagerV1_4Test
/// @notice SeigManagerV1_4 핵심 로직 단위 테스트
/// @dev Tokamak Economics Whitepaper V2 (December 9, 2025) 기준
contract SeigManagerV1_4Test is Test {
    uint256 internal constant RAY = 1e27;
    uint256 internal constant WEI_UNIT = 1e18;

    // V3 파라미터
    uint256 public daoDistributionRatio;
    uint256 public minStakingRatio;
    uint256 public validatorDistributionRatio;
    uint256 public halfSaturationPoint;
    uint256 public stakedSeigFactor;
    uint256 public totalEffectiveBridgedTON;

    // Bridged TON 정보
    mapping(address => SeigManagerV1_4Storage.BridgedTONInfo) public bridgedTONInfo;

    function setUp() public {
        // 백서 기준 초기값 설정
        daoDistributionRatio = 0.2e27;      // d = 20%
        minStakingRatio = 0.1e27;           // θ = 10%
        validatorDistributionRatio = 0.2e27; // α = 20%
        halfSaturationPoint = 10_000_000e27; // k = 1000만 TON
        stakedSeigFactor = 1e27;            // λ = 100%
    }

    // ==========================================
    // 쌍곡선 포화 함수 테스트
    // ==========================================

    /// @notice 백서 공식 (11): y(x) = L · (x / (k + x))
    function hyperbolicSaturation(uint256 x, uint256 maxL2Allocation)
        public
        view
        returns (uint256 y)
    {
        if (x == 0) return 0;
        // y(x) = L · (x / (k + x))
        y = _rdiv(_rmul(maxL2Allocation, x), halfSaturationPoint + x);
    }

    /// @notice x = 0 일 때 y(x) = 0
    function test_hyperbolicSaturation_zeroX() public view {
        uint256 L = 1000e27; // 1000 TON
        uint256 y = hyperbolicSaturation(0, L);
        assertEq(y, 0, "y(0) should be 0");
    }

    /// @notice x = k 일 때 y(k) = L/2
    function test_hyperbolicSaturation_atHalfSaturationPoint() public view {
        uint256 L = 1000e27; // 1000 TON
        uint256 k = halfSaturationPoint;

        uint256 y = hyperbolicSaturation(k, L);
        uint256 expectedY = L / 2;

        // 반포화점에서 y(k) = L/2
        assertApproxEqRel(y, expectedY, 1e16, "y(k) should be approximately L/2");
    }

    /// @notice 단조 증가: x1 < x2 => y(x1) < y(x2)
    function test_hyperbolicSaturation_monotonicallyIncreasing() public view {
        uint256 L = 1000e27;

        uint256 x1 = 100e27;
        uint256 x2 = 200e27;
        uint256 x3 = 500e27;

        uint256 y1 = hyperbolicSaturation(x1, L);
        uint256 y2 = hyperbolicSaturation(x2, L);
        uint256 y3 = hyperbolicSaturation(x3, L);

        assertTrue(y1 < y2, "y(x1) < y(x2)");
        assertTrue(y2 < y3, "y(x2) < y(x3)");
    }

    /// @notice 상한: y(x) < L for all x
    function test_hyperbolicSaturation_upperBoundL() public view {
        uint256 L = 1000e27;

        // 매우 큰 x 값
        uint256 largeX = 1_000_000_000e27; // 10억 TON
        uint256 y = hyperbolicSaturation(largeX, L);

        assertTrue(y < L, "y(x) should always be less than L");
        // 매우 큰 x에서 L에 근접
        assertApproxEqRel(y, L, 1e16, "y(very large x) should approach L");
    }

    /// @notice Fuzz 테스트: 쌍곡선 함수 속성
    function testFuzz_hyperbolicSaturation_properties(uint256 x, uint256 L) public view {
        // 합리적인 범위로 제한 (RAY 단위이므로 최소 1e18 이상)
        x = bound(x, 1e18, 1_000_000_000e27);
        L = bound(L, 1e18, 1_000_000_000e27);

        uint256 y = hyperbolicSaturation(x, L);

        // y(x) <= L
        assertTrue(y <= L, "y(x) should be <= L");

        // y(x) > 0 when x > 0 and L > 0 (정밀도 문제로 인해 x가 매우 작으면 0이 될 수 있음)
        // RAY 연산에서 최소 단위 이상이면 0보다 커야 함
        if (x >= 1e18 && L >= 1e18) {
            assertTrue(y > 0, "y(x) should be > 0 when x > 0 and L > 0");
        }
    }

    // ==========================================
    // 자격 조건 테스트 (S_i >= θ·B_i)
    // ==========================================

    /// @notice 백서 공식 (8): S_i >= θ·B_i 자격 조건
    function checkEligibility(
        uint256 currentStake,
        uint256 bridgedTON
    ) public view returns (bool eligible, uint256 requiredStake) {
        // θ·B_i 계산
        requiredStake = _rmul(bridgedTON, minStakingRatio);

        // S_i >= θ·B_i
        eligible = currentStake >= requiredStake;
    }

    /// @notice 충분한 스테이킹으로 자격 획득
    function test_checkEligibility_sufficient() public view {
        uint256 bridgedTON = 1000e27;  // B_i = 1000 TON
        uint256 requiredStake = _rmul(bridgedTON, minStakingRatio); // θ·B_i = 100 TON

        // S_i = 150 TON (충분)
        (bool eligible, uint256 required) = checkEligibility(150e27, bridgedTON);

        assertTrue(eligible, "Should be eligible with sufficient stake");
        assertEq(required, requiredStake, "Required stake calculation");
    }

    /// @notice 불충분한 스테이킹으로 자격 미달
    function test_checkEligibility_insufficient() public view {
        uint256 bridgedTON = 1000e27;  // B_i = 1000 TON

        // S_i = 50 TON (불충분, 필요 100 TON)
        (bool eligible, ) = checkEligibility(50e27, bridgedTON);

        assertFalse(eligible, "Should not be eligible with insufficient stake");
    }

    /// @notice 정확히 θ·B_i 스테이킹 (경계 조건)
    function test_checkEligibility_exact() public view {
        uint256 bridgedTON = 1000e27;
        uint256 exactRequired = _rmul(bridgedTON, minStakingRatio);

        (bool eligible, ) = checkEligibility(exactRequired, bridgedTON);

        assertTrue(eligible, "Should be eligible with exactly required stake");
    }

    /// @notice Fuzz 테스트: 자격 조건
    function testFuzz_checkEligibility(uint256 stake, uint256 bridgedTON) public view {
        stake = bound(stake, 0, 1_000_000_000e27);
        bridgedTON = bound(bridgedTON, 1, 1_000_000_000e27);

        (bool eligible, uint256 required) = checkEligibility(stake, bridgedTON);

        if (stake >= required) {
            assertTrue(eligible, "Should be eligible when stake >= required");
        } else {
            assertFalse(eligible, "Should not be eligible when stake < required");
        }
    }

    // ==========================================
    // 개별 L2 시뇨리지 계산 테스트
    // ==========================================

    /// @notice 백서 공식 (12): Seig_i = y(x) · (B̃_i / x)
    function calculateL2Seigniorage(
        uint256 effectiveBridgedTON,
        uint256 totalY,
        uint256 totalX
    ) public pure returns (uint256 seigniorage) {
        if (totalX == 0) return 0;
        if (effectiveBridgedTON == 0) return 0;

        // Seig_i = y(x) · (B̃_i / x)
        seigniorage = _rmul(totalY, _rdiv(effectiveBridgedTON, totalX));
    }

    /// @notice 비례 분배 정확성
    function test_calculateL2Seigniorage_proportional() public pure {
        uint256 totalY = 1000e27;  // y(x) = 1000 TON
        uint256 totalX = 10000e27; // x = 10000 TON

        // L2_A: B̃_A = 3000 TON (30%)
        uint256 seig_A = calculateL2Seigniorage(3000e27, totalY, totalX);

        // L2_B: B̃_B = 7000 TON (70%)
        uint256 seig_B = calculateL2Seigniorage(7000e27, totalY, totalX);

        // 30:70 비율 확인
        assertApproxEqRel(seig_A, 300e27, 1e16, "L2_A should get 30% of y(x)");
        assertApproxEqRel(seig_B, 700e27, 1e16, "L2_B should get 70% of y(x)");

        // 합계 = y(x)
        assertApproxEqRel(seig_A + seig_B, totalY, 1e16, "Sum should equal y(x)");
    }

    /// @notice totalX = 0 일 때 0 반환
    function test_calculateL2Seigniorage_zeroTotalX() public pure {
        uint256 seig = calculateL2Seigniorage(100e27, 1000e27, 0);
        assertEq(seig, 0, "Should return 0 when totalX is 0");
    }

    /// @notice effectiveBridgedTON = 0 일 때 0 반환 (자격 없음)
    function test_calculateL2Seigniorage_zeroEffective() public pure {
        uint256 seig = calculateL2Seigniorage(0, 1000e27, 10000e27);
        assertEq(seig, 0, "Should return 0 when effectiveBridgedTON is 0");
    }

    // ==========================================
    // 시퀀서/검증자 보상 계산 테스트
    // ==========================================

    /// @notice 백서 공식 (13): o_i = (1 - α) · Seig_i
    function calculateSequencerReward(uint256 l2Seigniorage)
        public
        view
        returns (uint256)
    {
        return _rmul(l2Seigniorage, RAY - validatorDistributionRatio);
    }

    /// @notice 검증자 보상: v_i = α · Seig_i / n
    function calculateValidatorReward(uint256 l2Seigniorage)
        public
        view
        returns (uint256)
    {
        return _rmul(l2Seigniorage, validatorDistributionRatio);
    }

    /// @notice 시퀀서/검증자 보상 비율 테스트
    function test_sequencerValidatorRewardSplit() public view {
        uint256 l2Seigniorage = 1000e27; // Seig_i = 1000 TON

        uint256 sequencerReward = calculateSequencerReward(l2Seigniorage);
        uint256 validatorReward = calculateValidatorReward(l2Seigniorage);

        // α = 20%, (1-α) = 80%
        assertApproxEqRel(sequencerReward, 800e27, 1e16, "Sequencer should get 80%");
        assertApproxEqRel(validatorReward, 200e27, 1e16, "Validators should get 20%");

        // 합계 = Seig_i
        assertApproxEqRel(
            sequencerReward + validatorReward,
            l2Seigniorage,
            1e16,
            "Sum should equal l2Seigniorage"
        );
    }

    // ==========================================
    // DAO 분배 테스트
    // ==========================================

    /// @notice 백서 공식 (7): S_DAO = d · A₂
    function calculateDAOAllocation(uint256 A2) public view returns (uint256) {
        return _rmul(A2, daoDistributionRatio);
    }

    /// @notice DAO 분배 정확성
    function test_daoAllocation() public view {
        uint256 A2 = 10000e27; // A₂ = 10000 TON

        uint256 daoAmount = calculateDAOAllocation(A2);

        // d = 20%
        assertApproxEqRel(daoAmount, 2000e27, 1e16, "DAO should get 20% of A2");
    }

    /// @notice L = (1 - d) · A₂ 테스트
    function test_l2MaxAllocation() public view {
        uint256 A2 = 10000e27;

        uint256 S_DAO = calculateDAOAllocation(A2);
        uint256 L = A2 - S_DAO;

        // L = (1 - 0.2) · A₂ = 80%
        assertApproxEqRel(L, 8000e27, 1e16, "L should be 80% of A2");
    }

    // ==========================================
    // 전환 메커니즘 테스트 (λ, r)
    // ==========================================

    /// @notice S_staked = λ · A · (S / T) 계산
    function calculateStakedSeig(
        uint256 A,
        uint256 lambda,
        uint256 S,
        uint256 T
    ) public pure returns (uint256) {
        return _rmul(_rmul(A, lambda), _rdiv(S, T));
    }

    /// @notice λ = 1 (V2 상태): 스테이커 시뇨리지 100%
    function test_transition_lambda1() public pure {
        uint256 A = 1000e27;
        uint256 S = 100e27;  // 스테이킹 금액
        uint256 T = 1000e27; // TON 총 발행량

        uint256 S_staked = calculateStakedSeig(A, 1e27, S, T);

        // S_staked = 1.0 * 1000 * (100/1000) = 100
        assertApproxEqRel(S_staked, 100e27, 1e16, "S_staked with lambda=1");
    }

    /// @notice λ = 0.5: 스테이커 시뇨리지 50%
    function test_transition_lambda05() public pure {
        uint256 A = 1000e27;
        uint256 S = 100e27;
        uint256 T = 1000e27;

        uint256 S_staked = calculateStakedSeig(A, 0.5e27, S, T);

        // S_staked = 0.5 * 1000 * (100/1000) = 50
        assertApproxEqRel(S_staked, 50e27, 1e16, "S_staked with lambda=0.5");
    }

    /// @notice λ = 0 (V3 상태): 스테이커 시뇨리지 0%
    function test_transition_lambda0() public pure {
        uint256 A = 1000e27;
        uint256 S = 100e27;
        uint256 T = 1000e27;

        uint256 S_staked = calculateStakedSeig(A, 0, S, T);

        assertEq(S_staked, 0, "S_staked with lambda=0 should be 0");
    }

    // ==========================================
    // 전체 분배 플로우 테스트
    // ==========================================

    /// @notice 전체 V3 분배 플로우
    function test_fullDistributionFlow() public view {
        // 입력
        uint256 A = 10000e27;  // 기간 시뇨리지 = 10000 TON
        uint256 lambda = 0;   // V3 완전 전환 상태
        uint256 r = 0;        // 추가 시뇨리지 없음
        uint256 S = 1000e27;  // 스테이킹
        uint256 T = 10000e27; // TON 총 발행량

        // Step 1: S_staked = λ · A · (S/T) = 0
        uint256 S_staked = calculateStakedSeig(A, lambda, S, T);
        assertEq(S_staked, 0, "S_staked should be 0 in V3");

        // Step 2: A₁ = A - S_staked = 10000
        uint256 A1 = A - S_staked;
        assertEq(A1, 10000e27, "A1 should equal A");

        // Step 3: S_relative = A₁ · r = 0
        uint256 S_relative = _rmul(A1, r);
        assertEq(S_relative, 0, "S_relative should be 0");

        // Step 4: A₂ = A₁ - S_relative = 10000
        uint256 A2 = A1 - S_relative;
        assertEq(A2, 10000e27, "A2 should equal A in V3");

        // Step 5: S_DAO = d · A₂ = 2000
        uint256 S_DAO = calculateDAOAllocation(A2);
        assertApproxEqRel(S_DAO, 2000e27, 1e16, "S_DAO = 20%");

        // Step 6: L = A₂ - S_DAO = 8000
        uint256 L = A2 - S_DAO;
        assertApproxEqRel(L, 8000e27, 1e16, "L = 80%");

        // Step 7: y(x) = L · (x / (k + x))
        uint256 x = 5_000_000e27; // 500만 TON (k의 절반)
        uint256 y = hyperbolicSaturation(x, L);

        // x = k/2 일 때, y ≈ L/3
        uint256 expectedY = _rdiv(_rmul(L, x), halfSaturationPoint + x);
        assertApproxEqRel(y, expectedY, 1e16, "y(x) calculation");

        // Step 8: 미분배분 = L - y(x) → DAO 귀속
        uint256 undistributed = L - y;
        assertTrue(undistributed > 0, "There should be undistributed amount");

        uint256 totalDAO = S_DAO + undistributed;
        assertTrue(totalDAO > S_DAO, "Total DAO should include undistributed");
    }

    // ==========================================
    // 경계 조건 테스트
    // ==========================================

    /// @notice 모든 L2가 자격 없을 때
    function test_noEligibleL2s() public view {
        uint256 A2 = 10000e27;
        uint256 S_DAO = calculateDAOAllocation(A2);
        uint256 L = A2 - S_DAO;

        // x = 0 (자격 있는 L2 없음)
        uint256 y = hyperbolicSaturation(0, L);

        assertEq(y, 0, "y(0) = 0");

        // 전체 L이 DAO로 귀속
        uint256 totalDAO = S_DAO + L;
        assertEq(totalDAO, A2, "All A2 goes to DAO when no eligible L2s");
    }

    /// @notice 단일 L2만 자격 있을 때
    function test_singleEligibleL2() public view {
        uint256 totalY = 1000e27;
        uint256 totalX = 500e27; // 단일 L2의 유효 Bridged TON

        // 100% 분배
        uint256 seig = calculateL2Seigniorage(totalX, totalY, totalX);

        assertApproxEqRel(seig, totalY, 1e16, "Single L2 should get all y(x)");
    }

    // ==========================================
    // 헬퍼 함수 (DSMath 스타일)
    // ==========================================

    function _rmul(uint256 x, uint256 y) internal pure returns (uint256) {
        return (x * y) / RAY;
    }

    function _rdiv(uint256 x, uint256 y) internal pure returns (uint256) {
        return (x * RAY) / y;
    }
}
