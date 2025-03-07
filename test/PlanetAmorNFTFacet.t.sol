// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "forge-std/Test.sol";
import "../src/Diamond.sol";
import "../src/facets/DiamondCutFacet.sol";
import "../src/facets/PlanetAmorNFTFacet.sol";
import "../src/interfaces/IDiamondCut.sol";

contract PlanetAmorNFTFacetTest is Test {
    Diamond diamond;
    DiamondCutFacet diamondCutFacet;
    PlanetAmorNFTFacet nftFacet;
    address owner;
    address user1;
    address user2;

    function setUp() public {
        owner = makeAddr("owner");
        user1 = makeAddr("user1");
        user2 = makeAddr("user2");
        vm.deal(owner, 100 ether);
        vm.deal(user1, 100 ether);
        vm.deal(user2, 100 ether);

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

    function test_OnlyOwnerCanMint() public {
        vm.startPrank(owner);
        PlanetAmorNFTFacet(address(diamond)).mint(1);
        assertEq(PlanetAmorNFTFacet(address(diamond)).numberMinted(owner), 1);
        vm.stopPrank();

        vm.startPrank(user1);
        vm.expectRevert("LibDiamond: Must be contract owner");
        PlanetAmorNFTFacet(address(diamond)).mint(1);
        vm.stopPrank();
    }

    function test_OwnerCanMintMultiple() public {
        vm.startPrank(owner);
        PlanetAmorNFTFacet(address(diamond)).mint(3);
        assertEq(PlanetAmorNFTFacet(address(diamond)).numberMinted(owner), 3);
        vm.stopPrank();
    }

    function test_TokenURI() public {
        // Mint a token first
        vm.startPrank(owner);
        PlanetAmorNFTFacet(address(diamond)).mint(1);
        
        // Set URIs
        PlanetAmorNFTFacet(address(diamond)).setBaseURI("ipfs://base/");
        PlanetAmorNFTFacet(address(diamond)).setUnrevealedURI("ipfs://unrevealed");

        // Check unrevealed URI
        assertEq(PlanetAmorNFTFacet(address(diamond)).tokenURI(0), "ipfs://unrevealed");

        // Reveal and check revealed URI
        PlanetAmorNFTFacet(address(diamond)).reveal();
        vm.stopPrank();

        assertEq(PlanetAmorNFTFacet(address(diamond)).tokenURI(0), "ipfs://base/0");
    }

    function test_OnlyOwnerFunctions() public {
        vm.startPrank(user1);
        
        vm.expectRevert("LibDiamond: Must be contract owner");
        PlanetAmorNFTFacet(address(diamond)).mint(1);
        
        vm.expectRevert("LibDiamond: Must be contract owner");
        PlanetAmorNFTFacet(address(diamond)).setBaseURI("ipfs://base/");
        
        vm.expectRevert("LibDiamond: Must be contract owner");
        PlanetAmorNFTFacet(address(diamond)).setUnrevealedURI("ipfs://unrevealed");
        
        vm.expectRevert("LibDiamond: Must be contract owner");
        PlanetAmorNFTFacet(address(diamond)).reveal();
        
        vm.expectRevert("LibDiamond: Must be contract owner");
        PlanetAmorNFTFacet(address(diamond)).withdraw();
        
        vm.stopPrank();
    }

    function test_NonExistentTokenURI() public {
        vm.expectRevert(PlanetAmorNFTFacet.NonExistentTokenURI.selector);
        PlanetAmorNFTFacet(address(diamond)).tokenURI(999);
    }

    function test_NameAndSymbol() public {
        assertEq(PlanetAmorNFTFacet(address(diamond)).name(), "PlanetAmor");
        assertEq(PlanetAmorNFTFacet(address(diamond)).symbol(), "AMOR");
    }
}
