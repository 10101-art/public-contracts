// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "erc721a/contracts/ERC721A.sol";
import "./OwnableExt.sol";
import "./WhitelistContractFilter.sol";
import "./Pausable.sol";

/// @title NFT Collection Contract
/// @dev Take https://github.com/chiru-labs/ERC721A as a basis
contract ERC721Collection is ERC721A, OwnableExt, Pausable {
    /// @notice Shows whether the collection is burned or not
    bool public isBurnt;
    /// @notice The maximum number of tokens that can be minted
    uint256 public maxSupply;
    /// @notice Base URI to form Token URI
    string public baseURI;
    /// @notice Metadata Frozen (change BaseURL)
    bool public isMetadataFrozen;
    uint256 public preSaleMint;
    bool public isBurnApproved;
    bool public isPausable = true;
    string public PROVENANCE;

    /// @notice If true then transferFrom is allowed
    bool public transferAllowedOverride = false;

    /// @notice WhitelistContractFilter address checking filter
    WhitelistContractFilter public whitelistContractFilter;

    /// @notice Constructor for creating an NFT collection
    /// @param _name Collection name
    /// @param _symbol Collection symbol
    /// @param _maxSupply The maximum number of tokens that can be minted
    /// @param _baseURICollection Base URI to form Token URI
    /// @param owner NFT collection owner
    constructor(
        string memory _name,
        string memory _symbol,
        uint256 _maxSupply,
        string memory _baseURICollection,
        address owner
    ) ERC721A(_name, _symbol) {
        maxSupply = _maxSupply;

        setBaseURI(_baseURICollection);

        if (owner != address(0)) {
            _transferOwnership(owner);
        }
    }

    modifier whenMetadataNotFreezen() {
        require(!isMetadataFrozen, "metadata frozen");
        _;
    }

    modifier whenNotFullyMinted() {
        require(totalSupply() < maxSupply, "tokens purchased");
        _;
    }

    /// @notice Function set new address contract WhitelistContractFilter
    /// @dev Just pass address(0) to turn this off
    function setWhitelistContractFilter(
        address _whitelistContractFilter
    ) external onlyAdmin {
        address oldValue = address(whitelistContractFilter);

        whitelistContractFilter = WhitelistContractFilter(
            _whitelistContractFilter
        );

        emit ChangingWhitelistContractFilter(
            _whitelistContractFilter,
            oldValue
        );
    }

    /// @notice Token collection minting function
    /// @param _to Account address for transferring tokens
    /// @param _quantity The number of tokens to mint.

    function mint(
        address _to,
        uint256 _quantity
    ) external onlyAdmin whenNotPaused {
        require(
            preSaleMint == 0 || totalSupply() + _quantity <= preSaleMint,
            "limit has been set on the mint of tokens"
        );

        require(
            totalSupply() + _quantity <= maxSupply,
            "it is impossible to mint such a number of tokens"
        );

        _mint(_to, _quantity);
    }

    /// @notice The function of burning all tokens of the collection
    /// @dev Only Admin
    function burnAll(uint256 amount) external onlyAdmin whenNotFullyMinted {
        uint256 total = ERC721A.totalSupply();

        require(total != 0, "nothing to burn");

        isBurnt = true;
        maxSupply = 0;

        unchecked {
            uint256 currentTokenId = total;
            uint256 amountBurntToken = 0;
            do {
                currentTokenId = currentTokenId - 1;

                emit Transfer(
                    ERC721A.ownerOf(currentTokenId),
                    address(0),
                    currentTokenId
                );

                amountBurntToken = amountBurntToken + 1;
            }
            while (currentTokenId != 0 && amount != amountBurntToken);
        }
    }

    // function burn(uint256 tokenId) external whenNotPaused {
    //     require(isBurnApproved, "burn not access");

    //     require(!isBurnt, "collection is burnt");

    //     _burn(tokenId);
    // }

    function setApproveBurn(bool _isBurnApproved) external onlyOwner {
        isBurnApproved = _isBurnApproved;
    }

    /// @notice Function to return the owner of the token
    /// @param tokenId Token Id collection
    function ownerOf(uint256 tokenId) public view override returns (address) {
        require(!isBurnt, "collection is burnt");

        return ERC721A.ownerOf(tokenId);
    }

    /// @notice Ovveride function checking Token Transfer
    /// @param from From address transfer
    /// @param to To address trasnfer
    /// @param startTokenId Start Token ID ERC721
    /// @param quantity Quantity Token ERC721
    function _beforeTokenTransfers(
        address from,
        address to,
        uint256 startTokenId,
        uint256 quantity
    ) internal view override {
        require(!isBurnt, "collection is burnt");
        require(checkApproval(to), "transferFrom is prohibited");

        require(
            (from == address(0) || totalSupply() == maxSupply) ||
            transferAllowedOverride,
            "not all tokens are minted"
        );
    }

    /// @notice Returns the total number of tokens in existence.
    function totalSupply() public view override returns (uint256) {
        return !isBurnt ? ERC721A.totalSupply() : 0;
    }

    /// @notice Returns the number of tokens in `owner`'s account.
    /// @param owner address owner
    function balanceOf(address owner) public view override returns (uint256) {
        return !isBurnt ? ERC721A.balanceOf(owner) : 0;
    }

    /// @notice Function for transferring a token from one account to another
    /// @param from Account address from where to transfer the token
    /// @param to Account address for transferring tokens
    /// @param tokenId Token Id collection
    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) public payable override whenNotPaused {
        _beforeTokenTransfers(from, to, tokenId, 1);

        ERC721A.transferFrom(from, to, tokenId);
    }

    function setApprovalForAll(
        address operator,
        bool approved
    ) public virtual override whenNotPaused {
        require(checkApproval(operator), "cannot approve");

        ERC721A.setApprovalForAll(operator, approved);
    }

    function approve(
        address to,
        uint256 tokenId
    ) public payable virtual override whenNotPaused {
        require(checkApproval(to), "cannot approve");

        ERC721A.approve(to, tokenId);
    }

    /// @notice Function to output the base URI
    function _baseURI() internal view override returns (string memory) {
        return baseURI;
    }

    /// @notice Function to write the base URI
    /// @param _newBaseURI New base URI for TokenURI
    function setBaseURI(
        string memory _newBaseURI
    ) public onlyAdmin whenMetadataNotFreezen {
        string memory oldbaseURI = baseURI;
        baseURI = _newBaseURI;

        emit MetadataUpdate(oldbaseURI, baseURI);
    }

    /// @notice Function pause contract
    function pause() external onlyAdmin {
        require(isPausable, "Pause function is disabled forever");
        Pausable._pause();
    }

    /// @notice Function unpause contract
    function unpause() external onlyAdmin {
        Pausable._unpause();
    }

    /// @notice Function to disable Pause function FOREVER
    function _disablePauseFunction() external onlyOwner {
        isPausable = false;
        if (paused()) {
            Pausable._unpause();
        }
    }

    /// @notice Function frozen metadata
    function _setMetadataFrozen() external onlyOwner {
        isMetadataFrozen = true;

        emit MetadataFrozen(address(this), owner());
    }

    /// @dev pass 0 to disable
    function setPresaleMint(uint256 _preSaleMint) external onlyAdmin {
        uint256 oldPreSaleMint = preSaleMint;
        preSaleMint = _preSaleMint;

        emit PresaleMintChanged(address(this), oldPreSaleMint, preSaleMint);
    }

    /// @notice Change transfer allowed override
    function setTransferAllowedOverride(
        bool _transferAllowedOverride
    ) external onlyAdmin {
        transferAllowedOverride = _transferAllowedOverride;
    }

    /// @notice Checking approve event
    /// @param account address account
    function checkApproval(address account) internal view returns (bool) {
        return
            address(whitelistContractFilter) == address(0) ||
            whitelistContractFilter.isApprovalContractAccount(
                address(this),
                account
            );
    }

    ///@notice Set Provenance for metadata
    ///@param _provenance Hash provenance
    function setProvenance(
        string memory _provenance
    ) external onlyAdmin whenMetadataNotFreezen {
        PROVENANCE = _provenance;
    }

    /// @notice Collection creation event
    /// @param newAddress new address
    /// @param oldAddress old address
    event ChangingWhitelistContractFilter(
        address newAddress,
        address oldAddress
    );

    /// @notice Collection metadata frozen event
    /// @param collection address collection
    /// @param owner address owner
    event MetadataFrozen(address collection, address owner);

    /// @notice Collection metadata update event
    /// @param oldURI string old URI collection
    /// @param newURI string new URI collection
    event MetadataUpdate(string oldURI, string newURI);

    /// @notice Pause disabled forever
    event PauseFunctionDisabledForever();

    /// @notice Collection change presaleMint event
    /// @param collection address this collection
    /// @param oldPresaleMint  old presale mint collection
    /// @param newPresaleMint  new presale mint collection
    event PresaleMintChanged(
        address collection,
        uint256 oldPresaleMint,
        uint256 newPresaleMint
    );
}
