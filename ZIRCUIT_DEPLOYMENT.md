# PhishStake Deployment Guide for Zircuit Testnet

This guide will help you deploy the PhishStake contract to Zircuit testnet.

## Prerequisites

### 1. Get Zircuit Testnet ETH
- Visit the [Zircuit testnet faucet](https://faucet.testnet.zircuit.com/) or use their Discord faucet
- You'll need ETH for transaction fees (deployment typically costs ~0.01 ETH)

### 2. Set up a Wallet
- Create a new wallet for testnet deployment (never use mainnet private keys)
- Export the private key (you'll need it for deployment)

### 3. Get Zircuit API Key (for verification)
- Visit [Zircuit Testnet Explorer](https://explorer.testnet.zircuit.com/)
- Click on "API Keys" in the top menu
- Connect your wallet and sign in
- Generate an API key (record it for later use)

## Deployment Steps

### 1. Environment Setup

Create a `.env` file in your project root:

```env
# Your wallet private key (WITHOUT 0x prefix)
PRIVATE_KEY=your_private_key_here

# Zircuit Explorer API key for contract verification
ZIRCUIT_API_KEY=your_api_key_here

# Optional: Existing USDC contract address (if available)
# USDC_ADDRESS=0x...

# Optional: Initial topup amount in USDC units (default: 1000 USDC = 1000000000)
# INITIAL_TOPUP=1000000000
```

### 2. Deploy to Zircuit Testnet

Run the deployment script:

```bash
# Load environment variables
source .env

# Deploy contracts
forge script script/DeployZircuit.s.sol:DeployZircuitScript \
  --rpc-url zircuit_testnet \
  --broadcast \
  --verify \
  --etherscan-api-key $ZIRCUIT_API_KEY \
  -vvvv
```

### 3. Alternative: Deploy without automatic verification

If automatic verification fails, deploy first, then verify separately:

```bash
# Deploy without verification
forge script script/DeployZircuit.s.sol:DeployZircuitScript \
  --rpc-url zircuit_testnet \
  --broadcast \
  -vvvv
```

## Manual Contract Verification

If automatic verification doesn't work, use these commands (the deployment script will output the exact commands):

### Verify PhishStake Contract
```bash
forge verify-contract --verifier-url https://explorer.testnet.zircuit.com/api/contractVerifyHardhat \
  <PHISH_STAKE_ADDRESS> src/PhishStake.sol:PhishStake \
  --etherscan-api-key $ZIRCUIT_API_KEY \
  --constructor-args $(cast abi-encode "constructor(address,address)" <USDC_ADDRESS> <OWNER_ADDRESS>)
```

### Verify Mock USDC Contract (if deployed)
```bash
forge verify-contract --verifier-url https://explorer.testnet.zircuit.com/api/contractVerifyHardhat \
  <MOCK_USDC_ADDRESS> script/DeployZircuit.s.sol:MockUSDC \
  --etherscan-api-key $ZIRCUIT_API_KEY
```

## Post-Deployment

### 1. Verify Deployment
Check your contracts on the [Zircuit Testnet Explorer](https://explorer.testnet.zircuit.com/):
- Search for your contract addresses
- Verify they show "Contract source code verified" badges
- Check the contract balance and owner

### 2. Test Basic Functionality
Use `cast` to test your deployed contract:

```bash
# Check common pot balance
cast call <PHISH_STAKE_ADDRESS> "commonPot()" --rpc-url zircuit_testnet

# Check owner
cast call <PHISH_STAKE_ADDRESS> "owner()" --rpc-url zircuit_testnet

# Check USDC contract
cast call <PHISH_STAKE_ADDRESS> "usdcToken()" --rpc-url zircuit_testnet
```

### 3. Interact with the Contract

#### For Mock USDC (if deployed):
```bash
# Mint USDC to your address
cast send <MOCK_USDC_ADDRESS> "mint(address,uint256)" <YOUR_ADDRESS> 10000000000 \
  --rpc-url zircuit_testnet --private-key $PRIVATE_KEY

# Check USDC balance
cast call <MOCK_USDC_ADDRESS> "balanceOf(address)" <YOUR_ADDRESS> --rpc-url zircuit_testnet
```

#### Test Staking:
```bash
# Approve USDC spending
cast send <USDC_ADDRESS> "approve(address,uint256)" <PHISH_STAKE_ADDRESS> 1000000000 \
  --rpc-url zircuit_testnet --private-key $PRIVATE_KEY

# Stake USDC with a hash
cast send <PHISH_STAKE_ADDRESS> "stake(uint256,bytes32)" 1000000000 0x1234567890123456789012345678901234567890123456789012345678901234 \
  --rpc-url zircuit_testnet --private-key $PRIVATE_KEY
```

## Network Information

- **Network Name**: Zircuit Testnet
- **Chain ID**: 48899
- **RPC URL**: https://testnet.zircuit.com
- **Block Explorer**: https://explorer.testnet.zircuit.com/
- **Faucet**: https://faucet.testnet.zircuit.com/

## Troubleshooting

### Common Issues:

1. **"Insufficient ETH" Error**: Get more testnet ETH from the faucet
2. **"Invalid Private Key"**: Ensure your private key is correct and doesn't include "0x"
3. **"RPC Error"**: Check your internet connection and try again
4. **"Verification Failed"**: Try manual verification commands provided by the script

### Gas Estimation:
- Mock USDC Deployment: ~960,000 gas
- PhishStake Deployment: ~1,030,000 gas
- Total Cost: ~0.002 ETH (at 1 gwei)

### Getting Help:
- Check the [Zircuit Discord](https://discord.gg/zircuit) for community support
- Review the [Zircuit Documentation](https://docs.zircuit.com/)
- Check deployment logs for specific error messages

## Next Steps

After successful deployment:
1. Update your frontend/dApp with the new contract addresses
2. Test all functionality thoroughly on testnet
3. Consider deploying to Zircuit mainnet when ready
4. Set up monitoring for your contracts

## Security Notes

- **Never use mainnet private keys for testnet**
- **Always verify contract addresses before interacting**
- **Test thoroughly before mainnet deployment**
- **Keep your API keys secure** 