// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/******************************************************************************\
* Author: hypervisor <chitch@alxi.nl> (https://twitter.com/0xalxi)
* EIP-5050 Token Interaction Standard: https://eips.ethereum.org/EIPS/eip-5050
*
* Implementation of an interactive token protocol.
/******************************************************************************/

import "./ERC5050Sender.sol";
import "./ERC5050Receiver.sol";

contract ERC5050 is ERC5050Sender, ERC5050Receiver {
    function _registerAction(string memory action) internal {
        _registerReceivable(action);
        _registerSendable(action);
    }
}
