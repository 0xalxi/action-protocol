// SPDX-License-Identifier: MIT
pragma solidity ^0.8.6;

/******************************************************************************\
* Author: hypervisor <chitch@alxi.nl> (https://twitter.com/0xalxi)
* EIP-5050 Token Interaction Standard: https://eips.ethereum.org/EIPS/eip-5050
*
* Implementation of an interactive token protocol.
/******************************************************************************/

import "./ERC5050Sender.sol";
import "./ERC5050Receiver.sol";

contract ERC5050TempProxyRegistry {
    mapping(address => mapping(bytes4 =>address)) _lookup;

    function register(address _contract, bytes4 interfaceId, address _proxy) external {
        _lookup[_contract][interfaceId] = _proxy;
    }

    function deregister(address _contract, bytes4 interfaceId) external {
        delete _lookup[_contract][interfaceId];
    }

    function getInterfaceImplementer(address _addr, bytes4 _interfaceId) external view returns (address) {
        return _lookup[_addr][_interfaceId];
    }
    
    // Not used or implemented for this example.
    function getManager(address _contract) external view returns (address) {
        return _contract;
    }
}
