// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

import "forge-std/Test.sol";
import "../../../src/Diamond.sol";
import "../../../src/facets/DiamondCutFacet.sol";
import "../../../src/facets/PlanetAmorNFTFacet.sol";
import "../../../src/interfaces/IDiamondCut.sol";

contract MintFuzzTest is Test {
    Diamond diamond;
    DiamondCutFacet diamondCutFacet;
    PlanetAmorNFTFacet nftFacet;
    address owner;

    function setUp() public {
        owner = makeAddr("owner");
        vm.deal(owner, 100 ether);
        vm.startPrank(owner);
        
        diamondCutFacet = new DiamondCutFacet();
        diamond = new Diamond(owner, address(diamondCutFacet));
        nftFacet = new PlanetAmorNFTFacet();

        bytes4[] memory selectors = new bytes4[](2);
        selectors[0] = PlanetAmorNFTFacet.mint.selector;
        selectors[1] = PlanetAmorNFTFacet.numberMinted.selector;

        IDiamondCut.FacetCut[] memory cut = new IDiamondCut.FacetCut[](1);
        cut[0] = IDiamondCut.FacetCut({
            facetAddress: address(nftFacet),
            action: IDiamondCut.FacetCutAction.Add,
            functionSelectors: selectors
        });

        IDiamondCut(address(diamond)).diamondCut(cut, address(0), "");
        vm.stopPrank();
    }

    function testFuzz_OwnerMintWithRandomQuantity(uint256 quantity) public {
        quantity = bound(quantity, 1, 100);
        
        vm.prank(owner);
        PlanetAmorNFTFacet(address(diamond)).mint(quantity);
        
        assertEq(PlanetAmorNFTFacet(address(diamond)).numberMinted(owner), quantity);
    }

    function testFuzz_NonOwnerCannotMint(uint256 quantity, address nonOwner) public {
        vm.assume(nonOwner != owner && nonOwner != address(0));
        quantity = bound(quantity, 1, 100);
        
        vm.prank(nonOwner);
        vm.expectRevert("LibDiamond: Must be contract owner");
        PlanetAmorNFTFacet(address(diamond)).mint(quantity);
    }
}
