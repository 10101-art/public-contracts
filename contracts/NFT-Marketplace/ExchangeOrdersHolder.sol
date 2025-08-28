// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;
pragma experimental ABIEncoderV2;

import "./ExchangeDomain.sol";
import "../libs/Encoding.sol";

/// @title ExchangeOrdersHolderV1
/// @notice Optionally holds orders, which can be exchanged without order's holder signature.
contract ExchangeOrdersHolder {
    mapping(bytes32 => OrderParams) internal orders;

    struct OrderParams {
        /* how much has owner (in wei, or UINT256_MAX if ERC-721) */
        uint256 selling;
        /* how much wants owner (in wei, or UINT256_MAX if ERC-721) */
        uint256 buying;
        /* fee for selling */
        uint256 fee;
        /* address owner */
        address owner;
    }

    /// @notice This function can be called to add the order to the contract, so it can be exchanged without signature.
    ///         Can be called only by the order owner.
    /// @param order - The order struct to add.
    function add(ExchangeDomain.Order calldata order) external {
        require(
            msg.sender == order.key.owner,
            "order could be added by owner only"
        );

        bytes32 key = Encoding.generateKey(order.key);

        require(
            orders[key].selling == 0 &&
                orders[key].buying == 0 &&
                orders[key].fee == 0,
            "Order is already existed. Try to change salt"
        );

        require(
            orders[key].fee <= 100_00,
            "The fee specified in the order exceeds 100%"
        );

        orders[key] = OrderParams({
            selling: order.selling,
            buying: order.buying,
            fee: order.fee,
            owner: order.key.owner
        });
    }

    /// @notice This function checks if order was added to the orders holder contract.
    /// @param order - The order struct to check.
    /// @return true if order is present in the contract's data.
    function exists(
        ExchangeDomain.Order calldata order
    ) external view returns (bool) {
        bytes32 key = Encoding.generateKey(order.key);
        OrderParams memory params = orders[key];
        return
            params.buying == order.buying &&
            params.selling == order.selling &&
            params.fee == order.fee &&
            params.owner == order.key.owner;
    }
}
