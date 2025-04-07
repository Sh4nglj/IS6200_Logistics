// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts-upgradeable/token/ERC20/ERC20Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";

contract PledgeToken is ERC20Upgradeable, OwnableUpgradeable {
    bool public transferEnabled;
    
    // 初始化函数（用于可升级合约）
    function initialize(string memory name, string memory symbol) initial public {
        __ERC20_init(name, symbol);
        __Ownable_init(msg.sender);
        transferEnabled = false;
    }

    // 禁用转账功能（待升级开启）
    function _update(address from, address to, uint256 value) internal override {
        require(transferEnabled || from == address(0), "Transfers disabled");
        super._update(from, to, value);
    }

    // 铸造函数（仅抵押池可调用）
    function mint(address to, uint256 amount) external onlyOwner {
        _mint(to, amount);
    }
}