// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

import { IDiamondCut } from "../interfaces/IDiamondCut.sol";
import { LibDiamond } from "../libraries/LibDiamond.sol";

/// @title Diamond Cut Facet
/// @author Nick Mudge <nick@perfectabstractions.com>, Planet Amor Team
/// @notice Handles diamond cut operations for upgrading the diamond
/// @dev Implements IDiamondCut interface for the EIP-2535 Diamond Standard
contract DiamondCutFacet is IDiamondCut {
    /// @notice Executes a diamond cut operation
    /// @dev Only callable by contract owner
    /// @param _diamondCut Array of facet cuts to perform
    /// @param _init Optional initialization contract address
    /// @param _calldata Optional initialization function call data
    function diamondCut(
        FacetCut[] calldata _diamondCut,
        address _init,
        bytes calldata _calldata
    ) external override {
        LibDiamond.enforceIsContractOwner();
        LibDiamond.diamondCut(_diamondCut, _init, _calldata);
    }
}
