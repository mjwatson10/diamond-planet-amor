// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

import {LibDiamond} from "../libraries/LibDiamond.sol";
import {IDiamondLoupe} from "../interfaces/IDiamondLoupe.sol";
import {IERC165} from "../interfaces/IERC165.sol";

/// @title Diamond Loupe Facet
/// @author Nick Mudge <nick@perfectabstractions.com>, Planet Amor Team
/// @notice Provides introspection functions for the Diamond
/// @dev Implements ERC-165 and Diamond Loupe interfaces
contract DiamondLoupeFacet is IDiamondLoupe, IERC165 {
    /// @notice Gets all facets and their selectors
    /// @dev Returns array of facet addresses and their function selectors
    /// @return facets_ Array of facet information
    function facets() external view override returns (Facet[] memory facets_) {
        LibDiamond.DiamondStorage storage ds = LibDiamond.diamondStorage();
        uint256 numFacets = ds.facetAddresses.length;
        facets_ = new Facet[](numFacets);
        for (uint256 i; i < numFacets; i++) {
            address facetAddress_ = ds.facetAddresses[i];
            facets_[i].facetAddress = facetAddress_;
            facets_[i].functionSelectors = ds.facetFunctionSelectors[facetAddress_].functionSelectors;
        }
    }

    /// @notice Gets all selectors for a facet
    /// @dev Returns array of function selectors for given facet address
    /// @param _facet The facet address to query
    /// @return facetFunctionSelectors_ Array of function selectors
    function facetFunctionSelectors(address _facet) external view override returns (bytes4[] memory facetFunctionSelectors_) {
        LibDiamond.DiamondStorage storage ds = LibDiamond.diamondStorage();
        facetFunctionSelectors_ = ds.facetFunctionSelectors[_facet].functionSelectors;
    }

    /// @notice Gets all facet addresses
    /// @dev Returns array of all facet addresses used by the diamond
    /// @return facetAddresses_ Array of facet addresses
    function facetAddresses() external view override returns (address[] memory facetAddresses_) {
        LibDiamond.DiamondStorage storage ds = LibDiamond.diamondStorage();
        facetAddresses_ = ds.facetAddresses;
    }

    /// @notice Gets the facet address for a selector
    /// @dev Returns the facet address that supports the given selector
    /// @param _functionSelector Function selector to query
    /// @return facetAddress_ The facet address for the selector
    function facetAddress(bytes4 _functionSelector) external view override returns (address facetAddress_) {
        LibDiamond.DiamondStorage storage ds = LibDiamond.diamondStorage();
        facetAddress_ = ds.selectorToFacetAndPosition[_functionSelector].facetAddress;
    }

    /// @notice Checks interface support
    /// @dev Implementation of IERC165 interface detection
    /// @param _interfaceId Interface identifier to check
    /// @return True if interface is supported
    function supportsInterface(bytes4 _interfaceId) external view override returns (bool) {
        LibDiamond.DiamondStorage storage ds = LibDiamond.diamondStorage();
        return ds.supportedInterfaces[_interfaceId];
    }
}
