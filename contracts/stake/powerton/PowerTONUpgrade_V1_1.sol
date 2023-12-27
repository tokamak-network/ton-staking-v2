// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";

import "../interfaces/IPowerTONSwapperEvent.sol";
// import "../interfaces/IAutoCoinageSnapshot.sol";
// import {ILockTOSDividend} from "../interfaces/ILockTOSDividend.sol";

import "../../common/AccessiblePowerTon.sol";
import "./PowerTONSwapperStorage.sol";
import {PowerTONHammerDAOStorage} from "./PowerTONHammerDAOStorage.sol";
import {PowerTON_V1_1_Storage} from "./PowerTON_V1_1_Storage.sol";

interface L2PowerTonI {
    function distributesTon(
        address l1Tokne,
        address l2Token,
        uint256 amount
    ) external;
}

interface IWTON {
    function balanceOf(address account) external view returns (uint256);
    function swapToTON(uint256 wtonAmount) external returns (bool);
    function approve(address spender, uint256 amount) external returns (bool);
    function allowance(address sender, address recipient) external returns (uint256);
}

interface L1BridgeI {
    function depositERC20To(
        address _l1Token,
        address _l2Token,
        address _to,
        uint256 _amount,
        uint32 _l2Gas,
        bytes calldata _data
    ) external;
}

interface L1CrossDomainMessengerI {
    function sendMessage(
        address _target,
        bytes memory _message,
        uint32 _gasLimit
    ) external;
}

contract PowerTONUpgrade_V1_1 is
    PowerTONSwapperStorage,
    AccessiblePowerTon,
    IPowerTONSwapperEvent,
    PowerTONHammerDAOStorage,
    PowerTON_V1_1_Storage
{

    event DistributedToL2(address l1Token, address l2Token, uint256 amount);

    function setAutocoinageSnapshot(address _autocoinageSnapshot)
        external
        onlyOwner
    {
        autocoinageSnapshot = _autocoinageSnapshot;
    }

    function setSeigManager(address _seigManager)
        external
        onlyOwner
    {
        seigManager = _seigManager;
    }

    function setAddresses(
        address _l1CrossDomainMessage,
        address _l1Bridge,
        address _ton,
        address _l2PowerTon,
        address _l2Ton,
        uint32 _depositMinGasLimit,
        uint32 _sendMsgMinGasLimit
        )
        external
        onlyOwner
    {
        l1CrossDomainMessage = _l1CrossDomainMessage;
        l1Bridge = _l1Bridge;
        ton = _ton;
        l2PowerTon = _l2PowerTon;
        l2Ton = _l2Ton;
        depositMinGasLimit = _depositMinGasLimit;
        sendMsgMinGasLimit = _sendMsgMinGasLimit;
    }

    /// @notice PowerTON으로 쌓인 WTON 전체를 LockTOSDividendProxy 컨트랙트에 위임
    function approveToDividendPool() private {
        IERC20(wton).approve(address(dividiedPool), type(uint256).max);
    }

    /// @notice LockTOSDividendProxy 컨트랙트를 사용해서 WTON을 sTOS 홀더에게 에어드랍
    // function distribute() external {
    //     uint256 wtonBalance = getWTONBalance();
    //     require(wtonBalance > 0, "balance of WTON is 0");

    //     // WTON 잔고보다 allowance가 낮으면 최대 값으로 위임 재설정
    //     if (
    //         wtonBalance >
    //         IERC20(wton).allowance(address(this), address(dividiedPool))
    //     ) {
    //         approveToDividendPool();
    //     }

    //     dividiedPool.distribute(wton, wtonBalance);
    //     emit Distributed(wton, wtonBalance);
    // }

    function distribute() external {
        _distributeToL2();
    }

    function getWTONBalance() public view returns (uint256) {
        return IERC20(wton).balanceOf(address(this));
    }

    function onDeposit(
        address layer2,
        address account,
        uint256 amount
    ) external  {

    }

    function onWithdraw(
        address layer2,
        address account,
        uint256 amount
    ) external  {

    }

    function updateSeigniorage(
        uint256 amount
    ) external  {

    }

    /* ========= internal ========== */
    function _distributeToL2() internal {

        _unwrap();
        uint256 balanceTon = IERC20(ton).balanceOf(address(this));

        if (balanceTon > 1 ether) {
            bytes memory  callData = abi.encodeWithSelector(
                    L2PowerTonI.distributesTon.selector,
                    ton,
                    l2Ton,
                    balanceTon
                ) ;

            _depositL1TokenToL2(l1Bridge, ton, l2Ton, l2PowerTon, balanceTon, depositMinGasLimit, bytes(''));

            L1CrossDomainMessengerI(l1CrossDomainMessage).sendMessage(
                l2PowerTon,
                callData,
                sendMsgMinGasLimit
            );

            emit DistributedToL2(ton, l2Ton, balanceTon);
        }
    }

    function _unwrap() internal {
        uint256 amount = IERC20(wton).balanceOf(address(this));
        if (amount > 1e9) IWTON(wton).swapToTON(amount);
    }

    function _depositL1TokenToL2(
        address l1Bridge, address l1Token, address l2Token, address depositTo,
        uint256 amount, uint32 _minGasLimit, bytes memory data)
        internal
    {
        uint256 allowance = IERC20(l1Token).allowance(address(this), l1Bridge);
        if (allowance < amount) IERC20(l1Token).approve(l1Bridge, type(uint256).max);
        L1BridgeI(l1Bridge).depositERC20To(
            l1Token,
            l2Token,
            depositTo,
            amount,
            _minGasLimit,
            data
        );
    }

}