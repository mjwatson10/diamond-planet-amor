// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

/// @title Diamond Cut Interface for EIP-2535
/// @author Nick Mudge <nick@perfectabstractions.com>
/// @notice Interface for modifying diamond facets and functions
/// @dev Defines the standard for upgrading/modifying diamond proxy contracts
interface IDiamondCut {
    /// @notice Enum for facet cut actions
    /// @dev Add=0, Replace=1, Remove=2
    enum FacetCutAction {Add, Replace, Remove}

    /// @notice Struct for facet cut information
    /// @dev Contains all necessary data for a diamond cut operation
    struct FacetCut {
        address facetAddress;      /// @notice Address of facet to add/replace/remove
        FacetCutAction action;     /// @notice Action to perform
        bytes4[] functionSelectors; /// @notice Function selectors to modify
    }

    /// @notice Emitted when a diamond cut is executed
    /// @param _diamondCut Array of facet addresses and function selectors
    /// @param _init Address of initialization contract
    /// @param _calldata Calldata for initialization
    event DiamondCut(FacetCut[] _diamondCut, address _init, bytes _calldata);

    /// @notice Performs a diamond cut operation
    /// @dev Add/replace/remove any number of functions and optionally execute
    ///      a function with delegatecall
    /// @param _diamondCut Array of facet addresses and function selectors
    /// @param _init Address of initialization contract
    /// @param _calldata Calldata for initialization
    function diamondCut(
        FacetCut[] calldata _diamondCut,
        address _init,
        bytes calldata _calldata
    ) external;
}
