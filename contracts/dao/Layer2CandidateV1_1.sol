// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "../proxy/ProxyStorage.sol";
import { AccessibleCommon } from "../common/AccessibleCommon.sol";
import "./CandidateStorage.sol";
import "./Layer2CandidateStorage.sol";
import { ICandidate } from "./interfaces/ICandidate.sol";
import { IERC20 } from  "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import { IDAOCommittee } from "./interfaces/IDAOCommittee.sol";

interface IOperateContract {
    function isOperator(address addr) external view returns (bool) ;
    function systemConfig() external view returns (address) ;
}

interface IISeigManager {
  function updateSeigniorage() external returns (bool);
  function coinages(address layer2) external view returns (address);
}

/// @title Managing a Layer2Candidate
contract Layer2CandidateV1_1 is
    ProxyStorage, AccessibleCommon, CandidateStorage, Layer2CandidateStorage
{
    modifier onlyCandidate() {
        require(IOperateContract(candidate).isOperator(msg.sender),
        "sender is not an admin of OperatorContract");
        _;
    }

    /* ========== onlyOwner ========== */
    function initialize(
        address _operateContract,
        string memory _memo,
        address _committee,
        address _seigManager
    ) external onlyOwner  {
        require(
            _operateContract != address(0)
            || _committee != address(0)
            || _seigManager != address(0),
            "Candidate: input is zero"
        );

        require(IOperateContract(_operateContract).systemConfig() != address(0), 'zero systemConfig');

        candidate = _operateContract;
        isLayer2Candidate = true;
        committee = _committee;
        seigManager = _seigManager;
        memo = _memo;

        _registerInterface(ICandidate(address(this)).isCandidateContract.selector);
    }

    /// @notice Set memo
    /// @param _memo New memo on this candidate
    function setMemo(string calldata _memo) external onlyOwner {
        memo = _memo;
    }


    /* ========== onlyCandidate ========== */

    /// @notice Try to be a member
    /// @param _memberIndex The index of changing member slot
    /// @return Whether or not the execution succeeded
    function changeMember(uint256 _memberIndex)
        external
        onlyCandidate
        returns (bool)
    {
        return IDAOCommittee(committee).changeMember(_memberIndex);
    }

    /// @notice Retire a member
    /// @return Whether or not the execution succeeded
    function retireMember() external onlyCandidate returns (bool) {
        return IDAOCommittee(committee).retireMember();
    }

    /// @notice Vote on an agenda
    /// @param _agendaID The agenda ID
    /// @param _vote voting type
    /// @param _comment voting comment
    function castVote(
        uint256 _agendaID,
        uint256 _vote,
        string calldata _comment
    )
        external
        onlyCandidate
    {
        IDAOCommittee(committee).castVote(_agendaID, _vote, _comment);
    }

    function claimActivityReward()
        external
        onlyCandidate
    {
        IDAOCommittee(committee).claimActivityReward(candidate);
    }


    /* ========== Anybody ========== */

    /// @notice Set DAOCommitteeProxy contract address
    /// @notice Call updateSeigniorage on SeigManager
    /// @return Whether or not the execution succeeded
    function updateSeigniorage() external returns (bool) {
        require(seigManager != address(0), "Candidate: SeigManager is zero");
        require(IISeigManager(seigManager).updateSeigniorage(), "fail updateSeigniorage");
        return true;
    }


    /* ========== view ========== */

    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
        return  _supportedInterfaces[interfaceId] || super.supportsInterface(interfaceId) ;
    }

    /// @notice Retrieves the total staked balance on this candidate
    /// @return totalsupply Total staked amount on this candidate
    function totalStaked()
        external
        view
        returns (uint256 totalsupply)
    {
        IERC20 coinage = _getCoinageToken();
        return coinage.totalSupply();
    }

    /// @notice Retrieves the staked balance of the account on this candidate
    /// @param _account Address being retrieved
    /// @return amount The staked balance of the account on this candidate
    function stakedOf(
        address _account
    )
        external
        view
        returns (uint256 amount)
    {
        IERC20 coinage = _getCoinageToken();
        return coinage.balanceOf(_account);
    }


    /// @notice Checks whether this contract is a candidate contract
    /// @return Whether or not this contract is a candidate contract
    function isCandidateContract() external pure returns (bool) {
        return true;
    }

    function isCandidateFwContract() external pure returns (bool) {
        return true;
    }

    /// operateContract
    function operator() external view returns (address) { return candidate; }
    function isLayer2() external pure returns (bool) { return true; }
    function currentFork() external pure returns (uint256) { return 1; }
    function lastEpoch(uint256 forkNumber) external pure returns (uint256) { return 1; }

    /* ========== internal ========== */

    function _getCoinageToken() internal view returns (IERC20) {
        return IERC20(IISeigManager(seigManager).coinages(address(this)));
    }
}
