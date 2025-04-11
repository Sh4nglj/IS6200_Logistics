// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.20;

import "./CollateralPool.sol";
import "./LogiToken.sol";

contract LogisticPlatform {
    CollateralPool public collateralPool;
    LogiToken public logiToken;
    
    // 修改构造函数或添加初始化方法
    function setCollateralPool(address poolAddress) external {
        collateralPool = CollateralPool(poolAddress);
    }

    function setLogiToken(address tokenAddress) external {
        logiToken = LogiToken(tokenAddress);
    }
    

    // 订单状态枚举（对应文档5种状态）
    enum OrderStatus {
        Created,     // 已创建
        SenderConfirmed,   // sender已确认
        CourierConfirmed,  // courier已确认
        SenderDelivered, // sender已发货
        InTransit,   // 运输中                  
        CourierDelivered,   // 已送达
        ReceiverReceived,   // 收货人已收到
        Finished,    // 已完成
        Cancelled    // 已取消
    }

    enum CreditChangeReason {
        FinishOrder,
        TransportOrder,
        RateOrder,
        BeingRated,
        Punishment,
        WinArgue,
        LoseArgue
    }

    // 订单结构体（核心数据结构）
    struct Order {                  
        uint256 id;                // 订单ID
        address sender;            // 发货人地址
        address courier;           // 承运人地址（初始为0）
        address receiver;          // 收货人地址
        OrderTimestamp orderTimestamp;  // 订单时间戳
        OrderStatus status;        // 当前状态
        OrderParam orderParam;     // 订单参数
        ItemInfo item;             // 物品详细信息
        bool isRated;
    }

    struct OrderTimestamp {
        uint256 createdAt;         // 创建时间戳
        uint256 assignedAt;
        uint256 confirmedAt;       // 确认时间戳
        uint256 transitBeginAt;       // 开始运输时间
        uint256 transitEndAt;       // 结束运输时间
        uint256 receivedAt;
        uint256 finishedAt;        // 完成时间戳
        uint256 canceledAt;        // 取消时间戳
    }

    // 订单信息 
    struct OrderParam {
        string coarsePickup;      // 粗粒度发货地
        string coarseDropoff;     // 粗粒度收货地
        uint256 depositAmount;     // 押金要求（ETH单位）
        uint256 orderValue;        // 订单总金额（wei单位）
    }

    // 物品信息子结构
    struct ItemInfo {
        uint256 volume;    // 体积（立方厘米）
        uint256 weight;    // 重量（克）
        string description; // 物品描述（加密存储）
    }

    mapping(uint256 => Order) public orders;
    uint256 public orderCounter; // 自增id

    // Event
    event OrderCreated(uint256 indexed orderId, address indexed sender, address courier, address indexed receiver, string coarsePickup, string coarseDropoff, uint256 orderValue);  // order创建时，courier不需要为indexed
    event OrderModified(uint256 indexed orderId, address indexed sender, address indexed courier, address receiver,  string coarsePickup, string coarseDropoff, uint256 orderValue);
    event OrderCancelled(uint256 indexed orderId, address indexed sender, address indexed courier, address receiver);
    event OrderStatusChanged(uint256 indexed orderId, address indexed sender, address indexed courier, address receiver, string newStatus);  // 使用string来表示订单状态，是因为定义的枚举不被event支持，导致event无法emit
    event OrderRated(uint256 indexed orderId, address indexed sender, address indexed courier, int64 credit, string comment);
    event CreditChanged(address indexed user, int64 credit, string reasonChanged);

    // modifiers
    modifier onlyParticipant(uint256 _orderId) {
        require(msg.sender == orders[_orderId].sender || msg.sender == orders[_orderId].courier || msg.sender == orders[_orderId].receiver, "Only the sender, courier or receiver can call this function.");
        _;
    }

    // Sender 相关函数
    function createOrder(
        address _receiver, 
        OrderParam memory _orderParam, 
        ItemInfo memory _itemInfo
    ) external returns (uint256) {
        // 新增抵押检查和锁定抵押品
        require(logiToken.getFreeBalance(msg.sender) >= _orderParam.orderValue, "Insufficient collateral");
        collateralPool.lockToken(msg.sender, _orderParam.orderValue);

        orderCounter++;
        
        OrderTimestamp memory _orderTimestamp = OrderTimestamp({
            createdAt: block.timestamp,
            assignedAt: 0,
            confirmedAt: 0,
            transitBeginAt: 0,
            receivedAt: 0,
            transitEndAt: 0,
            canceledAt: 0,
            finishedAt: 0
        });

        orders[orderCounter] = Order({
            id: orderCounter,
            sender: msg.sender,
            courier: address(0),
            receiver: _receiver,
            orderTimestamp: _orderTimestamp,
            status: OrderStatus.Created,
            orderParam: _orderParam,
            item: _itemInfo,
            isRated: false
        });

        emit OrderCreated(orderCounter, msg.sender, address(0), _receiver, _orderParam.coarsePickup, _orderParam.coarseDropoff, _orderParam.orderValue);
        emit OrderStatusChanged(orderCounter, msg.sender, address(0), _receiver, "Created");
        return orderCounter;
    }

    function modifyOrder(
        uint256 _orderId,
        OrderParam memory _orderParam, 
        ItemInfo memory _itemInfo
    ) external {
        Order storage currentOrder = orders[_orderId];
        require(currentOrder.status == OrderStatus.Created, "Order can not be modified now.");
        require(msg.sender == currentOrder.sender, "Only sender can modify");
        uint256 oldOrderValue = currentOrder.orderParam.orderValue;
        uint256 newOrderValue = _orderParam.orderValue;
        if (newOrderValue > oldOrderValue) {
            require(logiToken.getFreeBalance(msg.sender) >= (newOrderValue - oldOrderValue), "Insufficient balance");
            collateralPool.lockToken(msg.sender, newOrderValue - oldOrderValue);
        } else if (newOrderValue < oldOrderValue) {
            collateralPool.freeToken(msg.sender, oldOrderValue - newOrderValue);
        }

        currentOrder.orderParam = _orderParam;
        currentOrder.item = _itemInfo;

        emit OrderModified(_orderId, currentOrder.sender, currentOrder.courier, currentOrder.receiver, _orderParam.coarsePickup, _orderParam.coarseDropoff, _orderParam.orderValue);
    }

    // Sender cancel order
    function cancelOrder(
        uint256 _orderId
    ) external {
        require(msg.sender == orders[_orderId].sender, "Only sender can cancel");
        require(
            orders[_orderId].status == OrderStatus.Created || orders[_orderId].status == OrderStatus.SenderConfirmed || 
            orders[_orderId].status == OrderStatus.CourierConfirmed,
            "Order can only be cancelled under OrderStatus 'Created' or 'Confirmed'."
        );
        collateralPool.freeToken(orders[_orderId].sender, orders[_orderId].orderParam.orderValue);

        orders[_orderId].status = OrderStatus.Cancelled;
        orders[_orderId].orderTimestamp.canceledAt = block.timestamp;

        emit OrderCancelled(_orderId, orders[_orderId].sender, orders[_orderId].courier, orders[_orderId].receiver);
        emit OrderStatusChanged(_orderId, orders[_orderId].sender, orders[_orderId].courier, orders[_orderId].receiver, "Cancelled");
    }

    function confirmOrder(
        uint256 _orderId,
        address _courier
    ) external {
        require(msg.sender == orders[_orderId].sender, "Only the sender can confirm the order.");
        require(orders[_orderId].status == OrderStatus.Created, "Order can only be confirmed under OrderStatus 'Created'.");
        require(_courier != address(0), "Courier address is invalid");

        orders[_orderId].status = OrderStatus.SenderConfirmed;
        orders[_orderId].courier = _courier;
        orders[_orderId].orderTimestamp.assignedAt = block.timestamp;

        emit OrderStatusChanged(_orderId, orders[_orderId].sender, orders[_orderId].courier, orders[_orderId].receiver, "SenderConfirmed");
    }

    function sendDelivery(
        uint256 _orderId
    ) external {
        require(msg.sender == orders[_orderId].sender, "Only the sender can send the delivery.");
        require(orders[_orderId].status == OrderStatus.CourierConfirmed, "Order can only be confirmed under OrderStatus 'CourierConfirmed'.");

        orders[_orderId].status = OrderStatus.SenderDelivered;

        emit OrderStatusChanged(_orderId, orders[_orderId].sender, orders[_orderId].courier, orders[_orderId].receiver, "SenderDelivered");
    }

    function finishOrder(
        uint256 _orderId
    ) external {
        require(msg.sender == orders[_orderId].sender, "Only the sender can finish the order.");
        require(orders[_orderId].status == OrderStatus.ReceiverReceived, "Order status must be ReceiverReceived.");

        orders[_orderId].status = OrderStatus.Finished;
        orders[_orderId].orderTimestamp.finishedAt = block.timestamp;

        collateralPool.freeToken(orders[_orderId].courier, orders[_orderId].orderParam.depositAmount);
        collateralPool.settle(orders[_orderId].sender, orders[_orderId].courier, orders[_orderId].orderParam.orderValue);

        emit OrderStatusChanged(_orderId, orders[_orderId].sender, orders[_orderId].courier, orders[_orderId].receiver, "Finished");
        emit CreditChanged(msg.sender, 1, "FinishOrder");  // 完成订单给发送者和运输者增加较小的评分
        emit CreditChanged(orders[_orderId].courier, 1, "TransportOrder");
    }

    function rateCourier(
        uint256 _orderId,
        int64 _rating,
        string memory _comment
    ) external {
        require(msg.sender == orders[_orderId].sender, "Only the sender can rate the courier.");
        require(orders[_orderId].status == OrderStatus.Finished, "Order status must be Finished.");
        require(!orders[_orderId].isRated, "Order has already been rated.");
        require(_rating >= 1 && _rating <= 10, "Rating must be between 1 and 5.");

        orders[_orderId].isRated = true;

        emit OrderRated(_orderId, orders[_orderId].sender, orders[_orderId].courier, _rating, _comment);
        emit CreditChanged(msg.sender, 1, "RateOrder");
        emit CreditChanged(orders[_orderId].courier, _rating, "BeingRated");
    }

    // Courier relative functions
    function takeOrder(
        uint256 _orderId
    ) external {
        require(msg.sender == orders[_orderId].courier, "Only the courier can take the order.");
        require(orders[_orderId].status == OrderStatus.SenderConfirmed, "Order is not confirmed by sender.");
        require(logiToken.getFreeBalance(msg.sender) >= orders[_orderId].orderParam.depositAmount, "Insufficient collateral");
        collateralPool.lockToken(msg.sender, orders[_orderId].orderParam.depositAmount);

        orders[_orderId].status = OrderStatus.CourierConfirmed;
        orders[_orderId].orderTimestamp.confirmedAt = block.timestamp;

        emit OrderStatusChanged(_orderId, orders[_orderId].sender, orders[_orderId].courier, orders[_orderId].receiver, "CourierConfirmed");
    }

    function refuseOrder(
        uint256 _orderId
    ) external {
        require(msg.sender == orders[_orderId].courier, "Only courier can refuse");
        require(orders[_orderId].status == OrderStatus.CourierConfirmed, "Order can only be cancelled under OrderStatus 'Confirmed'.");
        collateralPool.freeToken(msg.sender, orders[_orderId].orderParam.depositAmount);
        
        orders[_orderId].status = OrderStatus.Created;
        orders[_orderId].courier = address(0);
        orders[_orderId].orderTimestamp.confirmedAt = 0;

        emit OrderStatusChanged(_orderId, orders[_orderId].sender, orders[_orderId].courier, orders[_orderId].receiver, "Created");
    }

    function takeDelivery(
        uint256 _orderId
    ) external {
        require(msg.sender == orders[_orderId].courier, "Invalid courier");
        require(orders[_orderId].status == OrderStatus.SenderDelivered, "Invalid order status");

        orders[_orderId].status = OrderStatus.InTransit;
        orders[_orderId].orderTimestamp.transitBeginAt = block.timestamp;

        emit OrderStatusChanged(_orderId, orders[_orderId].sender, orders[_orderId].courier, orders[_orderId].receiver, "InTransit");
    }

    function compeleteDelivery(
        uint256 _orderId
    ) external {
        require(msg.sender == orders[_orderId].courier, "Invalid courier");
        require(orders[_orderId].status == OrderStatus.InTransit, "Invalid order status");

        orders[_orderId].status = OrderStatus.CourierDelivered;
        orders[_orderId].orderTimestamp.transitEndAt = block.timestamp;

        emit OrderStatusChanged(_orderId, orders[_orderId].sender, orders[_orderId].courier, orders[_orderId].receiver, "CourierDelivered");
    }

    // receiver相关代码
    function receiveDelivery(
        uint256 _orderId
    ) external {
        require(msg.sender == orders[_orderId].receiver, "Invalid receiver");
        require(orders[_orderId].status == OrderStatus.CourierDelivered, "Invalid order status");

        orders[_orderId].status = OrderStatus.ReceiverReceived;
        orders[_orderId].orderTimestamp.receivedAt = block.timestamp;

        emit OrderStatusChanged(_orderId, orders[_orderId].sender, orders[_orderId].courier, orders[_orderId].receiver, "ReceiverReceived");
    }

    // utils functions
    /*
    便于前端快速查询订单信息
    */
    function queryOrder(
        uint256 _orderId
    // ) external onlyParticipant(_orderId) view returns (Order memory) {
    ) external view returns (Order memory) {
        return orders[_orderId];
    }
}