// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./OwnableExt.sol";
import "./ERC721Collection.sol";
import "@openzeppelin/contracts/utils/Create2.sol";

/// @title Contract factory for creating collections ERC721
contract ERC721Factory is OwnableExt {
    bytes public ERC721_BYTECODE;

    /// @notice NFT Collections
    ERC721Collection[] public erc721Collections;
    /// @notice Presale contract address
    address public presale;
    /// @notice Airdrop contract address
    address public airdrop;

    /// @notice WhitelistContractFilter address
    address public whitelistContractFilter;

    /// @notice Constructor for creating a factory contract
    /// @param _presale Presale contract address
    /// @param _airdrop Airdrop contract address
    /// @param _whitelistContractFilter WhitelistContractFilter address contract
    constructor(
        address _presale,
        address _airdrop,
        address _whitelistContractFilter
    ) {
        require(
            _presale != address(0),
            "Presale contract address cannot be null!"
        );
        require(
            _airdrop != address(0),
            "Airdrop contract address cannot be null!"
        );

        ERC721_BYTECODE = type(ERC721Collection).creationCode;

        presale = _presale;
        airdrop = _airdrop;
        whitelistContractFilter = _whitelistContractFilter;

        emit ChangeAddressContract("Presale", address(0), presale);

        emit ChangeAddressContract("Airdrop", address(0), airdrop);

        emit ChangeAddressContract(
            "WhitelistContractFilter",
            address(0),
            whitelistContractFilter
        );
    }

    /// @notice Function set new address contract Presale
    /// @dev Only Admin
    function setPresale(address _presale) external onlyAdmin {
        require(
            _presale != address(0),
            "Presale contract address cannot be null!"
        );

        address oldPresale = presale;

        presale = _presale;

        emit ChangeAddressContract("Presale", oldPresale, presale);
    }

    /// @notice Function set new address contract Airdrop
    /// @dev Only Admin
    function setAirdrop(address _airdrop) external onlyAdmin {
        require(
            _airdrop != address(0),
            "Airdrop contract address cannot be null!"
        );

        address oldAirdrop = airdrop;

        airdrop = _airdrop;

        emit ChangeAddressContract("Airdrop", oldAirdrop, airdrop);
    }

    /// @notice Function set new address contract WhitelistContractFilter
    /// @dev Only Admin
    function setWhitelistContractFilter(
        address _whitelistContractFilter
    ) external onlyAdmin {
        address oldWhitelistContractFilter = whitelistContractFilter;

        whitelistContractFilter = _whitelistContractFilter;

        emit ChangeAddressContract(
            "WhitelistContractFilter",
            oldWhitelistContractFilter,
            whitelistContractFilter
        );
    }

    /// @notice Function to create an NFT collection
    /// @param tokenName Сollection name
    /// @param tokenSymbol Сollection symbol
    /// @param baseURICollection Base URI to form Token URI (address IPFS)
    /// @param maxSupply The maximum number of tokens that can be minted
    function build(
        string memory tokenName,
        string memory tokenSymbol,
        string memory baseURICollection,
        uint256 maxSupply
    ) external onlyAdmin {
        address collectionAddress = createCollection(
            tokenName,
            tokenSymbol,
            baseURICollection,
            maxSupply
        );

        ERC721Collection newCollection = ERC721Collection(collectionAddress);

        newCollection.addAdmin(presale);
        newCollection.addAdmin(airdrop);
        newCollection.setWhitelistContractFilter(whitelistContractFilter);
        newCollection.transferOwnership(msg.sender);

        erc721Collections.push(newCollection);

        address addressCollection = address(newCollection);

        emit CollectionCreated(addressCollection);
    }

    /// @notice Function to print the number of created NFT collections in the given factory
    /// @return The Number NFT Collections
    function getCountERC721Collection() external view returns (uint256) {
        return erc721Collections.length;
    }

    ///@notice Create collection via bytecode
    /// @param tokenName Сollection name
    /// @param tokenSymbol Сollection symbol
    /// @param baseURICollection Base URI to form Token URI (address IPFS)
    /// @param maxSupply The maximum number of tokens that can be minted
    /// @return Address Collection
    function createCollection(
        string memory tokenName,
        string memory tokenSymbol,
        string memory baseURICollection,
        uint256 maxSupply
    ) private returns (address) {
        bytes memory bytecode = getBytecode(
            tokenName,
            tokenSymbol,
            baseURICollection,
            maxSupply
        );

        bytes32 salt = keccak256(
            abi.encodePacked(
                block.timestamp,
                tokenName,
                tokenSymbol,
                baseURICollection,
                maxSupply
            )
        );

        address addr = Create2.deploy(0, salt, bytecode);

        return addr;
    }

    function getBytecode(
        string memory tokenName,
        string memory tokenSymbol,
        string memory baseURICollection,
        uint256 maxSupply
    ) private view returns (bytes memory) {
        bytes memory bytecode = abi.encodePacked(
            ERC721_BYTECODE,
            abi.encode(
                tokenName,
                tokenSymbol,
                maxSupply,
                baseURICollection,
                address(this)
            )
        );

        return bytecode;
    }

    /// @notice Collection creation event
    /// @param collection Collection Address
    event CollectionCreated(address collection);

    /// @notice Change of address event
    /// @param nameContract Contract Name
    /// @param oldAddress Old contract address
    /// @param newAddress New contract address
    event ChangeAddressContract(
        bytes32 nameContract,
        address oldAddress,
        address newAddress
    );
}
