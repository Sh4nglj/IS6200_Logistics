// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.20;

import "./CollateralPool.sol";
import "./LogiToken.sol";
import "./ErrorCodes.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

/**
 * @title 物流平台合约
 * @dev 管理物流平台的订单流程、评分系统和分润机制
 */
contract LogisticPlatform is Ownable, ErrorCodes {
    // 状态变量
    CollateralPool public collateralPool;
    LogiToken public logiToken;

    uint256 public constant DISTRIBUTE_INTERVAL = 30 days; // 分润间隔
    uint256 private orderCounter; // 自增id
    uint256 private lastDistributeTime; // 上一次分润时间
    address[] private ratedCourierList;

    // 映射
    mapping(uint256 => Order) public orders;
    mapping(address => uint16) private courierCreditMap;
    
    // 枚举和结构体
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

    // 事件
    event OrderCreated(uint256 indexed orderId, address indexed sender);
    event OrderModified(uint256 indexed orderId, address indexed sender);
    event OrderCancelled(uint256 indexed orderId, address indexed sender);
    event OrderStatusChanged(uint256 indexed orderId, address indexed emitter, OrderStatus newStatus);
    event OrderRated(uint256 indexed orderId, address indexed sender, int8 credit, string comment);
    event CreditChanged(address indexed user, int8 credit);
    event ProfitDistributed(uint256 indexed timestamp, uint256 bonusPoolAmount, string message);

    /**
     * @dev 构造函数，初始化Ownable合约
     */
    constructor() Ownable(msg.sender) {
    }

    /**
     * @dev 设置抵押池合约地址
     * @param poolAddress 抵押池合约地址
     * @notice 只有合约所有者可以调用此函数
     */
    function setCollateralPool(address poolAddress) external onlyOwner {
        require(poolAddress != address(0), E1);
        collateralPool = CollateralPool(poolAddress);
    }

    /**
     * @dev 设置代币合约地址
     * @param tokenAddress 代币合约地址
     * @notice 只有合约所有者可以调用此函数
     */
    function setLogiToken(address tokenAddress) external onlyOwner {
        require(tokenAddress != address(0), E2);
        logiToken = LogiToken(tokenAddress);
    }
    
    /**
     * @dev 创建订单
     * @param _receiver 收货人地址
     * @param _orderParam 订单参数
     * @param _itemInfo 物品信息
     *
     * 发送方创建新的物流订单，需要锁定订单金额作为抵押
     */
    function createOrder(
        address _receiver, 
        OrderParam memory _orderParam, 
        ItemInfo memory _itemInfo
    ) external {
        require(logiToken.getFreeBalance(msg.sender) >= _orderParam.orderValue, E3);
        
        // 保存需要锁定的金额
        uint256 amountToLock = _orderParam.orderValue;
        
        // 状态更改
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
        
        // 外部交互
        collateralPool.lockToken(msg.sender, amountToLock);
    }

    /**
     * @dev 修改订单
     * @param _orderId 订单ID
     * @param _orderParam 新的订单参数
     * @param _itemInfo 新的物品信息
     *
     * 只有发送方可以修改处于Created状态的订单
     * 如果订单金额增加，需要锁定额外的代币
     */
    function modifyOrder(
        uint256 _orderId,
        OrderParam memory _orderParam, 
        ItemInfo memory _itemInfo
    ) external {
        Order storage currentOrder = orders[_orderId];

        require(currentOrder.status == OrderStatus.Created, E4);
        require(msg.sender == currentOrder.sender, E5);

        uint256 oldOrderValue = currentOrder.orderParam.orderValue;
        uint256 newOrderValue = _orderParam.orderValue;

        if (newOrderValue > oldOrderValue) {
            require(logiToken.getFreeBalance(msg.sender) >= (newOrderValue - oldOrderValue), E6);
            collateralPool.lockToken(msg.sender, newOrderValue - oldOrderValue);
        } else if (newOrderValue < oldOrderValue) {
            collateralPool.freeToken(msg.sender, oldOrderValue - newOrderValue);
        }

        currentOrder.orderParam = _orderParam;
        currentOrder.item = _itemInfo;

        emit OrderModified(_orderId, msg.sender);
    }

    /**
     * @dev 取消订单
     * @param _orderId 订单ID
     *
     * 只有发送方可以取消订单，且订单必须处于初始状态
     * 取消后解锁发送方的抵押代币
     */
    function cancelOrder(
        uint256 _orderId
    ) external {
        Order storage currentOrder = orders[_orderId];

        require(msg.sender == currentOrder.sender, E7);
        require(
            currentOrder.status == OrderStatus.Created || currentOrder.status == OrderStatus.SenderConfirmed || 
            currentOrder.status == OrderStatus.CourierConfirmed,
            E8
        );

        // 保存需要解锁的地址和金额
        address sender = currentOrder.sender;
        uint256 orderValue = currentOrder.orderParam.orderValue;
        
        // 状态更改 (Effects)
        currentOrder.status = OrderStatus.Cancelled;
        currentOrder.orderTimestamp.canceledAt = block.timestamp;

        emit OrderCancelled(_orderId, msg.sender);
        emit OrderStatusChanged(_orderId, sender, OrderStatus.Cancelled);
        
        // 外部交互 (Interactions)
        collateralPool.freeToken(sender, orderValue);
    }

    /**
     * @dev 发送方确认订单并指定快递员
     * @param _orderId 订单ID
     * @param _courier 快递员地址
     *
     * 将订单状态从Created更新为SenderConfirmed
     */
    function confirmOrder(
        uint256 _orderId,
        address _courier
    ) external {
        Order storage currentOrder = orders[_orderId];

        require(msg.sender == currentOrder.sender, E9);
        require(currentOrder.status == OrderStatus.Created, E10);
        require(_courier != address(0), E11);

        currentOrder.status = OrderStatus.SenderConfirmed;
        currentOrder.courier = _courier;

        emit OrderStatusChanged(_orderId, msg.sender, OrderStatus.SenderConfirmed);
    }

    /**
     * @dev 发送方发货确认
     * @param _orderId 订单ID
     *
     * 将订单状态从CourierConfirmed更新为SenderDelivered
     */
    function sendDelivery(
        uint256 _orderId
    ) external {
        Order storage currentOrder = orders[_orderId];

        require(msg.sender == currentOrder.sender, E12);
        require(currentOrder.status == OrderStatus.CourierConfirmed, E13);

        currentOrder.status = OrderStatus.SenderDelivered;

        emit OrderStatusChanged(_orderId, msg.sender, OrderStatus.SenderDelivered);
    }

    /**
     * @dev 完成订单
     * @param _orderId 订单ID
     *
     * 只有在收货人确认收货后，发送方才能完成订单
     * 完成后解锁快递员的押金并结算订单金额
     */
    function finishOrder(uint256 _orderId) external {
        Order storage currentOrder = orders[_orderId];

        require(msg.sender == currentOrder.sender, E14);
        require(currentOrder.status == OrderStatus.ReceiverReceived, E15);
        
        // 保存状态变量，防止重入攻击时引用旧值
        address courier = currentOrder.courier;
        uint256 depositAmount = currentOrder.orderParam.depositAmount;
        uint256 orderValue = currentOrder.orderParam.orderValue;
        
        // 状态更改 (Effects)
        currentOrder.status = OrderStatus.Finished;
        currentOrder.orderTimestamp.finishedAt = block.timestamp;
        
        emit OrderStatusChanged(_orderId, msg.sender, OrderStatus.Finished);
        emit CreditChanged(msg.sender, 1);
        emit CreditChanged(courier, 1);

        // 外部交互 (Interactions)
        collateralPool.freeToken(courier, depositAmount);
        collateralPool.settle(currentOrder.sender, courier, orderValue);
    }

    /**
     * @dev 发送方对快递员进行评分
     * @param _orderId 订单ID
     * @param _rating 评分（1-5分）
     * @param _comment 评价内容
     *
     * 只能对已完成且未评价过的订单进行评价
     * 评分会影响快递员在下一次分润中的收益比例
     */
    function rateCourier(
        uint256 _orderId,
        uint8 _rating,
        string memory _comment
    ) external {
        Order storage currentOrder = orders[_orderId];

        require(msg.sender == currentOrder.sender, E16);
        require(currentOrder.status == OrderStatus.Finished, E17);
        require(!currentOrder.isRated, E18);
        require(_rating >= 1 && _rating <= 5, E19);

        // 记录评分信息
        ratedCourierList.push(currentOrder.courier);
        courierCreditMap[currentOrder.courier] += _rating;
        currentOrder.isRated = true;

        emit OrderRated(_orderId, msg.sender, int8(_rating), _comment);
        emit CreditChanged(msg.sender, int8(1));
        emit CreditChanged(currentOrder.courier, int8(_rating));
    }

    /**
     * @dev 快递员接受订单
     * @param _orderId 订单ID
     *
     * 只有被指定的快递员可以接受订单
     * 需要锁定订单要求的押金作为担保
     */
    function takeOrder(
        uint256 _orderId
    ) external {
        Order storage currentOrder = orders[_orderId];

        require(msg.sender == currentOrder.courier, E20);
        require(currentOrder.status == OrderStatus.SenderConfirmed, E21);
        require(logiToken.getFreeBalance(msg.sender) >= currentOrder.orderParam.depositAmount, E22);
       
        collateralPool.lockToken(msg.sender, currentOrder.orderParam.depositAmount);

        currentOrder.status = OrderStatus.CourierConfirmed;
        currentOrder.orderTimestamp.confirmedAt = block.timestamp;

        emit OrderStatusChanged(_orderId, msg.sender, OrderStatus.CourierConfirmed);
    }

    /**
     * @dev 快递员拒绝订单
     * @param _orderId 订单ID
     *
     * 快递员可以拒绝已确认的订单
     * 拒绝后解锁快递员的押金
     */
    function refuseOrder(
        uint256 _orderId
    ) external {
        Order storage currentOrder = orders[_orderId];

        require(msg.sender == currentOrder.courier, E23);
        require(currentOrder.status == OrderStatus.CourierConfirmed, E24);
        
        // 保存状态变量，防止重入攻击
        address courier = msg.sender;
        uint256 depositAmount = currentOrder.orderParam.depositAmount;
        
        // 状态更改 (Effects)
        currentOrder.status = OrderStatus.Created;
        currentOrder.courier = address(0);
        currentOrder.orderTimestamp.confirmedAt = 0;

        emit OrderStatusChanged(_orderId, msg.sender, OrderStatus.Created);
        
        // 外部交互 (Interactions)
        collateralPool.freeToken(courier, depositAmount);
    }

    /**
     * @dev 快递员开始运输
     * @param _orderId 订单ID
     *
     * 将订单状态从SenderDelivered更新为InTransit
     */
    function takeDelivery(
        uint256 _orderId
    ) external {
        Order storage currentOrder = orders[_orderId];

        require(msg.sender == currentOrder.courier, E25);
        require(currentOrder.status == OrderStatus.SenderDelivered, E26);

        currentOrder.status = OrderStatus.InTransit;
        currentOrder.orderTimestamp.transitBeginAt = block.timestamp;

        emit OrderStatusChanged(_orderId, msg.sender, OrderStatus.InTransit);
    }

    /**
     * @dev 快递员确认送达
     * @param _orderId 订单ID
     *
     * 将订单状态从InTransit更新为CourierDelivered
     */
    function compeleteDelivery(
        uint256 _orderId
    ) external {
        Order storage currentOrder = orders[_orderId];

        require(msg.sender == currentOrder.courier, E27);
        require(currentOrder.status == OrderStatus.InTransit, E28);

        currentOrder.status = OrderStatus.CourierDelivered;
        currentOrder.orderTimestamp.transitEndAt = block.timestamp;

        emit OrderStatusChanged(_orderId, msg.sender, OrderStatus.CourierDelivered);
    }

    /**
     * @dev 收货人确认收货
     * @param _orderId 订单ID
     *
     * 将订单状态从CourierDelivered更新为ReceiverReceived
     */
    function receiveDelivery(
        uint256 _orderId
    ) external {
        Order storage currentOrder = orders[_orderId];

        require(msg.sender == currentOrder.receiver, E29);
        require(currentOrder.status == OrderStatus.CourierDelivered, E30);

        currentOrder.status = OrderStatus.ReceiverReceived;
        currentOrder.orderTimestamp.receivedAt = block.timestamp;

        emit OrderStatusChanged(_orderId, msg.sender, OrderStatus.ReceiverReceived);
    }

    /**
     * 分发平台奖金给快递员
     * 根据快递员的评分和计算出的分数比例，分配奖金池中的代币
     * 只有合约拥有者可以调用且必须满足时间间隔要求
     */
    function distributeProfit() external {
        require(collateralPool.owner() == msg.sender, E31);
        require(block.timestamp - lastDistributeTime >= DISTRIBUTE_INTERVAL, E32);     

        uint256 bonusPoolAmount = collateralPool.getBonusPool();
        require(bonusPoolAmount > 0, E33);
        
        uint256 courierCount = ratedCourierList.length;
        require(courierCount > 0, E34);
        
        // 计算每个快递员的分润比例
        address[] memory uniqueCouriers = getUniqueCouriers();
        uint256 totalCouriers = uniqueCouriers.length;

        // 更新分润时间
        lastDistributeTime = block.timestamp;
        
        if (totalCouriers > 0) {
            // 计算各个快递员的评分和总评分
            uint256[] memory courierScores = new uint256[](totalCouriers);
            uint256 totalScore = 0;
            
            for (uint256 i = 0; i < totalCouriers; i++) {
                address courier = uniqueCouriers[i];
                // 使用对数计算分数，使低评分提升空间更大
                courierScores[i] = calculateScore(courierCreditMap[courier]);
                totalScore += courierScores[i];
            }
            
            // 计算每个快递员应得的比例并分发
            if (totalScore > 0) {
                string memory message = "";
                uint256 totalDistributed = 0;
                
                // 第一步：计算每个快递员应得奖金但不实际分配
                uint256[] memory bonusAmounts = new uint256[](totalCouriers);
                
                for (uint256 i = 0; i < totalCouriers; i++) {
                    uint256 shareRatio = (courierScores[i] * 1e18) / totalScore;
                    
                    // 计算奖金但不立即分配
                    bonusAmounts[i] = (bonusPoolAmount * shareRatio) / 1e18;
                    totalDistributed += bonusAmounts[i];
                }
                
                // 第二步：处理剩余奖金，分配给评分最高的快递员
                uint256 remainder = bonusPoolAmount - totalDistributed;
                if (remainder > 0) {
                    // 找到评分最高的快递员
                    uint16 highestCredit = 0;
                    uint256 highestCourierIndex = 0;
                    
                    for (uint256 i = 0; i < totalCouriers; i++) {
                        uint16 credit = courierCreditMap[uniqueCouriers[i]];
                        if (credit > highestCredit) {
                            highestCredit = credit;
                            highestCourierIndex = i;
                        }
                    }
                    
                    // 将剩余奖金加给评分最高的快递员
                    bonusAmounts[highestCourierIndex] += remainder;
                }
                
                // 第三步：实际分配奖金
                for (uint256 i = 0; i < totalCouriers; i++) {
                    address courier = uniqueCouriers[i];
                    
                    // 使用新的函数，直接传入确切金额而非比例
                    uint256 courierBonus = collateralPool.distributeExactBonusTo(courier, bonusAmounts[i]);
                    message = string.concat(message, ";", Strings.toHexString(uint160(courier), 20), "_", Strings.toString(courierBonus));
                }
                
                // 触发分润完成事件
                emit ProfitDistributed(lastDistributeTime, bonusPoolAmount, message);
                
                // 重置评分列表
                delete ratedCourierList;

                // 重置评分映射
                for (uint256 i = 0; i < totalCouriers; i++) {
                    courierCreditMap[uniqueCouriers[i]] = 0;
                }
            }
        }
    }

    /**
     * 计算快递员的分成分数
     * @param _totalCredit 快递员累计评分
     * @return 分成分数
     * 
     * rating为快递员在过去一个月中所有订单评分的累计总和，为uint8类型，最大为255。
     * 
     * 分成采用类似对数的曲线，实现低分快速增长，高分缓慢增长的效果：
     * 1. 所有快递员都有基础分(100)保障，确保基本收益
     * 2. 评分1-3区间：增长最快，激励新手和低评分快递员提高服务
     * 3. 评分4-15区间：中等增长速度，是主要活跃区间
     * 4. 评分16-50区间：增长逐渐放缓，避免头部快递员垄断奖金
     * 5. 评分>50区间：增长最慢，高评分快递员获得稳定但有限的额外分成
     */
    function calculateScore(uint16 _totalCredit) private pure returns (uint256) {
        // 确保至少有1分，避免零分情况
        if (_totalCredit == 0) {
            _totalCredit = 1;
        }
        
        // 基础分固定为100，确保最低收益保障
        uint256 baseScore = 100;
        uint256 logScore;
        
        // 分段模拟对数曲线，不同分段使用不同增长率
        if (_totalCredit <= 3) {
            // 1-3分区间：每分增加60分，激励快速提升
            logScore = uint256(_totalCredit) * 60;
        } else if (_totalCredit <= 15) {
            // 4-15分区间：基础180分，每增加1分增加40分
            logScore = 180 + (uint256(_totalCredit) - 3) * 40;
        } else if (_totalCredit <= 50) {
            // 16-50分区间：基础660分，每增加1分增加20分
            logScore = 660 + (uint256(_totalCredit) - 15) * 20;
        } else if (_totalCredit <= 100) {
            // 51-100分区间：基础1360分，每增加1分增加10分
            logScore = 1360 + (uint256(_totalCredit) - 50) * 10;
        } else {
            // >100分区间：基础1860分，每增加1分增加5分，增长最缓慢
            logScore = 1860 + (uint256(_totalCredit) - 100) * 5;
        }
        
        // 返回总分：基础分 + 对数增长分
        return baseScore + logScore;
    }

    /**
     * 获取唯一的快递员地址列表
     * 从评分记录中提取不重复的快递员地址
     * @return 不重复的快递员地址数组
     */
    function getUniqueCouriers() private view returns (address[] memory) {
        uint256 courierCount = ratedCourierList.length;
        
        // 先计算有多少个唯一快递员
        address[] memory allCouriers = new address[](courierCount);
        uint256 uniqueCount = 0;
        
        for (uint256 i = 0; i < courierCount; i++) {
            address courier = ratedCourierList[i];
            bool found = false;
            
            // 检查此快递员是否已包含在我们的列表中
            for (uint256 j = 0; j < uniqueCount; j++) {
                if (allCouriers[j] == courier) {
                    found = true;
                    break;
                }
            }
            
            if (!found) {
                allCouriers[uniqueCount] = courier;
                uniqueCount++;
            }
        }
        
        // 创建精确大小的结果数组
        address[] memory uniqueCouriers = new address[](uniqueCount);
        for (uint256 i = 0; i < uniqueCount; i++) {
            uniqueCouriers[i] = allCouriers[i];
        }
        
        return uniqueCouriers;
    }

    function getCourierCredit(address _courier) external view returns (uint16) {
        return courierCreditMap[_courier];
    }

    function getOrderCounter() external view returns (uint256) {
        return orderCounter;
    }

    function getLastDistributeTime() external view returns (uint256) {
        return lastDistributeTime;
    }
}