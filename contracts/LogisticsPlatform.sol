// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./LogiToken.sol";
import "./UserManagement.sol";
import "./FeeManagement.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract LogisticsPlatform {

    enum OrderStatus {
        Pending, 
        Taken, 
        Transitting, 
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
    UserManagement public userManagement;
    FeeManagement public feeManagement;
    uint256 private orderCount;

    mapping(uint => Order) public orderMap;

    event OrderCreated(uint256 orderID, address senderAddr, uint256 ethAmount);
    event OrderTaken(uint256 orderID, address courierAddr);
    event OrderTransitting(uint256 orderID, OrderStatus newStatus);
    event OrderDelivered(uint256 orderID, address courierAddr, uint256 ltkReward);

    constructor(address _logiToken, address _userManagement, address _feeManagement) {
        logiToken = LogiToken(_logiToken);
        userManagement = UserManagement(_userManagement);
        feeManagement = FeeManagement(_feeManagement);
    }
    
    /**
    Record order and calculate LTK reward.
    msg.sender is Sender.

    TODO: 
    Now orderID is order count. Order Count never be released.
    */
    function createOrder( 
        address _receiverAddr, 
        string memory _senderLoc, 
        string memory _receiverLoc
    ) external payable {
        require(userManagement.userRoles(msg.sender) == UserManagement.Role.Sender, "Only sender can create order.");
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

        emit OrderCreated(orderCount, msg.sender, msg.value);
    }

    /**
    Update order information : courier addr and status.
    msg.sender is Courier
    */
    function takeOrder(uint _orderID) external {
        require(userManagement.userRoles(msg.sender) == UserManagement.Role.Courier, "Only courier can take order.");

        Order storage currentOrder = orderMap[_orderID];
        require(currentOrder.status == OrderStatus.Pending, "Only pending order can be taken.");

        currentOrder.courierAddr = msg.sender;
        currentOrder.status = OrderStatus.Taken;

        emit OrderTaken(_orderID, msg.sender);
    }

    /**
    Start to transit order or finish transitting.
    If finished, pay ETH and award LTK.
    msg.sender is Courier.
    */
    function modifyOrder(uint _orderID, OrderStatus _newStatus) external {
        require(userManagement.userRoles(msg.sender) == UserManagement.Role.Courier, "Only courier can modify order.");

        Order storage currentOrder = orderMap[_orderID];
        
        if (_newStatus == OrderStatus.Transitting) {
            require(currentOrder.status == OrderStatus.Taken, "Only taken order can be transitted.");

            currentOrder.status = OrderStatus.Transitting;

            emit OrderTransitting(_orderID, OrderStatus.Transitting);
        } 
        else if (_newStatus == OrderStatus.Delivered) {
            require(currentOrder.status == OrderStatus.Transitting, "Only transitting order can be delivered.");

            currentOrder.status = OrderStatus.Delivered;
            
            payable(msg.sender).transfer(currentOrder.ethAmount);
            logiToken.transfer(msg.sender, currentOrder.ltkReward);

            emit OrderDelivered(_orderID, msg.sender, currentOrder.ltkReward);
        }
        else if (_newStatus == OrderStatus.Cancelled) {
            // TODO
        }


    }

    // Rate courier.




}