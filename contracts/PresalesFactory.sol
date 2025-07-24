// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./Presale.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "./ETHPresale.sol";
import "@openzeppelin/contracts/utils/Create2.sol";

contract PresalesFactory is OwnableExt{

    mapping(string => bytes) public presalesContracts;
    string[] public presalesContractsNames;

    constructor() {
        presalesContracts["ETHPresale"] = type(ETHPresale).creationCode;
        presalesContractsNames.push("ETHPresale");
    }

    function addPresaleContract(string memory _name, bytes memory _bytecode) external onlyAdmin {
        presalesContracts[_name] = _bytecode;
        presalesContractsNames.push(_name);
    }

    function buildPresaleContract(string memory _name, uint _maxTokensAvailable, uint256 _tokenPrice, uint _activatingTimestamp, address _presaleAddress, address _collectionAddress, address _beneficiary) external onlyAdmin returns (address){
        bytes memory contractCode = presalesContracts[_name];


        bytes memory bytecode = abi.encodePacked(
            contractCode,
            abi.encode(
                _maxTokensAvailable, _tokenPrice, _activatingTimestamp, _presaleAddress, _collectionAddress, _beneficiary
            )
        );

        bytes32 salt = keccak256(abi.encodePacked(_maxTokensAvailable, _tokenPrice, _activatingTimestamp, _presaleAddress, _collectionAddress, _beneficiary));

        address presaleAddress = Create2.deploy(0, salt , bytecode);
        ETHPresale presaleContract = ETHPresale(presaleAddress);

        //Add current user to admin of presale contract
        presaleContract.addAdmin(msg.sender);
        presaleContract.transferOwnership(msg.sender);

        //Add presale contract to presale(manager) contract
        if(_presaleAddress != address(0)){
            Presale presale = Presale(_presaleAddress);
            presale.addAdmin(presaleAddress);
        }

        return presaleAddress;

    }




}
