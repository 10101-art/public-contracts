// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./Presale.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";


/**
 * Presale contract for native BNB/ETH or other token
 */
contract ETHPresale is OwnableExt, Pausable{
    uint256 public tokenPrice;
    uint public maxTokensAvailable;
    uint public totalTokensSold = 0;
    uint public activatingTimestamp;

    address public beneficiary;

    bool public isPresaleActive = false;

    Presale public presaleContract;
    address public collectionAddress;

    event PresaleTokensBought(address buyer, uint tokensAmount);
    event RealTokensClaimed(address buyer, uint tokensAmount);



    struct Purchase {
        uint tokenAmount;
        bool tokensClaimed;
    }


    mapping(address => Purchase) public purchases;


    constructor(uint _maxTokensAvailable, uint256 _tokenPrice, uint _activatingTimestamp, address _presaleAddress, address _collectionAddress, address _beneficiary) {
        maxTokensAvailable = _maxTokensAvailable;
        tokenPrice = _tokenPrice;
        activatingTimestamp = _activatingTimestamp;
        presaleContract = Presale(_presaleAddress);
        collectionAddress = _collectionAddress;
        beneficiary = _beneficiary;
    }

    /*
    @notice Pre-buy tokens
    */
    function buyTokens(uint tokenAmount) public payable whenNotPaused {

        require(isPresaleActive, "Presale is not active");
        require(beneficiary != address(0), "Beneficiary not set");

        require(totalTokensSold + tokenAmount <= maxTokensAvailable, "Not enough tokens available");
        require(msg.value == tokenAmount * tokenPrice, "Incorrect Ether value");
        require(!purchases[msg.sender].tokensClaimed, "Tokens already claimed");

        purchases[msg.sender].tokenAmount += tokenAmount;
        totalTokensSold += tokenAmount;

        payable(beneficiary).transfer(msg.value);

        emit PresaleTokensBought(msg.sender, tokenAmount);
    }

    /*
    @notice Claim tokens when presale is over
    */
    function getTokens() public whenNotPaused {

        require(block.timestamp >= activatingTimestamp, "It is not time yet");
        require(purchases[msg.sender].tokenAmount > 0, "No tokens to claim");
        require(!purchases[msg.sender].tokensClaimed, "Tokens already claimed");


        presaleContract.getTokensByAdminToUser(collectionAddress, msg.sender, purchases[msg.sender].tokenAmount);

        purchases[msg.sender].tokensClaimed = true;
        emit RealTokensClaimed(msg.sender, purchases[msg.sender].tokenAmount);
    }

    //Withdraw ERC20
    function withdrawERC20(address tokenAddress, uint256 amount) public onlyAdmin {
        IERC20 token = IERC20(tokenAddress);
        token.transfer(msg.sender, amount);
    }

    //Withdraw erc721
    function withdrawERC721(address tokenAddress, uint tokenId) public onlyAdmin {
        IERC721 token = IERC721(tokenAddress);
        token.transferFrom(address(this), msg.sender, tokenId);
    }


    function setTokenPrice(uint newPrice) public onlyAdmin {
        tokenPrice = newPrice;
    }

    function setPresaleActive(bool _isPresaleActive) public onlyAdmin {
        isPresaleActive = _isPresaleActive;
    }

    function setPrice(uint256 _tokenPrice) public onlyAdmin {
        tokenPrice = _tokenPrice;
    }

    function setMaxTokensAvailable(uint _maxTokensAvailable) public onlyAdmin {
        maxTokensAvailable = _maxTokensAvailable;
    }

    function setBeneficiary(address _beneficiary) public onlyAdmin {
        beneficiary = _beneficiary;
    }

    function changePresaleContract(address _presaleAddress) public onlyAdmin {
        presaleContract = Presale(_presaleAddress);
    }

    function changeCollectionAddress(address _collectionAddress) public onlyAdmin {
        collectionAddress = _collectionAddress;
    }

    function changeActivatingTimestamp(uint _activatingTimestamp) public onlyAdmin {
        activatingTimestamp = _activatingTimestamp;
    }



}
