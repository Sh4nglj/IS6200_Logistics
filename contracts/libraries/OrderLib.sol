// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.20;

library OrderLib {
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

    function initNewOrder(
        Order storage self,
        uint256 id,
        address sender,
        address receiver,
        OrderParam memory param,
        ItemInfo memory item
    ) internal {        
        self.id = id;
        self.sender = sender;
        self.receiver = receiver;
        self.orderParam = param;
        self.item = item;
        self.status = OrderStatus.Created;
        OrderTimestamp memory orderTimestamp = OrderTimestamp({
            createdAt: block.timestamp,
            assignedAt: 0,
            confirmedAt: 0,
            transitBeginAt: 0,
            receivedAt: 0,
            transitEndAt: 0,
            canceledAt: 0,
            finishedAt: 0
        });
        self.orderTimestamp = orderTimestamp;
        self.isRated = false;
    }
}