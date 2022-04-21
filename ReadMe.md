---
eip:
title: Token Interaction Standard
description: A standard action messaging protol for interactions on and between NFTs
author: Alexi (@0xalxi)
discussions-to:
type: Standards Track
category: ERC
status: Draft
created: 2021-4-18
---

## Simple Summary

A standard messaging protocol for interactive tokens.

## Abstract

This standard defines a broadly applicable action messaging protocol for the transmission of arbitrary, user-initiated actions between contracts and tokens. Shared state contracts provide arbitration and logging of the action process.

## Motivation

Tokenized item standards such as [ERC-721](./eip-721.md) and [ERC-1155](./eip-1155.md) serve as the objects of the Ethereum computing environment. Metaverse games are processes that run on these objects. A standard action messaging protocol will allow these game processes to be developed in the same open, Ethereum-native way as the objects they run on.

The messaging protocol outlined defines how an action is initiated and transmitted between tokens and shared state environments. Clients can use this common protocol to interact with a network of interactive token contracts, and developers can use the standard to leverage the user-side of the network. They can also save development time as the protocol solves the technical challenges of action messaging.

### Benefits
1. Make interactive token contracts discoverable and usable by metaverse/game/bridge applications
2. Allow for generalized action UIs for users to commit actions with/on their tokens
3. Provide a simple solution for developers to make dynamic NFTs and other tokens
4. Promote decentralized, collaborative game building

## Specification

The key words "MUST", "MUST NOT", "REQUIRED", "SHALL", "SHALL NOT", "SHOULD", "SHOULD NOT", "RECOMMENDED", "MAY", and "OPTIONAL" in this document are to be interpreted as described in RFC 2119.

```solidity
pragma solidity ^0.8.0;

/// @title ERC-xxx Token Interaction Standard
/// @dev See https://eips.ethereum.org/EIPS/eip-xxx
interface IERCxxxx {
    /// @notice Send an action to the target address
    /// @dev The action's `fromContract` is automatically set to `address(this)`,
    /// and the `from` parameter is set to `msg.sender`.
    /// @param action The action to send
    function commitAction(Action memory action) external payable;

    /// @notice Handle an action
    /// @dev Both the `to` contract and `state` contract are called via
    /// `handleAction()`. This means that `state` and `to` must be different.
    /// @param action The action to handle
    function handleAction(Action memory action, uint256 _nonce) external payable;

    /// @notice Check if an action is valid based on its hash and nonce
    /// @dev When an action passes through all three possible contracts
    /// (`fromContract`, `to`, and `state`) the `state` contract validates the
    /// action with the initating `fromContract` using a nonced action hash.
    /// This hash is calculated and saved to storage on the `fromContract` before
    /// action handling is initiated. The `state` contract calculates the hash
    /// and verifies it and nonce with the `fromContract`.
    /// @param _hash The hash to validate
    /// @param _nonce The nonce to validate
    function isValid(uint256 _hash, uint256 _nonce) external returns (bool);
    
    /// @notice Change or reaffirm the approved address for an action
    /// @dev The zero address indicates there is no approved address.
    ///  Throws unless `msg.sender` is the `_account`, or an authorized
    ///  operator of the `_account`.
    /// @param _account The account of the account-action pair to approve
    /// @param _action The action of the account-action pair to approve
    /// @param _approved The new approved account-action controller
    function approveForAction(
        address _account,
        string memory _action,
        address _approved
    ) external returns (bool);

    /// @notice Enable or disable approval for a third party ("operator") to conduct
    ///  all actions on behalf of `msg.sender`
    /// @dev Emits the ApprovalForAll event. The contract MUST allow
    ///  multiple operators per owner.
    /// @param _operator Address to add to the set of authorized operators
    /// @param _approved True if the operator is approved, false to revoke approval
    function setApprovalForAllActions(address _operator, bool _approved)
        external;

    /// @notice Get the approved address for an account-action pair
    /// @dev Throws if `_tokenId` is not a valid NFT.
    /// @param _account The account of the account-action to find the approved address for
    /// @param _action The action of the account-action to find the approved address for
    /// @return The approved address for this account-action, or the zero address if
    ///  there is none
    function getApprovedForAction(address _account, string memory _action)
        external
        view
        returns (address);

    /// @notice Query if an address is an authorized operator for another address
    /// @param _account The address on whose behalf actions are performed
    /// @param _operator The address that acts on behalf of the account
    /// @return True if `_operator` is an approved operator for `_account`, false otherwise
    function isApprovedForAllActions(address _account, address _operator)
        external
        view
        returns (bool);
        
    /// @dev This emits when an action is sent (`commitAction()`)
    event CommitAction(
        string indexed name,
        address _from,
        address indexed _fromContract,
        uint256 _tokenId,
        address indexed _to,
        uint256 _toTokenId,
        address _state,
        bytes _data
    );
    
    /// @dev This emits when an action is received (`handleAction()`)
    event HandleAction(
        string indexed name,
        address _from,
        address indexed _fromContract,
        uint256 _tokenId,
        address indexed _to,
        uint256 _toTokenId,
        address _state,
        bytes _data
    );
    
    /// @dev This emits when the approved address for an account-action pair
    ///  is changed or reaffirmed. The zero address indicates there is no
    ///  approved address.
    event ApprovalForAction(
        address indexed _account,
        string indexed _action,
        address indexed _approved
    );

    /// @dev This emits when an operator is enabled or disabled for an account.
    ///  The operator can conduct all actions on behalf of the account.
    event ApprovalForAllActions(
        address indexed _account,
        address indexed _operator,
        bool _approved
    );
}

/// @param _address The address of the interactive object
/// @param tokenId The token that is interacting (optional)
struct ActionObject {
    address _address;
    uint256 _tokenId;
}

/// @param name The name of the action
/// @param user The address of the sender
/// @param from The initiating object
/// @param to The receiving object
/// @param state The state contract
/// @param data Additional data with no specified format
struct Action {
    string name;
    address user;
    ActionObject from;
    ActionObject to;
    address state;
    bytes data;
}
```

### Extensions

#### Definable

An interface for contracts to advertise token functionality/compatibility with action types and flows. There are two implementations under consideration:

##### 1. Naive: List of Actions

Return a list of actions that the token supports.

Pro: Very simple to understand and use
Con: No identification system (overlapping keywords), or relational definitions (do X AFTER Y)

```solidity
pragma solidity ^0.8.0;

interface IERC4964Definable is IERC4964 {
    /// @notice Returns a bit-array of ORd action definitions, and
    /// the namespace used for the action encoding.
    /// @dev Actions
    /// @param tokenId The token to define
    function supportedActions(uint256 tokenId)
        external
        view
        returns (string[] memory names);
}
```

##### 2. Sophisticated: Registries and Encodings

Register namespaced actions and action-flows (do X AFTER Y) as bit-shifted uint256 keys.

These keys can then be ORd together to create a bit-array that defines the supported actions and flows of the token.

Pro: Solves overlapping keywords problem, and allows for relational definitions (do X AFTER Y)
Con: Difficult to understand and use

```solidity
pragma solidity ^0.8.0;

interface IActionRegistry {
    function register(string memory name, uint256 namespace) external;

    function lookup(string memory name, uint256 namespace)
        external
        view
        returns (uint256);

    function reverseLookup(uint256 key, uint256 namespace)
        external
        view
        returns (string memory);
}

interface IERCxxxxDefinable {
    /// @notice Returns a bit-array of ORd action definitions, and
    /// the namespace used for the action encoding.
    /// @param tokenId The token to define
    function definition(uint256 tokenId)
        external
        view
        returns (
            address registry,
            uint256 namespace,
            bytes32 def
        );
}
```

#### Action Proxies

Action proxies can be used to support backwards compatibility with non-upgradeable contracts, and potentially for cross-chain action bridging.

```solidity
pragma solidity ^0.8.0;

interface IProxyRegistry {
    function register(address _contract, address _proxy) external;
    
    function deregister(address _contract) external;

    function proxy(address _contract)
        external
        view
        returns (address);

    function reverseProxy(address _proxy)
        external
        view
        returns (address);
}
```

#### Controllable

Users of this standard may want to allow trusted contracts to control the action process to provide security guarantees, and support action bridging. Controllers step through the action chain, calling each contract individually in sequence.

Contracts that support Controllers SHOULD ignore require/revert statements related to action verification, and MUST NOT pass the action to the next contract in the chain.

```solidity
pragma solidity ^0.8.0;

interface IControllable {
    function approveController(address sender, string memory action)
        external
        returns (bool);

    function revokeController(address sender, string memory action)
        external
        returns (bool);

    function isApprovedController(address sender, string memory action)
        external
        view
        returns (bool);
}
```

## Rationale

There are many proposed uses for interactions with and between tokenized assets. Projects that are developing or have already developed such features include fully on-chain games like Realms' cross-collection Quests and the fighting game nFight, and partially on-chain games like Worldwide Webb and Axie Infinity. It is critical in each of these cases that users are able to commit actions on and across tokenized assets. Regardless of the nature of these actions, the ecosystem will be stronger if wee have a standardized interface that allows for asset-defined action handling, open interaction systems, and cross-functional bridges.

### Validation

Validation of the initiating contract via a hash of the action data was satisfactory to nearly everyone surveyed and was the most gas efficient verification solution explored. We recognize that this solution does not allow the receiving and state contracts to validate initiating the `from` account beyond using `tx.origin`, which is vulnerable to phishing attacks.

We considered using a signed message to validate user-intiation, but this approach had two major drawbacks:

1. **UX** users would be required to perform two steps to commit each action (sign the message, and send the transaction)
2. **Gas** performing signature verification is computationally intensive

Most importantly, the consensus among the developers surveyed is that strict user validation is not necessary because the concern is only that malicious initiating contracts will phish users to commit actions *with* the malicious contract's assets. **This protocol treats the initiating contract's token as the prime mover, not the user.** Anyone can tweet at Bill Gates. Any token can send an action to another token. Which actions are accepted, and how they are handled is left up to the contracts. High-value actions can be reputation-gated via state contracts, or access-gated with allow/disallow-lists. (`Controllable`)[#controllable] contracts can also be used via trusted controllers as an alternative to action chaining.

*Alternatives considered: action transmitted as a signed message, action saved to reusable storage slot on initiating contract*

### State Contracts

Moving state logic into dedicated, parameterized contracts makes state an action primitive and prevents state management from being obscured within the contracts. Specifically, it allows users to decide which "environment" to commit the action in, and allows the initiating and receiving contracts to share state data without requiring them to communicate.

The specifics of state contract interfaces are outside the scope of this standard, and are intended to be purpose-built for unique interactive environments.

### Action Strings

Actions are identified with arbitrary strings. Strings are easy to use because they are human-readable. The trade-off compared with an action ID registry model is in space and gas efficiency, and strict uniqueness.

### NFT Identifiers

Every NFT is identified by a unique `uint256` ID inside the ERC-721 smart contract. This identifying number SHALL NOT change for the life of the contract. The pair `(contract address, uint256 tokenId)` will then be a globally unique and fully-qualified identifier for a specific asset on an Ethereum chain. While some ERC-721 smart contracts may find it convenient to start with ID 0 and simply increment by one for each new NFT, callers SHALL NOT assume that ID numbers have any specific pattern to them, and MUST treat the ID as a "black box". Also note that NFTs MAY become invalid (be destroyed). Please see the enumeration functions for a supported enumeration interface.

The choice of `uint256` allows a wide variety of applications because UUIDs and sha3 hashes are directly convertible to `uint256`.

### Gas and Complexity (regarding action chaining)

Action handling within each contract can be arbitrarily complex, and there is no way to eliminate the possibility that certain contract interactions will run out of gas. However, develoeprs SHOULD make every effort to minimize gas usage in their action handler methods, and avoid the use of for-loops.

*Alternatives considered: multi-request action chains that push-pull from one contract to the next.*

## Backwards Compatibility

Non-upgradeable, already deployed token contracts will not be compatible with this standard unless a proxy registry extension is used.

## Test Cases

Test cases are include in `../assets/eip-####/`.

## Reference Implementation

Implementations for both standard contracts and EIP-2535 Diamonds are included in `../assets/eip-####/`.

## Security Considerations

The core security consideration of this protocol is action validation. Actions are passed from one contract to another, meaning it is not possible for the receiving contract to natively verify that the caller of the initiating contract matches the `action.from` address. One of the most important contributions of this protocol is that it provides an alternative to using signed messages, which require users to perform two operations for every action committed.

As discussed in [Validation](#validation), this is viable because the initiating contract / token is treated as the prime mover, not the user.

## Copyright

Copyright and related rights waived via [CC0](https://creativecommons.org/publicdomain/zero/1.0/).