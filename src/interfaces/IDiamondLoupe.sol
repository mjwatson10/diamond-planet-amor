// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

/// @title Diamond Loupe Interface for EIP-2535
/// @author Nick Mudge <nick@perfectabstractions.com>
/// @notice Interface for viewing facet information in diamond contracts
/// @dev These functions are expected to be called frequently by tools
interface IDiamondLoupe {
    /// @notice Struct containing facet information
    /// @dev Used by getters to return facet data
    struct Facet {
        address facetAddress;      /// @notice Address of the facet contract
        bytes4[] functionSelectors; /// @notice List of function selectors supported by the facet
    }

    /// @notice Gets all facet addresses and their function selectors
    /// @return facets_ Array of facet information
    function facets() external view returns (Facet[] memory facets_);

    /// @notice Gets all function selectors supported by a facet
    /// @param _facet The facet address
    /// @return facetFunctionSelectors_ Array of function selectors
    function facetFunctionSelectors(address _facet) external view returns (bytes4[] memory facetFunctionSelectors_);

    /// @notice Gets all facet addresses used by the diamond
    /// @return facetAddresses_ Array of facet addresses
    function facetAddresses() external view returns (address[] memory facetAddresses_);

    /// @notice Gets the facet address that supports the given selector
    /// @param _functionSelector Function selector to query
    /// @return facetAddress_ The facet address
    function facetAddress(bytes4 _functionSelector) external view returns (address facetAddress_);
}
