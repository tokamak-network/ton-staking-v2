// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";

import {iPowerTON} from "../interfaces/iPowerTON.sol";
import "../interfaces/IPowerTONSwapperEvent.sol";

import "../interfaces/IIERC20.sol";
import "../interfaces/IAutoCoinageSnapshot.sol";

import "../../common/AccessiblePowerTon.sol";
import "./PowerTONSwapperStorage.sol";

import {PowerTONHammerDAOStorage} from "./PowerTONHammerDAOStorage.sol";
import {ILockTOSDividend} from "../interfaces/ILockTOSDividend.sol";

contract PowerTONHammerDAO is
    PowerTONSwapperStorage,
    AccessiblePowerTon,
    iPowerTON,
    IPowerTONSwapperEvent,
    PowerTONHammerDAOStorage
{
    modifier onlySeigManagerOrOwner() {
        require(
            isAdmin(msg.sender) || msg.sender == seigManager,
            "PowerTONHammerDAO: sender is not seigManager or not admin"
        );
        _;
    }

    event OnChangeAmountInRecoder(
        address indexed account,
        uint256 amountToMint,
        uint256 amountToBurn
    );

    constructor() {}

    function setInfo(
        address _wton,
        address _autocoinageSnapshot,
        address _seigManager,
        address _dividiedPool
    ) external onlyOwner {
        wton = _wton;
        autocoinageSnapshot = _autocoinageSnapshot;
        seigManager = _seigManager;
        dividiedPool = ILockTOSDividend(_dividiedPool);
    }

    function setAutocoinageSnapshot(address _autocoinageSnapshot)
        external
        onlyOwner
    {
        autocoinageSnapshot = _autocoinageSnapshot;
    }

    /// @dev 업그레이드 이후 사용되지 않는 함수
    function approveToUniswap() external {}

    /// @notice PowerTON으로 쌓인 WTON 전체를 LockTOSDividendProxy 컨트랙트에 위임
    function approveToDividendPool() private {
        IERC20(wton).approve(address(dividiedPool), type(uint256).max);
    }

    /// @notice LockTOSDividendProxy 컨트랙트를 사용해서 WTON을 sTOS 홀더에게 에어드랍
    function distribute() external {
        uint256 wtonBalance = getWTONBalance();
        require(wtonBalance > 0, "balance of WTON is 0");

        // WTON 잔고보다 allowance가 낮으면 최대 값으로 위임 재설정
        if (
            wtonBalance >
            IERC20(wton).allowance(address(this), address(dividiedPool))
        ) {
            approveToDividendPool();
        }

        dividiedPool.distribute(wton, wtonBalance);
        emit Distributed(wton, wtonBalance);
    }

    function getWTONBalance() public view returns (uint256) {
        return IERC20(wton).balanceOf(address(this));
    }

    /// @dev 업그레이드 이후 사용되지 않는 함수
    function currentRound() external pure override returns (uint256) {
        return 0;
    }

    /// @dev 업그레이드 이후 사용되지 않는 함수
    function roundDuration() external pure override returns (uint256) {
        return 0;
    }

    /// @dev 업그레이드 이후 사용되지 않는 함수
    function totalDeposits() external pure override returns (uint256) {
        return 0;
    }

    /// @dev 업그레이드 이후 사용되지 않는 함수
    function winnerOf(uint256 round) external pure override returns (address) {
        return address(0);
    }

    /// @dev 업그레이드 이후 사용되지 않는 함수
    function powerOf(address account) external pure override returns (uint256) {
        return 0;
    }

    /// @dev 업그레이드 이후 사용되지 않는 함수
    function init() external override {}

    /// @dev 업그레이드 이후 사용되지 않는 함수
    function start() external override {}

    /// @dev 업그레이드 이후 사용되지 않는 함수
    function endRound() external override {}

    function onDeposit(
        address layer2,
        address account,
        uint256 amount
    ) external override onlySeigManagerOrOwner {
        IAutoCoinageSnapshot(autocoinageSnapshot).addSync(layer2, account);
        //emit OnDeposit(layer2, account, amount);
    }

    function onWithdraw(
        address layer2,
        address account,
        uint256 amount
    ) external override onlySeigManagerOrOwner {
        IAutoCoinageSnapshot(autocoinageSnapshot).addSync(layer2, account);
        //emit OnWithdraw(layer2, account, amount);
    }
}