// SPDX-License-Identifier: MIT

pragma solidity ^0.8.6;

/*********************************************************************************************\
* Author: Hypervisor <chitch@alxi.nl> (https://twitter.com/0xalxi)
* EIP-5050 Interactive NFTs with Modular Environments: https://eips.ethereum.org/EIPS/eip-5050
/*********************************************************************************************/

import {Action, IERC5050Receiver, IERC5050Sender} from "../interfaces/IERC5050.sol";
import {IERC5050RegistryClient} from "../interfaces/IERC5050RegistryClient.sol";
import {ActionsSet} from "../common/ActionsSet.sol";

library ERC5050Storage {
    using ActionsSet for ActionsSet.Set;

    bytes32 constant ERC_5050_STORAGE_POSITION =
        keccak256("erc5050.storage.location");

    struct Layout {
        uint256 nonce;
        bytes32 _hash;
        IERC5050RegistryClient proxyRegistry;
        ActionsSet.Set _sendableActions;
        ActionsSet.Set _receivableActions;
        mapping(address => mapping(bytes4 => address)) actionApprovals;
        mapping(address => mapping(address => bool)) operatorApprovals;
        mapping(address => mapping(bytes4 => bool)) _actionControllers;
        mapping(address => bool) _universalControllers;
        address proxiedSender;
        address proxiedReceiver;
        uint256 senderLock;
        uint256 receiverLock;
    }

    function layout() internal pure returns (Layout storage es) {
        bytes32 position = ERC_5050_STORAGE_POSITION;
        assembly {
            es.slot := position
        }
    }
    
    function getReceiverProxy(address _addr) internal view returns (address) {
        if(address(layout().proxyRegistry) == address(0)){
            return _addr;
        }
        if(_addr == address(0)) {
            return _addr;
        }
        if(layout().proxiedReceiver == address(this)) {
            return address(this);
        }
        return layout().proxyRegistry.getInterfaceImplementer(_addr, type(IERC5050Receiver).interfaceId);
    }
    
    function getSenderProxy(address _addr) internal view returns (address) {
        if(address(layout().proxyRegistry) == address(0)){
            return _addr;
        }
        if(_addr == address(0)) {
            return _addr;
        }
        if(layout().proxiedSender == address(this)) {
            return address(this);
        }
        return layout().proxyRegistry.getInterfaceImplementer(_addr, type(IERC5050Sender).interfaceId);
    }
    
    function setProxyRegistry(address _addr) internal {
        layout().proxyRegistry = IERC5050RegistryClient(_addr);
    }

    function _validate(Layout storage l, Action memory action)
        internal
    {
        ++l.nonce;
        l._hash = bytes32(
            keccak256(
                abi.encodePacked(
                    action.selector,
                    action.user,
                    action.from._address,
                    action.from._tokenId,
                    action.to._address,
                    action.to._tokenId,
                    action.state,
                    action.data,
                    l.nonce
                )
            )
        );
    }
    
    function isValid(Layout storage l, bytes32 actionHash, uint256 nonce)
        internal
        view
        returns (bool)
    {
        return actionHash == l._hash && nonce == l.nonce;
    }
}
