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
}
