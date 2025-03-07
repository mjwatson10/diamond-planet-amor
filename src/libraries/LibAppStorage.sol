// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

/// @title LibAppStorage - Storage layout for Planet Amor NFT
/// @notice Library for managing storage layout and constants for the Planet Amor collection
/// @dev Uses Diamond Storage pattern with namespaced structs
library LibAppStorage {
    /// @notice Storage struct for NFT-related data
    /// @dev Uses Diamond Storage pattern, ERC721A storage handled separately
    struct NFTStorage {
        /// @notice Base URI for token metadata
        string baseTokenURI;
        /// @notice Mapping from token ID to owner address
        mapping(uint256 => address) owners;
        /// @notice Mapping from owner address to balance
        mapping(address => uint256) balances;
        /// @notice Current token index for minting
        uint256 currentIndex;
        /// @notice Mint price (1 ETH)
        uint256 mintPrice;
    }

    /// @notice Storage struct for Diamond state
    /// @dev Follows EIP-2535 Diamond Standard
    struct AppStorage {
        /// @notice NFT-specific storage
        NFTStorage nft;
    }

    /// @notice Error thrown when trying to get URI for non-existent token
    error NonExistentTokenURI();
    /// @notice Error thrown when trying to set invalid base URI
    error InvalidBaseURI();
    /// @notice Error thrown when withdrawal transfer fails
    error WithdrawTransfer();
    /// @notice Error thrown when trying to mint more than allowed
    error ExceedsMaxMintQuantity();
    /// @notice Error thrown when trying to mint zero tokens
    error ZeroMintQuantity();

    /// @notice Storage position for NFT storage
    /// @dev Unique position using keccak256 hash
    bytes32 constant STORAGE_POSITION = keccak256("diamond.storage.planetamornft");

    /// @notice Maximum tokens that can be minted in a single transaction
    uint256 constant MAX_MINT_QUANTITY = 100;
    /// @notice Price per token in wei (1 ETH)
    uint256 constant MINT_PRICE = 1 ether;

    /// @notice Get the storage struct
    /// @return s Storage struct
    function diamondStorage() internal pure returns (AppStorage storage s) {
        bytes32 position = STORAGE_POSITION;
        assembly {
            s.slot := position
        }
    }

    /// @notice Convert uint256 to string
    /// @param value Value to convert
    /// @return String representation
    function toString(uint256 value) internal pure returns (string memory) {
        if (value == 0) {
            return "0";
        }
        uint256 temp = value;
        uint256 digits;
        while (temp != 0) {
            digits++;
            temp /= 10;
        }
        bytes memory buffer = new bytes(digits);
        while (value != 0) {
            digits -= 1;
            buffer[digits] = bytes1(uint8(48 + uint256(value % 10)));
            value /= 10;
        }
        return string(buffer);
    }
}
