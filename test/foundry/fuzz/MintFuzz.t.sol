// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

import "forge-std/Test.sol";
import "../../../src/Diamond.sol";
import "../../../src/facets/DiamondCutFacet.sol";
import "../../../src/facets/PlanetAmorNFTFacet.sol";
import "../../../src/interfaces/IDiamondCut.sol";

/// @title Planet Amor NFT Mint Fuzz Tests
/// @notice Fuzz test suite focused on minting functionality
/// @dev Uses Diamond proxy pattern for testing
contract MintFuzzTest is Test {
    Diamond diamond;
    DiamondCutFacet diamondCutFacet;
    PlanetAmorNFTFacet nftFacet;
    address owner;

    // Cache selectors to reduce gas costs
    bytes4 constant MINT_SELECTOR = PlanetAmorNFTFacet.mint.selector;
    bytes4 constant NUMBER_MINTED_SELECTOR = PlanetAmorNFTFacet.numberMinted.selector;

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
        bytes4[] memory selectors = new bytes4[](2);
        selectors[0] = MINT_SELECTOR;
        selectors[1] = NUMBER_MINTED_SELECTOR;

        IDiamondCut.FacetCut[] memory cut = new IDiamondCut.FacetCut[](1);
        cut[0] = IDiamondCut.FacetCut({
            facetAddress: address(nftFacet),
            action: IDiamondCut.FacetCutAction.Add,
            functionSelectors: selectors
        });

        IDiamondCut(address(diamond)).diamondCut(cut, address(0), "");
        vm.stopPrank();
    }

    /// @notice Fuzz test owner minting with random quantities
    /// @param quantity Random quantity to mint
    function testFuzz_OwnerMintWithRandomQuantity(uint256 quantity) public {
        // Bound quantity to valid range (1-100)
        quantity = bound(quantity, 1, 100);
        
        vm.prank(owner);
        PlanetAmorNFTFacet(address(diamond)).mint(quantity);
        
        assertEq(
            PlanetAmorNFTFacet(address(diamond)).numberMinted(owner),
            quantity,
            "Incorrect number of tokens minted"
        );
    }

    /// @notice Fuzz test non-owner minting attempts
    /// @param quantity Random quantity to attempt minting
    /// @param nonOwner Random address to attempt minting from
    function testFuzz_NonOwnerCannotMint(uint256 quantity, address nonOwner) public {
        // Filter out owner and zero address
        vm.assume(nonOwner != owner && nonOwner != address(0));
        
        // Bound quantity to valid range (1-100)
        quantity = bound(quantity, 1, 100);
        
        vm.prank(nonOwner);
        vm.expectRevert("LibDiamond: Must be contract owner");
        PlanetAmorNFTFacet(address(diamond)).mint(quantity);
    }
}
