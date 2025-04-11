// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts-upgradeable/token/ERC20/ERC20Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "./CollateralPool.sol";

contract LogiToken is ERC20Upgradeable, OwnableUpgradeable {
    // 状态变量
    CollateralPool private collateralPool;
    bool private transferEnabled;
    bool private paused;
    
    // 映射
    mapping(address => uint256) private lockedBalances;  // 抵押状态代币
    mapping(address => uint256) private freeBalances;  // 自由状态代币
    // mapping(address => uint256) private _redeemAllowance;  // 可赎回的代币

    // 事件
    event Paused(address indexed owner);
    event Unpaused(address indexed owner);
    event TokensLocked(address indexed user, uint256 amount);
    event TokensFreed(address indexed user, uint256 amount);
    event TokensBurned(address indexed user, uint256 amount);
    event TokensTransferred(address indexed from, address indexed to, uint256 amount);

    // 修饰器
    modifier onlyCollateralPool() {
        require(msg.sender == address(collateralPool), "Unauthorized");
        _;
    }
    
    modifier whenNotPaused() {
        require(!paused, "Contract is paused");
        _;
    }
    
    // 初始化函数（用于可升级合约）
    function initialize(string memory name, string memory symbol) initializer public {
        __ERC20_init(name, symbol);
        __Ownable_init(msg.sender);
        transferEnabled = false;
    }
    
    // =================== 核心业务功能 ===================
    
    // 铸造函数（仅抵押池可调用）
    function mint(address to, uint256 amount) external onlyCollateralPool {
        _mint(to, amount);
        freeBalances[to] += amount;
    }

    // 销毁授权函数(需要在销毁函数之前调用)
    function approveRedeem(address user) external onlyCollateralPool {
        _approve(user, address(collateralPool), freeBalances[user]);
    }

    function approveTransaction(address user, uint256 amount) external onlyCollateralPool {
        require(freeBalances[user] >= amount, "Insufficient free tokens");
        _approve(user, address(collateralPool), amount);
    }

    // 销毁函数（仅抵押池可调用）
    function burnFrom(address account, uint256 amount) external onlyCollateralPool {
        require(freeBalances[account] >= amount, "Insufficient free tokens");
        freeBalances[account] -= amount;
        _burn(account, amount);
        emit TokensBurned(account, amount);
    }

    // 代币锁定/解锁相关
    function lockToken(address user, uint256 amount) external onlyCollateralPool whenNotPaused {
        require(freeBalances[user] >= amount, "Insufficient free tokens");
        lockedBalances[user] += amount;
        freeBalances[user] -= amount;
        emit TokensLocked(user, amount);
    }

    function freeToken(address user, uint256 amount) external onlyCollateralPool {
        require(lockedBalances[user] >= amount, "Insufficient locked tokens");
        lockedBalances[user] -= amount;
        freeBalances[user] += amount;
        emit TokensFreed(user, amount);
    }

    // 安全控制
    function pause() external onlyOwner {
        paused = true;
        emit Paused(msg.sender);
    }

    function unpause() external onlyOwner {
        paused = false;
        emit Unpaused(msg.sender);
    }

    function transfer(address to, uint256 value) public override onlyCollateralPool returns (bool) {
        bool res = super.transfer(to, value);
        freeBalances[msg.sender] -= value;
        freeBalances[to] += value;
        emit TokensTransferred(msg.sender, to, value);
        return res;
    }

    function transferFrom(address from, address to, uint256 value) public override onlyCollateralPool returns (bool) {
        bool res =  super.transferFrom(from, to, value);
        freeBalances[from] -= value;
        freeBalances[to] += value;
        emit TokensTransferred(from, to, value);
        return res;
    }

    // =================== Setter函数 ===================
    function setCollateralPool(address _pool) external onlyOwner {
        collateralPool = CollateralPool(_pool);
    }

    function transferTokenOwnership(address _pool) external onlyOwner {
        require(_pool != address(0), "invalid address");
        _transferOwnership(_pool);
    }

    function setTransferEnabled(bool _enabled) external onlyOwner {
        transferEnabled = _enabled;
    }

    // =================== Getter函数 ===================
    function getCollateralPool() external view returns (address) {
        return address(collateralPool);
    }

    function isTransferEnabled() external view returns (bool) {
        return transferEnabled;
    }

    function isPaused() external view returns (bool) {
        return paused;
    }

    function getLockedBalance(address user) external view returns(uint256) {
        return lockedBalances[user];
    }

    function getFreeBalance(address user) external view returns(uint256) {
        return freeBalances[user];
    }
}