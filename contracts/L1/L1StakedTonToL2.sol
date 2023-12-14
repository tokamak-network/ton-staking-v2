// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import { LibL1StakedInfo } from "../libraries/LibL1StakedInfo.sol";
import { IRefactor } from "../stake/interfaces/IRefactor.sol";
import { AccessibleCommon } from "../common/AccessibleCommon.sol";
import "../proxy/ProxyStorage.sol";
import "./L1StakedTonToL2Storage.sol";
import "hardhat/console.sol";

interface AddressManagerI {
    function getAddress(string memory _name) external view returns (address);
}

interface IRegistry {
    function numLayer2s() external view returns (uint256);
    function layer2ByIndex(uint256 index) external view returns (address);
    function layer2s(address layer2) external view returns (bool);
}

interface ISeigManager {
    function coinages(address layer2) external view returns (address);
    function stakeOf(address layer2, address account) external view returns (uint256);
}

interface IRefactorCoinage {
    function getTotalAndFactor() external view returns (IRefactor.Balance memory, IRefactor.Factor memory) ;
    function getBalanceAndFactor(address account) external view returns (IRefactor.Balance memory, IRefactor.Factor memory);
}

interface IL1StakedTonInL2 {
    function register(bytes memory data) external ;
    function deposit(address layer2, address account, uint256 swton) external ;
    function withdraw(address layer2, address account, uint256 swton) external ;
    function rebaseIndex(address layer2, uint256 sharePerRay) external ;
}

interface L1CrossDomainMessengerI {
    function sendMessage(
        address _target,
        bytes memory _message,
        uint32 _gasLimit
    ) external;
}

contract L1StakedTonToL2 is ProxyStorage, AccessibleCommon, L1StakedTonToL2Storage {

    event Registered(address account, bytes syncPacket) ;
    event Deposited(address layer, address account, uint256 amount) ;
    event Withdrawal(address layer, address account, uint256 amount) ;
    event Initialized(
        address manager_,
        address seigManager_,
        address registry_,
        address addressManager_,
        uint32 minGasLimit_
    );

    modifier onlySeigManager() {
        require(seigManager == msg.sender, "not seigManager");
        _;
    }

    /* ========== CONSTRUCTOR ========== */
    constructor () {

    }

    function initialize (
        address manager_,
        address seigManager_,
        address registry_,
        address addressManager_,
        uint32 minGasLimit_
    ) external onlyOwner {
        manager = manager_;
        seigManager = seigManager_;
        registry = registry_;
        addressManager = addressManager_;
        minGasLimit = minGasLimit_;
        emit Initialized(manager_, seigManager_, registry_, addressManager_, minGasLimit_);
    }

    function setSeigManger(address seigManager_) external onlyOwner {
        require(seigManager != seigManager_, "same");
        seigManager = seigManager_;
    }

    function setAddressManager(address addressManagerAddress_) external onlyOwner {
        require(addressManager != addressManagerAddress_, "same");
        addressManager = addressManagerAddress_;
    }

    function setL1StakedTonInL2(address l1StakedTonInL2_) external onlyOwner {
        require(l1StakedTonInL2 != l1StakedTonInL2_, "same");
        l1StakedTonInL2 = l1StakedTonInL2_;
    }

    /* ========== onlyManager ========== */

    function setMinGasLimit(uint32 minGasLimit_) external onlyManager {
        require(minGasLimit != minGasLimit_, "same");
        minGasLimit = minGasLimit_;
    }

    /* ========== OnlySeigmanager ========== */
    function deposit(address layer2, address account, uint256 swton) external onlySeigManager {
        if (lastRegisterTime[account][layer2] == 0) {
            address[] memory layer2s = new address[](1);
            layer2s[0] = layer2;
            register(account, layer2s);
        } else {

            bytes memory callData = abi.encodeWithSelector(
            IL1StakedTonInL2.deposit.selector, layer2, account, swton);

            _sendMessage(
                l1StakedTonInL2,
                callData,
                minGasLimit
                );

            emit Deposited(layer2, account, swton);
        }
    }

    function withdraw(address layer2, address account, uint256 swton) public onlySeigManager {
        if(lastRegisterTime[account][layer2] == 0) {
            address[] memory layer2s = new address[](1);
            layer2s[0] = layer2;
            register (account, layer2s);
        } else {
            bytes memory callData = abi.encodeWithSelector(
                IL1StakedTonInL2.withdraw.selector, layer2, account, swton);

            _sendMessage(
                l1StakedTonInL2,
                callData,
                minGasLimit
                );

            emit Withdrawal(layer2, account, swton);
        }
    }

    function updateSeigniorage(address layer2, uint256 swton) external {
        bytes memory callData = abi.encodeWithSelector(
            IL1StakedTonInL2.rebaseIndex.selector, layer2, swton);

        _sendMessage(
            l1StakedTonInL2,
            callData,
            minGasLimit
            );
    }

    /* ========== Anybody can ========== */

    // register account's staked ton fro L1 to L2
    // @param account account address
    function register(address account) public {
        (LibL1StakedInfo.L1StakedPacket[] memory needSyncPackets, uint256 count) = registerData(account);

        require(count != 0, "no register data");
        LibL1StakedInfo.L1StakedPacket[] memory sync = new LibL1StakedInfo.L1StakedPacket[](count);

        for(uint256 i ; i < count; i++){
            sync[i] = needSyncPackets[i];
        }
        _register(account, sync);
    }

    // register layer2's account's staked ton fro L1 to L2
    // @param account account address
    // @param layer2s layer2's addresses
    function register(address account, address[] memory layer2s) public {
        uint256 num = layer2s.length;
        require(num != 0, "empty layer2s");
        LibL1StakedInfo.L1StakedPacket[] memory needSyncInfo = new LibL1StakedInfo.L1StakedPacket[](num);
        for(uint256 i = 0; i < num; i++){
            require(IRegistry(registry).layer2s(layer2s[i]), "unregistered layer in registry");
            uint256 amount = ISeigManager(seigManager).stakeOf(layer2s[i], account);
            needSyncInfo[i] = LibL1StakedInfo.L1StakedPacket(layer2s[i], amount);
        }
        _register(account, needSyncInfo);
    }

    /* ========== VIEW ========== */

    function getBalanceFactor(address layer2, address account)
        public view returns (uint256 balance, uint256 factor)
    {
        address coinage = ISeigManager(seigManager).coinages(layer2);
        require(coinage != address(0), "zero coinage");
        (IRefactor.Balance memory b, IRefactor.Factor memory f) = IRefactorCoinage(coinage).getBalanceAndFactor(account);
        balance = b.balance;
        factor = f.factor;
    }


    function registerData(address account)
        public view
        returns (LibL1StakedInfo.L1StakedPacket[] memory needSyncInfo, uint256 count)
    {
        uint256 num =  IRegistry(registry).numLayer2s();

        if (num != 0) {
            needSyncInfo = new LibL1StakedInfo.L1StakedPacket[](num);
            for(uint256 i = 0; i < num; i++){
                address layer2 = IRegistry(registry).layer2ByIndex(i);
                uint256 amount = ISeigManager(seigManager).stakeOf(layer2, account);
                needSyncInfo[count] = LibL1StakedInfo.L1StakedPacket(layer2, amount);
                count++;
            }
        }
    }

    function getL1CommunicationMessenger(address addressManager) public view returns(address _address) {
        if (addressManager == address(0)) return address(0);
        try
            AddressManagerI(addressManager).getAddress('Proxy__OVM_L1CrossDomainMessenger') returns (address a) {
                _address = a;
        } catch (bytes memory ) {
            _address = address(0);
        }
    }

    /* === ======= internal ========== */

    function _register(address account, LibL1StakedInfo.L1StakedPacket[] memory syncInfos) internal {
        require(syncInfos.length != 0, "no register data");

        bytes memory syncPackets ;
        uint256 count = syncInfos.length ;

        // packet {account address: 1st sync packet: 2nd sync packet: .....}
        // account address : 20 bytes
        // sync packets : count to sync * 52 bytes ( count * 52 )
            // one sync packets : 52 bytes:  (20 byte) address layer, (32) stakedAmount -> total 52
        for (uint256 i = 0; i < count; i++){
            lastRegisterTime[account][syncInfos[i].layer] = block.timestamp;
            bytes memory syncPacket = abi.encodePacked(syncInfos[i].layer, syncInfos[i].stakedAmount);
            syncPackets = bytes.concat(syncPackets, syncPacket);
            emit Registered(account, syncPacket);
        }

        bytes memory callData = abi.encodeWithSelector(
            IL1StakedTonInL2.register.selector,
            abi.encodePacked(account, syncPackets));

        _sendMessage(
            l1StakedTonInL2,
            callData,
            minGasLimit
            );
    }

    function _sendMessage(address target, bytes memory data, uint32 minGasLimit) internal {
        address l1Messenger = getL1CommunicationMessenger(addressManager);
        require(l1Messenger != address(0), "l1Messenger is ZeroAddress");

        // console.log('_sendMessage target %s', target, ' data.length %s', data.length);
        // console.logBytes(data);
        // console.log('_sendMessage l1Messenger %s', l1Messenger);

        L1CrossDomainMessengerI(l1Messenger).sendMessage(
                target,
                data,
                minGasLimit
            );
    }

}