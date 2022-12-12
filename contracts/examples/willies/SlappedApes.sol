// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import {ISlapState} from "./SlapState.sol";
import {Base64} from "@openzeppelin/contracts/utils/Base64.sol";
import {IERC721} from "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import {ERC5050, Action} from "../../ERC5050/ERC5050.sol";

// Bored
contract ApesProxy is ERC5050 {
    bytes4 constant SLAP_SELECTOR = bytes4(keccak256("slap"));

    // Suppose other actions are also supported
    bytes4 constant CAST_SELECTOR = bytes4(keccak256("cast"));
    bytes4 constant HONOR_SELECTOR = bytes4(keccak256("honor"));

    IERC721 bayc;

    /// Any state controller can be used for actions, but tokenURI
    /// reads need a single default.
    address defaultSlapStateController;

    /// Allow token holders to set custom default state controller for
    /// tokenURI reads.
    mapping(uint256 => address) tokenSlapStateController;

    /// Off-chain BAYC service listens for `StateControllerUpdate` events
    /// and updates render to match the user-defined state controller.
    event StateControllerUpdate(
        uint256 tokenId,
        string controllerType,
        address controller
    );

    constructor(address _bayc) {
        _registerAction("slap");
        bayc = IERC721(_bayc);
    }

    function sendAction(Action memory action)
        external
        payable
        override
        onlySendableAction(action)
    {
        require(bayc.ownerOf(action.from._tokenId) == msg.sender, "not owner");
        _sendAction(action);
    }

    function onActionReceived(Action calldata action, uint256 _nonce)
        external
        payable
        override
        onlyReceivableAction(action, _nonce)
    {
       _onActionReceived(action, _nonce);
    }

    /// Off-chain BAYC service listens for `ActionReceived` events and updates
    /// the render based on the `TokenSlapState` of the token's default `SlapStateController`.
    function getDefaultTokenSlapStateController(uint256 tokenId)
        public
        view
        returns (address)
    {
        if (tokenSlapStateController[tokenId] != address(0)) {
            return tokenSlapStateController[tokenId];
        }
        return defaultSlapStateController;
    }

    function setDefaultTokenSlapStateController(
        uint256 tokenId,
        address stateController
    ) external {
        require(IERC721(bayc).ownerOf(tokenId) == msg.sender, "not owner");
        tokenSlapStateController[tokenId] = stateController;
        emit StateControllerUpdate(tokenId, "slap", stateController);
    }

    function _sendSlap(Action memory action) private {
        uint256 strengthStart = ISlapState(action.state).getStrength(
            address(bayc),
            action.to._tokenId
        );
        require(strengthStart > 0, "dead ape");

        _sendAction(action);
    }
}
