// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

import "forge-std/Test.sol";
import "../src/Diamond.sol";
import "../src/facets/DiamondCutFacet.sol";
import "../src/facets/DiamondLoupeFacet.sol";
import "../src/facets/PlanetAmorNFTFacet.sol";
import "../src/interfaces/IDiamondCut.sol";

contract DiamondTest is Test {
    Diamond diamond;
    DiamondCutFacet diamondCutFacet;
    DiamondLoupeFacet diamondLoupeFacet;
    PlanetAmorNFTFacet nftFacet;
    address owner;
    address user1;

    function setUp() public {
        owner = makeAddr("owner");
        user1 = makeAddr("user1");
        vm.deal(owner, 100 ether);
        vm.deal(user1, 100 ether);

        vm.startPrank(owner);
        
        // Deploy DiamondCutFacet first
        diamondCutFacet = new DiamondCutFacet();
        
        // Deploy Diamond with owner and diamondCutFacet
        diamond = new Diamond(owner, address(diamondCutFacet));

        // Deploy other facets
        diamondLoupeFacet = new DiamondLoupeFacet();
        nftFacet = new PlanetAmorNFTFacet();

        // Add DiamondLoupe facet for introspection
        bytes4[] memory selectors = new bytes4[](5);
        selectors[0] = DiamondLoupeFacet.facets.selector;
        selectors[1] = DiamondLoupeFacet.facetFunctionSelectors.selector;
        selectors[2] = DiamondLoupeFacet.facetAddresses.selector;
        selectors[3] = DiamondLoupeFacet.facetAddress.selector;
        selectors[4] = DiamondLoupeFacet.supportsInterface.selector;

        IDiamondCut.FacetCut[] memory cut = new IDiamondCut.FacetCut[](1);
        cut[0] = IDiamondCut.FacetCut({
            facetAddress: address(diamondLoupeFacet),
            action: IDiamondCut.FacetCutAction.Add,
            functionSelectors: selectors
        });

        IDiamondCut(address(diamond)).diamondCut(cut, address(0), "");

        vm.stopPrank();
    }

    function test_DiamondDeployment() public view {
        assertTrue(address(diamond) != address(0), "Diamond not deployed");
        assertTrue(address(diamondCutFacet) != address(0), "DiamondCutFacet not deployed");
    }

    function test_DiamondCutFacetAddition() public {
        vm.startPrank(owner);

        // Deploy a new DiamondLoupeFacet for testing
        DiamondLoupeFacet newFacet = new DiamondLoupeFacet();

        bytes4[] memory selectors = new bytes4[](1);
        selectors[0] = DiamondLoupeFacet.facets.selector;

        IDiamondCut.FacetCut[] memory cut = new IDiamondCut.FacetCut[](1);
        cut[0] = IDiamondCut.FacetCut({
            facetAddress: address(newFacet),
            action: IDiamondCut.FacetCutAction.Replace,
            functionSelectors: selectors
        });

        IDiamondCut(address(diamond)).diamondCut(cut, address(0), "");

        // Verify facet was replaced
        address facetAddress = IDiamondLoupe(address(diamond)).facetAddress(selectors[0]);
        assertEq(facetAddress, address(newFacet));

        vm.stopPrank();
    }

    function test_DiamondCutFacetRemoval() public {
        vm.startPrank(owner);

        bytes4[] memory selectors = new bytes4[](1);
        selectors[0] = DiamondLoupeFacet.facets.selector;

        IDiamondCut.FacetCut[] memory removeCut = new IDiamondCut.FacetCut[](1);
        removeCut[0] = IDiamondCut.FacetCut({
            facetAddress: address(0),
            action: IDiamondCut.FacetCutAction.Remove,
            functionSelectors: selectors
        });

        IDiamondCut(address(diamond)).diamondCut(removeCut, address(0), "");

        // Verify facet was removed
        address facetAddress = IDiamondLoupe(address(diamond)).facetAddress(selectors[0]);
        assertEq(facetAddress, address(0));

        vm.stopPrank();
    }

    function test_OnlyOwnerCanCut() public {
        vm.startPrank(user1);

        IDiamondCut.FacetCut[] memory cut = new IDiamondCut.FacetCut[](1);
        bytes4[] memory selectors = new bytes4[](1);
        selectors[0] = DiamondLoupeFacet.facets.selector;

        cut[0] = IDiamondCut.FacetCut({
            facetAddress: address(diamondLoupeFacet),
            action: IDiamondCut.FacetCutAction.Add,
            functionSelectors: selectors
        });

        vm.expectRevert("LibDiamond: Must be contract owner");
        IDiamondCut(address(diamond)).diamondCut(cut, address(0), "");

        vm.stopPrank();
    }

    // Fuzzing Tests
    function testFuzz_AddFacetWithRandomSelectors(bytes4[] memory selectors) public {
        vm.assume(selectors.length > 0 && selectors.length <= 100);
        
        vm.startPrank(owner);
        DiamondLoupeFacet newFacet = new DiamondLoupeFacet();

        IDiamondCut.FacetCut[] memory cut = new IDiamondCut.FacetCut[](1);
        cut[0] = IDiamondCut.FacetCut({
            facetAddress: address(newFacet),
            action: IDiamondCut.FacetCutAction.Add,
            functionSelectors: selectors
        });

        try IDiamondCut(address(diamond)).diamondCut(cut, address(0), "") {
            // Verify selectors were added correctly
            for (uint i = 0; i < selectors.length; i++) {
                address facetAddress = IDiamondLoupe(address(diamond)).facetAddress(selectors[i]);
                if (facetAddress != address(0)) {
                    assertEq(facetAddress, address(newFacet));
                }
            }
        } catch {
            // Some selector combinations might be invalid or already exist
        }
        vm.stopPrank();
    }

    function testFuzz_FallbackWithRandomCalldata(bytes calldata randomCalldata) public {
        vm.assume(randomCalldata.length >= 4); // Need at least 4 bytes for function selector
        
        // Try to call with random calldata
        (bool success, ) = address(diamond).call(randomCalldata);
        
        if (!success) {
            // If call fails, verify it's because function doesn't exist
            bytes4 selector = bytes4(randomCalldata[:4]);
            address facet = IDiamondLoupe(address(diamond)).facetAddress(selector);
            assertEq(facet, address(0), "Function should not exist");
        }
    }

    function testFuzz_DiamondCutWithRandomInit(
        address initContract,
        bytes memory initCalldata,
        bytes4[] memory selectors
    ) public {
        vm.assume(initContract != address(0));
        vm.assume(selectors.length > 0 && selectors.length <= 10);
        
        vm.startPrank(owner);
        DiamondLoupeFacet newFacet = new DiamondLoupeFacet();

        IDiamondCut.FacetCut[] memory cut = new IDiamondCut.FacetCut[](1);
        cut[0] = IDiamondCut.FacetCut({
            facetAddress: address(newFacet),
            action: IDiamondCut.FacetCutAction.Add,
            functionSelectors: selectors
        });

        try IDiamondCut(address(diamond)).diamondCut(cut, initContract, initCalldata) {
            // If successful, verify the facet was added
            for(uint i = 0; i < selectors.length; i++) {
                address facet = IDiamondLoupe(address(diamond)).facetAddress(selectors[i]);
                if(facet != address(0)) {
                    assertEq(facet, address(newFacet));
                }
            }
        } catch {
            // Initialization might fail, which is expected for random data
        }
        vm.stopPrank();
    }
}
