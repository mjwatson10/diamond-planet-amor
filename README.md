# Diamond Planet Amor NFT

A modern NFT collection implementing EIP-2535 Diamond Standard and ERC721A for gas-efficient minting.

## Overview

Planet Amor is an NFT collection that represents unique celestial bodies in the universe. Each NFT is a one-of-a-kind planet with its own characteristics and artwork. The contract is built using the Diamond Standard (EIP-2535) for maximum upgradeability and gas efficiency.

### What is the Diamond Standard?

The Diamond Standard (EIP-2535) is an advanced proxy pattern that solves several limitations of traditional proxy contracts:

1. **Unlimited Contract Size**: Unlike traditional contracts that are limited to 24KB, Diamond contracts can have unlimited functionality by splitting code across multiple facets.

2. **Modular Upgrades**: Individual facets (modules) can be added, replaced, or removed without affecting other facets. This means we can:
   - Fix bugs in specific features
   - Add new features
   - Upgrade individual components
   - Remove unused functionality

3. **Function Management**: The Diamond contract maintains a function selector mapping that routes calls to the appropriate facet, allowing:
   - Multiple functions with the same name in different facets
   - Clear organization of related functionality
   - Gas-efficient function delegation

### Contract Architecture

```
Diamond (Main Contract)
├── PlanetAmorNFTFacet
│   ├── mint()
│   ├── tokenURI()
│   ├── reveal()
│   └── withdraw()
├── DiamondCutFacet
│   ├── diamondCut()
│   └── (upgrade functions)
└── DiamondLoupeFacet
    └── (introspection functions)
```

- **Diamond.sol**: The main proxy contract that:
  - Receives all function calls
  - Delegates calls to appropriate facets
  - Stores all contract state

- **PlanetAmorNFTFacet.sol**: Handles NFT functionality:
  - Minting mechanics (using ERC721A)
  - Token URI management
  - Reveal mechanism
  - Fund withdrawal

- **DiamondCutFacet.sol**: Manages upgrades:
  - Adding new facets
  - Replacing existing facets
  - Removing facets
  - Security checks

- **DiamondLoupeFacet.sol**: Provides transparency:
  - View all facets
  - List functions for each facet
  - Query facet addresses

### How It Works

1. **Function Calls**:
   - User calls a function on the Diamond contract
   - Diamond looks up the function selector in its mapping
   - Call is delegated to the appropriate facet

2. **State Management**:
   - All state variables are stored in the Diamond contract
   - Facets share the same storage layout
   - Storage layout is managed through LibDiamond

3. **Upgrades**:
   - Owner can add/replace/remove facets through diamondCut()
   - Each upgrade is atomic and can modify multiple facets
   - Failed upgrades are fully reverted

### Storage Layout

The Diamond pattern requires careful management of storage layout to prevent collisions and ensure upgrades don't corrupt existing state. Our implementation uses:

1. **Storage Pattern**:
   ```solidity
   // LibDiamond.sol
   struct DiamondStorage {
       mapping(bytes4 => FacetAddressAndPosition) facetAddressAndPositionMap;
       bytes4[] functionSelectors;
       mapping(address => FacetFunctionSelectors) facetFunctionSelectorsMap;
       address contractOwner;
   }
   ```

2. **Storage Namespacing**:
   ```solidity
   // PlanetAmorNFTFacet Storage
   struct NFTStorage {
       uint256 mintPrice;
       string baseURI;
       string unrevealedURI;
       bool revealed;
       // ERC721A storage is handled separately
   }
   ```

3. **Storage Access**:
   - Each facet uses a unique storage position (Diamond Storage pattern)
   - Storage positions are computed using unique namespace strings
   - Example:
     ```solidity
     bytes32 constant DIAMOND_STORAGE_POSITION = keccak256("diamond.standard.diamond.storage");
     bytes32 constant NFT_STORAGE_POSITION = keccak256("diamond.standard.nft.storage");
     ```

### Upgrade Process

The upgrade process is handled through the `diamondCut()` function in DiamondCutFacet. Here's how it works:

1. **Preparing an Upgrade**:
   ```solidity
   IDiamondCut.FacetCut[] memory cut = new IDiamondCut.FacetCut[](1);
   bytes4[] memory selectors = new bytes4[](2);
   
   // Example: Adding new mint functions
   selectors[0] = INewFeature.newMint.selector;
   selectors[1] = INewFeature.newBatchMint.selector;
   
   cut[0] = IDiamondCut.FacetCut({
       facetAddress: address(newFacet),
       action: IDiamondCut.FacetCutAction.Add,
       functionSelectors: selectors
   });
   ```

2. **Upgrade Actions**:
   - `Add`: Add new functions from a facet
   - `Replace`: Replace existing functions with new implementations
   - `Remove`: Remove functions from the diamond

3. **Security Checks**:
   - Only owner can perform upgrades
   - Function selectors must be unique
   - Facet address must be valid
   - Replace/Remove only existing functions
   - Add only new functions

4. **Initialization**:
   ```solidity
   // Optional initialization after upgrade
   bytes memory init = abi.encodeWithSignature(
       "init(uint256,string)",
       newPrice,
       newBaseURI
   );
   
   diamond.diamondCut(
       cut,
       initializationContractAddress,
       init
   );
   ```

5. **Atomic Execution**:
   - All changes in a cut are executed as one transaction
   - If any step fails, the entire upgrade reverts
   - State remains consistent even if upgrade fails

6. **Best Practices**:
   - Test upgrades on testnet first
   - Use initialization functions for new state variables
   - Keep detailed records of all upgrades
   - Verify function selectors before upgrade
   - Consider using timelock for critical upgrades

### Advanced Initialization Patterns

The Diamond Standard supports sophisticated initialization patterns for complex upgrades. Here are the key patterns we use:

1. **Multi-Facet Initialization**:
   ```solidity
   // Initialize multiple facets in one upgrade
   contract MultiInit {
       function init(
           uint256 mintPrice,
           string memory baseURI,
           address[] memory whitelist
       ) external {
           // Get NFT storage
           NFTStorage storage ns = LibDiamond.getStorage();
           ns.mintPrice = mintPrice;
           ns.baseURI = baseURI;
           
           // Get whitelist storage
           WhitelistStorage storage ws = LibDiamond.getWhitelistStorage();
           for (uint i = 0; i < whitelist.length; i++) {
               ws.whitelisted[whitelist[i]] = true;
           }
       }
   }

   // Usage in diamondCut
   bytes memory initData = abi.encodeWithSelector(
       MultiInit.init.selector,
       1 ether,
       "ipfs://...",
       whitelistAddresses
   );
   diamond.diamondCut(cuts, address(multiInit), initData);
   ```

2. **Staged Initialization**:
   ```solidity
   // Stage 1: Basic setup
   contract StageOneInit {
       function init() external {
           NFTStorage storage ns = LibDiamond.getStorage();
           ns.revealed = false;
           ns.unrevealedURI = "ipfs://unrevealed";
       }
   }

   // Stage 2: Post-reveal setup
   contract StageTwoInit {
       function init(string[] memory tokenURIs) external {
           NFTStorage storage ns = LibDiamond.getStorage();
           ns.revealed = true;
           for (uint i = 0; i < tokenURIs.length; i++) {
               ns.tokenURIs[i] = tokenURIs[i];
           }
       }
   }
   ```

3. **Conditional Initialization**:
   ```solidity
   contract ConditionalInit {
       function init(bytes memory config) external {
           (bool shouldUpdatePrice, uint256 newPrice,
            bool shouldUpdateURI, string memory newURI) = 
            abi.decode(config, (bool, uint256, bool, string));

           NFTStorage storage ns = LibDiamond.getStorage();
           
           if (shouldUpdatePrice) {
               require(newPrice > 0, "Invalid price");
               ns.mintPrice = newPrice;
           }
           
           if (shouldUpdateURI) {
               require(bytes(newURI).length > 0, "Invalid URI");
               ns.baseURI = newURI;
           }
       }
   }
   ```

4. **State Migration Pattern**:
   ```solidity
   // V1 Storage
   struct NFTStorageV1 {
       uint256 mintPrice;
       string baseURI;
   }

   // V2 Storage with new fields
   struct NFTStorageV2 {
       uint256 mintPrice;
       string baseURI;
       mapping(address => uint256) discounts;
   }

   contract MigrationInit {
       function init() external {
           // Get old storage
           NFTStorageV1 storage oldStorage = LibDiamond.getStorageAt(
               keccak256("diamond.storage.nft.v1")
           );
           
           // Get new storage
           NFTStorageV2 storage newStorage = LibDiamond.getStorageAt(
               keccak256("diamond.storage.nft.v2")
           );
           
           // Migrate data
           newStorage.mintPrice = oldStorage.mintPrice;
           newStorage.baseURI = oldStorage.baseURI;
           
           // Initialize new fields
           newStorage.discounts[msg.sender] = 50; // 50% discount for owner
       }
   }
   ```

5. **Best Practices for Initialization**:
   - Always validate input parameters
   - Use try/catch for external calls
   - Keep initialization functions simple and focused
   - Test initialization with various scenarios
   - Document storage changes clearly
   - Consider gas costs for large initializations
   - Use events to track initialization steps
   - Implement initialization guards when needed

Example of a robust initialization guard:
```solidity
contract GuardedInit {
    bytes32 constant INIT_STORAGE_POSITION = 
        keccak256("diamond.storage.init.guard");

    struct InitGuard {
        mapping(bytes4 => bool) initialized;
    }

    modifier initializer(bytes4 initSelector) {
        InitGuard storage guard = LibDiamond.getStorageAt(
            INIT_STORAGE_POSITION
        );
        require(
            !guard.initialized[initSelector],
            "Already initialized"
        );
        guard.initialized[initSelector] = true;
        _;
    }

    function init() external initializer(this.init.selector) {
        // Initialization logic
    }
}
```

### Example Upgrade

Here's a real example of adding a new feature:

```solidity
// 1. Deploy new facet
NewFeatureFacet newFeature = new NewFeatureFacet();

// 2. Prepare function selectors
bytes4[] memory selectors = new bytes4[](1);
selectors[0] = NewFeatureFacet.newFunction.selector;

// 3. Create the cut
IDiamondCut.FacetCut[] memory cut = new IDiamondCut.FacetCut[](1);
cut[0] = IDiamondCut.FacetCut({
    facetAddress: address(newFeature),
    action: IDiamondCut.FacetCutAction.Add,
    functionSelectors: selectors
});

// 4. Execute the upgrade
diamond.diamondCut(cut, address(0), "");
```

## Features

- EIP-2535 Diamond Standard implementation for upgradeable contracts
- ERC721A implementation for gas-efficient batch minting
- Modular facet architecture
- Reveal mechanism for artwork
- Fixed mint price of 1 ETH

## Technical Details

### Diamond Standard (EIP-2535)

The project uses the Diamond Standard which allows:
- Unlimited contract size through modular facets
- Upgradeable functionality
- Better organized code through separation of concerns

### ERC721A

Implements Azuki's ERC721A for efficient batch minting, significantly reducing gas costs for multiple mints in a single transaction.

## Contract Structure

- `Diamond.sol`: The main diamond contract that delegates calls to facets
- `PlanetAmorNFTFacet.sol`: Implements ERC721A functionality
- `DiamondCutFacet.sol`: Handles adding/replacing/removing facets
- `DiamondLoupeFacet.sol`: Provides introspection functions
- `LibDiamond.sol`: Core diamond functionality
- Various interfaces in the `interfaces/` directory

## Deployment

### Deployment Script

The project uses Foundry's script system for deployments. The deployment script (`script/DeployDiamond.s.sol`) handles the complete setup of the Diamond contract and all its facets:

```solidity
contract DeployDiamond is Script {
    function run() external {
        // Load deployer's private key from environment
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
        vm.startBroadcast(deployerPrivateKey);

        // 1. Deploy core contracts
        DiamondCutFacet diamondCutFacet = new DiamondCutFacet();
        Diamond diamond = new Diamond(
            msg.sender,  // Owner
            address(diamondCutFacet)
        );

        // 2. Deploy feature facets
        DiamondLoupeFacet diamondLoupeFacet = new DiamondLoupeFacet();
        PlanetAmorNFTFacet nftFacet = new PlanetAmorNFTFacet();

        // 3. Configure diamond cut for facets
        IDiamondCut.FacetCut[] memory cut = new IDiamondCut.FacetCut[](2);

        // 4. Add DiamondLoupe functions
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

        // 5. Add NFT functions
        bytes4[] memory nftFacetSelectors = new bytes4[](10);
        nftFacetSelectors[0] = PlanetAmorNFTFacet.mint.selector;
        nftFacetSelectors[1] = PlanetAmorNFTFacet.tokenURI.selector;
        nftFacetSelectors[2] = PlanetAmorNFTFacet.setBaseURI.selector;
        nftFacetSelectors[3] = PlanetAmorNFTFacet.setUnrevealedURI.selector;
        nftFacetSelectors[4] = PlanetAmorNFTFacet.reveal.selector;
        nftFacetSelectors[5] = PlanetAmorNFTFacet.withdraw.selector;
        nftFacetSelectors[6] = PlanetAmorNFTFacet.numberMinted.selector;
        nftFacetSelectors[7] = PlanetAmorNFTFacet.totalMinted.selector;
        nftFacetSelectors[8] = PlanetAmorNFTFacet.name.selector;
        nftFacetSelectors[9] = PlanetAmorNFTFacet.symbol.selector;

        cut[1] = IDiamondCut.FacetCut({
            facetAddress: address(nftFacet),
            action: IDiamondCut.FacetCutAction.Add,
            functionSelectors: nftFacetSelectors
        });

        // 6. Execute diamond cut
        IDiamondCut(address(diamond)).diamondCut(cut, address(0), "");

        vm.stopBroadcast();
    }
}
```

#### Deployment Process

1. **Environment Setup**:
   ```bash
   # Copy example environment file
   cp .env.example .env
   
   # Edit .env with your configuration
   PRIVATE_KEY=your_private_key_here
   RPC_URL=your_rpc_url_here
   ```

2. **Local Testing**:
   ```bash
   # Deploy to local Anvil chain
   forge script script/DeployDiamond.s.sol --fork-url http://localhost:8545 --broadcast
   ```

3. **Testnet Deployment**:
   ```bash
   # Deploy to testnet (e.g., Sepolia)
   forge script script/DeployDiamond.s.sol \
       --rpc-url $RPC_URL \
       --private-key $PRIVATE_KEY \
       --broadcast \
       --verify
   ```

4. **Mainnet Deployment**:
   ```bash
   # Deploy to mainnet with verification
   forge script script/DeployDiamond.s.sol \
       --rpc-url $RPC_URL \
       --private-key $PRIVATE_KEY \
       --broadcast \
       --verify \
       --etherscan-api-key $ETHERSCAN_KEY
   ```

#### Post-Deployment Steps

After deployment, the script outputs the addresses of all deployed contracts:
```
Diamond deployed at: 0x...
DiamondCutFacet deployed at: 0x...
DiamondLoupeFacet deployed at: 0x...
PlanetAmorNFTFacet deployed at: 0x...
```

Save these addresses for:
- Contract verification
- Frontend integration
- Further upgrades
- Documentation

#### Deployment Best Practices

1. **Pre-deployment Checklist**:
   - Verify all facet selectors are correct
   - Ensure no selector collisions
   - Check owner address is correct
   - Validate initial parameters

2. **Security Considerations**:
   - Use a dedicated deployment wallet
   - Never commit private keys
   - Verify contracts after deployment
   - Test on local/testnet first

3. **Gas Optimization**:
   - Deploy during low gas periods
   - Batch facet deployments efficiently
   - Consider function ordering for gas savings

#### Diamond-Specific Deployment Considerations

1. **Function Selector Management**:
   ```solidity
   // Helper function to get all selectors from a facet
   function getSelectors(address facet) internal view returns (bytes4[] memory) {
       // Get selectors using contract reflection
       (bool success, bytes memory data) = facet.staticcall(
           abi.encodeWithSignature("getAllSelectors()")
       );
       require(success, "Failed to get selectors");
       return abi.decode(data, (bytes4[]));
   }
   ```

2. **Facet Deployment Order**:
   ```solidity
   // Recommended deployment order
   DiamondCutFacet diamondCutFacet = new DiamondCutFacet();
   Diamond diamond = new Diamond(owner, address(diamondCutFacet));
   DiamondLoupeFacet loupe = new DiamondLoupeFacet();
   PlanetAmorNFTFacet nft = new PlanetAmorNFTFacet();
   ```

3. **Initial State Setup**:
   ```solidity
   // Example initialization contract
   contract DiamondInit {
       struct Args {
           string name;
           string symbol;
           string baseURI;
           uint256 mintPrice;
       }

       function init(bytes memory args) external {
           Args memory _args = abi.decode(args, (Args));
           
           // Initialize NFT storage
           NFTStorage storage ns = LibDiamond.getNFTStorage();
           ns.name = _args.name;
           ns.symbol = _args.symbol;
           ns.baseURI = _args.baseURI;
           ns.mintPrice = _args.mintPrice;
           ns.revealed = false;
       }
   }
   ```

4. **Verification Process**:
   ```bash
   # 1. Verify Diamond implementation
   forge verify-contract $DIAMOND_ADDRESS src/Diamond.sol:Diamond \
       --constructor-args $(cast abi-encode "constructor(address,address)" $OWNER $DIAMOND_CUT_FACET)

   # 2. Verify each facet
   forge verify-contract $DIAMOND_CUT_FACET src/facets/DiamondCutFacet.sol:DiamondCutFacet
   forge verify-contract $DIAMOND_LOUPE_FACET src/facets/DiamondLoupeFacet.sol:DiamondLoupeFacet
   forge verify-contract $NFT_FACET src/facets/PlanetAmorNFTFacet.sol:PlanetAmorNFTFacet
   ```

5. **Post-Deployment Verification**:
   ```solidity
   // Verify facets were added correctly
   function verifyDeployment(address diamond) internal view {
       // Get all facets
       IDiamondLoupe.Facet[] memory facets = 
           IDiamondLoupe(diamond).facets();
       
       // Verify expected number of facets
       require(facets.length == 3, "Wrong number of facets");
       
       // Verify each facet has correct functions
       for (uint i = 0; i < facets.length; i++) {
           bytes4[] memory selectors = 
               IDiamondLoupe(diamond).facetFunctionSelectors(
                   facets[i].facetAddress
               );
           // Verify selectors match expected
           verifySelectors(
               facets[i].facetAddress,
               selectors
           );
       }
   }
   ```

6. **Emergency Procedures**:
   ```solidity
   // Add emergency functions to DiamondCutFacet
   function emergencyPause() external {
       require(msg.sender == owner, "Not owner");
       LibDiamond.DiamondStorage storage ds = 
           LibDiamond.getDiamondStorage();
       ds.paused = true;
   }

   function emergencyUnpause() external {
       require(msg.sender == owner, "Not owner");
       LibDiamond.DiamondStorage storage ds = 
           LibDiamond.getDiamondStorage();
       ds.paused = false;
   }
   ```

## Development

### Prerequisites

- [Foundry](https://github.com/foundry-rs/foundry)

### Setup

1. Clone the repository
2. Install dependencies:
```bash
forge install
```

### Testing

Run the tests:
```bash
forge test
```

### Coverage

For regular test coverage analysis (excluding fuzz tests):
```bash
forge coverage --no-match-test "testFuzz"
```

For coverage including fuzz tests (may be slow):
```bash
forge coverage --fuzz-runs 10
```

Note: When running full coverage with fuzz tests, the process may be slow or get stuck due to the complexity of analyzing all possible execution paths. It's recommended to:
1. Run coverage without fuzz tests for regular development
2. Run fuzz tests separately using `forge test --match-test "testFuzz"`
3. Use `--fuzz-runs` with a lower number when including fuzz tests in coverage

## License

MIT
