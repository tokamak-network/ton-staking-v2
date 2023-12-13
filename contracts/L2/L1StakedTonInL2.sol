// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;
import "../libraries/BytesLib.sol";
import { LibL1StakedInfo } from "../libraries/LibL1StakedInfo.sol";
import "../proxy/ProxyStorage.sol";
import { AccessibleCommon } from "../common/AccessibleCommon.sol";
import "./L1StakedTonInL2Storage.sol";

import "hardhat/console.sol";

interface IL2SeigManager {
    function register(
        address account,
        LibL1StakedInfo.L1StakedPacket[] memory packets
    ) external;
}

interface IL2CrossDomainMessenger {
    function xDomainMessageSender() external view returns (address);
}

contract L1StakedTonInL2 is ProxyStorage, AccessibleCommon, L1StakedTonInL2Storage {
    using BytesLib for bytes;

    modifier onlyMessengerAndL1Register() {
        require(
            l2CrossDomainMessenger == msg.sender &&
            IL2CrossDomainMessenger(l2CrossDomainMessenger).xDomainMessageSender() == l1Register,
            "not onlyMessengerAndL1Register");
        _;
    }

    modifier nonZero(uint256 _val) {
        require(_val != 0, "zero value");
        _;
    }

    function initialize (
        address l2messanger_,
        address l1Register_,
        address l2SeigManager_
    ) external onlyOwner {
        l2CrossDomainMessenger = l2messanger_;
        l1Register = l1Register_;
        l2SeigManager = l2SeigManager_;
    }

    function setL1Register(address l1Register_) external onlyOwner {
        require(l1Register != l1Register_, "same");
        l1Register = l1Register_;
    }

    function setL2SeigManager(address l2SeigManager_) external onlyOwner {
        require(l2SeigManager != l2SeigManager_, "same");
        l2SeigManager = l2SeigManager_;
    }

    /*** Public ***/
    // function register(bytes memory data) public {
    //     console.log('IL1StosInL2 register in' );
    //     console.logBytes(data);
    //     console.log('IL1StosInL2 l2CrossDomainMessenger %s', l2CrossDomainMessenger);
    //     console.log('IL1StosInL2 msg.sender %s', msg.sender );
    //     address xDomainMessageSender = IL2CrossDomainMessenger(l2CrossDomainMessenger).xDomainMessageSender();

    //     console.log('IL1StosInL2 xDomainMessageSender %s', xDomainMessageSender );
    //     console.log('IL1StosInL2 l1Register %s', l1Register );


    // }

    function register(bytes memory data) public onlyMessengerAndL1Register {
    // function register(bytes memory data) public {
        console.log('register in ');
        console.logBytes(data);
        // packet {account address: 1st sync packet: 2nd sync packet: .....}
        // account address : 20 bytes
        // sync packets : count to sync * 52 bytes ( count * 52 )
            // one sync packets : 52 bytes:  (20 byte) address layer, (32) stakedAmount -> total 52
        require(data.length > 71, "wrong bytes length");
        address user = data.toAddress(0);
        console.log('register user %s ', user);

        uint256 packSize = 52;
        uint256 countInPacket = 4;
        uint256 packetNum = (data.length - 20) / packSize;
        uint256 num = packetNum / countInPacket ;
        if(num * countInPacket < packetNum) num++;

        for(uint256 i = 0; i < num; i++){
            uint256 start = 20 + (packSize * countInPacket * i);
            uint256 end = (packSize * countInPacket);
            if ( start + end > data.length)  end = data.length - start;

            LibL1StakedInfo.L1StakedPacket[] memory packets = decodeSyncPackets(data.slice(start, end));
            IL2SeigManager(l2SeigManager).register(user, packets);
        }

        // LibL1StakedInfo.L1StakedPacket[] memory packets = decodeSyncPackets(data.slice(20,(data.length-20)));
    }

    // function multiRegister(bytes[] memory datas) external onlyMessengerAndL1Register {
    //     require(datas.length != 0, "no data");
    //     for(uint256 i = 0; i < datas.length; i++) {
    //         register(datas[i]);
    //     }
    // }

    function decodeSyncPackets(bytes memory data) public pure returns (LibL1StakedInfo.L1StakedPacket[] memory packets) {

        uint256 packSize = 52;
        uint256 len = data.length / packSize;
        packets = new LibL1StakedInfo.L1StakedPacket[](len);
        for(uint256 i = 0; i < len ; i++){
            bytes memory packet = data.slice(i*packSize, packSize);

            packets[i] = LibL1StakedInfo.L1StakedPacket({
                layer: packet.toAddress(0),
                stakedAmount: packet.toUint256(20)
            });
            console.log(i, ': ' , packets[i].layer, packets[i].stakedAmount);
        }
    }

}
