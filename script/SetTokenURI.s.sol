// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "forge-std/Script.sol";
import "../src/facets/PlanetAmorNFTFacet.sol";
import "../src/Diamond.sol";

contract SetTokenURI is Script {
    function setUp() public {}

    function run() public {
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
        address diamondAddress = vm.envAddress("DIAMOND_ADDRESS");
        string memory baseURI = vm.envString("BASE_URI");
        string memory unrevealedURI = vm.envString("UNREVEALED_URI");
        bool shouldReveal = vm.envBool("SHOULD_REVEAL");

        vm.startBroadcast(deployerPrivateKey);

        // Set URIs
        PlanetAmorNFTFacet nft = PlanetAmorNFTFacet(diamondAddress);
        nft.setBaseURI(baseURI);
        nft.setUnrevealedURI(unrevealedURI);

        // Optionally reveal the collection
        if (shouldReveal) {
            nft.reveal();
        }

        vm.stopBroadcast();
    }
}
