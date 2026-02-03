// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import { LotteryCandidateProxy } from "../LotteryCandidateProxy.sol";
import "../../proxy/ProxyStorage.sol";
import { AccessibleCommon } from "../../common/AccessibleCommon.sol";
import "./LotteryCandidateFactoryStorage.sol";

interface ILotteryCandidate {
    function initialize(
        address _candidate,
        bool _isLayer2Candidate,
        string memory _memo,
        address _committee,
        address _seigManager,
        address _depositManager,
        address _ton,
        address _wton,
        uint256 _initialEntryFee
    ) external;
}

contract LotteryCandidateFactory is ProxyStorage, AccessibleCommon, LotteryCandidateFactoryStorage {
    event DeployedLotteryCandidate(
        address sender,
        address candidateContract,
        address operator,
        bool isLayer2Candidate,
        string name,
        address committee,
        address seigManager
    );

    modifier onlyDAOCommittee() {
        require(msg.sender == daoCommittee, "sender is not daoCommittee");
        _;
    }

    function setAddress(
        address _depositManager,
        address _daoCommittee,
        address _lotteryCandidateImp,
        address _ton,
        address _wton
    ) external onlyOwner {
        require(
            _ton != address(0) && _wton != address(0) &&
            _depositManager != address(0) && _daoCommittee != address(0) && _lotteryCandidateImp != address(0),
            "zero"
        );

        require(
            ton != _ton || wton != _wton ||
            depositManager != _depositManager || daoCommittee != _daoCommittee || lotteryCandidateImp != _lotteryCandidateImp,
            "same"
        );

        depositManager = _depositManager;
        daoCommittee = _daoCommittee;
        lotteryCandidateImp = _lotteryCandidateImp;
        ton = _ton;
        wton = _wton;
    }

    function setDefaultEntryFee(uint256 _defaultEntryFee) external onlyOwner {
        defaultEntryFee = _defaultEntryFee;
    }

    function deploy(
        address _sender,
        bool _isLayer2Candidate,
        string memory _name,
        address _committee,
        address _seigManager
    )
        public
        onlyDAOCommittee
        returns (address)
    {
        require(daoCommittee == _committee, "different daoCommittee");
        LotteryCandidateProxy c = new LotteryCandidateProxy();
        require(address(c) != address(0), "zero LotteryCandidateProxy");

        c.upgradeTo(lotteryCandidateImp);

        ILotteryCandidate(address(c)).initialize(
            _sender,
            _isLayer2Candidate,
            _name,
            _committee,
            _seigManager,
            depositManager,
            ton,
            wton,
            defaultEntryFee
        );

        c.transferAdmin(_committee);

        emit DeployedLotteryCandidate(
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
