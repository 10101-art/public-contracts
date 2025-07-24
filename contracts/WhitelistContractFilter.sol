// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./OwnableExt.sol";
import "./libs/UintLibrary.sol";
import "@openzeppelin/contracts/utils/Address.sol";

/// @title Whitelist Contract Filter
/// @notice This contract is designed to add filter to WhitelistContract filter element
/// @dev Is a service contract for other contracts
contract WhitelistContractFilter is OwnableExt {
    using UintLibrary for uint256;
    /* Structure FilterBatch */
    struct FilterBatch {
        /* Address element for filters*/
        address element;
        /* Array filters addresses */
        address[] filters;
    }

    /// @notice Enables/disables the Whitelist Contract filter
    /// @dev Get property. For read
    bool public activeFilter;

    /// @notice Private WhitelistContract mapping
    /// @dev Get property. For read
    mapping(address => mapping(address => bool))
        public privateWhitelistContract;

    /// @notice Public WhitelistContract mapping
    /// @dev Get property. For read
    mapping(address => bool) public publicWhitelistContract;

    /// @notice Function add filter element for element private WhitelistContract
    /// @dev Public function. Only Admin
    /// @param element address element for WhitelistContractFilter
    /// @param contractAccount address filter for element
    function addFilterPrivate(
        address element,
        address contractAccount
    ) public onlyAdmin {
        require(
            Address.isContract(contractAccount),
            "The address you are trying to whitelist is not a contract!"
        );

        privateWhitelistContract[element][contractAccount] = true;

        emit AddingApproveContractAccount(element, contractAccount);
    }

    /// @notice Function remove filter element for element private WhitelistContract
    /// @dev Public function. Only Admin
    /// @param element address element for WhitelistContract
    /// @param contractAccount address filter for element
    function removeFilterPrivate(
        address element,
        address contractAccount
    ) public onlyAdmin {
        privateWhitelistContract[element][contractAccount] = false;

        emit RemovingApproveContractAccount(element, contractAccount);
    }

    function addFilterPublic(address contractAccount) external onlyAdmin {
        require(
            Address.isContract(contractAccount),
            "The address you are trying to whitelist is not a contract!"
        );

        publicWhitelistContract[contractAccount] = true;

        emit AddingApproveContractAccount(address(0), contractAccount);
    }

    function removeFilterPublic(address contractAccount) external onlyAdmin {
        publicWhitelistContract[contractAccount] = false;

        emit RemovingApproveContractAccount(address(0), contractAccount);
    }

    /// @notice Function batch add filter element for element private WhitelistContract
    /// @dev Public function. Only Admin.
    /// @param filters Array struct contractAccountApprove (element -> filters);
    function addFilterPrivateBatch(
        FilterBatch[] calldata filters
    ) external onlyAdmin {
        for (uint256 i = 0; i < filters.length; ) {
            FilterBatch memory filter = filters[i];

            for (uint256 j = 0; j < filter.filters.length; ) {
                if (!Address.isContract(filter.filters[j])) continue;

                mapping(address => bool)
                    storage privateWhitelistElement = privateWhitelistContract[
                        filter.element
                    ];
                privateWhitelistElement[filter.filters[j]] = true;

                emit AddingApproveContractAccount(
                    filter.element,
                    filter.filters[j]
                );

                unchecked {
                    j += 1;
                }
            }

            unchecked {
                i += 1;
            }
        }
    }

    /// @notice Function batch remove filter element for element private WhitelistContract
    /// @dev Public function. Only Admin
    /// @param filters Array struct contractAccountApprove (element -> filters);
    function removeFilterPrivateBatch(
        FilterBatch[] calldata filters
    ) external onlyAdmin {
        for (uint256 i = 0; i < filters.length; ) {
            FilterBatch memory filter = filters[i];
            for (uint256 j = 0; j < filter.filters.length; ) {
                mapping(address => bool)
                    storage privateWhitelistElement = privateWhitelistContract[
                        filter.element
                    ];
                privateWhitelistElement[filter.filters[j]] = false;

                emit RemovingApproveContractAccount(
                    filter.element,
                    filter.filters[j]
                );

                unchecked {
                    j += 1;
                }
            }

            unchecked {
                i += 1;
            }
        }
    }

    /// @notice Function batch add filter element for WhitelistContract public
    /// @dev Public function. Only Admin
    /// @param filters address filters for WhitelistContract public
    function addFilterPublicBatch(
        address[] calldata filters
    ) external onlyAdmin {
        for (uint256 i = 0; i < filters.length; ) {
            if (!Address.isContract(filters[i])) continue;

            publicWhitelistContract[filters[i]] = true;

            emit AddingApproveContractAccount(address(0), filters[i]);

            unchecked {
                i += 1;
            }
        }
    }

    /// @notice Function batch remove filter element for WhitelistContract public
    /// @dev Public function. Only Admin
    /// @param filters address filters for WhitelistContract public
    function removeFilterPublicBatch(
        address[] calldata filters
    ) external onlyAdmin {
        for (uint256 i = 0; i < filters.length; ) {
            publicWhitelistContract[filters[i]] = false;

            emit RemovingApproveContractAccount(address(0), filters[i]);

            unchecked {
                i += 1;
            }
        }
    }

    /// @notice Function enable/disable filter elements by WhitelistContract
    /// @dev Only Admin.
    /// @param isActive enable/disable filter (true - false)
    function changeFilter(bool isActive) external onlyAdmin {
        activeFilter = isActive;

        emit ChangingFilter(address(this), isActive);
    }

    /// @notice Function check filter element for WhitelistContract (and if contractAccount contract activity, otherwise true)
    /// @dev Public function. For read
    /// @param element address element for WhitelistContract
    /// @param contractAccount address filter for element
    function isApprovalContractAccount(
        address element,
        address contractAccount
    ) public view returns (bool) {
        return
            !activeFilter ||
            isExistApprovalContractAccount(element, contractAccount);
    }

    /// @notice Function check filter element for contractAccount element WhitelistContract or public contractAccount check
    /// @dev Private function. For read
    /// @param element address element for WhitelistContract (0x0 address - public WhitelistContract)
    /// @param contractAccount address filter for element
    function isExistApprovalContractAccount(
        address element,
        address contractAccount
    ) private view returns (bool) {
        return
            !Address.isContract(contractAccount) ||
            (publicWhitelistContract[contractAccount] ||
                privateWhitelistContract[element][contractAccount]);
    }

    /// @notice Adding Approve filter element event
    /// @param element address element for WhitelistContract
    /// @param contractAccount address filter for element
    event AddingApproveContractAccount(
        address element,
        address contractAccount
    );
    /// @notice Removing Approve contractAccount element event
    /// @param element address element for WhitelistContract
    /// @param contractAccount address contractAccount for element
    event RemovingApproveContractAccount(
        address element,
        address contractAccount
    );
    /// @notice Changing filter event
    /// @param contractAccount Address contract WhitelistContract
    /// @param status Status active filter
    event ChangingFilter(address contractAccount, bool status);
}
