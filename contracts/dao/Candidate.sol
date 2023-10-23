// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "@openzeppelin/contracts/access/Ownable.sol";
import { IDAOCommittee } from "./interfaces/IDAOCommittee.sol";
import { IERC20 } from  "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import { ICandidate } from "./interfaces/ICandidate.sol";
import { ILayer2 } from "./interfaces/ILayer2.sol";
import { ILayer2Registry } from "./interfaces/ILayer2Registry.sol";

import "../proxy/ProxyStorage.sol";
import { AccessibleCommon } from "../common/AccessibleCommon.sol";
import "./CandidateStorage.sol";

import "hardhat/console.sol";

interface ICoinage {
  function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);
}

interface IOperator {
  function setWithdrawalDelay(uint256 withdrawalDelay_) external;
}

interface IISeigManager {
  function updateSeigniorage() external returns (bool);
  function coinages(address layer2) external view returns (address);
}
/// @title Managing a candidate
/// @notice Either a user or layer2 contract can be a candidate
contract Candidate is ProxyStorage, AccessibleCommon, CandidateStorage, ILayer2 {

    event TransferCoinage(address from, address to, uint256 amount);

    modifier onlyCandidate() {
        if (isLayer2Candidate) {
            ILayer2 layer2 = ILayer2(candidate);
            require(layer2.operator() == msg.sender, "Candidate: sender is not the operator of this contract");
        } else {
            require(candidate == msg.sender, "Candidate: sender is not the candidate of this contract");
        }
        _;
    }

    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
        return  _supportedInterfaces[interfaceId] || super.supportsInterface(interfaceId) ;
    }

    // function _registerInterface(bytes4 interfaceId) internal virtual {
    //     require(interfaceId != 0xffffffff, "ERC165: invalid interface id");
    //     _supportedInterfaces[interfaceId] = true;
    // }

    function initialize(
        address _candidate,
        bool _isLayer2Candidate,
        string memory _memo,
        address _committee,
        address _seigManager
    ) external onlyOwner  {
        require(
            _candidate != address(0)
            || _committee != address(0)
            || _seigManager != address(0),
            "Candidate: input is zero"
        );
        if (_isLayer2Candidate) {
            require(
                ILayer2(_candidate).isLayer2(),
                "Candidate: invalid layer2 contract"
            );
        }
        candidate = _candidate;
        isLayer2Candidate = _isLayer2Candidate;
        committee = _committee;
        seigManager = _seigManager;
        memo = _memo;
        
        _registerInterface(ICandidate(address(this)).isCandidateContract.selector);
    }

    function setSeigManager(address _seigManager) external onlyOwner {
        require(_seigManager != address(0), "Candidate: input is zero");
        seigManager = _seigManager;
    }

    /// @notice Set DAOCommitteeProxy contract address
    /// @param _committee New DAOCommitteeProxy contract address
    function setCommittee(address _committee) external onlyOwner {
        require(_committee != address(0), "Candidate: input is zero");
        committee = _committee;
    }

    /// @notice Set memo
    /// @param _memo New memo on this candidate
    function setMemo(string calldata _memo) external onlyOwner {
        memo = _memo;
    }

    /// @notice Set DAOCommitteeProxy contract address
    /// @notice Call updateSeigniorage on SeigManager
    /// @return Whether or not the execution succeeded
    function updateSeigniorage() external returns (bool) {
        require(seigManager != address(0), "Candidate: SeigManager is zero");
        require(
            !isLayer2Candidate,
            "Candidate: you should update seigniorage from layer2 contract"
        );
        console.log("candidateContract in");
        require(IISeigManager(seigManager).updateSeigniorage(), "fail updateSeigniorage");
        console.log("candidateContract finish");
        return true;
    }

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
        address receiver;

        if (isLayer2Candidate) {
            ILayer2 layer2 = ILayer2(candidate);
            receiver = layer2.operator();
        } else {
            receiver = candidate;
        }
        IDAOCommittee(committee).claimActivityReward(receiver);
    }

    /// @notice Checks whether this contract is a candidate contract
    /// @return Whether or not this contract is a candidate contract
    function isCandidateContract() external pure returns (bool) {
        return true;
    }

    function isCandidateFwContract() external pure returns (bool) {
        return true;
    }

    function operator() external view override returns (address) { return candidate; }
    function isLayer2() external pure override returns (bool) { return true; }
    function currentFork() external pure override returns (uint256) { return 1; }
    function lastEpoch(uint256 forkNumber) external pure override returns (uint256) { return 1; }
    function changeOperator(address _operator) external override { }

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

    function _getCoinageToken() internal view returns (IERC20) {
        address c;
        if (isLayer2Candidate) {
            c = candidate;
        } else {
            c = address(this);
        }

        require(c != address(0), "Candidate: coinage is zero");

        return IERC20(IISeigManager(seigManager).coinages(c));
    }

}
