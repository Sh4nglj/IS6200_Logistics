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

    enum OrderRating {
        NotFinished, 
        Good, 
        Neutral, 
        Bad, 
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
        OrderRating rating;

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
    event OrderDelivered(uint256 orderID);
    event OrderCancelled(uint256 orderID);
    event OrderRated(uint256 orderID, OrderRating rating);
    event LTKTransfered(uint256 orderID, address courierAddr, uint256 ltkReward);

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

        orderMap[orderCount] = Order({
            orderID : orderCount, 
            senderAddr : msg.sender, 
            courierAddr : address(0),
            receiverAddr : _receiverAddr, 
            senderLoc : _senderLoc, 
            receiverLoc : _receiverLoc, 
            status : OrderStatus.Pending, 
            rating : OrderRating.NotFinished,
            ethAmount : msg.value, 
            ltkReward : 0
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

            emit OrderDelivered(_orderID);
        }
        else if (_newStatus == OrderStatus.Cancelled) {
            require(currentOrder.status == OrderStatus.Transitting, "Only transitting order can be cancelled.");

            currentOrder.status = OrderStatus.Cancelled;
            currentOrder.rating = OrderRating.Cancelled;

            userManagement.penalizeCourier(msg.sender);

            emit OrderCancelled(_orderID);
        }
    }

    /**
    Receiver rate courier after order delivered.
    Good, Neutral, Bad
    Then transfer courier LTK bonus.
    msg.sender = Receiver
    */
    function rateCourier(uint256 _orderID, OrderRating _rating) external {
        require(userManagement.userRoles(msg.sender) == UserManagement.Role.Receiver, "Only receiver can rate order.");

        Order storage currentOrder = orderMap[_orderID];
        currentOrder.rating = _rating;

        address courierAddr = currentOrder.courierAddr;

        if (_rating == OrderRating.Good) {
            userManagement.rewardCourier(courierAddr);
        }
        else if (_rating == OrderRating.Bad) {
            userManagement.penalizeCourier(courierAddr);
        }

        transferLTK(_orderID);

        emit OrderRated(_orderID, _rating);
    }

    /**
    Courier get LTK reward after order be rated.
    */
    function transferLTK(uint256 _orderID) private {
        Order storage currentOrder = orderMap[_orderID];

        address courierAddr = currentOrder.courierAddr;

        uint256 courierReputation = userManagement.courierReputation(courierAddr);
        uint256 ltkReward = feeManagement.calculateLTKReward(currentOrder.senderLoc, currentOrder.receiverLoc, courierReputation);

        logiToken.transfer(msg.sender, ltkReward);
        // For recording order imformation.
        currentOrder.ltkReward = ltkReward;

        emit LTKTransfered(_orderID, courierAddr, ltkReward);
    }

    // TODO: Deposit.
}