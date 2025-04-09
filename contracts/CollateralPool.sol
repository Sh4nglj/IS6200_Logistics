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

    uint256 public constant COURIER_RATIO = 800;
    uint256 public constant PLATFORM_RATIO = 175;
    uint256 public constant OWNER_RATIO = 25;
    uint256 public constant TOTAL_RATIO = 1000;

    event Deposited(address indexed user, uint256 amount);
    event Redeemed(address indexed user, uint256 amount);
    event Settled(address indexed sender, address indexed courier, uint256 amount);
    event DebugInfo(string str, address indexed user);
    
    // Add modifier
    modifier onlyPlatform() {
        require(msg.sender == platform, "Unauthorized");
        _;
    }
    
    constructor(address tokenAddress, address _platform, address _owner) {
        token = LogiToken(tokenAddress);
        platform = _platform;
        owner = _owner;
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

    // 结算合约阶段
    function settle(address sender, address courier, uint256 amount) external onlyPlatform {
        emit DebugInfo("Pool owner", owner);
        
        token.freeToken(sender, amount);
        uint256 token_courier = (amount) * COURIER_RATIO / TOTAL_RATIO;
        uint256 token_platform = (amount) * PLATFORM_RATIO / TOTAL_RATIO;
        uint256 token_owner = (amount) * OWNER_RATIO / TOTAL_RATIO;

        token.approveTransaction(sender, amount);
        token.transferFrom(sender, courier, token_courier);
        token.transferFrom(sender, owner, token_platform);
        token.transferFrom(sender, address(this), token_owner);
    }

    // 用于platform中业务流程的调用
    function lockToken(address user, uint256 amount) external onlyPlatform {  // 不用onlyPlatform, 
        token.lockToken(user, amount);
    }

    function freeToken(address user, uint256 amount) external onlyPlatform { // onlyPlatform
        token.freeToken(user, amount);
    }
}
