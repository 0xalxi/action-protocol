// SPDX-License-Identifier: MIT

pragma solidity ^0.8.6;

/*********************************************************************************************\
* Author: Hypervisor <chitch@alxi.nl> (https://twitter.com/0xalxi)
* EIP-5050 Interactive NFTs with Modular Environments: https://eips.ethereum.org/EIPS/eip-5050
/*********************************************************************************************/

import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";

abstract contract ERC5050Proxy is Ownable {
    
    bytes32 constant internal ERC5050_ACCEPT_MAGIC = keccak256(abi.encodePacked("ERC5050_ACCEPT_MAGIC"));   
    
    address private _parent;
    
    function enableActionProxying(address _proxiedContract) external virtual onlyOwner {
        _parent = _proxiedContract;
    }
    
    /**
    @dev Allows all addresses to 
     */
    function canImplementInterfaceForAddress(bytes4 interfaceHash, address addr) external virtual returns(bytes32) {
        return ERC5050_ACCEPT_MAGIC;
    }
}