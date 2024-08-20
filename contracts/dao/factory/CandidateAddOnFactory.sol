// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import { CandidateAddOnProxy } from "../CandidateAddOnProxy.sol";

import "../../proxy/ProxyStorage.sol";
import { AccessibleCommon } from "../../common/AccessibleCommon.sol";
import "./CandidateAddOnFactoryStorage.sol";
interface ICandidateAddOn {
    function initialize(
        address _candidate,
        string memory _memo,
        address _committee,
        address _seigManager,
        address _ton,
        address _wton
    ) external;
}

interface IOnDemandL1BridgeRegistry {
    function exists(address _rollupConfig) external view returns (bool);
}

contract CandidateAddOnFactory is ProxyStorage, AccessibleCommon, CandidateAddOnFactoryStorage {

    /**
     * @notice  Event that occurs when a Candidate is created
     * @param sender            the sender address
     * @param layer2            the candidate address
     * @param operator          the operator/operatorManager address
     * @param isLayer2Candidate whether it is Layer2Candidate
     * @param name              the name of Layer2
     * @param committee         the committee address
     * @param seigManager       the seigManager address
     */
    event DeployedCandidate(
        address sender,
        address layer2,
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
        address _candidateAddOnImp,
        address _ton,
        address _wton,
        address _onDemandL1BridgeRegistry
    ) external onlyOwner {
        require(
            _ton != address(0) && _wton != address(0) &&
            _depositManager != address(0) && _daoCommittee != address(0) && _candidateAddOnImp != address(0)
            && _onDemandL1BridgeRegistry != address(0) , "zero");

        require(
            ton != _ton || wton != _wton ||
            depositManager != _depositManager || daoCommittee != _daoCommittee || candidateAddOnImp != _candidateAddOnImp
            || onDemandL1BridgeRegistry != _onDemandL1BridgeRegistry , "same");

        depositManager = _depositManager;
        daoCommittee = _daoCommittee;
        candidateAddOnImp = _candidateAddOnImp;
        ton = _ton;
        wton = _wton;

        onDemandL1BridgeRegistry = _onDemandL1BridgeRegistry;
    }

    /**
     * @notice Deploy the candidate contract
     * @param _sender       the sender address
     * @param _name         the name of layer2
     * @param _committee    the committee address
     * @param _seigManager  the seigManager address
     * @return              the created candidate address
     */
    function deploy(
        address _sender,
        string memory _name,
        address _committee,
        address _seigManager
    )
        public onlyDAOCommittee
        returns (address)
    {
        require(daoCommittee == _committee, "different daoCommittee");
        CandidateAddOnProxy c = new CandidateAddOnProxy();
        require(address(c) != address(0), "zero CandidateAddOnProxy");

        c.upgradeTo(candidateAddOnImp);
        ICandidateAddOn(address(c)).initialize(
            _sender,
            _name,
            _committee,
            _seigManager,
            ton,
            wton
        );
        c.transferAdmin(_committee);
        emit DeployedCandidate(
            _sender,
            address(c),
            _sender,
            true,
            _name,
            _committee,
            _seigManager
        );
        return address(c);
    }

}
