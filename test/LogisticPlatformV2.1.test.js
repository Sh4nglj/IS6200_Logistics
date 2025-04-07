const { expect } = require("chai");
const { ethers } = require("hardhat");

describe("LogisticPlatform - 创建订单测试", function () {
  let platform;
  let sender, receiver; // 声明测试账户

  // 测试前的初始化工作
  before(async () => {
    // 获取测试账户（默认获取前4个）
    [ , sender, , receiver ] = await ethers.getSigners();
  });

  // 每个测试用例前部署新合约
  beforeEach(async () => {
    const LogisticPlatform = await ethers.getContractFactory("LogisticPlatform");
    platform = await LogisticPlatform.deploy();
  });

  it("应该允许用户创建新订单", async () => {
    // 1. 构造测试数据
    const orderParams = {
      coarsePickup: "上海市浦东新区",
      coarseDropoff: "北京市朝阳区",
      depositAmount: ethers.parseEther("0.1"), // 0.1 ETH
      orderValue: ethers.parseEther("1.5")     // 1.5 ETH
    };
    const itemInfo = {
      volume: 5000,        // 5000立方厘米
      weight: 3000,        // 3000克
      description: "精密仪器" 
    };

    // 2. 执行创建订单操作
    const tx = await platform.connect(sender).createOrder(
      receiver.address,
      orderParams,
      itemInfo
    );

    // 3. 验证交易结果
    // 3.1 获取订单详情
    const order = await platform.orders(1);
    
    // 验证基础信息
    expect(order.id).to.equal(1);
    expect(order.sender).to.equal(sender.address);
    expect(order.receiver).to.equal(receiver.address);
    expect(order.courier).to.equal(ethers.ZeroAddress); // 初始应为零地址

    // 验证状态信息
    expect(order.status).to.equal(0); // 对应OrderStatus.Created

    // 验证时间戳
    // expect(order.orderTimestamp.createdAt).to.equal(mockTimestamp);

    // 验证订单参数
    expect(order.orderParam.coarsePickup).to.equal("上海市浦东新区");
    expect(order.orderParam.depositAmount).to.equal(ethers.parseEther("0.1"));

    // 验证物品信息
    expect(order.item.volume).to.equal(5000);
    expect(order.item.description).to.equal("精密仪器");

    // 4. 验证事件触发
    await expect(tx)
      .to.emit(platform, "OrderCreated")
      .withArgs(1, sender.address);

    await expect(tx)
      .to.emit(platform, "OrderStatusChanged")
      .withArgs(1, sender.address, 0); // Created状态对应索引0
  });
});

describe("LogisticPlatform - 修改订单测试", function () {
  let platform;
  let sender, receiver, otherUser, courier;

  before(async () => {
    [ , sender, , receiver, otherUser, courier ] = await ethers.getSigners();
  });

  beforeEach(async () => {
    const LogisticPlatform = await ethers.getContractFactory("LogisticPlatform");
    platform = await LogisticPlatform.deploy();
    
    // 前置操作：先创建订单
    await platform.connect(sender).createOrder(
      receiver.address,
      { 
        coarsePickup: "上海仓库A",
        coarseDropoff: "北京仓库B",
        depositAmount: ethers.parseEther("0.5"),
        orderValue: ethers.parseEther("5.0")
      },
      {
        volume: 10000,
        weight: 8000,
        description: "初始物品描述"
      }
    );
  });

  it("应该允许发货人修改未确认的订单", async () => {
    // 准备修改参数
    const newOrderParams = {
      coarsePickup: "上海浦东新仓库",
      coarseDropoff: "北京海淀分站",
      depositAmount: ethers.parseEther("1.0"),
      orderValue: ethers.parseEther("10.0")
    };
    const newItemInfo = {
      volume: 15000,
      weight: 12000,
      description: "更新后的物品描述"
    };

    // 执行修改操作
    const tx = await platform.connect(sender).modifyOrder(
      1,
      newOrderParams,
      newItemInfo
    );

    // 验证修改结果
    const modifiedOrder = await platform.orders(1);
    
    // 检查订单参数
    expect(modifiedOrder.orderParam.coarsePickup).to.equal("上海浦东新仓库");
    expect(modifiedOrder.orderParam.depositAmount).to.equal(ethers.parseEther("1.0"));
    
    // 检查物品信息
    expect(modifiedOrder.item.volume).to.equal(15000);
    expect(modifiedOrder.item.description).to.equal("更新后的物品描述");

    // 验证事件
    await expect(tx)
      .to.emit(platform, "OrderModified")
      .withArgs(1, sender.address);
  });

  it("应该阻止非发货人修改订单", async () => {
    await expect(
      platform.connect(otherUser).modifyOrder(
        1, {
          coarsePickup: "深圳南山仓房",
          coarseDropoff: "北京海淀分站",
          depositAmount: ethers.parseEther("1.0"),
          orderValue: ethers.parseEther("10.0")
        }, {
          volume: 15000,
          weight: 12000,
          description: "更新后的物品描述"
        })
    ).to.be.revertedWith("Only sender can modify");
  });

  it("应该阻止修改已确认的订单", async () => {
    // 将订单状态转为已确认
    await platform.connect(sender).confirmOrder(1, courier);

    // 尝试修改
    await expect(
      platform.connect(sender).modifyOrder(
        1, {
          coarsePickup: "深圳南山仓房",
          coarseDropoff: "北京海淀分站",
          depositAmount: ethers.parseEther("1.0"),
          orderValue: ethers.parseEther("10.0")
        }, {
          volume: 15000,
          weight: 12000,
          description: "更新后的物品描述"
        })
    ).to.be.revertedWith("Order can not be modified now.");
  });
});

describe("LogisticPlatform - 取消订单测试", function () {
  let platform;
  let sender, receiver, courier, otherUser;

  before(async () => {
    [ , sender, courier, receiver, otherUser ] = await ethers.getSigners();
  });

  beforeEach(async () => {
    const LogisticPlatform = await ethers.getContractFactory("LogisticPlatform");
    platform = await LogisticPlatform.deploy();
    
    // 创建初始订单
    await platform.connect(sender).createOrder(
      receiver.address,
      { 
        coarsePickup: "上海总仓",
        coarseDropoff: "北京分站",
        depositAmount: ethers.parseEther("0.5"),
        orderValue: ethers.parseEther("5.0")
      },
      {
        volume: 10000,
        weight: 8000,
        description: "测试货物"
      }
    );
  });

  it("应该允许发货人取消可取消状态的订单", async () => {
    // 测试三种可取消状态
    const validStatuses = [
      { action: null, statusName: "Created" }, // 初始状态
      { 
        action: async () => {
          await platform.connect(sender).confirmOrder(1, courier.address);
        }, 
        statusName: "SenderConfirmed" 
      },
      { 
        action: async () => {
          await platform.connect(sender).confirmOrder(1, courier.address);
          await platform.connect(courier).takeOrder(1);
        },
        statusName: "CourierConfirmed" 
      }
    ];

    for (const { action, statusName } of validStatuses) {
      // 执行前置状态转换
      if (action) await action();

      // 执行取消操作
      const tx = await platform.connect(sender).cancelOrder(1);

      // 验证状态
      const order = await platform.orders(1);
      expect(order.status).to.equal(8); // Cancelled状态索引为8

      // 验证事件
      await expect(tx)
        .to.emit(platform, "OrderCancelled")
        .withArgs(1, sender.address)
        .and.to.emit(platform, "OrderStatusChanged")
        .withArgs(1, sender.address, 8);
    }
  });

  it("应该阻止非发货人取消订单", async () => {
    await expect(
      platform.connect(receiver).cancelOrder(1)
    ).to.be.revertedWith("Only sender can cancel");

    await expect(
      platform.connect(courier).cancelOrder(1)
    ).to.be.revertedWith("Only sender can cancel");

    await expect(
      platform.connect(otherUser).cancelOrder(1)
    ).to.be.revertedWith("Only sender can cancel");
  });

  it("应该阻止取消不可取消状态的订单", async () => {
    // 将订单推进到InTransit状态
    await platform.connect(sender).confirmOrder(1, courier.address);
    await platform.connect(courier).takeOrder(1);
    await platform.connect(sender).sendDelivery(1);
    await platform.connect(courier).takeDelivery(1);

    // 尝试取消
    await expect(
      platform.connect(sender).cancelOrder(1)
    ).to.be.revertedWith("Order can only be cancelled under OrderStatus 'Created' or 'Confirmed'.");
  });

  it("应该记录取消时间戳", async () => {
    const block = await ethers.provider.getBlock("latest");
    
    await platform.connect(sender).cancelOrder(1);
    
    const order = await platform.orders(1);
    expect(order.orderTimestamp.canceledAt).to.be.gt(block.timestamp);
  });
});

describe("LogisticPlatform - 承运人拒绝订单测试", function () {
  let platform;
  let sender, courier, receiver, otherCourier;

  before(async () => {
    [ , sender, courier, receiver, otherCourier ] = await ethers.getSigners();
  });

  beforeEach(async () => {
    const LogisticPlatform = await ethers.getContractFactory("LogisticPlatform");
    platform = await LogisticPlatform.deploy();
    
    // 创建订单并推进到CourierConfirmed状态
    await platform.connect(sender).createOrder(
      receiver.address,
      { 
        coarsePickup: "杭州仓库",
        coarseDropoff: "广州仓库",
        depositAmount: ethers.parseEther("0.3"),
        orderValue: ethers.parseEther("3.0")
      },
      {
        volume: 8000,
        weight: 5000,
        description: "易碎物品"
      }
    );
    await platform.connect(sender).confirmOrder(1, courier.address);
    await platform.connect(courier).takeOrder(1);
  });

  it("应该允许承运人拒绝已确认的订单", async () => {
    // 执行拒绝操作
    const tx = await platform.connect(courier).refuseOrder(1);

    // 验证订单状态
    const order = await platform.orders(1);
    expect(order.status).to.equal(0); // 回到Created状态
    expect(order.courier).to.equal(ethers.ZeroAddress); // 承运人地址清零
    expect(order.orderTimestamp.confirmedAt).to.equal(0); // 确认时间戳重置

    // 验证事件
    await expect(tx)
      .to.emit(platform, "OrderStatusChanged")
      .withArgs(1, courier.address, 0);
  });

  it("应该阻止非承运人拒绝订单", async () => {
    // 测试其他地址尝试拒绝
    await expect(
      platform.connect(otherCourier).refuseOrder(1)
    ).to.be.revertedWith("Only courier can refuse"); // 根据合约中的错误提示

    await expect(
      platform.connect(sender).refuseOrder(1)
    ).to.be.revertedWith("Only courier can refuse");

    await expect(
      platform.connect(receiver).refuseOrder(1)
    ).to.be.revertedWith("Only courier can refuse");
  });

  it("应该阻止拒绝非确认状态的订单", async () => {
    // 先拒绝订单回到Created状态
    await platform.connect(courier).refuseOrder(1);

    // 再次尝试拒绝
    await expect(
      platform.connect(courier).refuseOrder(1)
    ).to.be.revertedWith("Only courier can refuse");
  });

  it("应该保留订单其他信息不变", async () => {
    // 记录原始信息
    const originalOrder = await platform.orders(1);

    // 执行拒绝操作
    await platform.connect(courier).refuseOrder(1);

    // 获取更新后的订单
    const updatedOrder = await platform.orders(1);

    // 验证核心信息保留
    expect(updatedOrder.sender).to.equal(originalOrder.sender);
    expect(updatedOrder.receiver).to.equal(originalOrder.receiver);
    expect(updatedOrder.orderParam.orderValue).to.equal(originalOrder.orderParam.orderValue);
    expect(updatedOrder.item.description).to.equal(originalOrder.item.description);
  });

  it("应该允许重新分配承运人", async () => {
    // 先拒绝订单
    await platform.connect(courier).refuseOrder(1);

    // 重新分配新承运人
    await platform.connect(sender).confirmOrder(1, otherCourier.address);
    await platform.connect(otherCourier).takeOrder(1);

    // 验证新承运人信息
    const order = await platform.orders(1);
    expect(order.courier).to.equal(otherCourier.address);
    expect(order.status).to.equal(2); // CourierConfirmed状态
  });

  it("应该重置确认时间戳", async () => {
    const originalOrder = await platform.orders(1);
    await platform.connect(courier).refuseOrder(1);
    const updatedOrder = await platform.orders(1);
    expect(updatedOrder.orderTimestamp.confirmedAt).to.not.equal(originalOrder.orderTimestamp.confirmedAt);
  });

  it("应该准确触发状态变更事件", async () => {
    const tx = await platform.connect(courier).refuseOrder(1);
    const receipt = await tx.wait();
    
    const statusEvent = receipt.logs.find(
      log => log.fragment.name === "OrderStatusChanged"
    );
    
    expect(statusEvent.args.newStatus).to.equal(0);
    expect(statusEvent.args.emitter).to.equal(courier.address);
  });

  it("应该支持连续多次拒绝分配", async () => {
    // 第一次拒绝
    await platform.connect(courier).refuseOrder(1);
    // 重新分配
    await platform.connect(sender).confirmOrder(1, otherCourier.address);
    await platform.connect(otherCourier).takeOrder(1);
    // 再次拒绝
    await platform.connect(otherCourier).refuseOrder(1);
    
    const order = await platform.orders(1);
    expect(order.status).to.equal(0);
    expect(order.courier).to.equal(ethers.ZeroAddress);
  });
});

describe("LogisticPlatform - 完整流程测试", function () {
  let platform;
  let sender, courier, receiver;
  const orderParams = {
    coarsePickup: "上海虹桥仓库",
    coarseDropoff: "北京大兴仓库",
    depositAmount: ethers.parseEther("0.5"),
    orderValue: ethers.parseEther("5.0")
  };
  const itemInfo = {
    volume: 10000,
    weight: 8000,
    description: "精密医疗设备"
  };

  before(async () => {
    [ , sender, courier, receiver ] = await ethers.getSigners();
  });

  beforeEach(async () => {
    const LogisticPlatform = await ethers.getContractFactory("LogisticPlatform");
    platform = await LogisticPlatform.deploy();
  });

  it("应该完成完整的物流生命周期", async () => {
    // 阶段1: 创建订单
    const createTx = await platform.connect(sender).createOrder(
      receiver.address,
      orderParams,
      itemInfo
    );
    await expect(createTx)
      .to.emit(platform, "OrderCreated")
      .withArgs(1, sender.address);

    // 验证初始状态
    let order = await platform.orders(1);
    expect(order.status).to.equal(0); // Created

    // 阶段2: 确认承运人
    const confirmTx = await platform.connect(sender).confirmOrder(1, courier.address);
    await expect(confirmTx)
      .to.emit(platform, "OrderStatusChanged")
      .withArgs(1, sender.address, 1); // SenderConfirmed

    order = await platform.orders(1);
    expect(order.courier).to.equal(courier.address);

    // 阶段3: 承运人接单
    const takeOrderTx = await platform.connect(courier).takeOrder(1);
    await expect(takeOrderTx)
      .to.emit(platform, "OrderStatusChanged")
      .withArgs(1, courier.address, 2); // CourierConfirmed

    order = await platform.orders(1);
    expect(order.orderTimestamp.confirmedAt).to.be.gt(0);
    expect(order.status).to.equal(2);

    // 阶段4: 发货人发货
    const sendTx = await platform.connect(sender).sendDelivery(1);
    await expect(sendTx)
      .to.emit(platform, "OrderStatusChanged")
      .withArgs(1, sender.address, 3); // SenderDelivered

    order = await platform.orders(1);
    expect(order.status).to.equal(3);

    // 阶段5: 承运人开始运输
    const takeDeliveryTx = await platform.connect(courier).takeDelivery(1);
    await expect(takeDeliveryTx)
      .to.emit(platform, "OrderStatusChanged")
      .withArgs(1, courier.address, 4); // InTransit

    order = await platform.orders(1);
    expect(order.orderTimestamp.transitBeginAt).to.be.gt(0);

    // 阶段6: 完成运输
    const completeTx = await platform.connect(courier).compeleteDelivery(1);
    await expect(completeTx)
      .to.emit(platform, "OrderStatusChanged")
      .withArgs(1, courier.address, 5); // CourierDelivered

    order = await platform.orders(1);
    expect(order.orderTimestamp.transitEndAt).to.be.gt(0);

    // 阶段7: 收货人确认收货
    const receiveTx = await platform.connect(receiver).receiveDelivery(1);
    await expect(receiveTx)
      .to.emit(platform, "OrderStatusChanged")
      .withArgs(1, receiver.address, 6); // ReceiverReceived

    order = await platform.orders(1);
    expect(order.orderTimestamp.receivedAt).to.be.gt(0);

    // 阶段8: 完成订单
    const finishTx = await platform.connect(sender).finishOrder(1);
    await expect(finishTx)
      .to.emit(platform, "OrderStatusChanged")
      .withArgs(1, sender.address, 7); // Finished

    // 最终验证
    const finalOrder = await platform.orders(1);
    expect(finalOrder.status).to.equal(7);
    expect(finalOrder.orderTimestamp.finishedAt).to.be.gt(0);
    
    // 验证所有时间戳顺序
    expect(finalOrder.orderTimestamp.createdAt).to.be.lt(finalOrder.orderTimestamp.confirmedAt);
    expect(finalOrder.orderTimestamp.confirmedAt).to.be.lt(finalOrder.orderTimestamp.transitBeginAt);
    expect(finalOrder.orderTimestamp.transitBeginAt).to.be.lt(finalOrder.orderTimestamp.transitEndAt);
    expect(finalOrder.orderTimestamp.transitEndAt).to.be.lt(finalOrder.orderTimestamp.receivedAt);
    expect(finalOrder.orderTimestamp.receivedAt).to.be.lt(finalOrder.orderTimestamp.finishedAt);
  });

  it("应该阻止非法状态转换", async () => {
    // 跳过确认步骤直接发货
    await platform.connect(sender).createOrder(receiver.address, orderParams, itemInfo);
    await expect(
      platform.connect(sender).sendDelivery(1)
    ).to.be.revertedWith("Order can only be confirmed under OrderStatus 'CourierConfirmed'.");
  });
});