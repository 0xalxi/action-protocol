// SPDX-License-Identifier: MIT
pragma solidity ^0.8.6;

import { IERC5050RegistryClient } from "./IERC5050RegistryClient.sol";
import { IERC5050Receiver, IERC5050Sender } from "../interfaces/IERC5050.sol";

contract ProxyClient {
    IERC5050RegistryClient proxyRegistry;
    address internal selfIsProxyForSender;
    address internal selfIsProxyForReceiver;

    function _setProxyRegistry(address _proxyRegistry) internal {
        proxyRegistry = IERC5050RegistryClient(_proxyRegistry);
    }

    function getSenderProxy(address _addr) internal view returns (address) {
        if(_addr == address(0)){
            return _addr;
        }
        if(selfIsProxyForSender == _addr) {
            return address(this);
        }
        if(address(proxyRegistry) == address(0)){
            return _addr;
        }
        return proxyRegistry.getInterfaceImplementer(_addr, type(IERC5050Sender).interfaceId);
    }

    function getReceiverProxy(address _addr) internal view returns (address) {
        if(_addr == address(0)){
            return _addr;
        }
        if(selfIsProxyForReceiver == _addr) {
            return address(this);
        }
        if(address(proxyRegistry) == address(0)){
            return _addr;
        }
        return proxyRegistry.getInterfaceImplementer(_addr, type(IERC5050Receiver).interfaceId);
    }
}
