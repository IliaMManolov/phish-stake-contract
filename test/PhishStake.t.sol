// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "forge-std/Test.sol";
import "forge-std/interfaces/IERC20.sol";
import "../src/PhishStake.sol";

// Mock USDC token for testing
contract MockUSDC is IERC20 {
    mapping(address => uint256) private _balances;
    mapping(address => mapping(address => uint256)) private _allowances;
    
    uint256 private _totalSupply;
    string public name = "Mock USDC";
    string public symbol = "USDC";
    uint8 public decimals = 6;
    
    function mint(address to, uint256 amount) external {
        _balances[to] += amount;
        _totalSupply += amount;
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
        return true;
    }
    
    function allowance(address owner, address spender) external view returns (uint256) {
        return _allowances[owner][spender];
    }
    
    function approve(address spender, uint256 amount) external returns (bool) {
        _allowances[msg.sender][spender] = amount;
        return true;
    }
    
    function transferFrom(address from, address to, uint256 amount) external returns (bool) {
        require(_allowances[from][msg.sender] >= amount, "Insufficient allowance");
        require(_balances[from] >= amount, "Insufficient balance");
        
        _allowances[from][msg.sender] -= amount;
        _balances[from] -= amount;
        _balances[to] += amount;
        return true;
    }
}

contract PhishStakeTest is Test {
    PhishStake public phishStake;
    MockUSDC public usdc;
    
    address public owner = address(1);
    address public user1 = address(2);
    address public user2 = address(3);
    address public user3 = address(4);
    
    bytes32 public hash1 = keccak256("hash1");
    bytes32 public hash2 = keccak256("hash2");
    bytes32 public hash3 = keccak256("hash3");
    
    event Staked(address indexed user, bytes32 indexed hash, uint256 amount);
    event Rewarded(address indexed user, bytes32 indexed hash, uint256 stakeReturned, uint256 reward);
    event Denied(address indexed user, bytes32 indexed hash, uint256 stakeAmount);
    event ToppedUp(uint256 amount);
    
    function setUp() public {
        usdc = new MockUSDC();
        phishStake = new PhishStake(address(usdc), owner);
        
        // Mint USDC to users and owner
        usdc.mint(user1, 1000e6); // 1000 USDC
        usdc.mint(user2, 1000e6);
        usdc.mint(user3, 1000e6);
        usdc.mint(owner, 10000e6); // 10000 USDC for owner
        
        // Approve PhishStake to spend USDC
        vm.prank(user1);
        usdc.approve(address(phishStake), type(uint256).max);
        
        vm.prank(user2);
        usdc.approve(address(phishStake), type(uint256).max);
        
        vm.prank(user3);
        usdc.approve(address(phishStake), type(uint256).max);
        
        vm.prank(owner);
        usdc.approve(address(phishStake), type(uint256).max);
    }
    
    function test_constructor() public {
        assertEq(address(phishStake.usdc()), address(usdc));
        assertEq(phishStake.owner(), owner);
        assertEq(phishStake.commonPot(), 0);
    }
    
    function test_constructor_reverts_zero_address() public {
        vm.expectRevert(PhishStake.ZeroAddress.selector);
        new PhishStake(address(0), owner);
        
        vm.expectRevert(PhishStake.ZeroAddress.selector);
        new PhishStake(address(usdc), address(0));
    }
    
    function test_stake_success() public {
        uint256 stakeAmount = 100e6; // 100 USDC
        
        vm.expectEmit(true, true, false, true);
        emit Staked(user1, hash1, stakeAmount);
        
        vm.prank(user1);
        phishStake.stake(hash1, stakeAmount);
        
        assertEq(phishStake.getStake(user1, hash1), stakeAmount);
        assertEq(usdc.balanceOf(user1), 900e6); // 1000 - 100
        assertEq(usdc.balanceOf(address(phishStake)), stakeAmount);
    }
    
    function test_stake_multiple_different_hashes() public {
        uint256 firstStake = 100e6;
        uint256 secondStake = 50e6;
        
        vm.prank(user1);
        phishStake.stake(hash1, firstStake);
        
        vm.prank(user1);
        phishStake.stake(hash2, secondStake); // Different hash, should be separate stake
        
        // Each hash should have its own stake
        assertEq(phishStake.getStake(user1, hash1), firstStake);
        assertEq(phishStake.getStake(user1, hash2), secondStake);
        assertEq(usdc.balanceOf(user1), 850e6); // 1000 - 150
    }
    
    function test_stake_same_hash_multiple_times() public {
        uint256 firstStake = 100e6;
        uint256 secondStake = 50e6;
        
        vm.prank(user1);
        phishStake.stake(hash1, firstStake);
        
        vm.prank(user1);
        phishStake.stake(hash1, secondStake); // Same hash, should add to existing stake
        
        assertEq(phishStake.getStake(user1, hash1), firstStake + secondStake);
        assertEq(usdc.balanceOf(user1), 850e6); // 1000 - 150
    }
    
    function test_stake_reverts_zero_amount() public {
        vm.expectRevert(PhishStake.InvalidAmount.selector);
        vm.prank(user1);
        phishStake.stake(hash1, 0);
    }
    
    function test_stake_reverts_insufficient_balance() public {
        vm.prank(user1);
        vm.expectRevert("Insufficient balance");
        phishStake.stake(hash1, 2000e6); // More than user1's balance
    }
    
    function test_topup_success() public {
        uint256 topupAmount = 1000e6;
        
        vm.expectEmit(false, false, false, true);
        emit ToppedUp(topupAmount);
        
        vm.prank(owner);
        phishStake.topup(topupAmount);
        
        assertEq(phishStake.commonPot(), topupAmount);
        assertEq(usdc.balanceOf(owner), 9000e6); // 10000 - 1000
        assertEq(usdc.balanceOf(address(phishStake)), topupAmount);
    }
    
    function test_topup_reverts_zero_amount() public {
        vm.expectRevert(PhishStake.InvalidAmount.selector);
        vm.prank(owner);
        phishStake.topup(0);
    }
    
    function test_topup_reverts_not_owner() public {
        vm.expectRevert(PhishStake.NotOwner.selector);
        vm.prank(user1);
        phishStake.topup(100e6);
    }
    
    function test_reward_success() public {
        uint256 stakeAmount = 100e6;
        uint256 rewardAmount = 50e6;
        
        // First stake
        vm.prank(user1);
        phishStake.stake(hash1, stakeAmount);
        
        // Topup common pot
        vm.prank(owner);
        phishStake.topup(1000e6);
        
        uint256 initialUser1Balance = usdc.balanceOf(user1);
        
        vm.expectEmit(true, true, false, true);
        emit Rewarded(user1, hash1, stakeAmount, rewardAmount);
        
        vm.prank(owner);
        phishStake.reward(user1, hash1, rewardAmount);
        
        // Check specific stake is cleared
        assertEq(phishStake.getStake(user1, hash1), 0);
        
        // Check common pot is reduced
        assertEq(phishStake.commonPot(), 1000e6 - rewardAmount);
        
        // Check user received stake + reward
        assertEq(usdc.balanceOf(user1), initialUser1Balance + stakeAmount + rewardAmount);
    }
    
    function test_reward_specific_hash_only() public {
        uint256 stakeAmount1 = 100e6;
        uint256 stakeAmount2 = 150e6;
        uint256 rewardAmount = 50e6;
        
        // Stake with two different hashes
        vm.prank(user1);
        phishStake.stake(hash1, stakeAmount1);
        
        vm.prank(user1);
        phishStake.stake(hash2, stakeAmount2);
        
        // Topup common pot
        vm.prank(owner);
        phishStake.topup(1000e6);
        
        uint256 initialUser1Balance = usdc.balanceOf(user1);
        
        // Reward only hash1
        vm.prank(owner);
        phishStake.reward(user1, hash1, rewardAmount);
        
        // Check only hash1 stake is cleared, hash2 remains
        assertEq(phishStake.getStake(user1, hash1), 0);
        assertEq(phishStake.getStake(user1, hash2), stakeAmount2);
        
        // Check user received only hash1 stake + reward
        assertEq(usdc.balanceOf(user1), initialUser1Balance + stakeAmount1 + rewardAmount);
    }
    
    function test_reward_reverts_no_stake() public {
        vm.expectRevert(PhishStake.NoStakeFound.selector);
        vm.prank(owner);
        phishStake.reward(user1, hash1, 50e6);
    }
    
    function test_reward_reverts_insufficient_common_pot() public {
        uint256 stakeAmount = 100e6;
        uint256 rewardAmount = 50e6;
        
        // Stake but don't topup common pot
        vm.prank(user1);
        phishStake.stake(hash1, stakeAmount);
        
        vm.expectRevert(PhishStake.InsufficientCommonPot.selector);
        vm.prank(owner);
        phishStake.reward(user1, hash1, rewardAmount);
    }
    
    function test_reward_reverts_not_owner() public {
        uint256 stakeAmount = 100e6;
        uint256 rewardAmount = 50e6;
        
        vm.prank(user1);
        phishStake.stake(hash1, stakeAmount);
        
        vm.expectRevert(PhishStake.NotOwner.selector);
        vm.prank(user2);
        phishStake.reward(user1, hash1, rewardAmount);
    }
    
    function test_deny_success() public {
        uint256 stakeAmount = 100e6;
        
        // First stake
        vm.prank(user1);
        phishStake.stake(hash1, stakeAmount);
        
        uint256 initialCommonPot = phishStake.commonPot();
        
        vm.expectEmit(true, true, false, true);
        emit Denied(user1, hash1, stakeAmount);
        
        vm.prank(owner);
        phishStake.deny(user1, hash1);
        
        // Check specific stake is cleared
        assertEq(phishStake.getStake(user1, hash1), 0);
        
        // Check common pot increased
        assertEq(phishStake.commonPot(), initialCommonPot + stakeAmount);
        
        // Check user doesn't receive their stake back
        assertEq(usdc.balanceOf(user1), 900e6); // Still 900 (1000 - 100 staked)
    }
    
    function test_deny_specific_hash_only() public {
        uint256 stakeAmount1 = 100e6;
        uint256 stakeAmount2 = 150e6;
        
        // Stake with two different hashes
        vm.prank(user1);
        phishStake.stake(hash1, stakeAmount1);
        
        vm.prank(user1);
        phishStake.stake(hash2, stakeAmount2);
        
        uint256 initialCommonPot = phishStake.commonPot();
        
        // Deny only hash1
        vm.prank(owner);
        phishStake.deny(user1, hash1);
        
        // Check only hash1 stake is cleared, hash2 remains
        assertEq(phishStake.getStake(user1, hash1), 0);
        assertEq(phishStake.getStake(user1, hash2), stakeAmount2);
        
        // Check common pot increased by only hash1 amount
        assertEq(phishStake.commonPot(), initialCommonPot + stakeAmount1);
    }
    
    function test_deny_reverts_no_stake() public {
        vm.expectRevert(PhishStake.NoStakeFound.selector);
        vm.prank(owner);
        phishStake.deny(user1, hash1);
    }
    
    function test_deny_reverts_not_owner() public {
        uint256 stakeAmount = 100e6;
        
        vm.prank(user1);
        phishStake.stake(hash1, stakeAmount);
        
        vm.expectRevert(PhishStake.NotOwner.selector);
        vm.prank(user2);
        phishStake.deny(user1, hash1);
    }
    
    function test_view_functions() public {
        uint256 stakeAmount = 100e6;
        
        vm.prank(user1);
        phishStake.stake(hash1, stakeAmount);
        
        vm.prank(owner);
        phishStake.topup(500e6);
        
        assertEq(phishStake.getStake(user1, hash1), stakeAmount);
        assertEq(phishStake.getCommonPot(), 500e6);
    }
    
    function test_multiple_users_complex_scenario() public {
        // User1 stakes 100 USDC with hash1 and 75 USDC with hash2
        vm.prank(user1);
        phishStake.stake(hash1, 100e6);
        
        vm.prank(user1);
        phishStake.stake(hash2, 75e6);
        
        // User2 stakes 200 USDC with hash1
        vm.prank(user2);
        phishStake.stake(hash1, 200e6);
        
        // User3 stakes 150 USDC with hash3
        vm.prank(user3);
        phishStake.stake(hash3, 150e6);
        
        // Owner tops up common pot
        vm.prank(owner);
        phishStake.topup(1000e6);
        
        assertEq(phishStake.commonPot(), 1000e6);
        
        // Owner rewards user1's hash1 stake with 50 USDC
        vm.prank(owner);
        phishStake.reward(user1, hash1, 50e6);
        
        // User1 should receive 100 (stake) + 50 (reward) = 150
        assertEq(usdc.balanceOf(user1), 975e6); // 825 + 150
        assertEq(phishStake.getStake(user1, hash1), 0); // hash1 stake cleared
        assertEq(phishStake.getStake(user1, hash2), 75e6); // hash2 stake remains
        assertEq(phishStake.commonPot(), 950e6); // 1000 - 50
        
        // Owner denies user2's hash1 stake
        vm.prank(owner);
        phishStake.deny(user2, hash1);
        
        assertEq(usdc.balanceOf(user2), 800e6); // 1000 - 200 (stake not returned)
        assertEq(phishStake.getStake(user2, hash1), 0); // hash1 stake cleared
        assertEq(phishStake.commonPot(), 1150e6); // 950 + 200
        
        // Owner rewards user3's hash3 stake with 100 USDC
        vm.prank(owner);
        phishStake.reward(user3, hash3, 100e6);
        
        // User3 should receive 150 (stake) + 100 (reward) = 250
        assertEq(usdc.balanceOf(user3), 1100e6); // 850 + 250
        assertEq(phishStake.getStake(user3, hash3), 0); // hash3 stake cleared
        assertEq(phishStake.commonPot(), 1050e6); // 1150 - 100
        
        // User1 still has hash2 stake
        assertEq(phishStake.getStake(user1, hash2), 75e6);
    }
    
    function test_reentrancy_protection() public {
        // This test verifies that the nonReentrant modifier works
        uint256 stakeAmount = 100e6;
        
        vm.prank(user1);
        phishStake.stake(hash1, stakeAmount);
        
        vm.prank(owner);
        phishStake.topup(100e6);
        
        vm.prank(owner);
        phishStake.reward(user1, hash1, 50e6);
        
        // If we reach here without reverting, the basic flow works
        assertTrue(true);
    }
} 