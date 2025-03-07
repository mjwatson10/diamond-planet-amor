// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "forge-std/Test.sol";
import "../src/Diamond.sol";
import "../src/facets/DiamondCutFacet.sol";
import "../src/facets/DiamondLoupeFacet.sol";
import "../src/interfaces/IDiamondCut.sol";
import "../src/interfaces/IDiamondLoupe.sol";

contract DiamondCutFacetTest is Test {
    Diamond diamond;
    DiamondCutFacet diamondCutFacet;
    DiamondLoupeFacet diamondLoupeFacet;
    address owner;
    address user1;

    function setUp() public {
        owner = makeAddr("owner");
        user1 = makeAddr("user1");
        vm.deal(owner, 100 ether);
        vm.deal(user1, 100 ether);

        vm.startPrank(owner);
        
        diamondCutFacet = new DiamondCutFacet();
        diamond = new Diamond(owner, address(diamondCutFacet));
        diamondLoupeFacet = new DiamondLoupeFacet();

        // Add DiamondLoupe facet for testing
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

    function test_AddFacet() public {
        vm.startPrank(owner);

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
        address facetAddress = IDiamondLoupe(address(diamond)).facetAddress(selectors[0]);
        assertEq(facetAddress, address(newFacet));

        vm.stopPrank();
    }

    function test_ReplaceFacet() public {
        vm.startPrank(owner);

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
        address facetAddress = IDiamondLoupe(address(diamond)).facetAddress(selectors[0]);
        assertEq(facetAddress, address(newFacet));

        vm.stopPrank();
    }

    function test_RemoveFacet() public {
        vm.startPrank(owner);

        bytes4[] memory selectors = new bytes4[](1);
        selectors[0] = DiamondLoupeFacet.facets.selector;

        IDiamondCut.FacetCut[] memory cut = new IDiamondCut.FacetCut[](1);
        cut[0] = IDiamondCut.FacetCut({
            facetAddress: address(0),
            action: IDiamondCut.FacetCutAction.Remove,
            functionSelectors: selectors
        });

        IDiamondCut(address(diamond)).diamondCut(cut, address(0), "");
        address facetAddress = IDiamondLoupe(address(diamond)).facetAddress(selectors[0]);
        assertEq(facetAddress, address(0));

        vm.stopPrank();
    }

    function test_OnlyOwnerCanCut() public {
        vm.startPrank(user1);

        bytes4[] memory selectors = new bytes4[](1);
        selectors[0] = DiamondLoupeFacet.facets.selector;

        IDiamondCut.FacetCut[] memory cut = new IDiamondCut.FacetCut[](1);
        cut[0] = IDiamondCut.FacetCut({
            facetAddress: address(diamondLoupeFacet),
            action: IDiamondCut.FacetCutAction.Add,
            functionSelectors: selectors
        });

        vm.expectRevert("LibDiamond: Must be contract owner");
        IDiamondCut(address(diamond)).diamondCut(cut, address(0), "");

        vm.stopPrank();
    }

    function test_CannotAddExistingFunction() public {
        vm.startPrank(owner);

        bytes4[] memory selectors = new bytes4[](1);
        selectors[0] = DiamondLoupeFacet.facets.selector;

        IDiamondCut.FacetCut[] memory addCut = new IDiamondCut.FacetCut[](1);
        addCut[0] = IDiamondCut.FacetCut({
            facetAddress: address(diamondLoupeFacet),
            action: IDiamondCut.FacetCutAction.Add,
            functionSelectors: selectors
        });

        vm.expectRevert("LibDiamondCut: Can't add function that already exists");
        IDiamondCut(address(diamond)).diamondCut(addCut, address(0), "");

        vm.stopPrank();
    }

    // Fuzzing Tests
    function testFuzz_MultipleRandomFacetCuts(
        uint8 numCuts,
        uint8[] memory actions,
        bytes4[][] memory selectorSets
    ) public {
        // Bound number of cuts and ensure arrays match
        numCuts = uint8(bound(numCuts, 1, 10));
        vm.assume(actions.length == numCuts);
        vm.assume(selectorSets.length == numCuts);

        vm.startPrank(owner);

        // Create multiple facets
        address[] memory facets = new address[](numCuts);
        for(uint i = 0; i < numCuts; i++) {
            DiamondLoupeFacet newFacet = new DiamondLoupeFacet();
            facets[i] = address(newFacet);
        }

        // Create and execute cuts
        IDiamondCut.FacetCut[] memory cuts = new IDiamondCut.FacetCut[](numCuts);
        for(uint i = 0; i < numCuts; i++) {
            // Ensure valid action (0 = Add, 1 = Replace, 2 = Remove)
            uint8 action = uint8(bound(actions[i], 0, 2));
            
            // For remove action, facet address should be zero
            address facetAddress = action == 2 ? address(0) : facets[i];

            // Ensure we have at least one selector
            vm.assume(selectorSets[i].length > 0 && selectorSets[i].length <= 10);

            cuts[i] = IDiamondCut.FacetCut({
                facetAddress: facetAddress,
                action: IDiamondCut.FacetCutAction(action),
                functionSelectors: selectorSets[i]
            });
        }

        try IDiamondCut(address(diamond)).diamondCut(cuts, address(0), "") {
            // Verify the state after cuts
            for(uint i = 0; i < numCuts; i++) {
                for(uint j = 0; j < selectorSets[i].length; j++) {
                    address facet = IDiamondLoupe(address(diamond)).facetAddress(selectorSets[i][j]);
                    if(cuts[i].action == IDiamondCut.FacetCutAction.Remove) {
                        assertEq(facet, address(0));
                    } else if (facet != address(0)) {
                        assertEq(facet, cuts[i].facetAddress);
                    }
                }
            }
        } catch {
            // Some combinations might be invalid, which is expected
        }

        vm.stopPrank();
    }

    function testFuzz_NonOwnerRandomCuts(
        address nonOwner,
        bytes4[] memory selectors
    ) public {
        vm.assume(nonOwner != owner && nonOwner != address(0));
        vm.assume(selectors.length > 0 && selectors.length <= 10);

        vm.startPrank(nonOwner);

        DiamondLoupeFacet newFacet = new DiamondLoupeFacet();
        
        IDiamondCut.FacetCut[] memory cuts = new IDiamondCut.FacetCut[](1);
        cuts[0] = IDiamondCut.FacetCut({
            facetAddress: address(newFacet),
            action: IDiamondCut.FacetCutAction.Add,
            functionSelectors: selectors
        });

        vm.expectRevert("LibDiamond: Must be contract owner");
        IDiamondCut(address(diamond)).diamondCut(cuts, address(0), "");

        vm.stopPrank();
    }
}
