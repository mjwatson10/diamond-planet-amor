// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

import "forge-std/Script.sol";
import "../src/facets/PlanetAmorNFTFacet.sol";
import "../src/Diamond.sol";

/// @title NFT Minting Script
/// @author Planet Amor Team
/// @notice Mints a specified number of Planet Amor NFTs
/// @dev Only the contract owner can execute this script
contract MintTokens is Script {
    /// @notice Sets up any required state before execution
    function setUp() public {}

    /// @notice Main execution function
    /// @dev Mints tokens using environment variables for configuration
    function run() public {
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
        address diamondAddress = vm.envAddress("DIAMOND_ADDRESS");
        uint256 mintAmount = vm.envUint("MINT_AMOUNT");

        require(mintAmount > 0, "Must mint at least 1 token");
        
        vm.startBroadcast(deployerPrivateKey);

        // Mint tokens
        PlanetAmorNFTFacet nft = PlanetAmorNFTFacet(diamondAddress);
        nft.mint(mintAmount);

        console.log("Minted %d tokens", mintAmount);
        console.log("Total minted: %d", nft.totalMinted());

        vm.stopBroadcast();
    }
}
