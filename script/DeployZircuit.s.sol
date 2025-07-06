// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "forge-std/Script.sol";
import "forge-std/console.sol";
import "../src/PhishStake.sol";

// Mock USDC for testnet deployment (if no real USDC is available)
contract MockUSDC {
    mapping(address => uint256) private _balances;
    mapping(address => mapping(address => uint256)) private _allowances;
    
    uint256 private _totalSupply;
    string public name = "Mock USDC";
    string public symbol = "USDC";
    uint8 public decimals = 6;
    
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
    
    function mint(address to, uint256 amount) external {
        _balances[to] += amount;
        _totalSupply += amount;
        emit Transfer(address(0), to, amount);
    }
    
    function totalSupply() external view returns (uint256) {
        return _totalSupply;
    }
    
    function balanceOf(address account) external view returns (uint256) {
        return _balances[account];
    }
    
    function transfer(address to, uint256 amount) external returns (bool) {
        require(_balances[msg.sender] >= amount, "Insufficient balance");
        _balances[msg.sender] -= amount;
        _balances[to] += amount;
        emit Transfer(msg.sender, to, amount);
        return true;
    }
    
    function allowance(address owner, address spender) external view returns (uint256) {
        return _allowances[owner][spender];
    }
    
    function approve(address spender, uint256 amount) external returns (bool) {
        _allowances[msg.sender][spender] = amount;
        emit Approval(msg.sender, spender, amount);
        return true;
    }
    
    function transferFrom(address from, address to, uint256 amount) external returns (bool) {
        require(_allowances[from][msg.sender] >= amount, "Insufficient allowance");
        require(_balances[from] >= amount, "Insufficient balance");
        
        _allowances[from][msg.sender] -= amount;
        _balances[from] -= amount;
        _balances[to] += amount;
        emit Transfer(from, to, amount);
        return true;
    }
}

contract DeployZircuitScript is Script {
    function run() external {
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
        address deployer = vm.addr(deployerPrivateKey);
        
        console.log("=== Zircuit Testnet Deployment ===");
        console.log("Deploying contracts with address:", deployer);
        console.log("Account balance:", deployer.balance / 1e18, "ETH");
        
        require(deployer.balance > 0.01 ether, "Insufficient ETH for deployment");
        
        vm.startBroadcast(deployerPrivateKey);
        
        // Check if USDC address is provided via environment variable
        address usdcAddress;
        try vm.envAddress("USDC_ADDRESS") returns (address addr) {
            usdcAddress = addr;
            console.log("Using existing USDC contract at:", usdcAddress);
        } catch {
            // Deploy Mock USDC if no address provided
            console.log("No USDC_ADDRESS provided, deploying Mock USDC...");
            MockUSDC mockUsdc = new MockUSDC();
            usdcAddress = address(mockUsdc);
            console.log("Mock USDC deployed at:", usdcAddress);
            
            // Mint initial USDC for testing
            mockUsdc.mint(deployer, 100000e6); // 100,000 USDC
            console.log("Minted 100,000 USDC to deployer");
        }
        
        // Deploy PhishStake contract
        PhishStake phishStake = new PhishStake(usdcAddress, deployer);
        console.log("PhishStake deployed at:", address(phishStake));
        
        // Get initial topup amount from environment (default 1000 USDC)
        uint256 initialTopup;
        try vm.envUint("INITIAL_TOPUP") returns (uint256 amount) {
            initialTopup = amount;
        } catch {
            initialTopup = 1000e6; // Default 1000 USDC
        }
        
        // Topup common pot if we have USDC
        if (initialTopup > 0) {
            // Check if we have enough USDC
            IERC20 usdc = IERC20(usdcAddress);
            uint256 balance = usdc.balanceOf(deployer);
            
            if (balance >= initialTopup) {
                usdc.approve(address(phishStake), initialTopup);
                phishStake.topup(initialTopup);
                console.log("Topped up common pot with", initialTopup / 1e6, "USDC");
            } else {
                console.log("Warning: Insufficient USDC balance for initial topup");
                console.log("USDC balance:", balance / 1e6, "Required:", initialTopup / 1e6);
            }
        }
        
        vm.stopBroadcast();
        
        console.log("");
        console.log("=== Deployment Summary ===");
        console.log("Network: Zircuit Testnet (Chain ID: 48899)");
        console.log("USDC Contract:", usdcAddress);
        console.log("PhishStake Contract:", address(phishStake));
        console.log("Owner:", deployer);
        console.log("Common Pot Balance:", phishStake.commonPot() / 1e6, "USDC");
        
        console.log("");
        console.log("=== Next Steps ===");
        console.log("1. Verify contracts on Zircuit explorer");
        console.log("2. Add these addresses to your frontend/scripts");
        console.log("3. Test staking functionality");
        
        console.log("");
        console.log("=== Verification Commands ===");
        console.log("# Verify PhishStake:");
        console.log("forge verify-contract --verifier-url https://explorer.testnet.zircuit.com/api/contractVerifyHardhat \\");
        console.log("  %s src/PhishStake.sol:PhishStake \\", address(phishStake));
        console.log("  --etherscan-api-key $ZIRCUIT_API_KEY \\");
        console.log("  --constructor-args $(cast abi-encode \"constructor(address,address)\" %s %s)", usdcAddress, deployer);
        
        if (usdcAddress != vm.envOr("USDC_ADDRESS", address(0))) {
            console.log("");
            console.log("# Verify Mock USDC:");
            console.log("forge verify-contract --verifier-url https://explorer.testnet.zircuit.com/api/contractVerifyHardhat \\");
            console.log("  %s script/DeployZircuit.s.sol:MockUSDC \\", usdcAddress);
            console.log("  --etherscan-api-key $ZIRCUIT_API_KEY");
        }
    }
} 