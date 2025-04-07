// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.20;

contract LogisticPlatform {
    // 订单状态枚举（对应文档5种状态）
    enum OrderStatus {
        Created,     // 已创建
        Confirmed,   // 已确认
        InTransit,   // 运输中
        Delivered,   // 已送达
        Completed,    // 已完成
        Cancelled    // 已取消
    }

    // 订单结构体（核心数据结构）
    struct Order {
        uint256 id;                // 订单ID
        address sender;            // 发货人地址
        address courier;           // 承运人地址（初始为0）
        address receiver;          // 收货人地址
        address[] optionalCourier;   // 可选的承运人地址（初始为0）
        OrderTimestamp orderTimestamp;  // 订单时间戳
        OrderStatus status;        // 当前状态
        OrderParam orderParam;     // 订单参数
        ItemInfo item;             // 物品详细信息
    }

    struct OrderTimestamp {
        uint40 createdAt;         // 创建时间戳
        uint40 confirmedAt;       // 确认时间戳
        uint40 transitAt;         // 开始运输时间
    }

    // 订单信息 
    struct OrderParam {
        string coarsePickup;      // 粗粒度发货地
        string coarseDropoff;     // 粗粒度收货地
        uint256 depositAmount;     // 押金要求（wei单位）
        uint256 orderValue;        // 订单总金额（wei单位）
    }

    // 物品信息子结构
    struct ItemInfo {
        uint256 volume;    // 体积（立方厘米）
        uint256 weight;    // 重量（克）
        string description; // 物品描述（加密存储）
    }

    mapping(uint256 => Order) public orders;
    uint256 private orderCounter; // increa

    // Event
    event OrderCreated(uint256 indexed orderId, address indexed sender);
    event OrderModified(uint256 indexed orderId, address indexed sender);
    event OrderCancelled(uint256 indexed orderId, address indexed sender);
    event OrderStatusChanged(uint256 indexed orderId, OrderStatus newStatus);

    // Struct Create Utils
    function getItemInfo(
        uint256 _volume,
        uint256 _weight,
        string calldata _description
    ) external pure returns (ItemInfo memory) {
        require(_volume > 0, "Invalid volume");
        require(_weight > 0, "Invalid weight");
        
        return ItemInfo({
            volume: _volume,
            weight: _weight,
            description: _description
        });
    }

    function getOrderParam(
        string calldata _coarsePickup,
        string calldata _coarseDropoff,
        uint256 _depositAmount,
        uint256 _orderValue
    ) external pure returns (OrderParam memory) {
        require(bytes(_coarsePickup).length > 0, "Invalid pickup");
        require(_depositAmount <= _orderValue, "Deposit exceeds value");

        return OrderParam({
            coarsePickup: _coarsePickup,
            coarseDropoff: _coarseDropoff,
            depositAmount: _depositAmount,
            orderValue: _orderValue
        });
    }

    function getTimestamp(
        uint40 createdAtTs,
        uint40 confirmedAtTs,
        uint40 completedAtTs
    ) external pure returns (OrderTimestamp memory) {
        return OrderTimestamp({
            createdAt: createdAtTs,
            confirmedAt: confirmedAtTs,
            transitAt: completedAtTs
        });
    }

    // Sender relative functions
    function createOrder(
        address _receiver, 
        OrderTimestamp memory _orderTimestamp, 
        OrderParam memory _orderParam, 
        ItemInfo memory _itemInfo
    ) external {
        orderCounter++;
        orders[orderCounter] = Order({
            id: orderCounter,
            sender: msg.sender,
            courier: address(0),
            receiver: _receiver,
            optionalCourier: new address[](0),
            orderTimestamp: _orderTimestamp,
            status: OrderStatus.Created,
            orderParam: _orderParam,
            item: _itemInfo
        });

        emit OrderCreated(orderCounter, msg.sender);
        emit OrderStatusChanged(orderCounter, OrderStatus.Created);
    }

    function modifyOrder(
        uint256 orderId,
        OrderParam memory _orderParam, 
        ItemInfo memory _itemInfo
    ) external {
        Order storage oldOrder = orders[orderId];
        require(msg.sender == oldOrder.sender, "Only sender can modify");

        Order memory newOrder = Order({
            id: orderId,  // Correct struct field name (was mislabeled as orderCounter)
            sender: oldOrder.sender,
            courier: oldOrder.courier,
            receiver: oldOrder.receiver,
            optionalCourier: oldOrder.optionalCourier,
            orderTimestamp: oldOrder.orderTimestamp,
            status: oldOrder.status,
            orderParam: _orderParam,
            item: _itemInfo
        });
        
        orders[orderId] = newOrder;
        emit OrderModified(orderId, msg.sender);
    }

    function cancelOrder(
        uint256 orderId
    ) external {
        require(msg.sender == orders[orderId].sender, "Only sender can modify");
        require(
            orders[orderId].status == OrderStatus.Created || orders[orderId].status == OrderStatus.Confirmed,
            "Order is not created"
        );
        orders[orderId].status = OrderStatus.Cancelled;
    }

    function confirmOrder(
        uint256 orderId,
        address courier
    ) external {
        Order storage order = orders[orderId];
        require(msg.sender == order.sender, "Only sender can confirm");
        require(order.status == OrderStatus.Created, "Order is unable to confirm");
        require(courier != address(0), "Courier address is invalid");

        order.status = OrderStatus.Confirmed;
        order.courier = courier;
        orders[orderId] = order;

        emit OrderStatusChanged(orderId, OrderStatus.Confirmed);
    }

    // Courier relative functions
    function takeOrder(
        uint256 orderId
    ) external {
        require(
            orders[orderId].status == OrderStatus.Created,
            "Order is not created"
        );
        // require();  // courier's deposit should meet the requirement
        orders[orderId].optionalCourier.push(msg.sender);
    }

    function refuseOrder(
        uint256 orderId
    ) external {
        require(
            msg.sender in orders[orderId].optionalCourier,
            "Order is not created"
        )
    }

    // ========== 状态检查 ==========
    modifier onlyParticipant(uint256 _orderId) {
        require(
            msg.sender == orders[_orderId].sender ||
            msg.sender == orders[_orderId].courier ||
            msg.sender == orders[_orderId].receiver,
            "Not a participant"
        );
        _;
    }
}