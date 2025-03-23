// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./LogiToken.sol";
import "./UserRegistry.sol";
import "./FeeManagement.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract LogisticsPlatform {

    enum OrderStatus {
        Pending, 
        Taken, 
        Transiting, 
        Delivered, 
        Cancelled
    }

    struct Order {
        uint256 orderID;

        address senderAddr;
        address courierAddr;
        address receiverAddr;

        string senderLoc;
        string receiverLoc;

        OrderStatus status;
        uint256 ethAmount;      // Cost of ETH.
        uint256 ltkReward;      // Reward to courier.

        // TODO: Imformation of Item delevered.
    }

    LogiToken public logiToken;
    UserRegistry public userRegistry;
    FeeManagement public feeManagement;
    uint256 private orderCount;

    mapping(uint => Order) public orderMap;

    event OrderCreated();
    event OrderTaken();


    // Modify order status.
    
    /**
    Record order and calculate LTK reward.
    msg.sender is Sender.
    */
    function createOrder( 
        address _receiverAddr, 
        string memory _senderLoc, 
        string memory _receiverLoc
    ) external payable {
        require(userRegistry.userRoles(msg.sender) == UserRegistry.Role.Sender, "Only sender can create order.");
        require(msg.value > 0, "ETH payment required.");

        orderCount++;

        uint256 ltkReward = feeManagement.calculateLTKReward(msg.value, _senderLoc, _receiverLoc);

        orderMap[orderCount] = Order({
            orderID : orderCount, 
            senderAddr : msg.sender, 
            courierAddr : address(0),
            receiverAddr : _receiverAddr, 
            senderLoc : _senderLoc, 
            receiverLoc : _receiverLoc, 
            status : OrderStatus.Pending, 
            ethAmount : msg.value, 
            ltkReward : ltkReward
        });

        emit OrderCreated();
    }

    /**
    Update order information : courier addr and status.
    msg.sender is Courier
    */
    function takeOrder(uint _orderID) external {
        require(userRegistry.userRoles(msg.sender) == UserRegistry.Role.Courier, "Only courier can take order.");

        Order storage currentOrder = orderMap[_orderID];
    }

    // Finish order.

    // Rate courier.

    // Process payment.




}