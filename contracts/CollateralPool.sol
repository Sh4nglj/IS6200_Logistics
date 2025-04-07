// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.20;

import "./LogiToken.sol";

contract CollateralPool {
    // Add token reference
    LogiToken public token;
    // Add platform reference
    address public platform;
    // Add these mappings
    mapping(address => uint256) public freeCollateral;
    mapping(address => uint256) public lockedCollateral;

    event Deposited(address indexed user, uint256 amount);
    
    // Add modifier
    modifier onlyPlatform() {
        require(msg.sender == address(platform), "Unauthorized");
        _;
    }
    
    constructor(address tokenAddress, address _platform) {
        token = LogiToken(tokenAddress);
        platform = _platform;
    }

    // Modified deposit function
    function deposit() external payable {
        require(msg.value > 0, "Invalid amount");
        freeCollateral[msg.sender] += msg.value;
        token.mint(msg.sender, msg.value);
        emit Deposited(msg.sender, msg.value);
    }

    // Add collateral locking functions
    function lockCollateral(address courier, uint256 amount) external onlyPlatform {
        require(freeCollateral[courier] >= amount, "Insufficient free collateral");
        freeCollateral[courier] -= amount;
        lockedCollateral[courier] += amount;
    }

    function unlockCollateral(address courier, uint256 amount) external onlyPlatform {
        require(lockedCollateral[courier] >= amount, "Insufficient locked collateral");
        lockedCollateral[courier] -= amount;
        freeCollateral[courier] += amount;
    }

    // Add view function
    function getFreeCollateral(address user) external view returns(uint256) {
        return freeCollateral[user];
    }
}