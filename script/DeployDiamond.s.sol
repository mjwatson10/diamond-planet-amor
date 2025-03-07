// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

import {Script} from "forge-std/Script.sol";
import {console} from "forge-std/console.sol";
import {Diamond} from "../src/Diamond.sol";
import {DiamondCutFacet} from "../src/facets/DiamondCutFacet.sol";
import {DiamondLoupeFacet} from "../src/facets/DiamondLoupeFacet.sol";
import {PlanetAmorNFTFacet} from "../src/facets/PlanetAmorNFTFacet.sol";
import {IDiamondCut} from "../src/interfaces/IDiamondCut.sol";

/// @title Diamond Standard Deployment Script
/// @author Planet Amor Team
/// @notice Deploys the Diamond proxy and all facets for the Planet Amor NFT collection
/// @dev Implements EIP-2535 Diamond Standard deployment pattern
contract DeployDiamond is Script {
    /// @notice Sets up any required state before deployment
    function setUp() public {}

    /// @notice Main deployment function
    /// @dev Deploys Diamond proxy, all facets, and configures initial diamond cut
    function run() public {
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
        vm.startBroadcast(deployerPrivateKey);

        // Deploy DiamondCutFacet
        DiamondCutFacet diamondCutFacet = new DiamondCutFacet();
        console.log("DiamondCutFacet deployed at: %s", address(diamondCutFacet));

        // Deploy Diamond
        address owner = vm.addr(deployerPrivateKey);
        Diamond diamond = new Diamond(owner, address(diamondCutFacet));
        console.log("Diamond deployed at: %s", address(diamond));

        // Deploy DiamondLoupeFacet
        DiamondLoupeFacet diamondLoupeFacet = new DiamondLoupeFacet();
        console.log("DiamondLoupeFacet deployed at: %s", address(diamondLoupeFacet));

        // Deploy PlanetAmorNFTFacet
        PlanetAmorNFTFacet nftFacet = new PlanetAmorNFTFacet();
        console.log("PlanetAmorNFTFacet deployed at: %s", address(nftFacet));

        // Build cut struct for diamond initialization
        IDiamondCut.FacetCut[] memory cut = new IDiamondCut.FacetCut[](2);

        // Add DiamondLoupeFacet
        bytes4[] memory loupeSelectors = new bytes4[](5);
        loupeSelectors[0] = DiamondLoupeFacet.facets.selector;
        loupeSelectors[1] = DiamondLoupeFacet.facetFunctionSelectors.selector;
        loupeSelectors[2] = DiamondLoupeFacet.facetAddresses.selector;
        loupeSelectors[3] = DiamondLoupeFacet.facetAddress.selector;
        loupeSelectors[4] = DiamondLoupeFacet.supportsInterface.selector;

        cut[0] = IDiamondCut.FacetCut({
            facetAddress: address(diamondLoupeFacet),
            action: IDiamondCut.FacetCutAction.Add,
            functionSelectors: loupeSelectors
        });

        // Add PlanetAmorNFTFacet
        bytes4[] memory nftSelectors = new bytes4[](7);
        nftSelectors[0] = PlanetAmorNFTFacet.mint.selector;
        nftSelectors[1] = PlanetAmorNFTFacet.tokenURI.selector;
        nftSelectors[2] = PlanetAmorNFTFacet.setBaseURI.selector;
        nftSelectors[3] = PlanetAmorNFTFacet.withdraw.selector;
        nftSelectors[4] = PlanetAmorNFTFacet.numberMinted.selector;
        nftSelectors[5] = PlanetAmorNFTFacet.name.selector;
        nftSelectors[6] = PlanetAmorNFTFacet.symbol.selector;

        cut[1] = IDiamondCut.FacetCut({
            facetAddress: address(nftFacet),
            action: IDiamondCut.FacetCutAction.Add,
            functionSelectors: nftSelectors
        });

        // Execute diamond cut
        IDiamondCut(address(diamond)).diamondCut(cut, address(0), "");

        vm.stopBroadcast();
    }
}
