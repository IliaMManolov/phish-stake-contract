# PhishStake Deployment Guide

This guide walks you through deploying the PhishStake contract to a local testnet using Foundry's Anvil.

## Prerequisites

Make sure you have Foundry installed:
```bash
curl -L https://foundry.paradigm.xyz | bash
foundryup
```

## Step 1: Create Environment Variables

Create a `.env` file in your project root:

```bash
# .env file
PRIVATE_KEY=ac0974bec39a17e36ba4a6b4d238ff944bacb478cbed5efcae784d7bf4f2ff80
RPC_URL=http://127.0.0.1:8545
```

> **Note**: The private key above is one of Anvil's default test keys. Never use this in production!

## Step 2: Start Anvil

Open a terminal and start the local testnet:

```bash
anvil
```

This will:
- Start a local Ethereum node on `http://127.0.0.1:8545`
- Create 10 test accounts with 10,000 ETH each
- Display the private keys for testing

Keep this terminal open while deploying and testing.

## Step 3: Deploy the Contract

In a new terminal, run the deployment script:

```bash
# Load environment variables and deploy
source .env
forge script script/Deploy.s.sol --rpc-url $RPC_URL --broadcast --private-key $PRIVATE_KEY
```

Or in a single command:
```bash
forge script script/Deploy.s.sol --rpc-url http://127.0.0.1:8545 --broadcast --private-key ac0974bec39a17e36ba4a6b4d238ff944bacb478cbed5efcae784d7bf4f2ff80
```

## Step 4: Verify Deployment

After successful deployment, you'll see output like:
```
Mock USDC deployed at: 0x5fbdb2315678afecb367f032d93f642f64180aa3
PhishStake deployed at: 0xe7f1725e7734ce288f8367e1bb143e90bb3f0512
Owner: 0xf39fd6e51aad88f6f4ce6ab8827279cfffb92266
Common Pot Balance: 1000 USDC
Owner USDC Balance: 9000 USDC
```

## Step 5: Interact with the Contract

### Using Cast (Command Line)

```bash
# Get contract addresses from deployment
USDC_ADDRESS=0x5fbdb2315678afecb367f032d93f642f64180aa3
PHISH_STAKE_ADDRESS=0xe7f1725e7734ce288f8367e1bb143e90bb3f0512
DEPLOYER_ADDRESS=0xf39fd6e51aad88f6f4ce6ab8827279cfffb92266

# Check common pot balance
cast call $PHISH_STAKE_ADDRESS "getCommonPot()" --rpc-url http://127.0.0.1:8545

# Check USDC balance of owner
cast call $USDC_ADDRESS "balanceOf(address)" $DEPLOYER_ADDRESS --rpc-url http://127.0.0.1:8545
```

### Example: Stake USDC

```bash
# Create a hash for staking
HASH=0x1234567890abcdef1234567890abcdef1234567890abcdef1234567890abcdef

# Approve PhishStake to spend 100 USDC
cast send $USDC_ADDRESS "approve(address,uint256)" $PHISH_STAKE_ADDRESS 100000000 --rpc-url http://127.0.0.1:8545 --private-key $PRIVATE_KEY

# Stake 100 USDC with the hash
cast send $PHISH_STAKE_ADDRESS "stake(bytes32,uint256)" $HASH 100000000 --rpc-url http://127.0.0.1:8545 --private-key $PRIVATE_KEY

# Check the stake
cast call $PHISH_STAKE_ADDRESS "getStake(address,bytes32)" $DEPLOYER_ADDRESS $HASH --rpc-url http://127.0.0.1:8545
```

### Example: Reward a Stake

```bash
# Reward the stake with 50 USDC bonus
cast send $PHISH_STAKE_ADDRESS "reward(address,bytes32,uint256)" $DEPLOYER_ADDRESS $HASH 50000000 --rpc-url http://127.0.0.1:8545 --private-key $PRIVATE_KEY
```

## Step 6: Multiple Users Testing

Use different Anvil accounts for multi-user testing:

```bash
# Anvil provides multiple test accounts
USER1_KEY=59c6995e998f97436827d175df0e1d05872348b3ad44ab2a3c8e5c8e5e5c8e5c
USER2_KEY=5de4111afa1a4b94908f83103eb1f1706367c2e68ca870fc3fb9a804cdab365a

# Mint USDC to users
cast send $USDC_ADDRESS "mint(address,uint256)" 0x70997970C51812dc3A010C7d01b50e0d17dc79C8 1000000000 --rpc-url http://127.0.0.1:8545 --private-key $PRIVATE_KEY

# User1 can now stake
cast send $USDC_ADDRESS "approve(address,uint256)" $PHISH_STAKE_ADDRESS 500000000 --rpc-url http://127.0.0.1:8545 --private-key $USER1_KEY
cast send $PHISH_STAKE_ADDRESS "stake(bytes32,uint256)" $HASH 500000000 --rpc-url http://127.0.0.1:8545 --private-key $USER1_KEY
```

## Troubleshooting

### Common Issues

1. **"Failed to get account"**: Make sure Anvil is running and the RPC URL is correct
2. **"Insufficient funds"**: The deployer account needs ETH for gas fees
3. **"Nonce too low"**: Reset Anvil or use a different account

### Reset Anvil

If you need to reset the blockchain state:
```bash
# Stop Anvil (Ctrl+C) and restart
anvil
```

## Production Deployment

For real testnets (Sepolia, Goerli) or mainnet:

1. **Never use test private keys**
2. **Use a real USDC contract address** (not the mock one)
3. **Set appropriate gas prices**
4. **Verify contracts on Etherscan**

Example for Sepolia:
```bash
forge script script/Deploy.s.sol --rpc-url https://rpc.sepolia.org --broadcast --private-key YOUR_REAL_PRIVATE_KEY --verify --etherscan-api-key YOUR_ETHERSCAN_KEY
```

## Contract Addresses

After deployment, save these addresses for future interactions:
- **Mock USDC**: `<address_from_deployment>`
- **PhishStake**: `<address_from_deployment>`
- **Owner**: `<your_deployer_address>`

## Security Notes

- 🔒 Never commit private keys to version control
- 🔒 Use hardware wallets for mainnet deployments
- 🔒 Test thoroughly on testnets before mainnet
- 🔒 Consider using a multisig wallet for contract ownership 