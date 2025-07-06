// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "forge-std/Script.sol";
import "forge-std/console.sol";
import "../src/PhishStake.sol";

// Mock USDC token for deployment
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

contract DeployFlowScript is Script {
    function run() external {
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
        address deployer = vm.addr(deployerPrivateKey);
        
        console.log("Deploying contracts to Flow testnet with address:", deployer);
        console.log("Account balance:", deployer.balance);
        
        vm.startBroadcast(deployerPrivateKey);
        
        // Deploy Mock USDC
        MockUSDC usdc = new MockUSDC();
        console.log("Mock USDC deployed at:", address(usdc));
        
        // Deploy PhishStake contract
        PhishStake phishStake = new PhishStake(address(usdc), deployer);
        console.log("PhishStake deployed at:", address(phishStake));
        
        // Mint some initial USDC for testing
        usdc.mint(deployer, 10000e6); // 10,000 USDC
        console.log("Minted 10,000 USDC to deployer");
        
        // Topup the common pot with 1,000 USDC
        usdc.approve(address(phishStake), 1000e6);
        phishStake.topup(1000e6);
        console.log("Topped up common pot with 1,000 USDC");
        
        vm.stopBroadcast();
        
        console.log("=== Flow Testnet Deployment Summary ===");
        console.log("Mock USDC:", address(usdc));
        console.log("PhishStake:", address(phishStake));
        console.log("Owner:", deployer);
        console.log("Common Pot Balance:", phishStake.commonPot() / 1e6, "USDC");
        console.log("Owner USDC Balance:", usdc.balanceOf(deployer) / 1e6, "USDC");
        console.log("Block Explorer:", "https://evm-testnet.flowscan.io");
    }
} 