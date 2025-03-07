// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

import "forge-std/Test.sol";
import "../src/Diamond.sol";
import "../src/facets/DiamondCutFacet.sol";
import "../src/facets/PlanetAmorNFTFacet.sol";
import "../src/interfaces/IDiamondCut.sol";

/// @title Planet Amor NFT Facet Fuzz Tests
/// @author Planet Amor Team
/// @notice Fuzz test suite for the Planet Amor NFT functionality
/// @dev Tests edge cases and random inputs for NFT operations
contract PlanetAmorNFTFacetFuzzTest is Test {
    Diamond diamond;
    DiamondCutFacet diamondCutFacet;
    PlanetAmorNFTFacet nftFacet;
    address owner;

    /// @notice Set up test environment
    /// @dev Deploys contracts and sets up test accounts
    function setUp() public {
        owner = makeAddr("owner");
        vm.deal(owner, 100 ether);

        vm.startPrank(owner);
        
        // Deploy contracts
        diamondCutFacet = new DiamondCutFacet();
        diamond = new Diamond(owner, address(diamondCutFacet));
        nftFacet = new PlanetAmorNFTFacet();

        // Setup function selectors
        bytes4[] memory selectors = new bytes4[](8);
        selectors[0] = PlanetAmorNFTFacet.mint.selector;
        selectors[1] = PlanetAmorNFTFacet.tokenURI.selector;
        selectors[2] = PlanetAmorNFTFacet.setBaseURI.selector;
        selectors[3] = PlanetAmorNFTFacet.withdraw.selector;
        selectors[4] = PlanetAmorNFTFacet.numberMinted.selector;
        selectors[5] = PlanetAmorNFTFacet.name.selector;
        selectors[6] = PlanetAmorNFTFacet.symbol.selector;
        selectors[7] = PlanetAmorNFTFacet.totalMinted.selector;

        // Setup diamond cut
        IDiamondCut.FacetCut[] memory cut = new IDiamondCut.FacetCut[](1);
        cut[0] = IDiamondCut.FacetCut({
            facetAddress: address(nftFacet),
            action: IDiamondCut.FacetCutAction.Add,
            functionSelectors: selectors
        });

        // Add facet
        IDiamondCut(address(diamond)).diamondCut(cut, address(0), "");
        vm.stopPrank();
    }

    /// @notice Helper to mint tokens in setup
    /// @dev Used to reduce duplicate code and gas costs
    function _mintTokens(uint256 quantity) internal {
        vm.startPrank(owner);
        PlanetAmorNFTFacet(address(diamond)).mint(quantity);
        vm.stopPrank();
    }

    /// @notice Fuzz test owner minting with random quantities
    /// @dev Tests minting with random quantities between 1 and 100
    /// @param quantity Random quantity to mint
    function testFuzz_OwnerMintWithRandomQuantity(uint256 quantity) public {
        quantity = bound(quantity, 1, 100);
        
        _mintTokens(quantity);
        
        assertEq(PlanetAmorNFTFacet(address(diamond)).numberMinted(owner), quantity);
        assertEq(PlanetAmorNFTFacet(address(diamond)).totalMinted(), quantity);
    }

    /// @notice Fuzz test non-owner minting attempts
    /// @dev Tests that non-owners cannot mint with random quantities and addresses
    /// @param quantity Random quantity to attempt minting
    /// @param nonOwner Random address to attempt minting from
    function testFuzz_NonOwnerCannotMint(uint256 quantity, address nonOwner) public {
        vm.assume(nonOwner != owner && nonOwner != address(0));
        quantity = bound(quantity, 1, 100);
        
        vm.startPrank(nonOwner);
        vm.expectRevert("LibDiamond: Must be contract owner");
        PlanetAmorNFTFacet(address(diamond)).mint(quantity);
        vm.stopPrank();
    }

    /// @notice Fuzz test token URI with random token IDs
    /// @dev Tests URI generation for valid and invalid token IDs
    /// @param tokenId Random token ID to query
    function testFuzz_TokenURIWithRandomTokenId(uint256 tokenId) public {
        tokenId = bound(tokenId, 0, 10);
        
        // Mint tokens in setup
        _mintTokens(5);
        
        vm.startPrank(owner);
        PlanetAmorNFTFacet(address(diamond)).setBaseURI("ipfs://base/");
        vm.stopPrank();

        if (tokenId >= 5) {
            vm.expectRevert(PlanetAmorNFTFacet.NonExistentTokenURI.selector);
            PlanetAmorNFTFacet(address(diamond)).tokenURI(tokenId);
        } else {
            string memory uri = PlanetAmorNFTFacet(address(diamond)).tokenURI(tokenId);
            assertEq(uri, string(abi.encodePacked("ipfs://base/", _toString(tokenId))));
        }
    }

    /// @notice Fuzz test base URI with random strings
    /// @dev Tests setting and retrieving URIs with random string inputs
    /// @param baseURI Random string to use as base URI
    function testFuzz_SetBaseURIWithRandomString(string memory baseURI) public {
        _mintTokens(1);
        
        vm.startPrank(owner);
        PlanetAmorNFTFacet(address(diamond)).setBaseURI(baseURI);
        string memory uri = PlanetAmorNFTFacet(address(diamond)).tokenURI(0);
        assertEq(uri, bytes(baseURI).length > 0 ? string(abi.encodePacked(baseURI, "0")) : "");
        vm.stopPrank();
    }

    /// @notice Helper function to convert uint256 to string
    /// @dev Used for token ID to string conversion in URI construction
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
