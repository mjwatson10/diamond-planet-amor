// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

import "forge-std/Test.sol";
import "../src/Diamond.sol";
import "../src/facets/DiamondCutFacet.sol";
import "../src/facets/PlanetAmorNFTFacet.sol";
import "../src/interfaces/IDiamondCut.sol";

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

        // Add NFT facet
        IDiamondCut.FacetCut[] memory cut = new IDiamondCut.FacetCut[](1);
        bytes4[] memory selectors = new bytes4[](7);
        selectors[0] = PlanetAmorNFTFacet.mint.selector;
        selectors[1] = PlanetAmorNFTFacet.tokenURI.selector;
        selectors[2] = PlanetAmorNFTFacet.setBaseURI.selector;
        selectors[3] = PlanetAmorNFTFacet.withdraw.selector;
        selectors[4] = PlanetAmorNFTFacet.numberMinted.selector;
        selectors[5] = PlanetAmorNFTFacet.name.selector;
        selectors[6] = PlanetAmorNFTFacet.symbol.selector;

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

    /// @notice Test owner can mint multiple tokens
    /// @dev Verifies batch minting functionality
    function test_OwnerCanMintMultiple() public {
        vm.startPrank(owner);
        PlanetAmorNFTFacet(address(diamond)).mint(3);
        assertEq(PlanetAmorNFTFacet(address(diamond)).numberMinted(owner), 3);
        vm.stopPrank();
    }

    /// @notice Test token URI functionality
    /// @dev Verifies correct URI construction and updates
    function test_TokenURI() public {
        vm.startPrank(owner);
        PlanetAmorNFTFacet(address(diamond)).mint(1);
        
        // Set URI and verify
        PlanetAmorNFTFacet(address(diamond)).setBaseURI("ipfs://base/");
        assertEq(PlanetAmorNFTFacet(address(diamond)).tokenURI(0), "ipfs://base/0");
        vm.stopPrank();
    }

    /// @notice Test owner-only functions
    /// @dev Verifies access control for restricted functions
    function test_OnlyOwnerFunctions() public {
        vm.startPrank(user1);
        
        vm.expectRevert("LibDiamond: Must be contract owner");
        PlanetAmorNFTFacet(address(diamond)).mint(1);
        
        vm.expectRevert("LibDiamond: Must be contract owner");
        PlanetAmorNFTFacet(address(diamond)).setBaseURI("ipfs://base/");
        
        vm.expectRevert("LibDiamond: Must be contract owner");
        PlanetAmorNFTFacet(address(diamond)).withdraw();
        
        vm.stopPrank();
    }

    /// @notice Test non-existent token URI handling
    /// @dev Verifies error handling for invalid token IDs
    function test_NonExistentTokenURI() public {
        vm.expectRevert(PlanetAmorNFTFacet.NonExistentTokenURI.selector);
        PlanetAmorNFTFacet(address(diamond)).tokenURI(999);
    }

    /// @notice Test collection name and symbol
    /// @dev Verifies basic NFT metadata
    function test_NameAndSymbol() public {
        assertEq(PlanetAmorNFTFacet(address(diamond)).name(), "PlanetAmor");
        assertEq(PlanetAmorNFTFacet(address(diamond)).symbol(), "AMOR");
    }
}
