// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";
import "./Pausable.sol";
import "./OwnableExt.sol";
import "./ERC721Collection.sol";
import "./libs/UintLibrary.sol";

///@title The contract for the distribution of tokens is free for users
contract Airdrop is OwnableExt, Pausable {
    using UintLibrary for uint256;

    /* Structure AirdropToken */
    struct AirdropToken {
        /* Address account */
        address account;
        /* Number token for airdrop */
        uint256 amount;
    }

    /* Structure DropToken */
    struct DropToken {
        /* Hash account (address account + maxAmount) */
        bytes32 accountHash;
        /* Address collection */
        address collection;
    }

    /// @notice Mapping NFT collections
    mapping(address => bool) public collections;
    /// @notice Mapping whitelistRoots
    /// @dev Merkle tree roots
    mapping(address => bytes32) public whitelistRoots;
    /// @notice Mapping Drop Token Accounts
    mapping(bytes32 => mapping(address => uint256)) public dropTokenAccounts;

    /* Collection Existence Modifier (Add)
        Parameters:
        - collection = Address collection
    */
    modifier checkAddCollection(address collection) {
        require(
            collections[collection],
            "There is no such object in the collection!"
        );
        _;
    }

    /* Collection Existence Modifier (Remove)
        Parameters:
        - collection = Address collection
    */
    modifier checkRemoveCollection(address collection) {
        require(
            !collections[collection],
            "Such an object already exists in the collection!"
        );
        _;
    }

    /// @notice Function to add collection to airdrop
    /// @dev Only Admin. Virtual method
    /// @param collection Address NFT collection
    function addCollection(
        address collection
    )
        external
        virtual
        onlyAdmin
        checkRemoveCollection(collection)
        whenNotPaused
    {
        collections[collection] = true;

        emit AddingCollection(collection);
    }

    /// @notice Function to remove collection from airdrop
    /// @dev Only Admin. Virtual method
    /// @param collection Address NFT collection
    function removeCollection(
        address collection
    ) external virtual onlyAdmin checkAddCollection(collection) whenNotPaused {
        delete collections[collection];

        emit RemovingCollection(collection);
    }

    /// @notice Function to assign merkle root to collection
    /// @dev Only Admin
    /// @param collection Address NFT collection
    /// @param merkleRoot Hash merkle root
    function setWhitelist(
        address collection,
        bytes32 merkleRoot
    ) external virtual onlyAdmin checkAddCollection(collection) whenNotPaused {
        whitelistRoots[collection] = merkleRoot;

        emit UpdateWhiteListRoot(collection, merkleRoot);
    }

    /// @notice Function for issuing NFT collection tokens for free
    /// @dev Only Whitelist for users
    /// @param collection Address NFT collection
    /// @param proofs A set of proofs to confirm that an account is whitelisted
    /// @param tokenAmount Number token for airdrop
    /// @param maxAmount Max Number token for airdrop. For check amount
    function getTokens(
        address collection,
        bytes32[] calldata proofs,
        uint256 tokenAmount,
        uint256 maxAmount
    ) external virtual checkAddCollection(collection) whenNotPaused {
        bytes32 accountHash = keccak256(
            abi.encodePacked(msg.sender, maxAmount)
        );

        require(
            isWhitelist(collection, proofs, accountHash),
            "Account is not whitelisted."
        );

        _getTokens(msg.sender, collection, tokenAmount, maxAmount);
    }

    /// @notice Function for issuing NFT collection tokens for free
    /// @dev Only Admin
    /// @param collection Address NFT collection
    /// @param airdropAccounts Account Dataset
    function getTokensAdmin(
        address collection,
        AirdropToken[] calldata airdropAccounts
    ) external onlyAdmin checkAddCollection(collection) whenNotPaused {
        for (uint256 i = 0; i < airdropAccounts.length; ) {
            ERC721Collection erc721 = ERC721Collection(collection);

            erc721.mint(airdropAccounts[i].account, airdropAccounts[i].amount);

            emit GetTokens(
                collection,
                airdropAccounts[i].account,
                airdropAccounts[i].amount
            );

            unchecked {
                i += 1;
            }
        }
    }

    /// @notice Function to check for whitelisting
    /// @dev Only Whitelist for users
    /// @param collection Address NFT collection
    /// @param proofs A set of proofs to confirm that an account is whitelisted
    /// @param leaf Hash data account
    function isWhitelist(
        address collection,
        bytes32[] calldata proofs,
        bytes32 leaf
    ) internal view virtual returns (bool) {
        bytes32 merkleRoot = whitelistRoots[collection];

        return MerkleProof.verify(proofs, merkleRoot, leaf);
    }

    /// @notice Private function get tokens: use in getTokens (public) and getTokensAdmin (public)
    /// @param _account Address Account
    /// @param _collection Address NFT collection
    /// @param _amount Number token for airdrop
    /// @param _maxAmount Max Number token for airdrop. For check amount
    function _getTokens(
        address _account,
        address _collection,
        uint256 _amount,
        uint256 _maxAmount
    ) private {
        ERC721Collection erc721 = ERC721Collection(_collection);
        bytes32 accountHash = keccak256(abi.encodePacked(_account, _maxAmount));
        mapping(address => uint256)
            storage accountCollections = dropTokenAccounts[accountHash];

        require(
            accountCollections[_collection] + _amount <= _maxAmount,
            "This account has already received a free token."
        );

        erc721.mint(_account, _amount);

        accountCollections[_collection] += _amount;

        emit GetTokens(_collection, _account, _amount);
    }

    /// @notice Function for clearing the history of issuing tokens
    /// @dev Only Admin. Virtual method
    /// @param accountsDrop A set of data on accounts for which you need to reset the history of issuing tokens
    function clearDropTokenAccounts(
        DropToken[] calldata accountsDrop
    ) external virtual onlyAdmin whenNotPaused {
        for (uint256 i = 0; i < accountsDrop.length; ) {
            delete dropTokenAccounts[accountsDrop[i].accountHash][
                accountsDrop[i].collection
            ];

            unchecked {
                i += 1;
            }
        }
    }

    ///@notice Pause working contract
    function pause() external onlyAdmin {
        Pausable._pause();
    }

    ///@notice Unpause working contract
    function unpause() external onlyAdmin {
        Pausable._unpause();
    }

    /// @notice Adding collection event
    /// @param collection Collection Address
    event AddingCollection(address collection);

    /// @notice Removing collection event
    /// @param collection Collection Address
    event RemovingCollection(address collection);

    /// @notice Get Tokens event
    /// @param collection Collection Address
    /// @param account Account Address
    /// @param amount The Number tokens
    event GetTokens(
        address indexed collection,
        address account,
        uint256 amount
    );

    /// @notice Update WhiteList Root event
    /// @param collection Collection Address
    /// @param merkleRoot Hash merkle root
    event UpdateWhiteListRoot(address indexed collection, bytes32 merkleRoot);
}
