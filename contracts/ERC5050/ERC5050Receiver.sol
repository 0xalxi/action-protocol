// SPDX-License-Identifier: MIT

pragma solidity ^0.8.6;

/*********************************************************************************************\
* Author: Hypervisor <chitch@alxi.nl> (https://twitter.com/0xalxi)
* EIP-5050 Interactive NFTs with Modular Environments: https://eips.ethereum.org/EIPS/eip-5050
/*********************************************************************************************/

import {Address} from "@openzeppelin/contracts/utils/Address.sol";
import {Strings} from "@openzeppelin/contracts/utils/Strings.sol";
import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";
import {IERC5050Sender, IERC5050Receiver, Action} from "../interfaces/IERC5050.sol";
import {IERC165} from "@openzeppelin/contracts/utils/introspection/IERC165.sol";
import "../common/Controllable.sol";
import "../common/ActionsSet.sol";
import {ERC5050ProxyClient} from "./ERC5050ProxyClient.sol";

contract ERC5050Receiver is
    Controllable,
    IERC5050Receiver,
    ERC5050ProxyClient,
    Ownable
{
    using Address for address;
    using ActionsSet for ActionsSet.Set;
    
    uint256 private constant _NOT_ENTERED = 1;
    uint256 private constant _ENTERED = 2;
    uint256 private _reentrancyLock;
    
    ActionsSet.Set private _receivableActions;

    function setProxyRegistry(address registry) external virtual onlyOwner {
        _setProxyRegistry(registry);
    }

    modifier onlyReceivableAction(Action calldata action, uint256 nonce) {
        if (_isApprovedController(msg.sender, action.selector)) {
            _;
            return;
        }
        require(_reentrancyLock == _NOT_ENTERED, "ERC5050: reentrant call");
        require(
            action.to._address == address(this) ||
                getReceiverProxy(action.to._address) == address(this),
            "ERC5050: invalid receiver"
        );
        require(
            _receivableActions.contains(action.selector),
            "ERC5050: invalid action"
        );
        if (action.from._address != address(0)) {
            require(
                action.from._address == msg.sender ||
                    getSenderProxy(action.from._address) == msg.sender,
                "ERC5050: invalid sender"
            );
        } else {
            require(action.user == msg.sender, "ERC5050: invalid sender");
        }
        _reentrancyLock = _ENTERED;
        _;
        _reentrancyLock = _NOT_ENTERED;
    }

    function receivableActions() external view returns (string[] memory) {
        return _receivableActions.names();
    }

    function onActionReceived(Action calldata action, uint256 nonce)
        external
        payable
        virtual
        override
        onlyReceivableAction(action, nonce)
    {
        _onActionReceived(action, nonce);
    }

    function _onActionReceived(Action calldata action, uint256 nonce)
        internal
        virtual
    {
        if (!_isApprovedController(msg.sender, action.selector)) {
            if (action.state != address(0)) {
                address next = getReceiverProxy(action.state);
                require(next.isContract(), "ERC5050: invalid state");
                try
                    IERC5050Receiver(next).onActionReceived{
                        value: msg.value
                    }(action, nonce)
                {} catch (bytes memory reason) {
                    if (reason.length == 0) {
                        revert("ERC5050: call to non ERC5050Receiver");
                    } else {
                        assembly {
                            revert(add(32, reason), mload(reason))
                        }
                    }
                }
            }
        }
        emit ActionReceived(
            action.selector,
            action.user,
            action.from._address,
            action.from._tokenId,
            action.to._address,
            action.to._tokenId,
            action.state,
            action.data
        );
    }

    function _registerReceivable(string memory action) internal {
        _receivableActions.add(action);
    }
    
    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual returns (bool) {
        return
            interfaceId == type(IERC5050Receiver).interfaceId ||
            interfaceId == type(IERC165).interfaceId;
    }
}
