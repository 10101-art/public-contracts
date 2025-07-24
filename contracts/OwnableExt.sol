// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/Ownable.sol";

///@title Contract extension for a contract Ownable
contract OwnableExt is Ownable {
    /// @notice Mapping admins
    mapping(address => bool) public admins;

    /* Modifier to check if the user is an admin */
    modifier onlyAdmin() {
        require(
            admins[msg.sender] || msg.sender == owner(),
            "The sender is not an admin!"
        );
        _;
    }

    /// @notice Function to add admin
    /// @dev Only Owner
    /// @param _account Address account
    function addAdmin(address _account) external onlyOwner {
        admins[_account] = true;

        emit AddingAdmin(_account);
    }

    /// @notice Function to remove admin
    /// @dev Only Owner
    /// @param _account Address account
    function deleteAdmin(address _account) external onlyOwner {
        delete admins[_account];

        emit RemovingAdmin(_account);
    }

    event AddingAdmin(address account);
    event RemovingAdmin(address account);
}
