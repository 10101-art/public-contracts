// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./OwnableExt.sol";
import "./Airdrop.sol";
import "@openzeppelin/contracts/interfaces/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "./Errors.sol";

///@title Contract for the presale of collections
contract Presale is Airdrop,Errors {
    /* using library */
    using SafeERC20 for IERC20;
    /* Structure Collection */
    struct Collection {
        /* Whitelist collection price */
        uint256 whitelistPrice;
        /* Public collection price */
        uint256 publicPrice;

        /* Price in wei. Marked as wei cuz we cat run contract on another chains */
        uint256 weiPrice;

        /* Start of sales according to the whitelist */
        uint256 startWhitelistTimestamp;
        /* Start of sales for everyone */
        uint256 startPublicTimestamp;
        /* Stop of sales according to the whitelist */
        uint256 stopWhitelistTimestamp;
        /* Stop of sales for everyone */
        uint256 stopTimestamp;
        /* Address ERC20 Token for buy */
        address erc20Address;
    }

    /// @notice Mapping information NFT collections
    mapping(address => Collection) public collectionInformations;

    /// @notice Mapping buy token NFT collections
    mapping(address => mapping(address => uint256)) public buyCollections;
    mapping(address => mapping(address => uint256)) public buyCollectionsWei;

    /// @notice Mapping purchased tokens according to the whitelist
    mapping(bytes32 => mapping(address => uint256)) public whitelistAmountBuy;

    /// @notice The address wich will receive collected fees
    address payable private beneficiary;

    constructor(address payable _beneficiary) {
        if (_beneficiary == address(0)) {
            _beneficiary = payable(address(this));
        }

        beneficiary = _beneficiary;
    }

    function addCollection(
        address collection
    ) external override whenNotPaused {}

    /// @notice Function to add collection to presale
    /// @dev Only Admin
    /// @param collection Address NFT collection
    /// @param whitelistPrice Whitelist collection price
    /// @param publicPrice Public collection price
    /// @param startWhitelistTimestamp Start of sales according to the whitelist
    /// @param startPublicTimestamp Start of sales for everyone
    /// @param stopWhitelistTimestamp Stop of sales according to the whitelist
    /// @param stopTimestamp Stop of sales for everyone
    /// @param erc20Address Address ERC20 for buy collection
    function addCollection(
        address collection,
        uint256 whitelistPrice,
        uint256 publicPrice,

        uint256 weiPrice,

        uint256 startWhitelistTimestamp,
        uint256 startPublicTimestamp,
        uint256 stopWhitelistTimestamp,
        uint256 stopTimestamp,
        address erc20Address
    ) external onlyAdmin checkRemoveCollection(collection) whenNotPaused {
        _beforeAddCollection(
            whitelistPrice,
            publicPrice,
            weiPrice,
            startWhitelistTimestamp,
            startPublicTimestamp,
            stopWhitelistTimestamp,
            stopTimestamp,
            erc20Address
        );

        Collection memory newCollection = Collection({
            whitelistPrice: whitelistPrice,
            publicPrice: publicPrice,
            weiPrice: weiPrice,
            startWhitelistTimestamp: startWhitelistTimestamp,
            startPublicTimestamp: startPublicTimestamp,
            stopWhitelistTimestamp: stopWhitelistTimestamp,
            stopTimestamp: stopTimestamp,
            erc20Address: erc20Address
        });

        collections[collection] = true;
        collectionInformations[collection] = newCollection;

        emit AddingCollection(collection);
    }

    /// @notice Function to edit collection to presale
    /// @dev Only Admin
    /// @param collection Address NFT collection
    /// @param whitelistPrice Whitelist collection price
    /// @param publicPrice Public collection price
    /// @param startWhitelistTimestamp Start of sales according to the whitelist
    /// @param startPublicTimestamp Start of sales for everyone
    /// @param stopWhitelistTimestamp Stop of sales according to the whitelist
    /// @param stopTimestamp Stop of sales for everyone
    /// @param erc20Address Address ERC20 for buy collection
    function editCollection(
        address collection,
        uint256 whitelistPrice,
        uint256 publicPrice,
        uint256 weiPrice,
        uint256 startWhitelistTimestamp,
        uint256 startPublicTimestamp,
        uint256 stopWhitelistTimestamp,
        uint256 stopTimestamp,
        address erc20Address
    ) external onlyAdmin checkAddCollection(collection) whenNotPaused {
        _beforeAddCollection(
            whitelistPrice,
            publicPrice,
            weiPrice,
            startWhitelistTimestamp,
            startPublicTimestamp,
            stopWhitelistTimestamp,
            stopTimestamp,
            erc20Address
        );

        Collection memory collectionEdit = Collection({
            whitelistPrice: whitelistPrice,
            publicPrice: publicPrice,
            weiPrice: weiPrice,
            startWhitelistTimestamp: startWhitelistTimestamp,
            startPublicTimestamp: startPublicTimestamp,
            stopWhitelistTimestamp: stopWhitelistTimestamp,
            stopTimestamp: stopTimestamp,
            erc20Address: erc20Address
        });

        collectionInformations[collection] = collectionEdit;

        emit EditingCollection(collection);
    }

    /// @notice Function to remove collection from presale
    /// @dev Only Admin
    /// @param collection Address NFT collection
    function removeCollection(
        address collection
    ) external override onlyAdmin checkAddCollection(collection) whenNotPaused {
        Collection storage erc721Information = collectionInformations[
            collection
        ];
        require(
            (block.timestamp < erc721Information.startWhitelistTimestamp &&
                block.timestamp < erc721Information.startPublicTimestamp) ||
                block.timestamp > erc721Information.stopTimestamp,
            ERROR_DELETION_PRIMARY_SALE_STARTED
        );

        delete collections[collection];
        delete collectionInformations[collection];

        emit RemovingCollection(collection);
    }

    function burnAll(
        address collection,
        uint256 amount
    ) external onlyAdmin whenNotPaused {
        ERC721Collection erc721 = ERC721Collection(collection);

        require(
            erc721.totalSupply() != erc721.maxSupply() &&
                (block.timestamp >
                    collectionInformations[collection].stopTimestamp),
            ERROR_BURN_ALL_NOT_AVAILABLE
        );

        erc721.burnAll(amount);

        emit BurningTokens(collection);
    }

    /// @notice The function of transferring ERC20 tokens from the contract to the owner
    /// @dev Only Admin
    /// @param _collection Address ERC721A
    /// @param _amount The Number ER20 token
    function withdraw(
        address _collection,
        uint256 _amount
    ) external onlyAdmin whenNotPaused {
        IERC20 erc20 = IERC20(collectionInformations[_collection].erc20Address);
        uint256 balanceContract = erc20.balanceOf(beneficiary);
        address ownerContract = owner();

        require(
            balanceContract != 0,
            ERROR_NOTHING_ON_BALANCE
        );

        if (address(this) == beneficiary) {
            erc20.safeTransfer(
                ownerContract,
                _amount <= balanceContract ? _amount : balanceContract
            );
        } else {
            erc20.safeTransferFrom(
                beneficiary,
                ownerContract,
                _amount <= balanceContract ? _amount : balanceContract
            );
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
    ) internal view override returns (bool) {
        bool isWhite = Airdrop.isWhitelist(collection, proofs, leaf);

        Collection storage erc721Information = collectionInformations[
            collection
        ];

        return
            isWhite &&
            (erc721Information.startWhitelistTimestamp <= block.timestamp &&
                block.timestamp <= erc721Information.stopWhitelistTimestamp);
    }

    /// @notice Function for issuing NFT collection tokens for free
    /// @dev Only Whitelist for users
    /// @param collection Address NFT collection
    /// @param proofs A set of proofs to confirm that an account is whitelisted
    /// @param tokenAmount Number token for presale
    /// @param maxAmount Max Number token for presale. For check amount
    function getTokens(
        address collection,
        bytes32[] calldata proofs,
        uint256 tokenAmount,
        uint256 maxAmount
    ) external override checkAddCollection(collection) whenNotPaused {
        ERC721Collection erc721 = ERC721Collection(collection);
        IERC20 erc20 = IERC20(collectionInformations[collection].erc20Address);

        bytes32 accountHash = keccak256(
            abi.encodePacked(msg.sender, maxAmount)
        );

        require(
            !erc721.isBurnt(),
            ERROR_COLLECTION_BURNED
        );

        require(
            block.timestamp <= collectionInformations[collection].stopTimestamp,
            ERROR_PURCHASE_TIME_ENDED
        );

        require(
            erc721.totalSupply() + tokenAmount <= erc721.maxSupply(),
            ERROR_NUMBER_FRAGMENTS_NOT_FOUND
        );

        require(
            beneficiary != address(0),
            ERROR_ADDRESS_BENEFICIARY_NULL
        );

        Collection memory collectionInformation = collectionInformations[
            collection
        ];

        uint256 cTokenWhiteAmount = getWhitelistAmount(
            collection,
            accountHash,
            proofs,
            tokenAmount,
            maxAmount
        );

        uint256 cTokenPublicAmount = getPublicAmount(
            collectionInformation,
            cTokenWhiteAmount,
            tokenAmount
        );

        uint256 cTotalPrice = getTotalPriceCollection(
            collectionInformation,
            cTokenWhiteAmount,
            cTokenPublicAmount
        );

        erc20.safeTransferFrom(msg.sender, beneficiary, cTotalPrice);

        erc721.mint(msg.sender, cTokenPublicAmount + cTokenWhiteAmount);

        whitelistAmountBuy[accountHash][collection] += cTokenWhiteAmount;
        buyCollections[collection][msg.sender] += cTotalPrice;

        emit GetTokens(
            collection,
            msg.sender,
            cTokenPublicAmount + cTokenWhiteAmount
        );
    }

    /*
    * @notice getTokens but for wei
    * @param collection Address NFT collection
    * @param tokenAmount Number token for sale
    */
    function getTokensWei(address collection, uint256 tokenAmount) external payable checkAddCollection(collection) whenNotPaused {


        ERC721Collection erc721 = ERC721Collection(collection);
        Collection memory collectionInformation = collectionInformations[collection];

        require(
            collectionInformation.startPublicTimestamp <= block.timestamp,
            ERROR_PURCHASE_TIME_NOT_YET
        );
        require(
            block.timestamp <= collectionInformations[collection].stopTimestamp,
            ERROR_PURCHASE_TIME_ENDED
        );

        require(
            collectionInformation.weiPrice > 0,
            ERROR_COLLECTION_NOT_SUPPORT_PURCHASE_WEI
        );


        uint256 cTotalWeiPrice = getWeiPrice(collectionInformation, tokenAmount);
        require(msg.value >= cTotalWeiPrice, ERROR_NOT_ENOUGH_MONEY);

        require(
            !erc721.isBurnt(),
            ERROR_COLLECTION_BURNED
        );
        require(
            erc721.totalSupply() + tokenAmount <= erc721.maxSupply(),
            ERROR_NUMBER_FRAGMENTS_NOT_FOUND
        );
        require(
            beneficiary != address(0),
            ERROR_ADDRESS_BENEFICIARY_NULL
        );

        // Mint tokens
        erc721.mint(msg.sender, tokenAmount);

        buyCollectionsWei[collection][msg.sender] += cTotalWeiPrice;

        //Return the extra money
        /*if (msg.value > cTotalWeiPrice) {
            payable(msg.sender).transfer(msg.value - cTotalWeiPrice);
        }*/

        //Send to beneficiary
        payable(beneficiary).transfer(cTotalWeiPrice);

        emit GetTokens(collection, msg.sender, tokenAmount);
    }

    /*
    * @notice getTokens but for admin to user
    * @param collection Address NFT collection
    * @param user Address user
    * @param tokenAmount Number token for sale
    */
    function getTokensByAdminToUser(address collection, address user, uint256 tokenAmount) external onlyAdmin checkAddCollection(collection) whenNotPaused {
        ERC721Collection erc721 = ERC721Collection(collection);
        Collection memory collectionInformation = collectionInformations[collection];

        require(
            !erc721.isBurnt(),
            ERROR_COLLECTION_BURNED
        );
        require(
            erc721.totalSupply() + tokenAmount <= erc721.maxSupply(),
            ERROR_NUMBER_FRAGMENTS_NOT_FOUND
        );

        // Mint tokens
        erc721.mint(user, tokenAmount);

        emit GetTokens(collection, user, tokenAmount);
    }

    /// @notice Function to return funds to the account
    /// @param collection Address NFT collection
    /*function returnFunds(
        address collection
    ) external checkAddCollection(collection) whenNotPaused {
        ERC721Collection erc721 = ERC721Collection(collection);
        Collection memory erc721Information = collectionInformations[
            collection
        ];

        IERC20 erc20 = IERC20(erc721Information.erc20Address);

        require(erc721.isBurnt(), ERROR_COLLECTION_TOKENS_NOT_BURNED);

        uint256 cTotalFunds = buyCollections[collection][msg.sender];
        uint256 weiTotalFunds = buyCollectionsWei[collection][msg.sender];

        require(cTotalFunds > 0 && weiTotalFunds > 0, ERROR_NOTHING_TO_RETURN);

        require(
            erc20.balanceOf(beneficiary) >= cTotalFunds,
            ERROR_NOT_ENOUGH_MONEY_TO_RETURN
        );

        require(
            address(this).balance >= weiTotalFunds,
            ERROR_NOT_ENOUGH_MONEY_TO_RETURN
        );

        if (address(this) == beneficiary) {
            erc20.safeTransfer(msg.sender, cTotalFunds);
        } else {
            erc20.safeTransferFrom(beneficiary, msg.sender, cTotalFunds);
        }

        //Return the wei
        payable(msg.sender).transfer(weiTotalFunds);

        delete buyCollections[collection][msg.sender];
        delete buyCollectionsWei[collection][msg.sender];

        emit ReturningFunds(msg.sender, collection, cTotalFunds);
    }*/

    /// @notice Function set Beneficiary
    /// @param _beneficiary Address beneficiary
    function setBeneficiary(
        address payable _beneficiary
    ) external onlyOwner whenNotPaused {
        require(
            _beneficiary != address(0),
            ERROR_ADDRESS_BENEFICIARY_NULL
        );
        address oldBeneficiary = beneficiary;

        beneficiary = _beneficiary;

        emit ChangedBeneficiaryPresale(oldBeneficiary, beneficiary);
    }

    /// @notice Function get Beneficiary
    function getBeneficiary() external view returns (address) {
        return beneficiary;
    }

    /// @notice Function for clearing the history of issuing tokens
    /// @dev Only Admin. Virtual method
    /// @param accountsDrop A set of data on accounts for which you need to reset the history of issuing tokens
    function clearDropTokenAccounts(
        DropToken[] calldata accountsDrop
    ) external override onlyAdmin whenNotPaused {
        for (uint256 i = 0; i < accountsDrop.length; ) {
            delete whitelistAmountBuy[accountsDrop[i].accountHash][
                accountsDrop[i].collection
            ];

            unchecked {
                i += 1;
            }
        }
    }

    /// @notice Private function for calculating the total purchase amount of tokens
    /// @dev Private method
    /// @param _collection NFT collection
    /// @param _whitelistTokenCount count whitelist token
    /// @param _publiclistTokenCount count publiclist token
    function getTotalPriceCollection(
        Collection memory _collection,
        uint256 _whitelistTokenCount,
        uint256 _publiclistTokenCount
    ) private pure returns (uint256) {
        uint256 totalPrice = _collection.whitelistPrice *
            _whitelistTokenCount +
            (_collection.publicPrice * _publiclistTokenCount);

        return totalPrice;
    }

    /*
    * @notice Private function for calculating the price in wei
    * @dev Private method
    * @param _collection NFT collection
    * @param _amount Number token for presale
    * @return
    */
    function getWeiPrice(Collection memory _collection, uint256 _buyingTokenCount) private view returns (uint256) {
        return _collection.weiPrice * _buyingTokenCount;
    }

    /// @notice Private function for displaying the number of whitelisted tokens that can be bought at the whitelisted price
    /// @dev Private method
    /// @param _collection Address NFT collection
    /// @param _accountHash Hash account (address account + maxAmountWhiteList)
    /// @param _proofs A set of proofs to confirm that an account is whitelisted
    /// @param _amount Number token for presale
    /// @param _maxAmount Max Number token for presale. For check amount
    /// @return
    function getWhitelistAmount(
        address _collection,
        bytes32 _accountHash,
        bytes32[] calldata _proofs,
        uint256 _amount,
        uint256 _maxAmount
    ) private view returns (uint256) {
        bool isWhite = isWhitelist(_collection, _proofs, _accountHash);

        if (!isWhite) return 0;

        uint256 whitelistTokenBuy = whitelistAmountBuy[_accountHash][
            _collection
        ];

        if (whitelistTokenBuy >= _maxAmount) return 0;

        uint256 availableWhiteListTokens = _maxAmount - whitelistTokenBuy;
        uint256 amount = _amount;

        if (availableWhiteListTokens >= amount) return amount;

        return availableWhiteListTokens;
    }

    /// @notice Private function for displaying the number of public tokens that can be bought at the public price
    /// @dev Private method
    /// @param _collection NFT collection
    /// @param _whitelistCount count whitelist token account
    /// @param _amount Number token for presale
    function getPublicAmount(
        Collection memory _collection,
        uint256 _whitelistCount,
        uint256 _amount
    ) private view returns (uint256) {
        uint256 totalPublicAmount = (_collection.startPublicTimestamp <=
            block.timestamp &&
            block.timestamp <= _collection.stopTimestamp)
            ? _amount - _whitelistCount
            : 0;

        return totalPublicAmount;
    }




    function _beforeAddCollection(
        uint256 whitelistPrice,
        uint256 publicPrice,
        uint256 weiPrice,
        uint256 startWhitelistTimestamp,
        uint256 startPublicTimestamp,
        uint256 stopWhitelistTimestamp,
        uint256 stopTimestamp,
        address erc20Address
    ) private pure {
        require(
            erc20Address != address(0),
            ERROR_ERC20_ADDRESS_NULL
        );
        require(
            whitelistPrice < publicPrice,
            ERROR_WHITELIST_PRICE_LESS_THAN_PUBLIC_PRICE
        );
        require(
            startWhitelistTimestamp <= startPublicTimestamp,
            ERROR_START_WHITELIST_TIMESTAMP_LESS_OR_EQUAL_START_PUBLIC_TIMESTAMP
        );
        require(
            startWhitelistTimestamp < stopWhitelistTimestamp,
            ERROR_START_WHITELIST_TIMESTAMP_LESS_STOP_WHITELIST_TIMESTAMP
        );
        require(
            startWhitelistTimestamp < stopTimestamp,
            ERROR_START_WHITELIST_TIMESTAMP_LESS_STOP_TIMESTAMP
        );
        require(
            startPublicTimestamp < stopTimestamp,
            ERROR_START_WHITELIST_TIMESTAMP_LESS_STOP_TIMESTAMP
        );
    }


    /// @notice Returning funds event
    /// @param account Account Address
    /// @param collection Collection Address
    /// @param amount The Number ERC20 Tokens
    event ReturningFunds(address account, address collection, uint256 amount);

    /// @notice Burning Tokens event
    /// @param collection Collection Address
    event BurningTokens(address collection);

    /// @notice Changed Address Beneficiary event
    /// @param oldBeneficiary Old address Beneficiary
    /// @param newBeneficiary New address Beneficiary
    event ChangedBeneficiaryPresale(
        address oldBeneficiary,
        address newBeneficiary
    );

    /// @notice Editing Address collection info event
    /// @param collection Address collection
    event EditingCollection(address collection);
}
