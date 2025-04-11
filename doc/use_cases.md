# 区块链物流平台使用场景

本文档介绍区块链物流平台的主要使用场景，通过真实的用例展示系统的工作流程和用户交互方式。

## 场景一：快递包裹配送

### 用户角色
- **张先生**：发送方，需要寄送一个包裹
- **李师傅**：配送员，承担运输任务
- **王女士**：接收方，等待接收包裹

### 详细流程

#### 1. 创建订单阶段

**张先生**:
1. 使用ETH购买平台代币LogiToken
   ```javascript
   // 前端代码示例
   await collateralPoolContract.deposit({value: ethers.utils.parseEther("0.5")});
   ```

2. 创建物流订单，指定接收方地址和订单详情
   ```javascript
   const orderParam = {
     coarsePickup: "北京市海淀区",
     coarseDropoff: "上海市浦东新区",
     depositAmount: ethers.utils.parseEther("0.1"),
     orderValue: ethers.utils.parseEther("0.3")
   };
   
   const itemInfo = {
     volume: 5000,  // 5000立方厘米
     weight: 2000,  // 2000克
     description: "电子产品，易碎"
   };
   
   await logisticPlatformContract.createOrder(
     "0x1234...5678",  // 王女士的地址
     orderParam,
     itemInfo
   );
   ```

3. 系统锁定张先生的0.3 LogiToken作为订单金额担保
   ```solidity
   // 合约内部执行
   collateralPool.lockToken(msg.sender, amountToLock);
   ```

4. 张先生确认订单信息准确
   ```javascript
   await logisticPlatformContract.confirmOrderBySender(orderId);
   ```

#### 2. 接单和运输阶段

**李师傅**:
1. 浏览可接订单列表，查看订单详情
   ```javascript
   const orders = await logisticPlatformContract.getAvailableOrders();
   ```

2. 接受张先生的订单
   ```javascript
   await logisticPlatformContract.acceptOrder(orderId);
   ```

3. 到达张先生处取件
   ```javascript
   // 物理世界行为
   ```

**张先生**:
1. 确认物品已交付给李师傅
   ```javascript
   await logisticPlatformContract.confirmDeliveryToSender(orderId);
   ```

**李师傅**:
1. 开始运输物品
   ```javascript
   await logisticPlatformContract.startTransit(orderId);
   ```

2. 到达目的地，送达物品给王女士
   ```javascript
   await logisticPlatformContract.confirmDeliveryToCourier(orderId);
   ```

#### 3. 收货和评价阶段

**王女士**:
1. 确认收到物品
   ```javascript
   await logisticPlatformContract.confirmReceipt(orderId);
   ```

2. 对李师傅的服务进行评价（9分/10分）
   ```javascript
   await logisticPlatformContract.rateOrder(orderId, 9, "服务很好，速度快，态度友善");
   ```

#### 4. 结算阶段

系统自动执行：
1. 订单状态更新为"Finished"
2. 解锁张先生的代币
3. 按照预设比例分配代币：
   - 李师傅直接获得80%：0.24 LogiToken
   - 奖金池获得17.5%：0.0525 LogiToken
   - 平台获得2.5%：0.0075 LogiToken

4. 更新李师傅的信誉评分
5. 记录交易完成的所有事件

```solidity
// 合约内部执行
collateralPool.settle(sender, courier, amount);
```

**李师傅**:
1. 将获得的LogiToken兑换为ETH
   ```javascript
   await collateralPoolContract.redeem(ethers.utils.parseEther("0.24"));
   ```

## 场景二：大件物品配送与抵押担保

### 用户角色
- **刘老板**：家具店主，需要配送一套家具
- **赵师傅**：有货车的配送员
- **孙先生**：家具购买者

### 详细流程

#### 1. 高价值订单创建

**刘老板**:
1. 存入大量ETH获取LogiToken
   ```javascript
   await collateralPoolContract.deposit({value: ethers.utils.parseEther("2.0")});
   ```

2. 创建高价值物流订单，设置较高的订单金额
   ```javascript
   const orderParam = {
     coarsePickup: "广州市番禺区",
     coarseDropoff: "广州市天河区",
     depositAmount: ethers.utils.parseEther("0.5"),
     orderValue: ethers.utils.parseEther("1.5")
   };
   
   const itemInfo = {
     volume: 500000,  // 500000立方厘米
     weight: 80000,   // 80公斤
     description: "实木家具一套，需小心搬运"
   };
   
   await logisticPlatformContract.createOrder(
     "0xabcd...efgh",  // 孙先生的地址
     orderParam,
     itemInfo
   );
   ```

#### 2. 配送员抵押与接单

**赵师傅**:
1. 存入ETH以获取足够的LogiToken用于抵押
   ```javascript
   await collateralPoolContract.deposit({value: ethers.utils.parseEther("0.6")});
   ```

2. 接受订单并锁定抵押金
   ```javascript
   await logisticPlatformContract.acceptOrderWithDeposit(orderId, ethers.utils.parseEther("0.5"));
   ```

3. 系统锁定赵师傅的0.5 LogiToken作为配送担保

#### 3. 运输和交付过程

正常完成运输流程，类似于场景一...

#### 4. 争议处理案例

假设在运输过程中，家具有轻微损坏：

**孙先生**:
1. 确认收到物品，但提出有损坏
   ```javascript
   await logisticPlatformContract.confirmReceiptWithIssue(
     orderId, 
     "家具有轻微磨损，需要索赔"
   );
   ```

2. 启动争议解决流程
   ```javascript
   await logisticPlatformContract.initiateDispute(orderId);
   ```

**争议解决**:
1. 平台介入调查（链下过程）
2. 达成部分赔偿协议
3. 执行调整后的结算
   ```javascript
   await logisticPlatformContract.resolveDispute(
     orderId,
     ethers.utils.parseEther("0.3"),  // 从配送员抵押中扣除的赔偿金
     "双方同意赔偿方案"
   );
   ```

## 场景三：批量订单和奖金池分配

### 用户角色
- **多个发送方**：创建多个订单
- **陈师傅**：高评分配送员
- **多个接收方**：各订单的接收方

### 详细流程

#### 1. 多订单完成

**陈师傅**:
1. 在一个月内完成了20个订单
2. 获得了大量高评分（平均9.5分）
3. 累积了直接收益

#### 2. 奖金池分配

**系统**:
1. 到达预设的分配时间点
   ```javascript
   const distributionTime = await logisticPlatformContract.lastDistributeTime();
   const currentTime = Math.floor(Date.now() / 1000);
   
   if (currentTime - distributionTime >= 30 * 24 * 60 * 60) {  // 30天
     await logisticPlatformContract.triggerDistribution();
   }
   ```

2. 根据配送员的评分和完成订单量计算分配比例
   ```solidity
   // 合约内部执行
   function calculateCourierShare(address courier) internal view returns (uint256) {
     uint256 completedOrders = getCompletedOrderCount(courier);
     uint256 avgRating = getAverageRating(courier);
     
     // 计算权重...
     return (completedOrders * avgRating * 10) / totalWeight;
   }
   ```

3. 陈师傅由于高评分和大量订单，获得了奖金池的较大份额
   ```solidity
   // 合约内部执行
   uint256 bonus = (bonusPool * courierShare) / SHARE_BASE;
   collateralPool.distributeExactBonusTo(courier, bonus);
   ```

## 场景四：合约升级与治理

### 用户角色
- **平台管理员**：负责系统维护和升级
- **平台用户**：持续使用平台服务

### 详细流程

#### 1. 发现功能需求或漏洞

**系统监控**:
1. 识别到某个功能需要优化或发现潜在安全问题

#### 2. 合约升级流程

**平台管理员**:
1. 开发新版本合约并进行全面测试
2. 部署升级合约
   ```javascript
   const LogiTokenV2 = await ethers.getContractFactory("LogiTokenV2");
   const logiTokenV2 = await upgrades.upgradeProxy(logiToken.address, LogiTokenV2);
   ```

3. 验证升级后的功能正常运行
   ```javascript
   const newFeature = await logiTokenV2.newFeature();
   console.log("New feature added:", newFeature);
   ```

4. 通知用户系统升级情况
   ```javascript
   await logisticPlatformContract.setSystemNotice(
     "系统已升级到2.0版本，新增功能：更高效的奖励机制和批量订单处理"
   );
   ```

#### 3. 用户无缝体验

**平台用户**:
1. 继续使用平台，享受新功能和改进，同时所有历史数据和状态保持不变

## 模拟交易示例

下面展示一个完整订单生命周期的链上交互示例：

```javascript
// 1. 发送方获取代币
await collateralPool.deposit({value: ethers.utils.parseEther("1.0")});

// 2. 创建订单
const orderId = await logisticPlatform.createOrder(...);

// 3. 发送方确认
await logisticPlatform.confirmOrderBySender(orderId);

// 4. 配送员接单
await logisticPlatform.acceptOrder(orderId);

// 5. 发送方确认交付
await logisticPlatform.confirmDeliveryBySender(orderId);

// 6. 配送员开始运输
await logisticPlatform.startTransit(orderId);

// 7. 配送员确认送达
await logisticPlatform.confirmDeliverByCourier(orderId);

// 8. 接收方确认收货
await logisticPlatform.confirmReceipt(orderId);

// 9. 接收方评价
await logisticPlatform.rateOrder(orderId, 10, "完美的服务");

// 10. 系统自动结算
// (触发在confirmReceipt内部)

// 11. 查询结算结果
const courierBalance = await logiToken.balanceOf(courierAddress);
console.log("Courier earned:", ethers.utils.formatEther(courierBalance));
```

## 总结

以上场景展示了区块链物流平台在不同情况下的工作流程和用户交互方式。通过智能合约实现的自动化流程，确保了交易的透明性、安全性和效率，同时激励机制促进了服务质量的提升。 