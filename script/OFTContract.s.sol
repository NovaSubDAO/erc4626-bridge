 // SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import { Script, console } from "forge-std/Script.sol";
import { OFTContract } from "../src/OFTContract.sol";
import { HelperConfig } from "./HelperConfig.s.sol";

contract DeployOFTContract is Script{
    
    address lzEndpoint;
    address delegate;
    address owner;
    address messageLibOwner;
    address send302Address;
    
    uint256 deployerKey;

    HelperConfig networkConfig;

    OFTContract oftContract;
    
    function run() external returns(OFTContract){
        networkConfig = new HelperConfig();
        (lzEndpoint, delegate, owner, messageLibOwner, send302Address, deployerKey) = networkConfig.activeNetworkConfig();
        vm.startBroadcast(deployerKey);
        oftContract = new OFTContract("oftContract", "OFT", lzEndpoint, delegate, owner);
        vm.stopBroadcast();

        return oftContract;
    }
}