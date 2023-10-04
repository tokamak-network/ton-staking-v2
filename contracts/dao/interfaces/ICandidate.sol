// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

interface ICandidate {
    function setSeigManager(address _seigMan) external;
    function setCommittee(address _committee) external;
    function updateSeigniorage() external returns (bool);
    function changeMember(uint256 _memberIndex) external returns (bool);
    function retireMember() external returns (bool);
    function castVote(uint256 _agendaID, uint256 _vote, string calldata _comment) external;
    function isCandidateContract() external view returns (bool);
    function totalStaked() external view returns (uint256 totalsupply);
    function stakedOf(address _account) external view returns (uint256 amount);
    function setMemo(string calldata _memo) external;
    function claimActivityReward() external;

    // getter
    function candidate() external view returns (address);
    function isLayer2Candidate() external view returns (bool);
    function memo() external view returns (string memory);
    function committee() external view returns (address);
    function seigManager() external view returns (address);
}
