// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "../../proxy/ProxyStorage.sol";
import { AccessibleCommon } from "../../common/AccessibleCommon.sol";
import { L2DividendPoolForTonStorage } from "./L2DividendPoolForTonStorage.sol";
import "@openzeppelin/contracts/utils/math/Math.sol";

import "../../libraries/LibDividend.sol";

import {IERC20} from "../../interfaces/IERC20.sol";
import "../../libraries/SafeERC20.sol";

// import "hardhat/console.sol";

interface IL2SeigManager {

    function onSnapshot() external returns (uint256 snapshotId);
    function balanceOfAt(address account, uint256 snapshotId) external view returns (uint256 amount);
    function totalSupplyAt(uint256 snapshotId) external view returns (uint256 amount);
    function totalSupply() external view returns (uint256 amount);
}

contract L2DividendPoolForTon is ProxyStorage, AccessibleCommon, L2DividendPoolForTonStorage {
    using SafeERC20 for IERC20;

    event Claimed(address indexed token, address indexed account, uint256 snapshotId, uint256 amount);
    event Distributed(address indexed token, uint256 snapshotId, uint256 amount);

    modifier ifFree {
        require(!free, "already in use");
        free = true;
        _;
        free = false;
    }

    modifier nonZero(uint256 value) {
        require(value != 0, "zero value");
        _;
    }

    modifier nonZeroAddress(address addr) {
        require(addr != address(0), "zero address");
        _;
    }

    /* ========== onlyOwner ========== */

    function initialize(address _l2SeigManager) external onlyOwner {
        l2SeigManager = _l2SeigManager;
    }

    /* ========== external  ========== */

    function distribute(address _token, uint256 _amount)
        external nonZero(_amount) nonZeroAddress(_token) ifFree
    {
        uint256 total = IL2SeigManager(l2SeigManager).totalSupply();
        require(total != 0, "no registered L1's staking ton");

        LibDividend.Distribution storage distr = distributions[_token];
        if (distr.exists == false) distributedTokens.push(_token);
        distr.exists = true;

        IERC20(_token).safeTransferFrom(msg.sender, address(this), _amount);

        uint256 snapshotId_ = IL2SeigManager(l2SeigManager).onSnapshot();
        require(snapshotId_ != 0, 'zero snapshotId');
        require(tokensPerSnapshotId[_token][snapshotId_] == 0, 'used snapshotId');

        snapshotIds[_token].push(snapshotId_);

        distr.lastBalance = IERC20(_token).balanceOf(address(this));
        distr.totalDistribution += _amount;
        tokensPerSnapshotId[_token][snapshotId_] = _amount;

        emit Distributed(_token, snapshotId_, _amount);
    }

    function claimBatch(address[] calldata _tokens) external {
        for (uint i = 0; i < _tokens.length; ++i) {
            claim(_tokens[i]);
        }
    }

    function claim(address _token) public {
        claimUpTo(_token, snapshotIds[_token][snapshotIds[_token].length-1]);
    }

    function claimUpTo(address _token, uint256 _snapshotId) public nonZero(_snapshotId) {

        require(snapshotIds[_token].length != 0, "no distribution");
        uint256 snapshotId = _snapshotId;
        uint256 len = snapshotIds[_token].length;
        if (_snapshotId > snapshotIds[_token][len-1]) snapshotId = snapshotIds[_token][len-1];

        uint256 amountToClaim = claimableForSnapshotIds(
                _token,
                msg.sender,
                claimStartSnapshotId[_token][msg.sender],
                snapshotId);

        require(amountToClaim > 0, "no claimable amlount");
        LibDividend.Distribution storage distr = distributions[_token];
        require(distr.lastBalance >= amountToClaim, "insufficient balance");
        claimStartSnapshotId[_token][msg.sender] = snapshotId + 1;
        distr.lastBalance -= amountToClaim;

        IERC20(_token).safeTransfer(msg.sender, amountToClaim);
        emit Claimed(_token, msg.sender, snapshotId, amountToClaim);
    }

    /* ========== public  ========== */

    function getAvailableClaims(address _account)
        external view returns (address[] memory tokens, uint256[] memory claimableAmounts)
    {
        uint256[] memory amounts = new uint256[](distributedTokens.length);

        for (uint256 i = 0; i < distributedTokens.length; ++i) {
            amounts[i] = claimable(_account, distributedTokens[i]);
        }

        return (distributedTokens, amounts);
    }

    function claimable(address _token, address _account) public view returns (uint256) {
        uint256 len = snapshotIds[_token].length;
        if (len == 0) return 0;

        uint256 endSnapshotId = snapshotIds[_token][len-1];
        uint256 startSnapshotId = claimStartSnapshotId[_token][_account];
        return claimableForSnapshotIds(_token, _account, startSnapshotId, endSnapshotId);
    }

    function calculateClaimPerSnapshotId(
        address _account,
        uint256 _snapshotId,
        uint256 _tokensPerSnapshotId
    ) public view returns (uint256) {
        uint256 balance = IL2SeigManager(l2SeigManager).balanceOfAt(_account, _snapshotId);
        uint256 supply = IL2SeigManager(l2SeigManager).totalSupplyAt(_snapshotId);
        if (balance == 0 || supply == 0) return 0;
        return (_tokensPerSnapshotId * balance / supply);
    }

    /* ========== internal  ========== */

    function claimableForSnapshotIds(
        address _token,
        address _account,
        uint256 startSnapshotId,
        uint256 endSnapshotId
    ) internal view returns (uint256 amountToClaim) {
        if (startSnapshotId > endSnapshotId) return 0;
        if (startSnapshotId == 0) startSnapshotId = 1;
        uint256 epochIterator = startSnapshotId;
        while (epochIterator <= endSnapshotId) {
            if (tokensPerSnapshotId[_token][epochIterator] != 0) {
                amountToClaim += calculateClaimPerSnapshotId(
                    _account,
                    epochIterator,
                    tokensPerSnapshotId[_token][epochIterator]);
            }
            epochIterator++;
        }
    }

}
