//SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import { Script } from "forge-std/Script.sol";

contract HelperConfig is Script {
    struct NetworkConfig{
        address lzEndpoint;
        address delegate;
        address owner;
        address messageLibOwner;
        address send302Address;
        uint256 deployerKey;
    }

    NetworkConfig public activeNetworkConfig;

    constructor(){
        //Deploying on Sepolia
        if(block.chainid == 11155111){
            activeNetworkConfig = getSepoliaNetworkConfig();
        }

        //Deploying on Optimism Sepolia
        else if(block.chainid == 11155420){
            activeNetworkConfig = getOPSepoliaNetworkConfig();
        }
    }

    function getSepoliaNetworkConfig() public view returns(NetworkConfig memory){
        return NetworkConfig({
            lzEndpoint: 0x6EDCE65403992e310A62460808c4b910D972f10f,
            delegate: vm.envAddress("DELEGATE"),
            owner: vm.envAddress("OWNER"),
            messageLibOwner: 0xc13b65f7c53Cd6db2EA205a4b574b4a0858720A6,
            send302Address: 0xcc1ae8Cf5D3904Cef3360A9532B477529b177cCE,
            deployerKey: vm.envUint("PRIVATE_KEY_ETH")
        });
    }

    function getOPSepoliaNetworkConfig() public view returns(NetworkConfig memory){
        return NetworkConfig({
            lzEndpoint: 0x6EDCE65403992e310A62460808c4b910D972f10f,
            delegate: vm.envAddress("DELEGATE"),
            owner: vm.envAddress("OWNER"),
            messageLibOwner: 0xc13b65f7c53Cd6db2EA205a4b574b4a0858720A6,
            send302Address: 0xB31D2cb502E25B30C651842C7C3293c51Fe6d16f,
            deployerKey: vm.envUint("PRIVATE_KEY_ETH")
        });
    }
}