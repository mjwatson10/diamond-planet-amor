// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

import "forge-std/Test.sol";
import "../../../src/Diamond.sol";
import "../../../src/facets/DiamondCutFacet.sol";
import "../../../src/facets/PlanetAmorNFTFacet.sol";
import "../../../src/interfaces/IDiamondCut.sol";

/// @title Planet Amor NFT URI Fuzz Tests
/// @notice Fuzz test suite focused on URI functionality
/// @dev Uses Diamond proxy pattern for testing
contract URIFuzzTest is Test {
    Diamond diamond;
    DiamondCutFacet diamondCutFacet;
    PlanetAmorNFTFacet nftFacet;
    address owner;

    // Cache selectors to reduce gas costs
    bytes4 constant MINT_SELECTOR = PlanetAmorNFTFacet.mint.selector;
    bytes4 constant TOKEN_URI_SELECTOR = PlanetAmorNFTFacet.tokenURI.selector;
    bytes4 constant SET_BASE_URI_SELECTOR = PlanetAmorNFTFacet.setBaseURI.selector;

    /// @notice Set up test environment
    function setUp() public {
        // Deploy with fixed owner for deterministic testing
        owner = address(0x1234);
        vm.deal(owner, 100 ether);
        
        vm.startPrank(owner);
        
        // Deploy minimal Diamond setup
        diamondCutFacet = new DiamondCutFacet();
        diamond = new Diamond(owner, address(diamondCutFacet));
        nftFacet = new PlanetAmorNFTFacet();

        // Add only required selectors
        bytes4[] memory selectors = new bytes4[](3);
        selectors[0] = MINT_SELECTOR;
        selectors[1] = TOKEN_URI_SELECTOR;
        selectors[2] = SET_BASE_URI_SELECTOR;

        IDiamondCut.FacetCut[] memory cut = new IDiamondCut.FacetCut[](1);
        cut[0] = IDiamondCut.FacetCut({
            facetAddress: address(nftFacet),
            action: IDiamondCut.FacetCutAction.Add,
            functionSelectors: selectors
        });

        IDiamondCut(address(diamond)).diamondCut(cut, address(0), "");
        vm.stopPrank();
    }

    /// @notice Fuzz test URI retrieval for minted tokens
    /// @param tokenId Random token ID to test
    /// @param baseURI Random base URI to set
    function testFuzz_TokenURIForValidToken(uint256 tokenId, string calldata baseURI) public {
        // Bound token ID to reasonable range and ensure baseURI is not empty
        tokenId = bound(tokenId, 0, 99);
        vm.assume(bytes(baseURI).length > 0 && bytes(baseURI).length < 1000);
        
        vm.startPrank(owner);
        
        // Mint token and set URI
        PlanetAmorNFTFacet(address(diamond)).mint(tokenId + 1);
        PlanetAmorNFTFacet(address(diamond)).setBaseURI(baseURI);
        
        string memory uri = PlanetAmorNFTFacet(address(diamond)).tokenURI(tokenId);
        assertEq(uri, string(abi.encodePacked(baseURI, vm.toString(tokenId))), "Incorrect token URI");
        
        vm.stopPrank();
    }

    /// @notice Fuzz test URI retrieval for non-existent tokens
    /// @param tokenId Random non-existent token ID
    function testFuzz_TokenURIForInvalidToken(uint256 tokenId) public {
        // Use token ID beyond minted range
        vm.assume(tokenId > 0);
        
        vm.expectRevert(PlanetAmorNFTFacet.NonExistentTokenURI.selector);
        PlanetAmorNFTFacet(address(diamond)).tokenURI(tokenId);
    }
}
