// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;
pragma experimental ABIEncoderV2;

import "../NFT-Marketplace/ExchangeDomain.sol";

library Encoding {
    /// @notice Encode order key to use as the mapping key.
    /// @param key - the `OrderKey` struct.
    /// @return Encoded order key.
    function generateKey(
        ExchangeDomain.OrderKey memory key
    ) internal pure returns (bytes32) {
        return
            keccak256(
                abi.encodePacked(
                    key.owner,
                    key.sellAsset.token,
                    key.sellAsset.tokenId,
                    key.buyAsset.token,
                    key.buyAsset.tokenId,
                    key.salt
                )
            );
    }
}
