// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import { Layer2CandidateProxy } from "../Layer2CandidateProxy.sol";

import "../../proxy/ProxyStorage.sol";
import { AccessibleCommon } from "../../common/AccessibleCommon.sol";
import "./Layer2CandidateFactoryStorage.sol";

interface ILayer2Candidate {
    function initialize(
        address _candidate,
        bool _isLayer2Candidate,
        string memory _memo,
        address _committee,
        address _seigManager
    ) external;
}

interface IOnDemandL2Registry {
    function exists(address _systemConfig) external view returns (bool);
}

contract Layer2CandidateFactory is ProxyStorage, AccessibleCommon, Layer2CandidateFactoryStorage {

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
        address _layer2CandidateImp,
        address _ton,
        address _wton,
        address _onDemandL2Registry
    ) external onlyOwner {
        require(
            _ton != address(0) && _wton != address(0) &&
            _depositManager != address(0) && _daoCommittee != address(0) && _layer2CandidateImp != address(0)
            && _onDemandL2Registry != address(0) , "zero");

        require(
            ton != _ton || wton != _wton ||
            depositManager != _depositManager || daoCommittee != _daoCommittee || layer2CandidateImp != _layer2CandidateImp
            || onDemandL2Registry != _onDemandL2Registry , "same");

        depositManager = _depositManager;
        daoCommittee = _daoCommittee;
        layer2CandidateImp = _layer2CandidateImp;
        ton = _ton;
        wton = _wton;

        onDemandL2Registry = _onDemandL2Registry;
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
        require(daoCommittee == _committee, "different daoCommittee");
        Layer2CandidateProxy c = new Layer2CandidateProxy();
        require(address(c) != address(0), "zero Layer2CandidateProxy");

        c.upgradeTo(layer2CandidateImp);

        ILayer2Candidate(address(c)).initialize(
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
