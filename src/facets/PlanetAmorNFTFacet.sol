// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

import "ERC721A/ERC721A.sol";
import "../libraries/LibDiamond.sol";
import "../libraries/LibAppStorage.sol";

/// @title Planet Amor NFT Facet
/// @notice Handles NFT functionality for the Planet Amor collection
/// @dev Uses Diamond Storage pattern with LibAppStorage, ERC721A for efficient minting
contract PlanetAmorNFTFacet {
    using LibAppStorage for LibAppStorage.AppStorage;

    /// @notice Emitted when a token's URI is set permanently
    /// @param _value The permanent URI value
    /// @param _id The token ID
    event PermanentURI(string _value, uint256 indexed _id);
    event Transfer(address indexed from, address indexed to, uint256 indexed tokenId);

    /// @notice Mint new tokens
    /// @param quantity Number of tokens to mint
    function mint(uint256 quantity) external payable {
        LibDiamond.enforceIsContractOwner();
        if (quantity == 0) revert LibAppStorage.ZeroMintQuantity();
        if (quantity > LibAppStorage.MAX_MINT_QUANTITY) revert LibAppStorage.ExceedsMaxMintQuantity();

        LibAppStorage.AppStorage storage s = LibAppStorage.diamondStorage();
        uint256 startTokenId = s.nft.currentIndex;
        unchecked {
            s.nft.currentIndex += quantity;
            s.nft.balances[msg.sender] += quantity;
            
            // Emit transfer events
            for(uint256 i = 0; i < quantity; i++) {
                s.nft.owners[startTokenId + i] = msg.sender;
                emit Transfer(address(0), msg.sender, startTokenId + i);
            }
        }
    }

    /// @notice Get number of tokens minted by an address
    /// @param owner Address to check
    /// @return Number of tokens minted
    function numberMinted(address owner) public view returns (uint256) {
        return LibAppStorage.diamondStorage().nft.balances[owner];
    }

    /// @notice Set base URI for token metadata
    /// @param baseURI New base URI
    function setBaseURI(string calldata baseURI) external {
        LibDiamond.enforceIsContractOwner();
        if (bytes(baseURI).length == 0) revert LibAppStorage.InvalidBaseURI();
        LibAppStorage.diamondStorage().nft.baseTokenURI = baseURI;
    }

    /// @notice Get token URI
    /// @param tokenId Token ID to get URI for
    /// @return Token URI
    function tokenURI(uint256 tokenId) public view returns (string memory) {
        LibAppStorage.AppStorage storage s = LibAppStorage.diamondStorage();
        if (s.nft.owners[tokenId] == address(0)) revert LibAppStorage.NonExistentTokenURI();

        string memory currentBaseURI = s.nft.baseTokenURI;
        return bytes(currentBaseURI).length != 0 
            ? string(abi.encodePacked(currentBaseURI, LibAppStorage.toString(tokenId)))
            : "";
    }

    /// @notice Returns the total number of tokens minted
    /// @return Total supply
    function totalMinted() public view returns (uint256) {
        return LibAppStorage.diamondStorage().nft.currentIndex;
    }

    /// @notice Returns the collection name
    /// @return Collection name string
    function name() public pure returns (string memory) {
        return "Planet Amor";
    }

    /// @notice Returns the collection symbol
    /// @return Collection symbol string
    function symbol() public pure returns (string memory) {
        return "AMOR";
    }

    /// @notice Withdraws contract balance to owner
    /// @dev Only callable by contract owner
    function withdraw() external {
        LibDiamond.enforceIsContractOwner();
        (bool success, ) = msg.sender.call{value: address(this).balance}("");
        if (!success) revert LibAppStorage.WithdrawTransfer();
    }
}
