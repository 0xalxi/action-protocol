// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/**********************************************************\
* Author: alxi <chitch@alxi.nl> (https://twitter.com/0xalxi)
* EIP-xxxx Token Interaction Standard: [tbd]
*
* Implementation of an interactive token protocol.
/**********************************************************/

import {Address} from "@openzeppelin/contracts/utils/Address.sol";
import {Strings} from "@openzeppelin/contracts/utils/Strings.sol";
import {IERCxxxxSender, IERCxxxxReceiver, Action} from "../interfaces/IERCxxxx.sol";
import "../common/Controllable.sol";

contract ERCxxxxReceiver is Controllable, IERCxxxxReceiver {
    using Address for address;

    mapping(bytes4 => bool) receivableActions;

    modifier onlyReceivableAction(Action calldata action, uint256 nonce) {
        if (_isApprovedController(msg.sender, action.selector)) {
            return;
        }
        require(
            action.to._address == address(this),
            "ERCxxxx: invalid receiver"
        );
        require(receivableActions[action.selector], "ERCxxxx: invalid action");
        require(
            action.from._address == address(0) ||
                action.from._address == msg.sender,
            "ERCxxxx: invalid sender"
        );
        require(
            action.from._address != address(0) || action.user == msg.sender,
            "ERCxxxx: invalid sender"
        );
        _;
    }

    function isReceivable(bytes4 selector) external view returns (bool) {
        return receivableActions[selector];
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
                require(action.state.isContract(), "ERCxxxx: invalid state");
                try
                    IERCxxxxReceiver(action.state).onActionReceived{
                        value: msg.value
                    }(action, nonce)
                {} catch (bytes memory reason) {
                    if (reason.length == 0) {
                        revert("ERCxxxx: call to non ERCxxxxReceiver");
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

    function _registerReceivable(bytes4 action) internal {
        receivableActions[action] = true;
    }
}
