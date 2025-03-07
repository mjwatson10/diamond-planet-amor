// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

import "forge-std/Script.sol";
import "../src/facets/PlanetAmorNFTFacet.sol";
import "../src/Diamond.sol";

/// @title Token URI Configuration Script
/// @author Planet Amor Team
/// @notice Sets the base URI for the Planet Amor NFT collection
/// @dev Uses environment variables for configuration
contract SetTokenURI is Script {
    /// @notice Sets up any required state before execution
    function setUp() public {}

    /// @notice Main execution function
    /// @dev Sets the base URI for token metadata using environment variables
    function run() public {
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
        address diamondAddress = vm.envAddress("DIAMOND_ADDRESS");
        string memory baseURI = vm.envString("BASE_URI");

        vm.startBroadcast(deployerPrivateKey);

        // Set base URI
        PlanetAmorNFTFacet nft = PlanetAmorNFTFacet(diamondAddress);
        nft.setBaseURI(baseURI);

        console.log("Base URI set to: %s", baseURI);
        console.log("Example token URI for token 0: %s0", baseURI);

        vm.stopBroadcast();
    }
}
