// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

import "forge-std/Test.sol";
import "../src/Diamond.sol";
import "../src/facets/DiamondCutFacet.sol";
import "../src/facets/PlanetAmorNFTFacet.sol";
import "../src/interfaces/IDiamondCut.sol";
import "../src/libraries/LibAppStorage.sol";

/// @title Planet Amor NFT Facet Tests
/// @author Planet Amor Team
/// @notice Test suite for the Planet Amor NFT functionality
/// @dev Tests core NFT operations including minting and URI management
contract PlanetAmorNFTFacetTest is Test {
    Diamond diamond;
    DiamondCutFacet diamondCutFacet;
    PlanetAmorNFTFacet nftFacet;
    address owner;
    address user1;
    address user2;

    /// @notice Set up test environment
    /// @dev Deploys contracts and sets up test accounts
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

        // Add NFT facet functions
        bytes4[] memory selectors = new bytes4[](7);
        selectors[0] = PlanetAmorNFTFacet.mint.selector;
        selectors[1] = PlanetAmorNFTFacet.tokenURI.selector;
        selectors[2] = PlanetAmorNFTFacet.setBaseURI.selector;
        selectors[3] = PlanetAmorNFTFacet.numberMinted.selector;
        selectors[4] = PlanetAmorNFTFacet.totalMinted.selector;
        selectors[5] = PlanetAmorNFTFacet.name.selector;
        selectors[6] = PlanetAmorNFTFacet.symbol.selector;

        IDiamondCut.FacetCut[] memory cut = new IDiamondCut.FacetCut[](1);
        cut[0] = IDiamondCut.FacetCut({
            facetAddress: address(nftFacet),
            action: IDiamondCut.FacetCutAction.Add,
            functionSelectors: selectors
        });

        IDiamondCut(address(diamond)).diamondCut(cut, address(0), "");
        vm.stopPrank();
    }

    /// @notice Test that only owner can mint tokens
    /// @dev Verifies owner can mint and non-owners cannot
    function testMintAsOwner() public {
        vm.startPrank(owner);
        PlanetAmorNFTFacet(address(diamond)).mint(1);
        assertEq(PlanetAmorNFTFacet(address(diamond)).numberMinted(owner), 1);
        vm.stopPrank();
    }

    /// @notice Test owner can mint multiple tokens
    /// @dev Verifies batch minting functionality
    function testMintMultipleAsOwner() public {
        vm.startPrank(owner);
        PlanetAmorNFTFacet(address(diamond)).mint(5);
        assertEq(PlanetAmorNFTFacet(address(diamond)).numberMinted(owner), 5);
        vm.stopPrank();
    }

    /// @notice Test cannot mint zero tokens
    /// @dev Verifies error handling for zero mint quantity
    function testCannotMintZeroTokens() public {
        vm.startPrank(owner);
        vm.expectRevert(LibAppStorage.ZeroMintQuantity.selector);
        PlanetAmorNFTFacet(address(diamond)).mint(0);
        vm.stopPrank();
    }

    /// @notice Test cannot mint more than max quantity
    /// @dev Verifies error handling for exceeding max mint quantity
    function testCannotMintMoreThanMaxQuantity() public {
        vm.startPrank(owner);
        vm.expectRevert(LibAppStorage.ExceedsMaxMintQuantity.selector);
        PlanetAmorNFTFacet(address(diamond)).mint(101);
        vm.stopPrank();
    }

    /// @notice Test non-owner cannot mint
    /// @dev Verifies access control for minting
    function testNonOwnerCannotMint() public {
        vm.startPrank(user1);
        vm.expectRevert("LibDiamond: Must be contract owner");
        PlanetAmorNFTFacet(address(diamond)).mint(1);
        vm.stopPrank();
    }

    /// @notice Test owner can set base URI
    /// @dev Verifies base URI management functionality
    function testSetBaseURIAsOwner() public {
        vm.startPrank(owner);
        PlanetAmorNFTFacet(address(diamond)).setBaseURI("ipfs://test/");
        PlanetAmorNFTFacet(address(diamond)).mint(1);
        assertEq(PlanetAmorNFTFacet(address(diamond)).tokenURI(0), "ipfs://test/0");
        vm.stopPrank();
    }

    /// @notice Test non-owner cannot set base URI
    /// @dev Verifies access control for base URI management
    function testNonOwnerCannotSetBaseURI() public {
        vm.startPrank(user1);
        vm.expectRevert("LibDiamond: Must be contract owner");
        PlanetAmorNFTFacet(address(diamond)).setBaseURI("ipfs://test/");
        vm.stopPrank();
    }

    /// @notice Test cannot set empty base URI
    /// @dev Verifies error handling for invalid base URI
    function testCannotSetEmptyBaseURI() public {
        vm.startPrank(owner);
        vm.expectRevert(LibAppStorage.InvalidBaseURI.selector);
        PlanetAmorNFTFacet(address(diamond)).setBaseURI("");
        vm.stopPrank();
    }

    /// @notice Test token URI for non-existent token
    /// @dev Verifies error handling for invalid token IDs
    function testTokenURIForNonexistentToken() public {
        vm.expectRevert(LibAppStorage.NonExistentTokenURI.selector);
        PlanetAmorNFTFacet(address(diamond)).tokenURI(0);
    }

    /// @notice Test collection name
    /// @dev Verifies basic NFT metadata
    function testName() public {
        assertEq(PlanetAmorNFTFacet(address(diamond)).name(), "Planet Amor");
    }

    /// @notice Test collection symbol
    /// @dev Verifies basic NFT metadata
    function testSymbol() public {
        assertEq(PlanetAmorNFTFacet(address(diamond)).symbol(), "AMOR");
    }

    /// @notice Test total minted
    /// @dev Verifies total minted functionality
    function testTotalMinted() public {
        vm.startPrank(owner);
        PlanetAmorNFTFacet(address(diamond)).mint(5);
        assertEq(PlanetAmorNFTFacet(address(diamond)).totalMinted(), 5);
        vm.stopPrank();
    }
}
