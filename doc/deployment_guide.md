# 区块链物流平台部署与演示指南

本文档提供区块链物流平台的部署流程和演示步骤，帮助开发者和用户快速上手使用系统。

## 环境准备

### 软件要求
- Node.js (v16.0.0+)
- npm (v8.0.0+)
- Hardhat (v2.12.0+)
- MetaMask 浏览器扩展
- Git

### 开发网络
- 本地开发：Hardhat Network
- 测试网部署：Goerli/Sepolia 测试网
- 主网部署：以太坊主网

## 本地开发环境搭建

### 1. 克隆代码仓库

```bash
git clone https://github.com/your-username/IS6200_Logistics.git
cd IS6200_Logistics
```

### 2. 安装依赖

```bash
npm install
```

### 3. 编译智能合约

```bash
npx hardhat compile
```

### 4. 运行测试

```bash
npx hardhat test
```

确保所有测试通过，以验证合约功能正常。

## 本地网络部署

### 1. 启动本地节点

```bash
npx hardhat node
```

这将启动一个本地以太坊节点，并创建测试账户。

### 2. 部署合约到本地网络

打开新的终端窗口，运行：

```bash
npx hardhat run scripts/deploy.js --network localhost
```

部署脚本将依次部署 LogiToken、CollateralPool 和 LogisticPlatform 合约，并设置它们之间的关联关系。

### 3. 记录合约地址

部署完成后，脚本会输出所有合约的地址，例如：

```
LogiToken deployed to: 0x5FbDB2315678afecb367f032d93F642f64180aa3
CollateralPool deployed to: 0xe7f1725E7734CE288F8367e1Bb143E90bb3F0512
LogisticPlatform deployed to: 0x9fE46736679d2D9a65F0992F2272dE9f3c7fa6e0
```

请记录这些地址，后续交互时需要使用。

## 测试网部署

### 1. 配置环境变量

创建 `.env` 文件并添加以下内容：

```
PRIVATE_KEY=your_private_key_here
ETHERSCAN_API_KEY=your_etherscan_api_key_here
GOERLI_URL=https://goerli.infura.io/v3/your_infura_project_id
```

### 2. 修改部署配置

编辑 `hardhat.config.js` 文件，确保包含测试网配置：

```javascript
require("@nomicfoundation/hardhat-toolbox");
require("dotenv").config();

module.exports = {
  solidity: "0.8.20",
  networks: {
    goerli: {
      url: process.env.GOERLI_URL,
      accounts: [process.env.PRIVATE_KEY]
    }
  },
  etherscan: {
    apiKey: process.env.ETHERSCAN_API_KEY
  }
};
```

### 3. 部署到测试网

```bash
npx hardhat run scripts/deploy.js --network goerli
```

### 4. 验证合约

```bash
npx hardhat verify --network goerli LOGI_TOKEN_ADDRESS "LogiToken" "LOGI"
npx hardhat verify --network goerli COLLATERAL_POOL_ADDRESS LOGI_TOKEN_ADDRESS PLATFORM_ADDRESS
npx hardhat verify --network goerli LOGISTIC_PLATFORM_ADDRESS
```

## 前端应用部署（如有）

如果项目包含前端应用，可以按以下步骤配置和部署：

### 1. 更新合约地址

编辑前端应用中的配置文件，更新合约地址为最新部署的地址。

### 2. 构建前端应用

```bash
cd frontend
npm install
npm run build
```

### 3. 部署前端

可以将构建好的前端应用部署到 IPFS、Netlify、Vercel 等平台。

## 使用平台指南

本节提供平台主要功能的使用方法，以MetaMask和控制台交互为例。

### 1. 连接钱包

1. 打开MetaMask
2. 切换到相应网络（本地开发/测试网）
3. 连接到应用

### 2. 获取平台代币

#### 使用控制台：

```javascript
// 获取合约实例
const collateralPool = await ethers.getContractAt("CollateralPool", "COLLATERAL_POOL_ADDRESS");

// 存入ETH获取代币
await collateralPool.deposit({value: ethers.utils.parseEther("1.0")});
```

#### 使用前端（如有）：
1. 导航到"存款"页面
2. 输入ETH金额
3. 点击"存款"按钮
4. 确认MetaMask交易

### 3. 创建订单

#### 使用控制台：

```javascript
// 获取合约实例
const logisticPlatform = await ethers.getContractAt("LogisticPlatform", "LOGISTIC_PLATFORM_ADDRESS");

// 创建订单参数
const orderParam = {
  coarsePickup: "起始地",
  coarseDropoff: "目的地",
  depositAmount: ethers.utils.parseEther("0.1"),
  orderValue: ethers.utils.parseEther("0.5")
};

const itemInfo = {
  volume: 10000,  // 10000立方厘米
  weight: 5000,   // 5000克
  description: "物品描述"
};

// 创建订单
await logisticPlatform.createOrder(
  "RECEIVER_ADDRESS",
  orderParam,
  itemInfo
);
```

#### 使用前端（如有）：
1. 导航到"创建订单"页面
2. 填写订单表单
3. 点击"创建"按钮
4. 确认MetaMask交易

### 4. 接受订单

#### 使用控制台：

```javascript
// 获取可用订单
const availableOrders = await logisticPlatform.getAvailableOrders();
console.log("Available orders:", availableOrders);

// 接受指定订单
await logisticPlatform.acceptOrder(ORDER_ID);
```

#### 使用前端（如有）：
1. 导航到"可用订单"页面
2. 查看订单详情
3. 点击"接受"按钮
4. 确认MetaMask交易

### 5. 订单状态更新

以下是订单生命周期中的状态更新操作：

```javascript
// 发送方确认订单
await logisticPlatform.confirmOrderBySender(ORDER_ID);

// 发送方确认交付物品
await logisticPlatform.confirmDeliveryBySender(ORDER_ID);

// 配送员开始运输
await logisticPlatform.startTransit(ORDER_ID);

// 配送员确认送达
await logisticPlatform.confirmDeliveryByCourier(ORDER_ID);

// 接收方确认收货
await logisticPlatform.confirmReceipt(ORDER_ID);

// 接收方评价
await logisticPlatform.rateOrder(ORDER_ID, 9, "评价内容");
```

### 6. 赎回代币

完成订单后，配送员可以将获得的LogiToken赎回为ETH：

```javascript
await collateralPool.redeem(ethers.utils.parseEther("0.5"));
```

## 演示脚本

以下是一个完整的演示脚本，可用于展示平台的主要功能：

```javascript
// 演示脚本 - 完整订单流程
async function demoCompleteOrderFlow() {
  console.log("=== 开始物流平台演示 ===");
  
  // 获取账户
  const [owner, sender, courier, receiver] = await ethers.getSigners();
  console.log(`发送方: ${sender.address}`);
  console.log(`配送员: ${courier.address}`);
  console.log(`接收方: ${receiver.address}`);
  
  // 获取合约实例
  const logiToken = await ethers.getContractAt("LogiToken", LOGI_TOKEN_ADDRESS);
  const collateralPool = await ethers.getContractAt("CollateralPool", COLLATERAL_POOL_ADDRESS);
  const logisticPlatform = await ethers.getContractAt("LogisticPlatform", LOGISTIC_PLATFORM_ADDRESS);
  
  // 1. 发送方获取代币
  console.log("\n1. 发送方存入ETH获取代币");
  await collateralPool.connect(sender).deposit({value: ethers.utils.parseEther("1.0")});
  
  const senderBalance = await logiToken.balanceOf(sender.address);
  console.log(`发送方代币余额: ${ethers.utils.formatEther(senderBalance)} LOGI`);
  
  // 2. 创建订单
  console.log("\n2. 发送方创建订单");
  const orderParam = {
    coarsePickup: "北京市海淀区",
    coarseDropoff: "上海市浦东新区",
    depositAmount: ethers.utils.parseEther("0.1"),
    orderValue: ethers.utils.parseEther("0.5")
  };
  
  const itemInfo = {
    volume: 10000,
    weight: 5000,
    description: "电子产品，小心轻放"
  };
  
  await logisticPlatform.connect(sender).createOrder(
    receiver.address,
    orderParam,
    itemInfo
  );
  
  // 获取订单ID
  const orderCounter = await logisticPlatform.orderCounter();
  const orderId = orderCounter;
  console.log(`订单创建成功，ID: ${orderId}`);
  
  // 3. 配送员接单
  console.log("\n3. 配送员接单");
  await logisticPlatform.connect(courier).acceptOrder(orderId);
  
  // 4. 发送方确认交付
  console.log("\n4. 发送方确认物品交付");
  await logisticPlatform.connect(sender).confirmDeliveryBySender(orderId);
  
  // 5. 配送员开始运输
  console.log("\n5. 配送员开始运输");
  await logisticPlatform.connect(courier).startTransit(orderId);
  
  // 6. 配送员确认送达
  console.log("\n6. 配送员确认送达");
  await logisticPlatform.connect(courier).confirmDeliveryByCourier(orderId);
  
  // 7. 接收方确认收货
  console.log("\n7. 接收方确认收货");
  await logisticPlatform.connect(receiver).confirmReceipt(orderId);
  
  // 8. 接收方评价
  console.log("\n8. 接收方评价");
  await logisticPlatform.connect(receiver).rateOrder(orderId, 10, "服务非常好，物品完好无损");
  
  // 9. 查看结果
  console.log("\n9. 查看结算结果");
  const courierBalance = await logiToken.balanceOf(courier.address);
  console.log(`配送员获得代币: ${ethers.utils.formatEther(courierBalance)} LOGI`);
  
  const orderInfo = await logisticPlatform.orders(orderId);
  console.log(`订单状态: ${orderInfo.status}`);
  
  // 10. 配送员赎回代币
  console.log("\n10. 配送员赎回代币");
  await collateralPool.connect(courier).redeem(courierBalance);
  
  console.log("=== 演示完成 ===");
}

// 运行演示
demoCompleteOrderFlow()
  .then(() => process.exit(0))
  .catch((error) => {
    console.error(error);
    process.exit(1);
  });
```

## 故障排除

### 常见问题与解决方案

1. **合约交互失败**
   - 检查Gas设置是否足够
   - 确认账户有足够的ETH
   - 验证合约地址是否正确

2. **代币余额不足**
   - 确保在创建订单前已存入足够的ETH获取代币
   - 检查代币是否被锁定在其他订单中

3. **权限错误**
   - 确认使用正确的账户调用函数
   - 检查合约间的权限设置是否正确

4. **合约升级问题**
   - 确保使用兼容的新合约版本
   - 验证所有状态变量在升级过程中得到保留

## 安全注意事项

1. **私钥安全**
   - 永远不要共享或暴露私钥
   - 使用环境变量存储敏感信息

2. **合约交互**
   - 在交易前检查参数是否正确
   - 对于大额交易，考虑先在测试网验证

3. **代码审计**
   - 在主网部署前进行安全审计
   - 考虑使用形式化验证工具

4. **监控**
   - 定期监控合约状态和交易
   - 设置异常活动警报

## 联系与支持

如有问题或需要帮助，请通过以下方式联系我们：
- GitHub Issues：[创建问题](https://github.com/your-username/IS6200_Logistics/issues)
- 电子邮件：support@example.com 