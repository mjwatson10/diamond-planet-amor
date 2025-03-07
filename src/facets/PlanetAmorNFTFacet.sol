// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

import {LibDiamond} from "../libraries/LibDiamond.sol";

/// @title PlanetAmorNFTFacet
/// @author Planet Amor Team
/// @notice ERC721A NFT implementation for the Planet Amor collection
/// @dev This facet handles NFT minting and metadata functionality
contract PlanetAmorNFTFacet {
    /// @notice Thrown when trying to get URI of non-existent token
    error NonExistentTokenURI();
    /// @notice Thrown when withdrawal of funds fails
    error WithdrawTransfer();
    /// @notice Thrown when trying to mint more than allowed
    error ExceedsMaxMintQuantity();
    /// @notice Thrown when trying to mint zero tokens
    error ZeroMintQuantity();
    /// @notice Thrown when trying to set invalid base URI
    error InvalidBaseURI();

    /// @notice Emitted when a token's URI is set permanently
    /// @param _value The permanent URI value
    /// @param _id The token ID that received the permanent URI
    event PermanentURI(string _value, uint256 indexed _id);
    event Transfer(address indexed from, address indexed to, uint256 indexed tokenId);

    struct NFTStorage {
        string baseTokenURI;
        mapping(uint256 => address) owners;
        mapping(address => uint256) balances;
        uint256 _currentIndex;
    }
    
    bytes32 constant STORAGE_POSITION = keccak256("diamond.storage.planetamornft");
    uint256 constant MAX_MINT_QUANTITY = 100;
    
    function diamondStorage() internal pure returns (NFTStorage storage ds) {
        bytes32 position = STORAGE_POSITION;
        assembly {
            ds.slot := position
        }
    }

    /// @notice Restricts function access to contract owner
    /// @dev Uses LibDiamond for ownership checks
    modifier onlyOwner() {
        LibDiamond.enforceIsContractOwner();
        _;
    }

    /// @notice Mints new tokens to the owner's address
    /// @dev Only callable by contract owner
    /// @param quantity Number of tokens to mint
    function mint(uint256 quantity) external onlyOwner {
        if (quantity == 0) revert ZeroMintQuantity();
        if (quantity > MAX_MINT_QUANTITY) revert ExceedsMaxMintQuantity();
        
        NFTStorage storage s = diamondStorage();
        uint256 startTokenId = s._currentIndex;
        unchecked {
            s._currentIndex += quantity;
            s.balances[msg.sender] += quantity;
            
            // Emit transfer events
            for(uint256 i = 0; i < quantity; i++) {
                s.owners[startTokenId + i] = msg.sender;
                emit Transfer(address(0), msg.sender, startTokenId + i);
            }
        }
    }

    /// @notice Returns the URI for a given token
    /// @dev Reverts if token doesn't exist
    /// @param tokenId The ID of the token to get URI for
    /// @return Token URI string
    function tokenURI(uint256 tokenId) public view returns (string memory) {
        NFTStorage storage s = diamondStorage();
        if (s.owners[tokenId] == address(0)) revert NonExistentTokenURI();

        string memory currentBaseURI = s.baseTokenURI;
        return bytes(currentBaseURI).length != 0 
            ? string(abi.encodePacked(currentBaseURI, _toString(tokenId)))
            : "";
    }

    /// @notice Sets the base URI for token metadata
    /// @dev Only callable by contract owner
    /// @param baseURI New base URI
    function setBaseURI(string memory baseURI) external onlyOwner {
        if (bytes(baseURI).length == 0) revert InvalidBaseURI();
        diamondStorage().baseTokenURI = baseURI;
    }

    /// @notice Returns the total number of tokens minted
    /// @return Total supply
    function totalMinted() public view returns (uint256) {
        return diamondStorage()._currentIndex;
    }

    /// @notice Returns the number of tokens minted by an address
    /// @param owner Address to check
    /// @return Number of tokens minted
    function numberMinted(address owner) public view returns (uint256) {
        return diamondStorage().balances[owner];
    }

    /// @notice Returns the collection name
    function name() public pure returns (string memory) {
        return "PlanetAmor";
    }

    /// @notice Returns the collection symbol
    function symbol() public pure returns (string memory) {
        return "AMOR";
    }

    /// @notice Withdraws contract balance to owner
    /// @dev Only callable by contract owner
    function withdraw() external onlyOwner {
        (bool success, ) = msg.sender.call{value: address(this).balance}("");
        if (!success) revert WithdrawTransfer();
    }

    /// @notice Helper function to convert uint256 to string
    /// @param value Number to convert
    /// @return String representation of the number
    function _toString(uint256 value) internal pure returns (string memory) {
        if (value == 0) return "0";
        
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
