// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

/// @title ERC-165 Standard Interface Detection
/// @author Nick Johnson, Fabian Vogelsteller, Jordi Baylina
/// @notice Interface for detecting supported interfaces in contracts
/// @dev See https://eips.ethereum.org/EIPS/eip-165
interface IERC165 {
    /// @notice Checks if a contract implements an interface
    /// @dev Interface identification is specified in ERC-165
    /// @param interfaceId The interface identifier, as specified in ERC-165
    /// @return True if the contract implements `interfaceId` and
    ///  `interfaceId` is not 0xffffffff, false otherwise
    function supportsInterface(bytes4 interfaceId) external view returns (bool);
}
