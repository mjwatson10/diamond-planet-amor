// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

/// @title ERC-173 Contract Ownership Standard
/// @author Nick Mudge <nick@perfectabstractions.com>
/// @notice Standard interface for contract ownership
/// @dev See https://eips.ethereum.org/EIPS/eip-173
interface IERC173 {
    /// @notice Emitted when contract ownership is transferred
    /// @param previousOwner Address of the previous owner
    /// @param newOwner Address of the new owner
    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /// @notice Get the address of the contract owner
    /// @return The address of the owner
    function owner() external view returns (address);

    /// @notice Transfer contract ownership to a new address
    /// @dev Can only be called by the current owner
    /// @param newOwner Address to receive contract ownership
    function transferOwnership(address newOwner) external;
}
