// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;
pragma experimental ABIEncoderV2;

import "../OwnableExt.sol";
import "./ExchangeDomain.sol";
import "../libs/Encoding.sol";

contract ExchangeState is OwnableExt {
    // keccak256(OrderKey) => completed
    mapping(bytes32 => uint256) public completed;

    address public previousStateAddress;

    /// @notice Get the amount of selled tokens.
    /// @param key - the `OrderKey` struct.
    /// @return Selled tokens count for the order.
    function getCompleted(
        ExchangeDomain.OrderKey calldata key
    ) external view returns (uint256) {
        bytes32 keyValue = Encoding.generateKey(key);
        uint256 result = completed[keyValue];

        if (previousStateAddress != address(0)) {
            result += ExchangeState(previousStateAddress).getCompleted(key);
        }
        return result;
    }

    /// @notice Sets the new amount of selled tokens. Can be called only by the contract admin.
    /// @param key - the `OrderKey` struct.
    /// @param newCompleted - The new value to set.
    function setCompleted(
        ExchangeDomain.OrderKey calldata key,
        uint256 newCompleted
    ) external onlyAdmin {
        bytes32 keyValue = Encoding.generateKey(key);
        completed[keyValue] = newCompleted;
    }

    /// @notice Function to set the previous state
    /// @dev Only Owner
    /// @param _previousStateAddress Address previous state
    function setPreviousState(
        address _previousStateAddress
    ) external onlyOwner {
        previousStateAddress = _previousStateAddress;
    }
}
