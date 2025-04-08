// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.20;

import "./CollateralPool.sol";

contract LogisticPlatform {
    CollateralPool public collateralPool;
    
    // 修改构造函数或添加初始化方法
    function setCollateralPool(address poolAddress) external {
        collateralPool = CollateralPool(poolAddress);
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
    event OrderCreated(uint256 indexed orderId, address indexed sender);
    event OrderModified(uint256 indexed orderId, address indexed sender);
    event OrderCancelled(uint256 indexed orderId, address indexed sender);
    event OrderStatusChanged(uint256 indexed orderId, address indexed emitter, OrderStatus newStatus);
    event OrderRated(uint256 indexed orderId, address indexed sender, int64 credit, string comment);
    event CreditChanged(address indexed user, int64 credit);

    // Sender 相关函数
    function createOrder(
        address _receiver, 
        OrderParam memory _orderParam, 
        ItemInfo memory _itemInfo
    ) external {
        // 新增抵押检查和锁定抵押品
        // require(collateralPool.freeCollateral(msg.sender) >= _orderParam.depositAmount, "Insufficient collateral");
        // collateralPool.lockCollateral(msg.sender, _orderParam.depositAmount);

        orderCounter++;
        OrderTimestamp memory _orderTimestamp = OrderTimestamp({
            createdAt: block.timestamp,
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

        emit OrderCreated(orderCounter, msg.sender);
        emit OrderStatusChanged(orderCounter, msg.sender, OrderStatus.Created);
    }

    function modifyOrder(
        uint256 orderId,
        OrderParam memory _orderParam, 
        ItemInfo memory _itemInfo
    ) external {
        Order storage oldOrder = orders[orderId];
        require(msg.sender == oldOrder.sender, "Only sender can modify");
        require(oldOrder.status == OrderStatus.Created, "Order can not be modified now.");

        Order memory newOrder = Order({
            id: orderId,  // Correct struct field name (was mislabeled as orderCounter)
            sender: oldOrder.sender,
            courier: oldOrder.courier,
            receiver: oldOrder.receiver,
            orderTimestamp: oldOrder.orderTimestamp,
            status: oldOrder.status,
            orderParam: _orderParam,
            item: _itemInfo,
            isRated: oldOrder.isRated
        });
        
        orders[orderId] = newOrder;
        emit OrderModified(orderId, msg.sender);
    }

    function cancelOrder(
        uint256 orderId
    ) external {
        require(msg.sender == orders[orderId].sender, "Only sender can cancel");
        require(
            orders[orderId].status == OrderStatus.Created || orders[orderId].status == OrderStatus.SenderConfirmed || 
            orders[orderId].status == OrderStatus.CourierConfirmed,
            "Order can only be cancelled under OrderStatus 'Created' or 'Confirmed'."
        );
        orders[orderId].status = OrderStatus.Cancelled;
        orders[orderId].orderTimestamp.canceledAt = block.timestamp;
        emit OrderCancelled(orderId, msg.sender);
        emit OrderStatusChanged(orderId, msg.sender, OrderStatus.Cancelled);
    }

    function confirmOrder(
        uint256 orderId,
        address courier
    ) external {
        require(msg.sender == orders[orderId].sender, "Only the sender can confirm the order.");
        require(orders[orderId].status == OrderStatus.Created, "Order can only be confirmed under OrderStatus 'Created'.");
        require(courier != address(0), "Courier address is invalid");

        orders[orderId].status = OrderStatus.SenderConfirmed;
        orders[orderId].courier = courier;

        emit OrderStatusChanged(orderId, msg.sender, OrderStatus.SenderConfirmed);
    }

    function sendDelivery(
        uint256 orderId
    ) external {
        require(msg.sender == orders[orderId].sender, "Only the sender can send the delivery.");
        require(orders[orderId].status == OrderStatus.CourierConfirmed, "Order can only be confirmed under OrderStatus 'CourierConfirmed'.");

        orders[orderId].status = OrderStatus.SenderDelivered;

        emit OrderStatusChanged(orderId, msg.sender, OrderStatus.SenderDelivered);
    }

    function finishOrder(
        uint256 orderId
    ) external {
        require(msg.sender == orders[orderId].sender, "Only the sender can finish the order.");
        require(orders[orderId].status == OrderStatus.ReceiverReceived, "Order status must be ReceiverReceived.");

        orders[orderId].status = OrderStatus.Finished;
        orders[orderId].orderTimestamp.finishedAt = block.timestamp;

        emit OrderStatusChanged(orderId, msg.sender, OrderStatus.Finished);
        emit CreditChanged(msg.sender, 1);  // 完成订单给发送者和运输者增加较小的评分
        emit CreditChanged(orders[orderId].courier, 1);
    }

    function rateCourier(
        uint256 orderId,
        int64 rating,
        string memory comment
    ) external {
        require(msg.sender == orders[orderId].sender, "Only the sender can rate the courier.");
        require(orders[orderId].status == OrderStatus.Finished, "Order status must be Finished.");
        require(!orders[orderId].isRated, "Order has already been rated.");
        require(rating >= 1 && rating <= 10, "Rating must be between 1 and 5.");

        orders[orderId].isRated = true;

        emit OrderRated(orderId, msg.sender, rating, comment);
        emit CreditChanged(msg.sender, 1);
        emit CreditChanged(orders[orderId].courier, rating);
    }

    // Courier relative functions
    function takeOrder(
        uint256 orderId
    ) external {
        require(msg.sender == orders[orderId].courier, "Only the courier can take the order.");
        require(orders[orderId].status == OrderStatus.SenderConfirmed, "Order is not confirmed by sender.");

        orders[orderId].status = OrderStatus.CourierConfirmed;
        orders[orderId].orderTimestamp.confirmedAt = block.timestamp;

        emit OrderStatusChanged(orderId, msg.sender, OrderStatus.CourierConfirmed);
    }

    function refuseOrder(
        uint256 orderId
    ) external {
        require(msg.sender == orders[orderId].courier, "Only courier can refuse");
        require(orders[orderId].status == OrderStatus.CourierConfirmed, "Order can only be cancelled under OrderStatus 'Confirmed'.");
        orders[orderId].status = OrderStatus.Created;
        orders[orderId].courier = address(0);
        orders[orderId].orderTimestamp.confirmedAt = 0;

        emit OrderStatusChanged(orderId, msg.sender, OrderStatus.Created);
    }

    function takeDelivery(
        uint256 orderId
    ) external {
        require(msg.sender == orders[orderId].courier, "Invalid courier");
        require(orders[orderId].status == OrderStatus.SenderDelivered, "Invalid order status");

        orders[orderId].status = OrderStatus.InTransit;
        orders[orderId].orderTimestamp.transitBeginAt = block.timestamp;

        emit OrderStatusChanged(orderId, msg.sender, OrderStatus.InTransit);
    }

    function compeleteDelivery(
        uint256 orderId
    ) external {
        require(msg.sender == orders[orderId].courier, "Invalid courier");
        require(orders[orderId].status == OrderStatus.InTransit, "Invalid order status");

        orders[orderId].status = OrderStatus.CourierDelivered;
        orders[orderId].orderTimestamp.transitEndAt = block.timestamp;

        emit OrderStatusChanged(orderId, msg.sender, OrderStatus.CourierDelivered);
    }

    // receiver相关代码
    function receiveDelivery(
        uint256 orderId
    ) external {
        require(msg.sender == orders[orderId].receiver, "Invalid receiver");
        require(orders[orderId].status == OrderStatus.CourierDelivered, "Invalid order status");

        orders[orderId].status = OrderStatus.ReceiverReceived;
        orders[orderId].orderTimestamp.receivedAt = block.timestamp;

        emit OrderStatusChanged(orderId, msg.sender, OrderStatus.ReceiverReceived);
    }
}