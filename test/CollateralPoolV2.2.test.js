const { expect } = require("chai");
const { ethers, upgrades } = require("hardhat");

describe("CollateralPool - 基础功能测试", function () {
  let token, pool;
  let owner, user;

  before(async function () {
    [owner, user] = await ethers.getSigners();

    // 部署代币合约
    const LogiToken = await ethers.getContractFactory("LogiToken");
    token = await upgrades.deployProxy(LogiToken, ["LogiToken", "LOGI"], {
        initializer: "initialize",
    });
    await token.waitForDeployment();

    // 部署抵押池合约
    const CollateralPool = await ethers.getContractFactory("CollateralPool");
    pool = await CollateralPool.deploy(
      await token.getAddress(),
      owner.address
    );

    // 设置代币合约的抵押池地址
    await token.setCollateralPool(pool.address);
    
    // 转移所有权（如果需要）
    await token.transferOwnership(pool.address);
  });

  it("抵押与销毁代币", async () => {
    const depositAmount = ethers.parseEther("1.0");
    
    // 执行存款
    await expect(
      pool.connect(user).deposit({ value: depositAmount })
    ).to.changeEtherBalance(user, -depositAmount);

    // 验证状态
    expect(await pool.freeCollateral(user.address)).to.equal(depositAmount);
    expect(await token.balanceOf(user.address)).to.equal(depositAmount);
  });
});