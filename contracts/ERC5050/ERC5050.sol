// SPDX-License-Identifier: MIT

pragma solidity ^0.8.6;

/*********************************************************************************************\
* Author: Hypervisor <chitch@alxi.nl> (https://twitter.com/0xalxi)
* EIP-5050 Interactive NFTs with Modular Environments: https://eips.ethereum.org/EIPS/eip-5050
/*********************************************************************************************/

import {ERC165} from "@openzeppelin/contracts/utils/introspection/ERC165.sol";
import {ERC5050Sender, IERC5050Sender, Action} from "./ERC5050Sender.sol";
import {ERC5050Receiver, IERC5050Receiver} from "./ERC5050Receiver.sol";

contract ERC5050 is ERC5050Sender, ERC5050Receiver {
    function _registerAction(string memory action) internal {
        _registerSendable(action);
        _registerReceivable(action);
    }
    
    function setProxyRegistry(address registry) external virtual override(ERC5050Sender, ERC5050Receiver) onlyOwner {
        _setProxyRegistry(registry);
    }
    
    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override(ERC5050Sender, ERC5050Receiver) returns (bool) {
        return super.supportsInterface(interfaceId);
    }
}
