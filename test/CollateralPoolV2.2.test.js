const { expect } = require("chai");
const { ethers, upgrades } = require("hardhat");

describe("CollateralPool - 基础功能测试", function () {
  let token, pool;
  let owner, user;

  beforeEach(async function () {
    [owner, user] = await ethers.getSigners();

    // 部署代币合约
    // 获取LogiToken合约工厂实例
    const LogiToken = await ethers.getContractFactory("LogiToken");
    // 使用可升级代理模式部署LogiToken合约，传入代币名称和符号
    token = await upgrades.deployProxy(LogiToken, ["LogiToken", "LOGI"], {
        initializer: "initialize",  // 指定初始化函数名
    });
    // 等待合约部署完成
    await token.waitForDeployment();

    token.on("DebugLog", (val0, val1, event) => {
        console.log(`[实时监听] 地址 ${event.args} 转账详情:
    可用余额: ${val0.toString()}
    转账金额: ${val1.toString()}`);
    });

    // 部署抵押池合约
    const CollateralPool = await ethers.getContractFactory("CollateralPool");
    pool = await CollateralPool.deploy(
      token.target,
      owner.address
    );

    // 设置代币合约的抵押池地址
    await token.setCollateralPool(pool.target);
    
    // 转移所有权（如果需要）
    await token.transferTokenOwnership(pool.target);
  });

  it("抵押与销毁代币", async () => {
    const depositAmount = 800;
    
    // 执行存款
    await expect(pool.connect(user).deposit({ value: depositAmount })).to.changeEtherBalance(user, -depositAmount);

    // 验证状态
    expect(await token.balanceOf(user)).to.equal(depositAmount);
    expect(await token.getFreeBalance(user)).to.equal(depositAmount);

    const redeemAmount = 425;
    expect(await token.balanceOf(user.address)).to.gte(redeemAmount);
    await expect(pool.connect(user).redeem(redeemAmount)).to.changeEtherBalance(user, redeemAmount)

    restDepositAmount = depositAmount - redeemAmount;
    expect(await token.balanceOf(user.address)).to.equal(restDepositAmount);
    expect(await token.getFreeBalance(user.address)).to.equal(restDepositAmount);
  });

  it("多次deposit一次redeem", async () => {
    const depositAmount0 = 5000;
    const depositAmount1 = 400;
    const depositAmount2 = 300;
    const redeemAmount = 5500;
    restDepositAmount = depositAmount0 + depositAmount1 + depositAmount2 - redeemAmount;

    await expect(pool.connect(user).deposit({ value: depositAmount0 })).to.changeEtherBalance(user, -depositAmount0);
    expect(await token.getFreeBalance(user.address)).to.equal(depositAmount0);
    expect(await token.balanceOf(user.address)).to.equal(depositAmount0);

    await expect(pool.connect(user).deposit({ value: depositAmount1 })).to.changeEtherBalance(user, -depositAmount1);
    expect(await token.getFreeBalance(user.address)).to.equal(depositAmount0 + depositAmount1);
    expect(await token.balanceOf(user.address)).to.equal(depositAmount0 + depositAmount1);

    await expect(pool.connect(user).deposit({ value: depositAmount2 })).to.changeEtherBalance(user, -depositAmount2);
    expect(await token.getFreeBalance(user.address)).to.equal(depositAmount0 + depositAmount1 + depositAmount2);
    expect(await token.balanceOf(user.address)).to.equal(depositAmount0 + depositAmount1 + depositAmount2);

    expect(await token.balanceOf(user.address)).to.gte(redeemAmount);
    expect(await token.getFreeBalance(user.address)).to.equal(depositAmount0 + depositAmount1 + depositAmount2)
    await expect(pool.connect(user).redeem(redeemAmount)).to.changeEtherBalance(user, redeemAmount);

    expect(await token.getFreeBalance(user.address)).to.equal(restDepositAmount);
    expect(await token.balanceOf(user.address)).to.equal(restDepositAmount);
  });

  it("多次deposit多次redeem", async () => {
    const depositAmount0 = 5000;
    const redeemAmount0 = 2500;
    const depositAmount1 = 1200;
    const depositAmount2 = 1700;
    const redeemAmount1 = 5400;
    const depositAmount3 = 3000;

    await expect(pool.connect(user).deposit({ value: depositAmount0 })).to.changeEtherBalance(user, -depositAmount0);
    expect(await token.getFreeBalance(user.address)).to.equal(depositAmount0);
    expect(await token.balanceOf(user.address)).to.equal(depositAmount0);

    await expect(pool.connect(user).redeem(redeemAmount0)).to.changeEtherBalance(user, redeemAmount0);
    expect(await token.getFreeBalance(user.address)).to.equal(depositAmount0 - redeemAmount0);
    expect(await token.balanceOf(user.address)).to.equal(depositAmount0 - redeemAmount0);
    
    await expect(pool.connect(user).deposit({ value: depositAmount1 })).to.changeEtherBalance(user, -depositAmount1);
    expect(await token.getFreeBalance(user.address)).to.equal(depositAmount0 - redeemAmount0 + depositAmount1);
    expect(await token.balanceOf(user.address)).to.equal(depositAmount0 - redeemAmount0 + depositAmount1);
    
    await expect(pool.connect(user).deposit({ value: depositAmount2 })).to.changeEtherBalance(user, -depositAmount2);
    expect(await token.getFreeBalance(user.address)).to.equal(depositAmount0 - redeemAmount0 + depositAmount1 + depositAmount2);
    expect(await token.balanceOf(user.address)).to.equal(depositAmount0 - redeemAmount0 + depositAmount1 + depositAmount2);

    await expect(pool.connect(user).redeem(redeemAmount1)).to.changeEtherBalance(user, redeemAmount1);
    expect(await token.getFreeBalance(user.address)).to.equal(depositAmount0 - redeemAmount0 + depositAmount1 + depositAmount2 - redeemAmount1);
    expect(await token.balanceOf(user.address)).to.equal(depositAmount0 - redeemAmount0 + depositAmount1 + depositAmount2 - redeemAmount1);

    await expect(pool.connect(user).deposit({ value: depositAmount3 })).to.changeEtherBalance(user, -depositAmount3);
    expect(await token.getFreeBalance(user.address)).to.equal(depositAmount0 - redeemAmount0 + depositAmount1 + depositAmount2 - redeemAmount1 + depositAmount3);
    expect(await token.balanceOf(user.address)).to.equal(depositAmount0 - redeemAmount0 + depositAmount1 + depositAmount2 - redeemAmount1 + depositAmount3);
  });

  it("redeem剩余不足", async () => {
    const depositAmount0 = 1000;
    const lockAmount0 = 300;
    const redeemAmount0 = 800;
    const freeAmount0 = 200;
    const redeemAmount1 = 800;

    await expect(pool.connect(user).deposit({ value: depositAmount0 })).to.changeEtherBalance(user, -depositAmount0);
    expect(await token.getFreeBalance(user.address)).to.equal(depositAmount0);
    expect(await token.balanceOf(user.address)).to.equal(depositAmount0);

    await pool.connect(user).lockToken(user.address, lockAmount0);
    expect(await token.getLockedBalance(user.address)).to.equal(lockAmount0);
    expect(await token.getFreeBalance(user.address)).to.equal(depositAmount0 - lockAmount0);
    expect(await token.balanceOf(user.address)).to.equal(depositAmount0);

    // expect(await pool.connect(user).redeem(redeemAmount0)).to.be.revertedWith("Insufficient free tokens");

    await pool.connect(user).freeToken(user.address, freeAmount0);
    expect(await token.getLockedBalance(user.address)).to.equal(lockAmount0 - freeAmount0);
    expect(await token.getFreeBalance(user.address)).to.equal(depositAmount0 - lockAmount0 + freeAmount0);
    expect(await token.balanceOf(user.address)).to.equal(depositAmount0);

    await pool.connect(user).redeem(redeemAmount1);
    expect(await token.getLockedBalance(user.address)).to.equal(lockAmount0 - freeAmount0);
    expect(await token.getFreeBalance(user.address)).to.equal(depositAmount0 - lockAmount0 + freeAmount0 - redeemAmount1);
    expect(await token.balanceOf(user.address)).to.equal(depositAmount0 - redeemAmount1);
  });
});