// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "forge-std/Script.sol";
import "../src/facets/PlanetAmorNFTFacet.sol";
import "../src/Diamond.sol";

contract MintTokens is Script {
    function setUp() public {}

    function run() public {
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
        address diamondAddress = vm.envAddress("DIAMOND_ADDRESS");
        uint256 mintAmount = vm.envUint("MINT_AMOUNT");

        require(mintAmount > 0, "Must mint at least 1 token");
        
        vm.startBroadcast(deployerPrivateKey);

        // Mint tokens
        PlanetAmorNFTFacet nft = PlanetAmorNFTFacet(diamondAddress);
        nft.mint(mintAmount);

        console.log("Successfully minted %s tokens", mintAmount);
        console.log("Total minted: %s", nft.totalMinted());

        vm.stopBroadcast();
    }
}
