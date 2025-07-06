# PhishStake Contract

A Solidity smart contract for USDC staking with admin reward and penalty mechanisms.

## Features

- **Individual Hash Staking**: Users can stake USDC with different hashes, each tracked separately
- **Multiple Stakes**: Users can have multiple stakes with different hashes simultaneously
- **Hash-Specific Rewards**: Admin can reward specific stakes by hash, returning only that stake plus rewards
- **Hash-Specific Penalties**: Admin can deny specific stakes by hash, transferring only that stake to the common pot
- **Common Pot Management**: Admin can top up the common pot with additional USDC
- **Access Control**: Only the contract owner can perform admin functions
- **Reentrancy Protection**: Built-in protection against reentrancy attacks

## Contract Functions

### User Functions
- `stake(bytes32 hash, uint256 amount)`: Stake USDC with an associated hash (can be called multiple times with different hashes)
- `getStake(address user, bytes32 hash)`: View a user's stake amount for a specific hash
- `getCommonPot()`: View the current common pot balance

### Admin Functions (Owner Only)
- `reward(address user, bytes32 hash, uint256 rewardAmount)`: Reward a specific stake by hash with bonus from common pot
- `deny(address user, bytes32 hash)`: Deny a specific stake by hash, adding it to the common pot
- `topup(uint256 amount)`: Add USDC to the common pot

## Usage

### Deploy the Contract
```solidity
// Deploy with USDC token address and initial owner
PhishStake phishStake = new PhishStake(usdcAddress, ownerAddress);
```

### Stake USDC
```solidity
// Approve USDC spending first
usdc.approve(address(phishStake), amount);

// Stake with different hashes (each tracked separately)
phishStake.stake(keccak256("first-hash"), 100e6);  // 100 USDC for first hash
phishStake.stake(keccak256("second-hash"), 50e6);  // 50 USDC for second hash

// Can add more to existing hash
phishStake.stake(keccak256("first-hash"), 25e6);   // Now first hash has 125 USDC total
```

### Admin Operations
```solidity
// Top up common pot
phishStake.topup(1000e6); // Add 1000 USDC to common pot

// Reward a specific stake by hash (returns that stake + reward)
phishStake.reward(userAddress, specificHash, 50e6); // Give 50 USDC reward for specificHash

// Deny a specific stake by hash (that stake goes to common pot)
phishStake.deny(userAddress, specificHash);
```

## Testing

Run the comprehensive test suite:

```bash
forge test
```

For verbose output:
```bash
forge test -vv
```

## Events

The contract emits the following events:
- `Staked(address user, bytes32 hash, uint256 amount)`
- `Rewarded(address user, bytes32 hash, uint256 stakeReturned, uint256 reward)`
- `Denied(address user, bytes32 hash, uint256 stakeAmount)`
- `ToppedUp(uint256 amount)`

## Security Features

- **Access Control**: Admin functions restricted to contract owner
- **Reentrancy Protection**: NonReentrant modifier on state-changing functions
- **Input Validation**: Zero amount and zero address checks
- **Safe Token Transfers**: Proper ERC20 transfer handling with revert on failure

## Gas Optimization

The contract uses efficient storage patterns and minimal external calls to keep gas costs low.

## License

MIT License

## ETHGlobal Prizes

### Zircuit Integration

**Project Summary**: PhishStake is a hash-based USDC staking protocol with admin-controlled reward and penalty mechanisms, featuring a common pot system for decentralized stake management.

**Zircuit Integration**: We integrated PhishStake with Zircuit's testnet infrastructure by developing custom deployment scripts (`DeployZircuit.s.sol`) that handle both Mock USDC deployment and PhishStake contract deployment with automatic verification via Zircuit's block explorer API. The integration leverages Zircuit's EVM-compatible architecture to deploy our Solidity contracts seamlessly, utilizing their testnet faucet for ETH and their explorer for contract verification. Our deployment pipeline is specifically configured for Zircuit's Chain ID (48899) and RPC endpoints, ensuring optimal compatibility with their network infrastructure.

**Team**:
 - Eito Miyamura - Oxford CS grad and currently running a startup for autonomous bug-finding hackbots for smart contracts
 - Ilia Manolov - Oxford CS grad, experience at a leading market maker, and also working on above-mentioned hackbots

**Testing Instructions**:
1. **Prerequisites**: Ensure you have Foundry installed and Zircuit testnet ETH
2. **Setup Environment**: 
   ```bash
   # Clone the repository
   git clone [repository-url]
   cd phish-stake-contract
   
   # Install dependencies
   forge install
   
   # Set up environment variables
   cp .env.example .env
   # Edit .env with your PRIVATE_KEY
   ```
3. **Run Tests**: 
   ```bash
   # Run comprehensive test suite
   forge test
   
   # Run with detailed output
   forge test -vvv
   ```
4. **Deploy to Zircuit Testnet**:
   ```bash
   # Deploy contracts
   forge script script/DeployZircuit.s.sol:DeployZircuitScript \
     --rpc-url zircuit_testnet \
     --broadcast \
     --verify \
     -vvvv
   ```
5. **Verify Integration**: Check deployed contracts on [Zircuit Testnet Explorer](https://explorer.testnet.zircuit.com/)

**Zircuit Development Experience**: It was a bit rough to deploy everything, in all honesty. Really wish there were some end-to-end examples of how to do it but we managed somehow.

**Demo**: [Placeholder] - Video demonstration showcasing the complete staking workflow, admin functions, and Zircuit integration available at [demo-link].

**Contract Addresses** (Zircuit Testnet):
- PhishStake: [To be deployed]
- Mock USDC: [To be deployed]

**Verification Status**: ✅ Contracts verified on Zircuit Testnet Explorer




## Foundry

**Foundry is a blazing fast, portable and modular toolkit for Ethereum application development written in Rust.**

Foundry consists of:

-   **Forge**: Ethereum testing framework (like Truffle, Hardhat and DappTools).
-   **Cast**: Swiss army knife for interacting with EVM smart contracts, sending transactions and getting chain data.
-   **Anvil**: Local Ethereum node, akin to Ganache, Hardhat Network.
-   **Chisel**: Fast, utilitarian, and verbose solidity REPL.

## Documentation

https://book.getfoundry.sh/

## Usage

### Build

```shell
$ forge build
```

### Test

```shell
$ forge test
```

### Format

```shell
$ forge fmt
```

### Gas Snapshots

```shell
$ forge snapshot
```

### Anvil

```shell
$ anvil
```

### Deploy

```shell
$ forge script script/Counter.s.sol:CounterScript --rpc-url <your_rpc_url> --private-key <your_private_key>
```

### Cast

```shell
$ cast <subcommand>
```

### Help

```shell
$ forge --help
$ anvil --help
$ cast --help
```