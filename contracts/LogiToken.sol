// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts-upgradeable/token/ERC20/ERC20Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "./CollateralPool.sol";

contract LogiToken is ERC20Upgradeable, OwnableUpgradeable {
    CollateralPool public collateralPool;
    
    bool public transferEnabled;
    
    // 初始化函数（用于可升级合约）
    function initialize(string memory name, string memory symbol) initializer public {
        __ERC20_init(name, symbol);
        __Ownable_init(msg.sender);
        transferEnabled = false;
    }

    function setCollateralPool(address _pool) external onlyOwner {
        collateralPool = CollateralPool(_pool);
    }

    // 禁用转账功能（待升级开启）
    function _update(address from, address to, uint256 value) internal override {
        if(from != address(0)) {
            uint256 available = collateralPool.freeCollateral(from);
            require(available >= value, "Transfer exceeds available collateral");
        }
        super._update(from, to, value);
    }

    // 铸造函数（仅抵押池可调用）
    function mint(address to, uint256 amount) external onlyOwner {
        _mint(to, amount);
    }
}