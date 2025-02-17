// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "forge-std/Script.sol";
import "../src/Diamond.sol";
import "../src/facets/DiamondCutFacet.sol";
import "../src/facets/DiamondLoupeFacet.sol";
import "../src/facets/NFTFacet.sol";
import "../src/interfaces/IDiamondCut.sol";

contract DeployDiamond is Script {
    function run() external {
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
        vm.startBroadcast(deployerPrivateKey);

        // Deploy DiamondCutFacet
        DiamondCutFacet diamondCutFacet = new DiamondCutFacet();
        
        // Deploy Diamond
        Diamond diamond = new Diamond(msg.sender, address(diamondCutFacet));

        // Deploy facets
        DiamondLoupeFacet diamondLoupeFacet = new DiamondLoupeFacet();
        NFTFacet nftFacet = new NFTFacet();

        // Build cut struct for diamond loupe and NFT facets
        IDiamondCut.FacetCut[] memory cut = new IDiamondCut.FacetCut[](2);

        // Add DiamondLoupeFacet functions
        bytes4[] memory diamondLoupeFacetSelectors = new bytes4[](5);
        diamondLoupeFacetSelectors[0] = DiamondLoupeFacet.facets.selector;
        diamondLoupeFacetSelectors[1] = DiamondLoupeFacet.facetFunctionSelectors.selector;
        diamondLoupeFacetSelectors[2] = DiamondLoupeFacet.facetAddresses.selector;
        diamondLoupeFacetSelectors[3] = DiamondLoupeFacet.facetAddress.selector;
        diamondLoupeFacetSelectors[4] = DiamondLoupeFacet.supportsInterface.selector;

        cut[0] = IDiamondCut.FacetCut({
            facetAddress: address(diamondLoupeFacet),
            action: IDiamondCut.FacetCutAction.Add,
            functionSelectors: diamondLoupeFacetSelectors
        });

        // Add NFTFacet functions
        bytes4[] memory nftFacetSelectors = new bytes4[](10);
        nftFacetSelectors[0] = NFTFacet.mint.selector;
        nftFacetSelectors[1] = NFTFacet.tokenURI.selector;
        nftFacetSelectors[2] = NFTFacet.setBaseURI.selector;
        nftFacetSelectors[3] = NFTFacet.setUnrevealedURI.selector;
        nftFacetSelectors[4] = NFTFacet.reveal.selector;
        nftFacetSelectors[5] = NFTFacet.withdraw.selector;
        nftFacetSelectors[6] = NFTFacet.numberMinted.selector;
        nftFacetSelectors[7] = NFTFacet.totalMinted.selector;
        nftFacetSelectors[8] = NFTFacet.name.selector;
        nftFacetSelectors[9] = NFTFacet.symbol.selector;

        cut[1] = IDiamondCut.FacetCut({
            facetAddress: address(nftFacet),
            action: IDiamondCut.FacetCutAction.Add,
            functionSelectors: nftFacetSelectors
        });

        // Upgrade diamond with facets
        IDiamondCut(address(diamond)).diamondCut(cut, address(0), "");

        vm.stopBroadcast();

        console.log("Diamond deployed at:", address(diamond));
        console.log("DiamondCutFacet deployed at:", address(diamondCutFacet));
        console.log("DiamondLoupeFacet deployed at:", address(diamondLoupeFacet));
        console.log("NFTFacet deployed at:", address(nftFacet));
    }
}
