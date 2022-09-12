// SPDX-License-Identifier: MIT

pragma solidity ^0.8.6;

/******************************************************************************\
* Author: hypervisor <chitch@alxi.nl> (https://twitter.com/0xalxi)
* EIP-5050 Token Interaction Standard: https://eips.ethereum.org/EIPS/eip-5050
*
* Implementation of an interactive token protocol.
/******************************************************************************/

import {ERC165} from "@openzeppelin/contracts/utils/introspection/ERC165.sol";
import {ERC5050Sendable, IERC5050Sender} from "./ERC5050Sender.sol";
import {ERC5050Receivable, IERC5050Receiver} from "./ERC5050Receiver.sol";

contract ERC5050 is ERC5050Sendable, ERC5050Receivable, ERC165 {
    function _registerAction(string memory action) internal {
        _registerSendable(action);
        _registerReceivable(action);
    }
    
    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override(ERC165) returns (bool) {
        return
            interfaceId == type(IERC5050Sender).interfaceId ||
            interfaceId == type(IERC5050Receiver).interfaceId ||
            super.supportsInterface(interfaceId);
    }
}
