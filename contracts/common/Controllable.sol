// SPDX-License-Identifier: MIT
pragma solidity ^0.8.6;

/******************************************************************************\
* Author: hypervisor <chitch@alxi.nl> (https://twitter.com/0xalxi)
* EIP-5050 Token Interaction Standard: https://eips.ethereum.org/EIPS/eip-5050
*
* Implementation of an interactive token protocol.
/******************************************************************************/

import "../interfaces/IControllable.sol";

contract Controllable is IControllable {
    mapping(address => mapping(bytes4 => bool)) private _actionControllers;
    mapping(address => bool) private _universalControllers;

    function setControllerApproval(address _controller, bytes4 _action, bool _approved)
        external
        virtual
    {
        _actionControllers[_controller][_action] = _approved;
        emit ControllerApproval(
            _controller,
            _action,
            _approved
        );
    }
    
    function setControllerApprovalForAll(address _controller, bool _approved)
        external
        virtual
    {
        _universalControllers[_controller] = _approved;
        emit ControllerApprovalForAll(
            _controller,
            _approved
        );
    }

    function isApprovedController(address _controller, bytes4 _action)
        external
        view
        returns (bool)
    {
        return _isApprovedController(_controller, _action);
    }

    function _isApprovedController(address _controller, bytes4 _action)
        internal
        view
        returns (bool)
    {
        if (_universalControllers[_controller]) {
            return true;
        }
        return _actionControllers[_controller][_action];
    }
}
