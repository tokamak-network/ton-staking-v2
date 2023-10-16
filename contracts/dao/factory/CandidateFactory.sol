// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import { CandidateProxy } from "../CandidateProxy.sol";

import "../../proxy/ProxyStorage.sol";
import { AccessibleCommon } from "../../common/AccessibleCommon.sol";
import "./CandidateFactoryStorage.sol";
// import "hardhat/console.sol";

interface ICandidate {
    function initialize(
        address _candidate,
        bool _isLayer2Candidate,
        string memory _memo,
        address _committee,
        address _seigManager
    ) external;
}

contract CandidateFactory is ProxyStorage, AccessibleCommon, CandidateFactoryStorage {

    event DeployedCandidate(
        address sender,
        address layer2,
        address operator,
        bool isLayer2Candidate,
        string name,
        address committee,
        address seigManager
    );

    function setAddress(
        address _depositManager,
        address _daoCommittee,
        address _candidateImp,
        address _ton,
        address _wton
    ) external onlyOwner {
        require(
            _ton != address(0) && _wton != address(0) &&
            _depositManager != address(0) && _daoCommittee != address(0) && _candidateImp != address(0)  , "zero");

        require(
            ton != _ton || wton != _wton ||
            depositManager != _depositManager || daoCommittee != _daoCommittee || candidateImp != _candidateImp  , "same");

        depositManager = _depositManager;
        daoCommittee = _daoCommittee;
        candidateImp = _candidateImp;
        ton = _ton;
        wton = _wton;
    }

    function deploy(
        address _sender,
        bool _isLayer2Candidate,
        string memory _name,
        address _committee,
        address _seigManager
    )
        public
        returns (address)
    {
        require(msg.sender == daoCommittee, "sender is not daoCommittee");
        // require(daoCommittee == _committee, "different daoCommittee");
        CandidateProxy c = new CandidateProxy();
        require(address(c) != address(0), "zero CandidateFwProxy");

        c.upgradeTo(candidateImp);

        ICandidate(address(c)).initialize(
            _sender,
            _isLayer2Candidate,
            _name,
            _committee,
            _seigManager
        );

        c.transferAdmin(_committee);

        emit DeployedCandidate(
            _sender,
            address(c),
            _sender,
            _isLayer2Candidate,
            _name,
            _committee,
            _seigManager
        );
        return address(c);
    }

}
