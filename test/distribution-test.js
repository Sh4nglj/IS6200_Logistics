// SPDX-License-Identifier: MIT

/**
 * 物流平台分成功能测试
 * 
 * 运行方法：
 * 1. 在终端中切换到项目根目录
 * 2. 执行命令：npx hardhat test test/distribution-test.js
 * 
 * 本测试模拟完成10个订单并进行评分，然后触发一次分成，验证分成结果
 */

const { expect } = require("chai");
const { ethers } = require("hardhat");
const { time } = require("@nomicfoundation/hardhat-network-helpers");
const { upgrades } = require("hardhat");

describe("物流平台分成功能测试", function () {
  // 定义测试需要的变量
  let logiToken;
  let collateralPool;
  let logisticPlatform;
  let owner;
  let sender1, sender2;
  let courier1, courier2, courier3;
  let receiver;
  let orderIds = [];

  // 测试前的准备工作
  before(async function () {
    console.log("开始部署合约...");
    
    // 获取测试账号
    [owner, sender1, sender2, courier1, courier2, courier3, receiver] = await ethers.getSigners();
    
    // 部署 LogiToken 合约 - 使用可升级合约方式
    const LogiToken = await ethers.getContractFactory("LogiToken");
    logiToken = await upgrades.deployProxy(LogiToken, ["LogiToken", "LOGI"], {
      initializer: "initialize",
    });
    await logiToken.waitForDeployment();
    console.log("LogiToken 合约已部署:", logiToken.target);
    
    // 部署 LogisticPlatform 合约
    const LogisticPlatform = await ethers.getContractFactory("LogisticPlatform");
    logisticPlatform = await LogisticPlatform.deploy();
    await logisticPlatform.waitForDeployment();
    console.log("LogisticPlatform 合约已部署:", logisticPlatform.target);
    
    // 部署 CollateralPool 合约
    const CollateralPool = await ethers.getContractFactory("CollateralPool");
    collateralPool = await CollateralPool.deploy(logiToken.target, logisticPlatform.target);
    await collateralPool.waitForDeployment();
    console.log("CollateralPool 合约已部署:", collateralPool.target);
    
    // 设置 LogisticPlatform 的 CollateralPool 和 LogiToken
    await logisticPlatform.setCollateralPool(collateralPool.target);
    await logisticPlatform.setLogiToken(logiToken.target);
    
    // 设置 LogiToken 的 CollateralPool
    await logiToken.setCollateralPool(collateralPool.target);
    
    // 转移 LogiToken 所有权给 CollateralPool
    await logiToken.transferTokenOwnership(collateralPool.target);
    
    console.log("合约部署和初始化完成");
  });

  // 为测试准备资金
  it("准备测试资金", async function () {
    console.log("为测试账户充值代币...");
    
    // 为发送方1充值
    await collateralPool.connect(sender1).deposit({ value: ethers.parseEther("5") });
    
    // 为发送方2充值
    await collateralPool.connect(sender2).deposit({ value: ethers.parseEther("5") });
    
    // 为快递员充值（用于抵押）
    await collateralPool.connect(courier1).deposit({ value: ethers.parseEther("2") });
    await collateralPool.connect(courier2).deposit({ value: ethers.parseEther("2") });
    await collateralPool.connect(courier3).deposit({ value: ethers.parseEther("2") });
    
    // 检查余额
    const sender1Balance = await logiToken.getFreeBalance(sender1.address);
    const courier1Balance = await logiToken.getFreeBalance(courier1.address);
    
    console.log("发送方1余额:", ethers.formatEther(sender1Balance));
    console.log("快递员1余额:", ethers.formatEther(courier1Balance));
    
    expect(sender1Balance).to.be.gt(0);
    expect(courier1Balance).to.be.gt(0);
  });

  // 创建并完成10个订单
  it("创建并完成10个订单", async function () {
    console.log("开始创建并完成10个订单...");
    
    // 创建10个订单
    for (let i = 0; i < 10; i++) {
      // 选择发送方
      const sender = i % 2 === 0 ? sender1 : sender2;
      
      // 选择快递员（轮流分配）
      const couriers = [courier1, courier2, courier3];
      const courier = couriers[i % 3];
      
      // 创建订单参数
      const orderParam = {
        coarsePickup: "北京市海淀区",
        coarseDropoff: "上海市浦东新区",
        depositAmount: ethers.parseEther("0.1"),  // 押金0.1 ETH
        orderValue: ethers.parseEther("0.2")      // 订单金额0.2 ETH
      };
      
      const itemInfo = {
        volume: 1000,  // 1000立方厘米
        weight: 2000,  // 2000克
        description: "电子产品，小心轻放"
      };
      
      // 步骤1：创建订单
      console.log(`创建第${i+1}个订单...`);
      let tx = await logisticPlatform.connect(sender).createOrder(
        receiver.address,
        orderParam,
        itemInfo
      );
      let receipt = await tx.wait();
      
      // 从事件中获取订单ID
      const orderCreatedEvent = receipt.logs.find(log => 
        log.fragment && log.fragment.name === "OrderCreated"
      );
      const orderId = orderCreatedEvent.args[0];
      orderIds.push(orderId);
      
      console.log(`订单${orderId}已创建`);
      
      // 步骤2：发送方确认订单并指定快递员
      await logisticPlatform.connect(sender).confirmOrder(orderId, courier.address);
      console.log(`发送方已确认订单${orderId}并指定快递员${courier.address}`);
      
      // 步骤3：快递员接受订单
      await logisticPlatform.connect(courier).takeOrder(orderId);
      console.log(`快递员已接受订单${orderId}`);
      
      // 步骤4：发送方发货
      await logisticPlatform.connect(sender).sendDelivery(orderId);
      console.log(`发送方已发货${orderId}`);
      
      // 步骤5：快递员开始运输
      await logisticPlatform.connect(courier).takeDelivery(orderId);
      console.log(`快递员开始运输订单${orderId}`);
      
      // 步骤6：快递员送达
      await logisticPlatform.connect(courier).compeleteDelivery(orderId);
      console.log(`快递员已送达订单${orderId}`);
      
      // 步骤7：收货人确认收货
      await logisticPlatform.connect(receiver).receiveDelivery(orderId);
      console.log(`收货人已确认收货${orderId}`);
      
      // 步骤8：发送方完成订单

      // 为 CollateralPool 授权使用发送方代币
      await logiToken.connect(sender).approve(collateralPool.target, orderParam.orderValue);
      console.log(`发送方已授权CollateralPool使用${orderParam.orderValue}代币`);

      await logisticPlatform.connect(sender).finishOrder(orderId);
      console.log(`订单${orderId}已完成`);
    }
    
    console.log("10个订单全部完成");
  });

  // 对订单进行评分
  it("对完成的订单进行评分", async function () {
    console.log("开始对订单进行评分...");
    
    // 为每个订单评分
    for (let i = 0; i < orderIds.length; i++) {
      const orderId = orderIds[i];
      const sender = i % 2 === 0 ? sender1 : sender2;
      
      // 评分范围1-5，根据订单ID的模决定评分
      // 让不同快递员有不同评分以验证分润效果
      let rating;
      if (i % 3 === 0) {
        rating = 5;  // courier1 获得高分
      } else if (i % 3 === 1) {
        rating = 3;  // courier2 获得中等分数
      } else {
        rating = 2;  // courier3 获得较低分数
      }
      
      await logisticPlatform.connect(sender).rateCourier(
        orderId,
        rating,
        `评价订单${orderId}，服务质量${rating}/5`
      );
      
      console.log(`订单${orderId}已评分: ${rating}分`);
    }
    
    console.log("所有订单评分完成");
  });

  // 检查奖金池金额
  it("检查奖金池金额", async function () {
    const bonusPoolAmount = await collateralPool.getBonusPool();
    console.log("奖金池金额:", ethers.formatEther(bonusPoolAmount), "ETH");
    
    // 验证奖金池不为0
    expect(bonusPoolAmount).to.be.gt(0);
    
    // 理论上，每个订单金额为0.2 ETH，其中17.5%进入奖金池
    // 10个订单总共应该有 10 * 0.2 * 0.175 = 0.35 ETH进入奖金池
    const expectedBonus = ethers.parseEther("0.35");
    expect(bonusPoolAmount).to.be.closeTo(expectedBonus, ethers.parseEther("0.01"));
  });

  // 触发分成
  it("触发分成并验证结果", async function () {
    console.log("准备触发分成...");
    
    // 记录分成前余额
    const beforeBalance1 = await logiToken.balanceOf(courier1.address);
    const beforeBalance2 = await logiToken.balanceOf(courier2.address);
    const beforeBalance3 = await logiToken.balanceOf(courier3.address);
    
    console.log("分成前余额:");
    console.log("- 快递员1:", ethers.formatEther(beforeBalance1), "ETH");
    console.log("- 快递员2:", ethers.formatEther(beforeBalance2), "ETH");
    console.log("- 快递员3:", ethers.formatEther(beforeBalance3), "ETH");
    
    // 时间推进到可以分成的时间点（30天后）
    await time.increase(30 * 24 * 60 * 60);
    // 获取每个快递员的信用评分
    const credit1 = await logisticPlatform.getCourierCredit(courier1.address);
    const credit2 = await logisticPlatform.getCourierCredit(courier2.address);
    const credit3 = await logisticPlatform.getCourierCredit(courier3.address);
    
    console.log("快递员信用评分:");
    console.log("- 快递员1:", credit1.toString());
    console.log("- 快递员2:", credit2.toString());
    console.log("- 快递员3:", credit3.toString());
    
    // // 获取每个快递员的分成比例
    // const ratio1 = await logisticPlatform.calculateCourierRatio(courier1.address);
    // const ratio2 = await logisticPlatform.calculateCourierRatio(courier2.address);
    // const ratio3 = await logisticPlatform.calculateCourierRatio(courier3.address);
    
    // console.log("快递员分成比例:");
    // console.log("- 快递员1:", ethers.formatEther(ratio1));
    // console.log("- 快递员2:", ethers.formatEther(ratio2));
    // console.log("- 快递员3:", ethers.formatEther(ratio3));
    // 触发分成
    await logisticPlatform.connect(owner).distributeProfit();
    console.log("分成已触发");
    
    // 记录分成后余额
    const afterBalance1 = await logiToken.balanceOf(courier1.address);
    const afterBalance2 = await logiToken.balanceOf(courier2.address);
    const afterBalance3 = await logiToken.balanceOf(courier3.address);
    
    console.log("分成后余额:");
    console.log("- 快递员1:", ethers.formatEther(afterBalance1), "ETH");
    console.log("- 快递员2:", ethers.formatEther(afterBalance2), "ETH");
    console.log("- 快递员3:", ethers.formatEther(afterBalance3), "ETH");
    
    // 计算增加的余额
    const increase1 = afterBalance1 - beforeBalance1;
    const increase2 = afterBalance2 - beforeBalance2;
    const increase3 = afterBalance3 - beforeBalance3;
    
    console.log("增加的余额:");
    console.log("- 快递员1:", ethers.formatEther(increase1), "ETH");
    console.log("- 快递员2:", ethers.formatEther(increase2), "ETH");
    console.log("- 快递员3:", ethers.formatEther(increase3), "ETH");
    
    // 由于快递员1获得高分，理论上应该获得更多奖励
    expect(increase1).to.be.gt(increase2);
    expect(increase1).to.be.gt(increase3);
    
    // 由于快递员2获得中等分数，理论上应该比快递员3获得更多奖励
    expect(increase2).to.be.gt(increase3);
    
    // 检查奖金池是否清零或接近于0
    const finalBonusPool = await collateralPool.getBonusPool();
    console.log("分成后奖金池余额:", ethers.formatEther(finalBonusPool), "ETH");
    expect(finalBonusPool).to.be.lt(ethers.parseEther("0.01"));
  });
}); 