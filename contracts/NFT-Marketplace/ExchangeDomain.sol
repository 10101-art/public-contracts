// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;
pragma experimental ABIEncoderV2;

/// @title ExchangeDomain
/// @notice Describes all structures used in exchanges.
contract ExchangeDomain {
    enum AssetType {
        ERC20,
        ERC721
    }

    struct Asset {
        address token;
        uint256 tokenId;
        AssetType assetType;
    }

    struct OrderKey {
        /* who signed the order */
        address owner;
        /* random number */
        uint256 salt;
        /* what has owner */
        Asset sellAsset;
        /* what wants owner */
        Asset buyAsset;
    }

    struct Order {
        OrderKey key;
        /* how much has owner (in wei, or UINT256_MAX if ERC-721) */
        uint256 selling;
        /* how much wants owner (in wei, or UINT256_MAX if ERC-721) */
        uint256 buying;
        /* fee. Represented as percents * 100 (100% - 10000. 1% - 100)*/
        uint256 fee;
    }

    /* An ECDSA signature. */
    struct ECDSASig {
        /* v parameter */
        uint8 v;
        /* r parameter */
        bytes32 r;
        /* s parameter */
        bytes32 s;
    }
}
