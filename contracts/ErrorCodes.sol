// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.20;

/**
 * @title 物流平台错误码定义
 * @dev 定义了物流平台合约中使用的所有错误码
 */
contract ErrorCodes {
    // 通用错误
    string constant E1 = "E1"; // Invalid pool address
    string constant E2 = "E2"; // Invalid token address
    string constant E3 = "E3"; // Insufficient collateral
    
    // 订单修改和取消错误
    string constant E4 = "E4"; // Order can not be modified now
    string constant E5 = "E5"; // Only sender can modify
    string constant E6 = "E6"; // Insufficient balance
    string constant E7 = "E7"; // Only sender can cancel
    string constant E8 = "E8"; // Order can only be cancelled under OrderStatus 'Created' or 'Confirmed'
    
    // 订单确认和发货错误
    string constant E9 = "E9";   // Only the sender can confirm the order
    string constant E10 = "E10"; // Order can only be confirmed under OrderStatus 'Created'
    string constant E11 = "E11"; // Courier address is invalid
    string constant E12 = "E12"; // Only the sender can send the delivery
    string constant E13 = "E13"; // Order can only be confirmed under OrderStatus 'CourierConfirmed'
    
    // 订单完成错误
    string constant E14 = "E14"; // Only the sender can finish the order
    string constant E15 = "E15"; // Order status must be ReceiverReceived
    
    // 订单评分错误
    string constant E16 = "E16"; // Only the sender can rate the courier
    string constant E17 = "E17"; // Order status must be Finished
    string constant E18 = "E18"; // Order has already been rated
    string constant E19 = "E19"; // Rating must be between 1 and 5
    
    // 快递员操作错误
    string constant E20 = "E20"; // Only the courier can take the order
    string constant E21 = "E21"; // Order is not confirmed by sender
    string constant E22 = "E22"; // Insufficient collateral
    string constant E23 = "E23"; // Only courier can refuse
    string constant E24 = "E24"; // Order can only be cancelled under OrderStatus 'Confirmed'
    string constant E25 = "E25"; // Invalid courier
    string constant E26 = "E26"; // Invalid order status
    string constant E27 = "E27"; // Invalid courier
    string constant E28 = "E28"; // Invalid order status
    
    // 收货人操作错误
    string constant E29 = "E29"; // Invalid receiver
    string constant E30 = "E30"; // Invalid order status
    
    // 分润相关错误
    string constant E31 = "E31"; // Only owner can distribute profit
    string constant E32 = "E32"; // Not time to distribute
    string constant E33 = "E33"; // No profit to distribute
    string constant E34 = "E34"; // No rated couriers
} 