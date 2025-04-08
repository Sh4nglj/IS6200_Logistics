// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.20;

import "./LogiToken.sol";
// import "@openzeppelin/contracts/security/ReentrancyGuard.sol";

// contract CollateralPool is ReentrancyGuard {
contract CollateralPool {
    // Add token reference
    LogiToken public token;
    // Add platform reference
    address public platform;
    address private owner;

    event Deposited(address indexed user, uint256 amount);
    event Redeemed(address indexed user, uint256 amount);
    
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
        token.mint(msg.sender, msg.value);
        emit Deposited(msg.sender, msg.value);
    }

    function redeem(uint256 amount) external {
        // 获取授权
        token.approveRedeem(msg.sender);

        // 调用代币合约的销毁函数
        token.burnFrom(msg.sender, amount);
        
        // 执行ETH返还
        (bool success, ) = msg.sender.call{value: amount}("");
        require(success, "Transfer failed");

        emit Redeemed(msg.sender, amount);
    }

    function settle(address sender, address courier, uint256 amount) external onlyPlatform{
        token.freeToken(sender, amount);
        uint256 token_courier = (amount) * 800 / 1000;
        uint256 token_platform = (amount) * 175 / 1000;
        uint256 token_owner = (amount) * 25 / 1000;

        token.transferFrom(sender, courier, token_courier);
        token.transferFrom(sender, owner, token_platform);
        token.transferFrom(sender, address(this), token_owner);
    }

    // 用于platform中业务流程的调用
    function lockToken(address user, uint256 amount) external {  // 不用onlyPlatform, 
        token.lockToken(user, amount);
    }

    function freeToken(address user, uint256 amount) external   { // onlyPlatform
        token.freeToken(user, amount);
    }
}
