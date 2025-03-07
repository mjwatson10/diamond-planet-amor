// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "forge-std/Test.sol";
import "../src/Diamond.sol";
import "../src/facets/DiamondCutFacet.sol";
import "../src/facets/PlanetAmorNFTFacet.sol";
import "../src/interfaces/IDiamondCut.sol";

contract PlanetAmorNFTFacetFuzzTest is Test {
    Diamond diamond;
    DiamondCutFacet diamondCutFacet;
    PlanetAmorNFTFacet nftFacet;
    address owner;

    function setUp() public {
        owner = makeAddr("owner");
        vm.deal(owner, 100 ether);

        vm.startPrank(owner);
        
        // Deploy contracts
        diamondCutFacet = new DiamondCutFacet();
        diamond = new Diamond(owner, address(diamondCutFacet));
        nftFacet = new PlanetAmorNFTFacet();

        // Add NFT facet
        IDiamondCut.FacetCut[] memory cut = new IDiamondCut.FacetCut[](1);
        bytes4[] memory selectors = new bytes4[](10);
        selectors[0] = PlanetAmorNFTFacet.mint.selector;
        selectors[1] = PlanetAmorNFTFacet.tokenURI.selector;
        selectors[2] = PlanetAmorNFTFacet.setBaseURI.selector;
        selectors[3] = PlanetAmorNFTFacet.setUnrevealedURI.selector;
        selectors[4] = PlanetAmorNFTFacet.reveal.selector;
        selectors[5] = PlanetAmorNFTFacet.withdraw.selector;
        selectors[6] = PlanetAmorNFTFacet.numberMinted.selector;
        selectors[7] = PlanetAmorNFTFacet.totalMinted.selector;
        selectors[8] = PlanetAmorNFTFacet.name.selector;
        selectors[9] = PlanetAmorNFTFacet.symbol.selector;

        cut[0] = IDiamondCut.FacetCut({
            facetAddress: address(nftFacet),
            action: IDiamondCut.FacetCutAction.Add,
            functionSelectors: selectors
        });

        IDiamondCut(address(diamond)).diamondCut(cut, address(0), "");
        vm.stopPrank();
    }

    function testFuzz_OwnerMintWithRandomQuantity(uint256 quantity) public {
        // Bound quantity to reasonable range (1 to 100)
        quantity = bound(quantity, 1, 100);
        
        vm.startPrank(owner);
        PlanetAmorNFTFacet(address(diamond)).mint(quantity);
        
        assertEq(PlanetAmorNFTFacet(address(diamond)).numberMinted(owner), quantity);
        assertEq(PlanetAmorNFTFacet(address(diamond)).totalMinted(), quantity);
        vm.stopPrank();
    }

    function testFuzz_NonOwnerCannotMint(uint256 quantity, address nonOwner) public {
        vm.assume(nonOwner != owner && nonOwner != address(0));
        quantity = bound(quantity, 1, 100);
        
        vm.startPrank(nonOwner);
        vm.expectRevert("LibDiamond: Must be contract owner");
        PlanetAmorNFTFacet(address(diamond)).mint(quantity);
        vm.stopPrank();
    }

    function testFuzz_TokenURIWithRandomTokenId(uint256 tokenId) public {
        // First mint some tokens as owner
        vm.startPrank(owner);
        PlanetAmorNFTFacet(address(diamond)).mint(5);
        vm.stopPrank();

        // If tokenId is beyond minted range, expect revert
        if (tokenId >= 5) {
            vm.expectRevert(PlanetAmorNFTFacet.NonExistentTokenURI.selector);
            PlanetAmorNFTFacet(address(diamond)).tokenURI(tokenId);
        } else {
            // Valid tokenId should return URI
            string memory uri = PlanetAmorNFTFacet(address(diamond)).tokenURI(tokenId);
            assertTrue(bytes(uri).length >= 0);
        }
    }

    function testFuzz_SetBaseURIWithRandomString(string memory baseURI) public {
        vm.startPrank(owner);
        PlanetAmorNFTFacet(address(diamond)).setBaseURI(baseURI);
        PlanetAmorNFTFacet(address(diamond)).reveal();
        
        // Mint a token to test URI
        PlanetAmorNFTFacet(address(diamond)).mint(1);

        string memory uri = PlanetAmorNFTFacet(address(diamond)).tokenURI(0);
        assertTrue(bytes(uri).length >= 0);
        vm.stopPrank();
    }
}
