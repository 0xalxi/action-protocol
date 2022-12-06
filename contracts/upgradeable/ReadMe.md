# ERC5050Upragedable

The upgradeable ERC5050 implementation provided here is designed for use with a [Diamond](https://github.com/mudgen/diamond-3) but specifically only implements the [Diamond Storage Pattern](https://dev.to/mudgen/how-diamond-storage-works-90e) and so can be used with simple `delegatecall` proxies as well.

It is recommended that projects implementing ERC5050 implement upgradeability to allow them to extend functionality over time. 

## Implement with a Diamond

This brief explanation assumes familiarity with the [Diamond Standard](https://github.com/mudgen/diamond-3) and makes no assumptions about your specific implementation.

There are only three steps to implementing ERC5050 support in your Diamond.

1. Add the ERC5050 Sender / Receiver interfaceId(s) to your ERC165 registry.
2. Wrap the contract in a handler Facet
3. Add action handler(s)

```solidity
// Just for demonstration purposes, we are using the SolidState libraries
import "@solidstate/contracts/introspection/ERC165Storage.sol";
import "@solidstate/contracts/access/ownable/Ownabled.sol";
import "@solidstate/contracts/token/ERC721/SolidStateERC721.sol"

import { ERC5050 } from "./ERC5050Upgradeable/ERC5050.sol";
import { IERC5050Sender, IERC5050Receiver } from "../interfaces/IERC5050.sol";

contract ActionFacet is ERC5050, Ownabled, SolidStateERC721 {
    
    using ERC165Storage for ERC165Storage.Layout;
    
    function initializeActionFacet() external onlyOwner {
        
        ERC165Storage.layout().setSupportedInterface(type(IERC5050Sender).interfaceId, true);
        ERC165Storage.layout().setSupportedInterface(type(IERC5050Receiver).interfaceId, true);
        
        _registerAction("equip");
    }
    
    function sendAction(Action memory action)
        public
        payable
        override
        onlySendableAction(action)
    {
        require(
            ownerOf(action.from._tokenId) == action.user,
            "invalid sender"
        );
        
        // Add hanlding logic here
        
        _sendAction(action);
    }
    
    function onActionReceived(Action calldata action, uint256 _nonce)
        external
        payable
        override
        onlyReceivableAction(action, _nonce)
    {   
        
        // Add hanlding logic here
        
        _onActionReceived(action, _nonce);
    }
}
```

## Implement with Transparent Proxy

Most upgradeable contracts use a simple Transparent Proxy with a single logic contract. Implementing ERC5050 in this case is very simple, and arguably simpler than most upgradeable contracts as the [Diamond Storage Pattern](https://dev.to/mudgen/how-diamond-storage-works-90e) means you do not need to worry about storage collisions when you upgrade.

1. Inherit ERC5050
2. Register sendable and receivable action(s)
3. Implement action handler(s)
4. Implement `supportsInterface()` to return true for IERC5050Sender / IERC5050Receiver

```solidity
import {ERC165} from "@openzeppelin/contracts/utils/introspection/ERC165.sol";

import { IERC5050Sender, IERC5050Receiver } from "../interfaces/IERC5050.sol";

contract NFT is ERC721, ERC5050 {
    
    constructor() ERC721("nft", "NFT") {
        _registerSendable("move");
        _registerReceivable("attune");
        _registerAction("equip");
    }
    
    function sendAction(Action memory action)
        public
        payable
        override
        onlySendableAction(action)
    {
        require(
            ownerOf(action.from._tokenId) == action.user,
            "invalid sender"
        );
        
        // Add hanlding logic here
        
        _sendAction(action);
    }
    
    function onActionReceived(Action calldata action, uint256 _nonce)
        external
        payable
        override
        onlyReceivableAction(action, _nonce)
    {   
        
        // Add hanlding logic here
        
        _onActionReceived(action, _nonce);
    }
    
    function supportsInterface(bytes4 interfaceId) public view virtual override(ERC165) returns (bool) {
        return
            interfaceId == type(IERC5050Sender).interfaceId ||
            interfaceId == type(IERC5050Receiver).interfaceId ||
            super.supportsInterface(interfaceId);
    }
    
}

```