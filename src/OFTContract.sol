// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import { OFT } from "@layerzerolabs/lz-evm-oapp-v2/contracts/oft/OFT.sol";
import { OApp, Origin } from "@layerzerolabs/lz-evm-oapp-v2/contracts/oapp/OApp.sol";
import { ILayerZeroEndpointV2 } from "@layerzerolabs/lz-evm-protocol-v2/contracts/interfaces/ILayerZeroEndpointV2.sol";
import { SendParam } from "@layerzerolabs/lz-evm-oapp-v2/contracts/oft/interfaces/IOFT.sol";
import { Ownable } from "@openzeppelin/contracts/access/Ownable.sol";
import { MessagingFee, OFTReceipt, MessagingReceipt } from "@layerzerolabs/lz-evm-oapp-v2/contracts/oft/interfaces/IOFT.sol";

contract OFTContract is OFT {
    address private immutable i_lzEndpoint;
    address private immutable i_owner;

    MessagingReceipt public messagingReceipt;

    constructor(
        string memory _name,
        string memory _symbol,
        address _lzEndpoint,
        address _delegate,
        address _owner
    ) OFT(_name, _symbol, _lzEndpoint, _delegate) Ownable(_owner) {
        i_lzEndpoint = _lzEndpoint;
        i_owner = _owner;
    }

    function mint(address _to, uint256 _amount) public {
        _mint(_to, _amount);
    }

    function sendOFT(
        SendParam calldata sendParam,
        MessagingFee calldata messagingFee,
        address refundAddress
    ) public payable returns (MessagingReceipt memory msgReceipt, OFTReceipt memory oftReceipt){
        return this.send{value: msg.value}(sendParam, messagingFee, payable(refundAddress));
    }

    function receiveOFT(
        Origin calldata _origin,
        bytes32 _guid,
        bytes calldata _message,
        address _executor,
        bytes calldata _extraData
    ) public {
        _lzReceive(_origin, _guid, _message, _executor, _extraData);
    }

    function _setDelegate(address _delegate) public onlyOwner {
        ILayerZeroEndpointV2(i_lzEndpoint).setDelegate(_delegate);
    }

    function toLD(uint64 _amountSD) public view returns (uint256 amountLD) {
        return _toLD(_amountSD);
    }

    function toSD(uint256 _amountLD) public view returns (uint64 amountSD) {
        return _toSD(_amountLD);
    }

    function credit(address _to, uint256 _amountToCreditLD, uint32 _srcEid) public returns (uint256 amountReceivedLD) {
        return _credit(_to, _amountToCreditLD, _srcEid);
    }

    function getOwner() public view returns(address){
        return i_owner;
    }

    function getEndpoint() public view returns(address){
        return i_lzEndpoint;
    }
}
