// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "forge-std/interfaces/IERC20.sol";

/**
 * @title PhishStake
 * @dev A staking contract where users can stake USDC with a hash, and admin can reward or deny stakes
 */
contract PhishStake {
    IERC20 public immutable usdc;
    address public owner;
    
    // Reentrancy protection
    bool private _locked;
    
    // Common pot balance
    uint256 public commonPot;
    
    // User stakes mapping: user address -> hash -> stake amount
    mapping(address => mapping(bytes32 => uint256)) public stakes;
    
    // Events
    event Staked(address indexed user, bytes32 indexed hash, uint256 amount);
    event Rewarded(address indexed user, bytes32 indexed hash, uint256 stakeReturned, uint256 reward);
    event Denied(address indexed user, bytes32 indexed hash, uint256 stakeAmount);
    event ToppedUp(uint256 amount);
    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);
    
    // Errors
    error InsufficientStake();
    error InsufficientCommonPot();
    error TransferFailed();
    error NoStakeFound();
    error InvalidAmount();
    error NotOwner();
    error ReentrancyGuard();
    error ZeroAddress();
    
    // Modifiers
    modifier onlyOwner() {
        if (msg.sender != owner) revert NotOwner();
        _;
    }
    
    modifier nonReentrant() {
        if (_locked) revert ReentrancyGuard();
        _locked = true;
        _;
        _locked = false;
    }
    
    /**
     * @dev Constructor
     * @param _usdc Address of the USDC token contract
     * @param _initialOwner Address of the initial owner/admin
     */
    constructor(address _usdc, address _initialOwner) {
        if (_usdc == address(0)) revert ZeroAddress();
        if (_initialOwner == address(0)) revert ZeroAddress();
        
        usdc = IERC20(_usdc);
        owner = _initialOwner;
        emit OwnershipTransferred(address(0), _initialOwner);
    }
    
    /**
     * @dev Allows anyone to stake USDC with a hash
     * @param hash The hash associated with the stake
     * @param amount The amount of USDC to stake
     */
    function stake(bytes32 hash, uint256 amount) external nonReentrant {
        if (amount == 0) revert InvalidAmount();
        
        // Transfer USDC from user to contract
        if (!usdc.transferFrom(msg.sender, address(this), amount)) {
            revert TransferFailed();
        }
        
        // Update user's stake for this specific hash
        stakes[msg.sender][hash] += amount;
        
        emit Staked(msg.sender, hash, amount);
    }
    
    /**
     * @dev Admin function to reward a user, returning their stake plus a reward
     * @param user The address of the user to reward
     * @param hash The hash associated with the stake to reward
     * @param rewardAmount The reward amount from the common pot
     */
    function reward(address user, bytes32 hash, uint256 rewardAmount) external onlyOwner nonReentrant {
        uint256 userStake = stakes[user][hash];
        if (userStake == 0) revert NoStakeFound();
        if (rewardAmount > commonPot) revert InsufficientCommonPot();
        
        // Clear user's stake for this specific hash
        stakes[user][hash] = 0;
        
        // Reduce common pot by reward amount
        commonPot -= rewardAmount;
        
        // Transfer stake + reward to user
        uint256 totalPayout = userStake + rewardAmount;
        if (!usdc.transfer(user, totalPayout)) {
            revert TransferFailed();
        }
        
        emit Rewarded(user, hash, userStake, rewardAmount);
    }
    
    /**
     * @dev Admin function to deny a user's stake, adding it to the common pot
     * @param user The address of the user to deny
     * @param hash The hash associated with the stake to deny
     */
    function deny(address user, bytes32 hash) external onlyOwner nonReentrant {
        uint256 userStake = stakes[user][hash];
        if (userStake == 0) revert NoStakeFound();
        
        // Clear user's stake for this specific hash
        stakes[user][hash] = 0;
        
        // Add stake to common pot
        commonPot += userStake;
        
        emit Denied(user, hash, userStake);
    }
    
    /**
     * @dev Admin function to top up the common pot with USDC
     * @param amount The amount of USDC to add to the common pot
     */
    function topup(uint256 amount) external onlyOwner nonReentrant {
        if (amount == 0) revert InvalidAmount();
        
        // Transfer USDC from admin to contract
        if (!usdc.transferFrom(msg.sender, address(this), amount)) {
            revert TransferFailed();
        }
        
        // Add to common pot
        commonPot += amount;
        
        emit ToppedUp(amount);
    }
    
    /**
     * @dev View function to get user's stake amount for a specific hash
     * @param user The address of the user
     * @param hash The hash associated with the stake
     * @return The stake amount
     */
    function getStake(address user, bytes32 hash) external view returns (uint256) {
        return stakes[user][hash];
    }
    
    /**
     * @dev View function to get the common pot balance
     * @return The common pot balance
     */
    function getCommonPot() external view returns (uint256) {
        return commonPot;
    }
} 