# Diamond Planet Amor NFT

A modern NFT collection implementing EIP-2535 Diamond Standard and ERC721A for gas-efficient minting.

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
- `NFTFacet.sol`: Implements ERC721A functionality
- `DiamondCutFacet.sol`: Handles adding/replacing/removing facets
- `DiamondLoupeFacet.sol`: Provides introspection functions
- `LibDiamond.sol`: Core diamond functionality
- Various interfaces in the `interfaces/` directory

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

### Deployment

1. Set up your environment variables:
```bash
cp .env.example .env
# Edit .env with your configuration
```

2. Deploy the contracts:
```bash
forge script script/DeployDiamond.s.sol --rpc-url <your_rpc_url> --private-key <your_private_key>
```

## License

MIT
