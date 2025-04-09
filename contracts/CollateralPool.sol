// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.20;

import "./LogiToken.sol";
// import "@openzeppelin/contracts/security/ReentrancyGuard.sol";

/**
 * @title 抵押池合约
 * @dev 用于管理平台的代币抵押、赎回和分成功能
 */
// contract CollateralPool is ReentrancyGuard {
contract CollateralPool {
    // Add token reference
    LogiToken public token;

    // Add platform reference
    address public platform;
    address public owner;

    // 分成比例常量
    uint256 public constant COURIER_RATIO = 800;  // 快递员直接分成比例 80%
    uint256 public constant BONUS_RATIO = 175;    // 奖金池比例 17.5%
    uint256 public constant OWNER_RATIO = 25;     // 平台所有者比例 2.5%
    uint256 public constant TOTAL_RATIO = 1000;   // 总比例基数

    // 奖金池
    uint256 private bonusPool;

    // 事件定义
    event Deposited(address indexed user, uint256 amount);
    event Redeemed(address indexed user, uint256 amount);
    event BonusAdded(uint256 amount, uint256 newTotal);
    event BonusDistributed(address indexed courier, uint256 amount, uint256 shareRatio);
    
    /**
     * @dev 仅允许平台合约调用的修饰器
     */
    modifier onlyPlatform() {
        require(msg.sender == address(platform), "Unauthorized");
        _;
    }

    /**
     * @dev 仅允许合约所有者调用的修饰器
     */
    modifier onlyOwner() {
        require(msg.sender == owner, "Only owner can call");
        _;
    }
    
    /**
     * @dev 构造函数
     * @param tokenAddress LogiToken合约地址
     * @param _platform 平台合约地址
     */
    constructor(address tokenAddress, address _platform) {
        token = LogiToken(tokenAddress);
        platform = _platform;
        owner = msg.sender;
    }

    /**
     * @dev 存款函数，用户可以存入ETH获取对应的LogiToken
     * 存款金额必须大于0，ETH自动转换为等额的LogiToken
     */
    function deposit() external payable {
        require(msg.value > 0, "Invalid amount");
        token.mint(msg.sender, msg.value);
        emit Deposited(msg.sender, msg.value);
    }

    /**
     * @dev 赎回函数，允许用户销毁LogiToken并获取对应的ETH
     * @param amount 要赎回的代币数量
     */
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

    /**
     * @dev 结算订单并分配收益
     * @param sender 订单的发送方地址
     * @param courier 订单的快递员地址
     * @param amount 订单金额
     *
     * 按照预设比例将金额分配给：
     * 1. 快递员直接获得的部分 (80%)
     * 2. 奖金池部分 (17.5%)
     * 3. 平台所有者部分 (2.5%)
     */
    function settle(address sender, address courier, uint256 amount) external onlyPlatform {
        token.freeToken(sender, amount);
        uint256 token_courier = (amount * COURIER_RATIO) / TOTAL_RATIO;
        uint256 token_bonus = (amount * BONUS_RATIO) / TOTAL_RATIO;
        uint256 token_owner = (amount * OWNER_RATIO) / TOTAL_RATIO;

        // 转给快递员直接收益部分
        token.transferFrom(sender, courier, token_courier);
        
        // 转给owner部分
        token.transferFrom(sender, owner, token_owner);
        
        // 加入奖金池部分
        token.transferFrom(sender, address(this), token_bonus);
        bonusPool += token_bonus;
        
        emit BonusAdded(token_bonus, bonusPool);
    }

    /**
     * @dev 锁定用户的代币作为订单抵押
     * @param user 要锁定代币的用户地址
     * @param amount 要锁定的代币数量
     */
    function lockToken(address user, uint256 amount) external onlyPlatform {
        token.lockToken(user, amount);
    }

    /**
     * @dev 释放用户的已锁定代币
     * @param user 要释放代币的用户地址
     * @param amount 要释放的代币数量
     */
    function freeToken(address user, uint256 amount) external onlyPlatform {
        token.freeToken(user, amount);
    }

    /**
     * @dev 获取当前奖金池金额
     * @return 奖金池中的代币数量
     */
    function getBonusPool() external view returns (uint256) {
        return bonusPool;
    }
    
    /**
     * @dev 向快递员分发奖金
     * @param courier 快递员地址
     * @param shareRatio 分成比例（18位精度）
     *
     * 根据计算出的比例，从奖金池中分配代币给快递员
     * 此函数只能由平台合约调用，确保分配公平性
     */
    function distributeBonusTo(address courier, uint256 shareRatio) external onlyPlatform returns (uint256) {
        require(courier != address(0), "Invalid courier address");
        require(bonusPool > 0, "Bonus pool is empty");
        
        // 计算快递员应得奖金，使用18位精度
        uint256 courierBonus = (bonusPool * shareRatio) / 1e18;
        
        // 确保有奖金可分
        if (courierBonus > 0) {
            // 从奖金池中减去
            bonusPool -= courierBonus;
            
            // 转账给快递员
            token.transfer(courier, courierBonus);
            
            emit BonusDistributed(courier, courierBonus, shareRatio);
        }

        return courierBonus;
    }
    
    /**
     * @dev 允许所有者提取未分配的奖金池余额
     * 此函数用于分润周期结束后，处理奖金池中剩余的代币
     * 只有合约所有者可以调用此函数
     */
    function withdrawRemainingBonus() external onlyOwner {
        require(bonusPool > 0, "No bonus to withdraw");
        
        uint256 amountToWithdraw = bonusPool;
        bonusPool = 0;
        
        token.transfer(owner, amountToWithdraw);
    }
}
