// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import { Test, console } from "forge-std/Test.sol";
import { OFTContract } from "../src/OFTContract.sol";
import { HelperConfig } from "../script/HelperConfig.s.sol";
import { DeployOFTContract } from "../script/OFTContract.s.sol";
import { OptionsBuilder } from "@layerzerolabs/lz-evm-oapp-v2/contracts/oapp/libs/OptionsBuilder.sol";
import { SendParam } from "@layerzerolabs/lz-evm-oapp-v2/contracts/oft/interfaces/IOFT.sol";
import { MessagingFee, OFTReceipt, MessagingReceipt } from "@layerzerolabs/lz-evm-oapp-v2/contracts/oft/interfaces/IOFT.sol";
import { ILayerZeroEndpointV2, Origin } from "@layerzerolabs/lz-evm-protocol-v2/contracts/interfaces/ILayerZeroEndpointV2.sol";
import { OFTMsgCodec } from "@layerzerolabs/lz-evm-oapp-v2/contracts/oft/libs/OFTMsgCodec.sol";


contract TestOFTContract is Test {
    using OptionsBuilder for bytes;

    address lzEndpoint; // The LayerZero endpoint address
    address delegate; // The delegate address
    address owner; // The owner of the OFT
    address messageLibOwner; // The owner of the message library
    address send302Address; // The address of the message library
    address source_chain_address = 0x6EDCE65403992e310A62460808c4b910D972f10f; // The address of the source chain
    address destination_chain_address = 0x6EDCE65403992e310A62460808c4b910D972f10f; // The address of the destination chain
    
    string OPTIMISM_RPC_URL = vm.envString("OPTIMISM_RPC_URL");

    uint256 constant INITIAL_BALANCE = 100 ether; // The initial balance to mint
    uint256 constant AMOUNT_TO_SEND = 0.1 ether; // The amount to send

    uint256 optimismFork; // The Optimism fork

    uint32 source_eid = 40161; // The Endpoint ID of the source chain
    uint32 destination_eid = 40232; // The Endpoint ID of the destination chain

    HelperConfig networkConfig; // The network configuration

    OFTContract oftContractA; // The OFT contract --> Chain A
    OFTContract oftContractB; // The OFT contract --> Chain B
    DeployOFTContract deployerChainA; // The OFT contract deployer
    DeployOFTContract deployerChainB; // The OFT contract deployer

    modifier mintToken(){
        vm.selectFork(optimismFork);
        oftContractB.mint(address(oftContractB), INITIAL_BALANCE);

        vm.selectFork(0);
        oftContractA.mint(address(oftContractA), INITIAL_BALANCE);
        _;
    }

    function setUp() public {
        optimismFork = vm.createFork(OPTIMISM_RPC_URL);

        networkConfig = new HelperConfig();
        (lzEndpoint, delegate, owner, messageLibOwner, send302Address, ) = networkConfig.activeNetworkConfig();
        
        deployerChainA = new DeployOFTContract();
        oftContractA = deployerChainA.run();
        owner = oftContractA.getOwner();

        if(!isDefaultSendLibrary()){
            vm.prank(messageLibOwner);
            ILayerZeroEndpointV2(lzEndpoint).setDefaultSendLibrary(source_eid, send302Address);
        }

        vm.selectFork(optimismFork);
        deployerChainB = new DeployOFTContract();
        oftContractB = deployerChainB.run();
        vm.selectFork(0);
    }

    function isDefaultSendLibrary() public view returns(bool){
        bool success = ILayerZeroEndpointV2(lzEndpoint).isDefaultSendLibrary(send302Address, 40232);
        return success;
    }

    function addressToBytes32(address _addr) internal pure returns (bytes32) {
        return bytes32(uint256(uint160(_addr)));
    }

    modifier setPeer(){
        vm.prank(owner);
        oftContractA.setPeer(destination_eid, addressToBytes32(destination_chain_address));
        
        vm.selectFork(optimismFork);
        
        vm.prank(owner);
        oftContractB.setPeer(source_eid, addressToBytes32(source_chain_address));
        
        vm.selectFork(0);
        _;
    }

    ///////////////////////////////////////////////////////////////////////
    ////////////////////// Testing the Send function //////////////////////
    ///////////////////////////////////////////////////////////////////////

    function testSendOFT() public setPeer() mintToken(){
        bytes memory options = OptionsBuilder.newOptions().addExecutorLzReceiveOption(200000, 0);
        SendParam memory sendParam = SendParam(
            destination_eid,
            addressToBytes32(destination_chain_address),
            AMOUNT_TO_SEND,
            AMOUNT_TO_SEND,
            options,
            "",
            ""
        );

        MessagingFee memory fee = oftContractA.quoteSend(sendParam, false);

        vm.prank(owner);
        oftContractA.sendOFT{ value: fee.nativeFee }(sendParam, fee, payable(address(this)));
        assert(oftContractA.balanceOf(address(oftContractA)) == INITIAL_BALANCE - sendParam.amountLD);
    }

    ///////////////////////////////////////////////////////////////////////
    ////////////////////// Testing the Receive function ///////////////////
    ///////////////////////////////////////////////////////////////////////

    function testReceiveOFT() public setPeer() mintToken(){
        bytes memory options = OptionsBuilder.newOptions().addExecutorLzReceiveOption(200000, 0);
        SendParam memory sendParam = SendParam(
            destination_eid,
            addressToBytes32(address(oftContractB)),
            AMOUNT_TO_SEND,
            AMOUNT_TO_SEND,
            options,
            "",
            ""
        );
        MessagingFee memory fee = oftContractA.quoteSend(sendParam, false);

        vm.prank(owner);
        (MessagingReceipt memory messageReceipt, ) = oftContractA.sendOFT{ value: fee.nativeFee }(sendParam, fee, payable(address(this)));

        bool hasCompose = false;
        bytes memory message;
        (message, hasCompose) = OFTMsgCodec.encode(
            sendParam.to,
            oftContractA.toSD(sendParam.amountLD),
            sendParam.composeMsg
        );

        Origin memory origin = Origin(
            source_eid,
            addressToBytes32(owner),
            messageReceipt.nonce
        );

        vm.selectFork(optimismFork);
        vm.prank(owner);
        oftContractB.receiveOFT(
            origin,
            messageReceipt.guid,
            message,
            address(oftContractA),
            ""
        );

        vm.selectFork(0);
        assert(oftContractA.balanceOf(address(oftContractA)) == INITIAL_BALANCE - sendParam.amountLD);
        
        vm.selectFork(optimismFork);
        assert(oftContractB.balanceOf(address(oftContractB)) == INITIAL_BALANCE + sendParam.amountLD);
    }

}