const { expect } = require("chai");
const { ethers, upgrades } = require("hardhat");

describe("LogisticPlatform with CollateralPool", function () {
  let owner, sender, courier, receiver;
  let token, pool, platform;

  before(async () => {
    [owner, sender, courier, receiver] = await ethers.getSigners();

    // Deploy contracts
    const LogisticPlatform = await ethers.getContractFactory("LogisticPlatform");
    platform = await LogisticPlatform.deploy();
    await platform.waitForDeployment();

    const LogiToken = await ethers.getContractFactory("LogiToken");
    token = await upgrades.deployProxy(LogiToken, ["LogiToken", "LOGI"], {
        initializer: "initialize",
    });
    await token.waitForDeployment();

    const CollateralPool = await ethers.getContractFactory("CollateralPool");
    pool = await CollateralPool.deploy(
        token.target,
        platform.target,
        owner.address
    );
    await pool.waitForDeployment();

    // Setup contracts
    await platform.setCollateralPool(pool.target);
    await platform.setLogiToken(token.target);
    await token.setCollateralPool(pool.target);

    console.log(`    owner address: ${owner.address}`);
    console.log(`    sender address: ${sender.address}`);
    console.log(`    courier address: ${courier.address}`);
    console.log(`    receiver address: ${receiver.address}`);
    console.log(`    pool address: ${pool.target}`);
    console.log(`    platform address: ${platform.target}`);
    console.log(`    token address: ${token.target}`);

    pool.on("DebugInfo", (str, msg_sender) => {
        console.log(`${str}: ${msg_sender}`);
    });
    pool.on("Deposited", (msg_sender, msg_value) => {
        console.log(`deposited: ${msg_sender.toString()}  deposited value: ${msg_value.toString()}`);
    });
    pool.on("Redeemed", (msg_sender, amoung) => {
        console.log(`redeemed: ${msg_sender.toString()}  redeemed value: ${amoung.toString()}`);
    });
    platform.on("OrderStatusChanged", (_orderId, msg_sender, orderStatus) => {
        console.log(`order ${ _orderId } status changed: ${msg_sender.toString()}  order status: ${orderStatus.toString()}`);
    });
    token.on("TokensLocked", (user, amount) => {
        console.log(`tokens locked: ${user.toString()}  locked value: ${amount.toString()}`);
    })
    token.on("TokensFreed", (user, amount) => {
        console.log(`tokens freed: ${user.toString()}  unlocked value: ${amount.toString()}`);
    })
    token.on("TokensBurned", (user, amount) => {
        console.log(`tokens burned: ${user.toString()}  burned value: ${amount.toString()}`);
    })
    token.on("TokensTransferred", (from, to, amount) => {
        console.log(`tokens transferred: ${from.toString()}  to: ${to.toString()}  transferred value: ${amount.toString()}`);
    })
})

  it("should complete full order flow with collateral", async () => {
    // 1. Deposit collateral
    const depositAmount0 = ethers.parseEther("10");
    const depositAmount1 = ethers.parseEther("3");
    expect(await pool.connect(sender).deposit({ value: depositAmount0 })).to.changeEtherBalance(sender, -depositAmount0);
    
    // Verify initial balances
    expect(await token.getFreeBalance(sender.address)).to.equal(depositAmount0);

    // 2. Create order
    const orderValue = ethers.parseEther("5");
    const depositRequirement = ethers.parseEther("1");
    
    const orderParam = {
      coarsePickup: "Location A",
      coarseDropoff: "Location B",
      depositAmount: depositRequirement,
      orderValue: orderValue
    };

    const itemInfo = {
      volume: 1000,
      weight: 2000,
      description: "Test package"
    };

    await platform.connect(sender).createOrder(
      receiver.address,
      orderParam,
      itemInfo
    );

    // Verify locked balances after order creation
    expect(await token.getFreeBalance(sender.address)).to.equal(depositAmount0 - orderValue);
    expect(await token.getLockedBalance(sender.address)).to.equal(orderValue);

    // 3. Courier takes order
    // First deposit collateral for courier
    await pool.connect(courier).deposit({ value: depositAmount1 });
    await platform.connect(sender).confirmOrder(1, courier.address);
    await platform.connect(courier).takeOrder(1);

    // Verify courier's locked balance
    expect(await token.getFreeBalance(courier.address)).to.equal(depositAmount1 - depositRequirement);
    expect(await token.getLockedBalance(courier.address)).to.equal(depositRequirement);

    // 4. Complete delivery workflow
    await platform.connect(sender).sendDelivery(1);
    await platform.connect(courier).takeDelivery(1);
    await platform.connect(courier).compeleteDelivery(1);
    await platform.connect(receiver).receiveDelivery(1);
    await platform.connect(sender).finishOrder(1);

    // console.log("Sender balance:", await token.getFreeBalance(sender.address));
    // console.log("Courier balance:", await token.getFreeBalance(courier.address));

    // 推进区块时间
    // await ethers.provider.send("evm_increaseTime", [3600]);
    // await ethers.provider.send("evm_mine");

    // 5. Verify final balances
    const expectedCourierShare = orderValue * 800n / 1000n;
    const expectedPlatformShare = orderValue * 175n / 1000n;
    const expectedOwnerShare = orderValue * 25n / 1000n;

    // Sender balance
    expect(await token.getFreeBalance(sender.address)).to.equal(
      depositAmount0 - orderValue + orderValue - expectedCourierShare - expectedPlatformShare - expectedOwnerShare
    );
    expect(await token.getLockedBalance(sender.address)).to.equal(0);

    // Courier balance
    expect(await token.getFreeBalance(courier.address)).to.equal(
      depositAmount1 + expectedCourierShare // initial deposit + share
    );
    expect(await token.getLockedBalance(courier.address)).to.equal(0);

    // Platform owner balance
    expect(await token.balanceOf(owner.address)).to.equal(expectedPlatformShare);
    
    // Collateral pool balance
    expect(await token.balanceOf(pool.target)).to.equal(expectedOwnerShare);

    // 使用 setTimeout 封装成 Promise
    const sleep = (ms) => new Promise(resolve => setTimeout(resolve, ms));
    await sleep(2000); 
  });
});