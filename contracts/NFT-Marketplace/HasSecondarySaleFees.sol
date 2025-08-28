// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/utils/introspection/ERC165Storage.sol";
import "./IHasSecondarySaleFees.sol";

/// @title Abstract contract "Has Secondary Sale Fees"
abstract contract HasSecondarySaleFees is ERC165Storage, IHasSecondarySaleFees {
    event SecondarySaleFees(
        uint256 indexed tokenId,
        address[] recipients,
        uint256[] bps
    );

    constructor() {
        _registerInterface(type(IHasSecondarySaleFees).interfaceId);
    }

    function getFeeRecipients(
        uint256 id
    ) public view virtual override returns (address payable[] memory);

    function getFeeBps(
        uint256 id
    ) public view virtual override returns (uint256[] memory);
}
