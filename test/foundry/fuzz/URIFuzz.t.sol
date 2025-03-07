// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

import "forge-std/Test.sol";
import "../../../src/Diamond.sol";
import "../../../src/facets/DiamondCutFacet.sol";
import "../../../src/facets/PlanetAmorNFTFacet.sol";
import "../../../src/interfaces/IDiamondCut.sol";

contract URIFuzzTest is Test {
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

        bytes4[] memory selectors = new bytes4[](3);
        selectors[0] = PlanetAmorNFTFacet.mint.selector;
        selectors[1] = PlanetAmorNFTFacet.tokenURI.selector;
        selectors[2] = PlanetAmorNFTFacet.setBaseURI.selector;

        IDiamondCut.FacetCut[] memory cut = new IDiamondCut.FacetCut[](1);
        cut[0] = IDiamondCut.FacetCut({
            facetAddress: address(nftFacet),
            action: IDiamondCut.FacetCutAction.Add,
            functionSelectors: selectors
        });

        IDiamondCut(address(diamond)).diamondCut(cut, address(0), "");
        vm.stopPrank();
    }

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

    function testFuzz_TokenURIWithRandomTokenId(uint256 tokenId) public {
        tokenId = bound(tokenId, 0, 10);
        
        vm.startPrank(owner);
        PlanetAmorNFTFacet(address(diamond)).mint(5);
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

    function testFuzz_SetBaseURIWithRandomString(string memory baseURI) public {
        vm.startPrank(owner);
        PlanetAmorNFTFacet(address(diamond)).mint(1);
        PlanetAmorNFTFacet(address(diamond)).setBaseURI(baseURI);
        string memory uri = PlanetAmorNFTFacet(address(diamond)).tokenURI(0);
        assertEq(uri, bytes(baseURI).length > 0 ? string(abi.encodePacked(baseURI, "0")) : "");
        vm.stopPrank();
    }
}
