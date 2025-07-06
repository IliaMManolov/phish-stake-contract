// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import {Script, console} from "forge-std/Script.sol";
import {PhishStake} from "../src/PhishStake.sol";
import {IERC20} from "forge-std/interfaces/IERC20.sol";

contract InteractZircuit is Script {
    // Deployed contract addresses
    address constant USDC_ADDRESS = 0xDB03E54A4DB2Ecaa40B554110E28091f3361D251;
    address constant PHISH_STAKE_ADDRESS = 0x5dC86EA7b0fdf8940Fc73C56641c77FBa5227c72;
    
    function run() external {
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
        address deployer = vm.addr(deployerPrivateKey);
        
        PhishStake phishStake = PhishStake(PHISH_STAKE_ADDRESS);
        IERC20 usdc = IERC20(USDC_ADDRESS);
        
        vm.startBroadcast(deployerPrivateKey);
        
        console.log("=== PhishStake Contract Interaction ===");
        console.log("Interacting with address:", deployer);
        console.log("USDC Balance:", usdc.balanceOf(deployer));
        console.log("Common Pot Balance:", phishStake.commonPot());
        
        // Test 1: Approve USDC spending
        console.log("\n1. Approving USDC spending...");
        usdc.approve(PHISH_STAKE_ADDRESS, 50000000); // 50 USDC
        console.log("Approved 50 USDC for staking");
        
        // Test 2: Stake with different hashes
        console.log("\n2. Testing staking functionality...");
        
        bytes32 hash1 = keccak256("phishing_site_abc123");
        bytes32 hash2 = keccak256("malicious_url_def456");
        
        phishStake.stake(hash1, 10000000); // 10 USDC
        console.log("Staked 10 USDC for hash1");
        
        phishStake.stake(hash2, 15000000); // 15 USDC
        console.log("Staked 15 USDC for hash2");
        
        // Test 3: Add more to existing stake
        phishStake.stake(hash1, 5000000); // 5 more USDC
        console.log("Added 5 more USDC to hash1");
        
        // Test 4: Check stake amounts
        console.log("\n3. Checking stake amounts...");
        console.log("Your stake for hash1:", phishStake.getStake(deployer, hash1));
        console.log("Your stake for hash2:", phishStake.getStake(deployer, hash2));
        
        // Test 5: Check updated balances
        console.log("\n4. Final balances...");
        console.log("Your USDC Balance:", usdc.balanceOf(deployer));
        console.log("Common Pot Balance:", phishStake.commonPot());
        console.log("Contract USDC Balance:", usdc.balanceOf(PHISH_STAKE_ADDRESS));
        
        vm.stopBroadcast();
        
        console.log("\n=== Interaction Complete ===");
        console.log("You can view transactions on: https://explorer.testnet.zircuit.com");
    }
} 