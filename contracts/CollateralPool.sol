// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.20;

import "./PledgeToken.sol";

contract CollateralPool {
    PledgeToken public token;
    mapping(address => uint256) public collateralAmount;
    event Deposited(address indexed user, uint256 amount);

    constructor(address tokenAddress) {
        token = PledgeToken(tokenAddress);
    }

    function deposit() external payable {
        require(msg.value > 0, "Invalid amount");
        
        collateralAmount[msg.sender] += msg.value;
        token.mint(msg.sender, msg.value); // 1:1 铸造代币
        
        emit Deposited(msg.sender, msg.value);
    }

    function getCollateral(address user) external view returns(uint256) {
        return collateralAmount[user];
    }
}