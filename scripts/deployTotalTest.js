const { ethers, upgrades, network } = require("hardhat");
const fs = require("fs");
const { platform } = require("os");

/*
我现在希望模拟一个有30个用户利用物流网络进行收发货的情况。具体收发货接收的参数可见LogisticPlatform。 
我们现在需要如下设置： 
1. 模拟一个7个城市间的路网（请使用中国的城市做模拟），这应该可以用一个图进行存储，这是一个无向有权图，且存在途径点的概念 用户则有如下属性需要设定：
2. 模拟用户
  用户的类型：在收货，发货，运货之间都有可能选择还是都会选择 
  用户所在的城市：根据图 
  用户发货的概率：每个用户每个时间发货的可能性都不同 
  用户发货的类型：体积与重量和description是随机生成的 
  用户订单的价格：是一个距离，体积，大小的函数 
  用户的移动：路线和频率 
  用户下单的概率: 一个随机的
  用户接单的概率：与其当前路线，订单的价格有关 
  用户路上花费的时间：取决于路线的权重和以及每个用户的随机延误（每个用户不同） 
  用户评分的态度：随机的函数，会影响评分高低 
  用户的评分：取决于运输时间和用户评分的态度

现在我希望根据上述叙述，生成2个数据结构，一个是路网图，可以是一个以邻接表表示的图，一个是用户属性，包含30个用户，key从"Account #1" ~ "Account #30"
*/

// 0. 定义概率调节因子等常数
const ORDER_GENERATE_ADJ_FAC = 0.1;
const ACCOUNT_NUM = 100;
const TOTAL_FRAMES = 24 * 28;  // 模拟一周（24小时×7天）
const DEBUG_BOOL = false;

// 1. 中国七大城市路网图（邻接表表示）
const cityGraph = {
  // 节点列表（城市及坐标）
  nodes: {
    "北京": { lat: 39.9042, lng: 116.4074 },
    "上海": { lat: 31.2304, lng: 121.4737 },
    "广州": { lat: 23.1291, lng: 113.2644 },
    "武汉": { lat: 30.5928, lng: 114.3052 },
    "成都": { lat: 30.5728, lng: 104.0668 },
    "西安": { lat: 34.3416, lng: 108.9398 },
    "沈阳": { lat: 41.8057, lng: 123.4315 }
  },

  // 邻接表（权重单位为小时）
  adjacencyList: {
    "北京": [
      { city: "上海", weight: 4.5 },   // 高铁时间
      { city: "沈阳", weight: 2.5 },
      { city: "武汉", weight: 5.0 }
    ],
    "上海": [
      { city: "北京", weight: 4.5 },
      { city: "武汉", weight: 3.0 },
      { city: "广州", weight: 6.0 }
    ],
    "广州": [
      { city: "武汉", weight: 4.0 },
      { city: "成都", weight: 8.0 }
    ],
    "武汉": [
      { city: "北京", weight: 5.0 },
      { city: "上海", weight: 3.0 },
      { city: "广州", weight: 4.0 },
      { city: "西安", weight: 6.0 }
    ],
    "成都": [
      { city: "广州", weight: 8.0 },
      { city: "西安", weight: 5.0 }
    ],
    "西安": [
      { city: "武汉", weight: 6.0 },
      { city: "成都", weight: 5.0 },
      { city: "沈阳", weight: 7.0 }
    ],
    "沈阳": [
      { city: "北京", weight: 2.5 },
      { city: "西安", weight: 7.0 }
    ]
  }
};

// 2. ACCOUNT_NUM个用户属性数据集
const accounts = Array.from({length: ACCOUNT_NUM}, (_, i) => {
  const cities = Object.keys(cityGraph.nodes);
  const baseCity = cities[Math.floor(Math.random() * cities.length)];
  const baseCapacity = Math.abs(gaussianRandom(20, 10)); // 基础能力系数
  const basePatience = Math.abs(gaussianRandom(36, 24)); // 基准忍耐时间（小时）
  
  return {
    // 基本属性
    id: `Account #${i+1}`,
    type: getRandomUserType(),       // 用户类型组合
    currentCity: baseCity,          // 当前所在城市
    
    // 发货相关属性
    shippingProbability: Math.random() * 0.4 + 0.05, // 发货概率 10%-90%
    shippingParams: {
      volume: randomInt(100, 5000),   // 体积 500-5000 cm³
      weight: randomInt(100, 5000), // 重量 200g-5 kg
      description: generateDescription() // 随机描述
    },
    shippingRoute: generateRandomRoute(baseCity),

    // 新增订单忍耐度属性
    orderPatience: {
      baseHours: Math.round(basePatience),                  // 基准忍耐时间（小时）
      maxCancelProb: Math.min(Math.random() * 0.8 + 0.2, 1), // 最大取消概率20%-100%
      decayRate: Math.random() * 0.1 + 0.05,                // 每小时取消概率增长率5%-15%
      urgencyFactors: {                                      // 紧急程度影响因子
        description: {                                      // 根据货物描述的影响
          '加急': 1.5,
          '普通': 1.0,
          '易碎': 0.8
        },
        price: p => Math.min(1, p / 1000)                   // 价格影响因子（每1000元降低10%概率）
      }
    },
    
    // 订单定价策略
    priceFunction: (distance, volume, weight) => {
      return distance * 0.5 + volume * 0.01 + weight * 0.005; // 示例定价公式
    },
    
    // 移动模式
    movement: {
      route: generateRandomRoute(baseCity), // 随机移动路线
      frequency: randomInt(1, 7)           // 每周移动次数 1-7
    },
    
    // 接单行为
    acceptProbability: (orderPrice, routeMatch) => {
      const base = orderPrice / 100;       // 价格因素
      return routeMatch ? base * 1.5 : base // 路线匹配时概率提高50%
    },
    
    // 运输时间参数
    transitTime: {
      baseMultiplier: 1.0 + Math.random(), // 1.0-2.0倍基础时间
      delayFactor: Math.random() * 0.3     // 0-30%随机延误
    },
    
    // 评分行为
    ratingBehavior: {
      strictness: Math.random(),          // 0-1严格程度
      timeSensitivity: Math.random()      // 0-1时间敏感性
    },

    // 新增载荷能力属性
    capacity: {
      maxVolume: Math.round(baseCapacity * 1000),    // 最大体积承载能力 cm³
      maxWeight: Math.round(baseCapacity * 100),     // 最大重量承载能力 kg
      currentVolume: 0,                              // 当前已用体积
      currentWeight: 0                               // 当前已用重量
    },
    
    // 新增运输策略
    transportStrategy: {
      preferCombined: Math.random() > 0.3,          // 70%概率偏好合并运输
      riskTolerance: Math.random()                  // 风险承受能力 0-1
    },

    moveCount: 0, // 新增移动计数器
    status: 'idle',          // 当前状态：idle(静止)/moving(移动)
    currentRoute: null,      // 当前移动路线信息
    moveHistory: []          // 移动历史记录
  };
});

// 3. 新增订单数据结构和全部orders
let globalOrderId = 1;
const allOrders = [];
const orderStats = {
  totalCreated: 0,
  completed: 0,
  canceled: 0,
  get completionRate() {
    return this.completed / this.totalCreated || 0;
  }
};

// 工具函数
function getRandomUserType() {
  const types = ['shipper', 'courier'];
  return types.filter(() => Math.random() > 0.5); // 可能多选
}

function generateRandomRoute(baseCity) {
  const route = [baseCity];
  // 生成包含2-4个城市的随机路线
  for (let i = 0; i < randomInt(2,4); i++) {
    const connections = cityGraph.adjacencyList[route[route.length-1]];
    route.push(connections[randomInt(0, connections.length-1)].city);
  }
  return route;
}

function generateDescription() {
  const items = ['电子产品', '服装', '食品', '家具', '医疗器械', '书籍'];
  const adj = ['精密', '易碎', '普通', '加急', '温控'];
  return `${adj[randomInt(0,4)]}${items[randomInt(0,5)]}`;
}

function randomInt(min, max) {
  return Math.floor(Math.random() * (max - min + 1)) + min;
}

// 高斯分布随机数生成函数
function gaussianRandom(mean=0, stdev=1) {
  const u = 1 - Math.random();
  const v = Math.random();
  const z = Math.sqrt(-2.0 * Math.log(u)) * Math.cos(2.0 * Math.PI * v);
  return z * stdev + mean;
}

function isRouteMatch(courier, from, to) {
  const route = courier.movement.route;
  return route.includes(from) && route.includes(to) && 
         route.indexOf(from) < route.indexOf(to);
}

function calculateBidProbability(courier, order) {
  const baseProb = courier.acceptProbability(order.price, true);
  const loadFactor = 1 - (courier.capacity.currentVolume / courier.capacity.maxVolume);
  return baseProb * loadFactor;
}

function calculateETAToPickup(courier, pickupCity) {
  const currentIndex = courier.movement.route.indexOf(courier.currentCity);
  const targetIndex = courier.movement.route.indexOf(pickupCity);
  
  if (currentIndex === -1 || targetIndex === -1) return Infinity;
  return targetIndex > currentIndex ? 
    targetIndex - currentIndex : 
    courier.movement.route.length - currentIndex + targetIndex;
}

// 涉及主流程中的函数
// 初始化用户状态
function initializeUserStates() {
  accounts.forEach(user => {
    user.currentCity = user.movement.route[0]; // 重置到初始位置
  });
}

// 更新用户位置
function updateUserLocations(frame) {
  accounts.forEach(user => {
    if (user.status === 'idle') {
      // 检查是否需要启动移动
      if (shouldStartMoving(user, frame)) {
        startMoving(user, frame);
      }
    } else if (user.status === 'moving') {
      // 更新移动进度
      updateMoving(user, frame)
      
      // 到达目的地
      if (user.currentRoute.cityPointer == user.currentRoute.routeLength - 1) {
        completeMovement(user, frame);
      }
    }
  });
}

// 判断是否应该开始移动
function shouldStartMoving(user, frame) {
  // 根据移动频率计算触发条件（每周移动N次 ≈ 每天移动N/7次）
  const dailyFrequency = user.movement.frequency / 7;
  const moveChance = dailyFrequency / 24 * 4; // 每个时间帧的概率，乘4是因为在移动时并不判断是否移动
  
  return Math.random() < moveChance;
}

// 开始移动
function startMoving(user, frame) {
  const route = generateRandomRoute(user.currentCity);
  const target = route[route.length - 1];
  
  user.status = 'moving';
  user.currentRoute = {
    cityPointer: 0,
    route: route,
    from: user.currentCity,
    to: target,
    startedAt: frame,
    remainingFrames: null,
    routeLength: route.length,
  };
  if (DEBUG_BOOL) {
    console.log(`${user.id} 开始从 ${user.currentCity} 向 ${target} 的路径`);
  }
}

function updateMoving(user, frame) {
  cityPointer = user.currentRoute.cityPointer;
  route = user.currentRoute.route;
  if (user.currentRoute.remainingFrames == null) {
    const currentCity = route[cityPointer];
    const nextCity = route[cityPointer + 1];
    adjList = cityGraph.adjacencyList[currentCity];
    const weight = adjList.find(city => city.city === nextCity).weight;
    const baseFrames = Math.ceil(weight);
    const delayFrames = Math.floor(baseFrames * user.transitTime.delayFactor * Math.random());
    user.currentRoute.remainingFrames = totalFrames = baseFrames + delayFrames - 1;
    if (DEBUG_BOOL) {
      console.log(`${user.id} 开始从 ${route[0]} 向 ${route[route.length-1]} 途径 ${nextCity} 的路径, 预计需要 ${totalFrames} 个时间帧`);
    }
  } else {
    user.currentRoute.remainingFrames--;
  }
  if (user.currentRoute.remainingFrames <= 0) {
    user.currentRoute.cityPointer++;
    user.currentCity = route[user.currentRoute.cityPointer]
  }
}

// 完成移动
function completeMovement(user, frame) {
  user.status = 'idle';
  user.currentCity = user.currentRoute.to;
  user.moveCount++;
  
  user.moveHistory.push({
    from: user.currentRoute.from,
    to: user.currentRoute.to,
    startFrame: user.currentRoute.startedAt,
    endFrame: frame,
    duration: frame - user.currentRoute.startedAt
  });
  
  if (DEBUG_BOOL) {
    console.log(`${user.id} 抵达 ${user.currentCity}，实际用时 ${frame - user.currentRoute.startedAt} 个时间帧`);
  };
  user.currentRoute = null;
}

async function generateOrders(frame, accountMap, pool) {
  for (const user of accounts) { // Replace forEach with for...of
    if (!user.type.includes('shipper')) continue;

    const hour = frame % 24;
    const timeFactor = 0.5 + 0.5 * Math.cos((hour - 12) * Math.PI / 12);
    const orderProb = user.shippingProbability * timeFactor * ORDER_GENERATE_ADJ_FAC;

    if (Math.random() < orderProb) {
      const order = await createOrder(user, frame, accountMap, pool);
      allOrders.push(order);
      orderStats.totalCreated++;
      if (DEBUG_BOOL) {
        console.log(`生成订单: ${order.id} 从 ${order.from} 到 ${order.to}`);
      };
    }
  }
}

// 创建订单详情
async function createOrder(user, frame, accountMap, platform) {
  // 随机选择目的地
  const connectedCities = cityGraph.adjacencyList[user.currentCity];
  const destination = connectedCities[Math.floor(Math.random() * connectedCities.length)].city;

  // 寻找base在destination的用户作为接收者
  const potentialReceivers = accounts.filter(acc => 
    acc.currentCity === destination && 
    acc.id !== user.id // 排除自己
  );
  
  // 如果找不到则使用默认账户
  const receiverAccount = potentialReceivers[Math.floor(Math.random() * potentialReceivers.length)];

  // 获取对应的以太坊账户
  const sender = accountMap[user.id];
  const receiver = accountMap[receiverAccount.id];

  // 计算运输距离
  const distance = getCityDistance(user.currentCity, destination);
  const price = calculateOrderPrice(user, distance);

  const orderParam = {
    coarsePickup: user.currentCity,
    coarseDropoff: destination,
    depositAmount: 0,
    orderValue: price
  };

  const itemInfo = {
    volume: user.shippingParams.volume,
    weight: user.shippingParams.weight,
    description: user.shippingParams.description
  };

  const tx = await platform.connect(sender).createOrder(
    receiver.address,
    orderParam,
    itemInfo
  );
  const receipt = await tx.wait();

  // Parse from transaction receipt logs
  const event = receipt.logs.find(log => log.fragment?.name === 'OrderCreated');
  const [orderId] = event.args;

  return {
    id: orderId,
    frame: frame + 1,
    user: user.id,
    receiver: receiverAccount.id,
    from: user.currentCity,
    to: destination,
    distance: distance,
    goods: {
      volume: user.shippingParams.volume,
      weight: user.shippingParams.weight,
      description: user.shippingParams.description
    },
    price: price,
    status: "created", // 状态机: created -> bid -> assigned -> accepted -> in_transit -> completed
    bids: [],          // 承运商投标记录
    assignedCourier: null,
    timeline: {
      created: frame,
      bidStart: null,
      assignedAt: null,
      acceptedAt: null,
      pickupAt: null,
      completedAt: null
    }
  };
}

// 1. 处理投标流程
function processBiddingOrders(frame) {
  allOrders.forEach(order => {
    if (order.status !== 'created') return;
    
    accounts.forEach(courier => {
      if (!courier.type.includes('courier')) return;  // 运输中途亦可接单
          
      // 检查路线匹配和负载能力
      const routeMatch = isRouteMatch(courier, order.from, order.to);
      const hasCapacity = courier.capacity.currentVolume + order.goods.volume <= courier.capacity.maxVolume &&
                         courier.capacity.currentWeight + order.goods.weight <= courier.capacity.maxWeight;
      
      if (routeMatch && hasCapacity) {
        const bidProb = calculateBidProbability(courier, order);
        if (Math.random() < bidProb) {
          order.bids.push({
            courier: courier.id,
            bidAt: frame,
            eta: calculateETAToPickup(courier, order.from)
          });
          if (DEBUG_BOOL) {
            console.log(`${courier.id} 对订单 ${order.id} 投标，预计 ${frame + order.bids[0].eta} 时间帧到达`);
          }
        }
      }
    });
    
    if (order.bids.length > 0) {
      order.status = 'bid';
      order.timeline.bidStart = frame;
    }
  });
}

// 2. 处理订单委派
async function processOrderAssignment(frame, accountMap, platform) {
  for (order of allOrders.filter(o => o.status === 'bid')) {
    // 选择最早到达的承运商
    const selectedBid = order.bids.reduce((prev, current) => 
      (current.eta < prev.eta) ? current : prev
    );
    
    order.assignedCourier = selectedBid.courier;
    order.status = 'assigned';
    const sender = accountMap[order.user];
    const courier = accountMap[order.assignedCourier];
    await platform.connect(sender).confirmOrder(order.id, courier);
    await platform.connect(courier).takeOrder(order.id);
    order.timeline.assignedAt = frame;
    if (DEBUG_BOOL) {
      console.log(`订单 ${order.id} 委派给 ${selectedBid.courier}`);
    }
  }
}

// 3. 处理取货
async function processOrderPickup(frame, accountMap, platform) {
  for (order of allOrders.filter(o => o.status === 'assigned')) {
    const courier = accounts.find(c => c.id === order.assignedCourier);
    
    // 检查是否到达取货城市
    if (courier.currentCity === order.from) {
      order.status = 'accepted';
      const sender = accountMap[order.user];
      const courier_ = accountMap[order.assignedCourier];
      await platform.connect(sender).sendDelivery(order.id);
      await platform.connect(courier_).takeDelivery(order.id);
      order.timeline.acceptedAt = frame;
      order.timeline.pickupAt = frame;
      
      // 更新承运商负载
      courier.capacity.currentVolume += order.goods.volume;
      courier.capacity.currentWeight += order.goods.weight;
      if (DEBUG_BOOL) {
        console.log(`${courier.id} 在 ${order.from} 接单 ${order.id}`);
      }
    }
  }
}

// 4. 处理订单完成
async function processOrderCompletion(frame, accountMap, platform) {
  for (order of allOrders.filter(o => o.status === 'accepted')) {
    const courier = accounts.find(c => c.id === order.assignedCourier);
    
    // 检查是否到达目的城市
    if (courier.currentCity === order.to) {
      order.status = 'completed';
      const sender = accountMap[order.user];
      const courier_ = accountMap[order.assignedCourier];
      const receiver = accountMap[order.receiver];
      await platform.connect(courier_).compeleteDelivery(order.id);
      await platform.connect(receiver).receiveDelivery(order.id);
      await platform.connect(sender).finishOrder(order.id);
      orderStats.completed++; // 新增统计
      order.timeline.completedAt = frame;
      
      // 释放承运商负载
      courier.capacity.currentVolume -= order.goods.volume;
      courier.capacity.currentWeight -= order.goods.weight;
      if (DEBUG_BOOL) {
        console.log(`${courier.id} 完成订单 ${order.id} 于 ${order.to}`);
      }
    }
  }
}

// 计算订单取消概率的函数（需在订单处理逻辑中添加）
function calculateCancelProbability(order, currentFrame) {
  const user = accounts.find(u => u.id === order.user);
  const elapsedHours = currentFrame - order.timeline.created;
  
  // 计算调整后的基准时间
  const descFactor = user.orderPatience.urgencyFactors.description[order.goods.description.split('')[0]] || 1;
  const effectiveBase = user.orderPatience.baseHours * descFactor;
  
  // 计算基础概率
  let prob = Math.min(
    user.orderPatience.maxCancelProb,
    Math.max(0, elapsedHours - effectiveBase) * user.orderPatience.decayRate
  );
  
  // 应用价格因子
  const priceFactor = user.orderPatience.urgencyFactors.price(order.price);
  prob *= (1 - priceFactor);
  
  return Math.min(0.99, Math.max(0.01, prob));
}

// 在订单处理循环中添加取消检查
async function checkOrderCancellations(currentFrame, accountMap, platform) {
  for (order of allOrders.filter(o => o.status === 'created')) {
    const cancelProb = calculateCancelProbability(order, currentFrame);
      if (Math.random() < cancelProb) {
        order.status = 'canceled';
        await platform.connect(accountMap[order.user]).cancelOrder(order.id);
        orderStats.canceled++; // 新增统计
        if (DEBUG_BOOL) {
          console.log(`订单 ${order.id} 因等待超时被取消，取消概率 ${(cancelProb*100).toFixed(1)}%`);
        }
      }
  }
}

// 计算城市间距离（简化版）
function getCityDistance(from, to) {
  const route = cityGraph.adjacencyList[from].find(r => r.city === to);
  return route ? route.weight : 0;
}

// 计算订单价格
function calculateOrderPrice(user, distance) {
  const rawValue = user.priceFunction(
    distance,
    user.shippingParams.volume,
    user.shippingParams.weight
  ) * 1e14;
  return rawValue.toFixed(0);
}

// 计算预计运输时间
function calculateDeliveryTime(user, baseTime) {
  return Math.round(
    baseTime * 
    user.transitTime.baseMultiplier * 
    (1 + Math.random() * user.transitTime.delayFactor)
  );
}

// 日志记录
function logSimulationState(frame) {
  if (DEBUG_BOOL) {
    console.log(`当前活跃订单状态:`);
  }
  const statusCount = {
    created: 0,
    bid: 0,
    assigned: 0,
    accepted: 0,
    completed: 0
  };
  
  allOrders.forEach(o => statusCount[o.status]++);
  if (DEBUG_BOOL) {
    console.table(statusCount);
  }

  // 示例订单流程跟踪
  const sampleOrder = allOrders.find(o => o.status === 'accepted');
  if (sampleOrder && DEBUG_BOOL) {
    console.log(`示例订单 ${sampleOrder.id} 状态:`);
    console.log(`  当前承运商: ${sampleOrder.assignedCourier}`);
    console.log(`  运输进度: ${sampleOrder.from} → ${sampleOrder.to}`);
    console.log(`  已耗时: ${frame - sampleOrder.timeline.created} 时间帧`);
  }
}


async function getSigners() {
  const signers = await ethers.getSigners();
  const accountMap = {
      'Owner': signers[0]
  };

  // Add accounts #1 to #10 (assuming 10 test accounts exist)
  for (let i = 1; i <= 100; i++) {
      accountMap[`Account #${i}`] = signers[i];
  }
  // console.log("Account addresses:");
  // for (const [key, signer] of Object.entries(accountMap)) {
  //   console.log(`    ${key.padEnd(10)}: ${signer.address}`);
  // }

  return accountMap;
}

async function deployContracts(accountMap) {
  // Get signers
  const owner = await accountMap["Owner"];

  // Deploy contracts
  let LogisticPlatform = await ethers.getContractFactory("LogisticPlatform");
  let platform = await LogisticPlatform.deploy();
  await platform.waitForDeployment();

  let LogiToken = await ethers.getContractFactory("LogiToken");
  let token = await upgrades.deployProxy(LogiToken, ["LogiToken", "LOGI"], {
      initializer: "initialize",
  });
  await token.waitForDeployment();

  let CollateralPool = await ethers.getContractFactory("CollateralPool");
  let pool = await CollateralPool.deploy(
      token.target,
      platform.target,
      owner.address
  );
  await pool.waitForDeployment();

  // Setup contracts
  await platform.setCollateralPool(pool.target);
  await platform.setLogiToken(token.target);
  await token.setCollateralPool(pool.target);

  console.log("Contract addresses:")
  console.log(`    owner address: ${owner.address}`);
  console.log(`    pool address: ${pool.target}`);
  console.log(`    platform address: ${platform.target}`);
  console.log(`    token address: ${token.target}`);

  return { platform, token, pool };
}

async function main() {
  const accountMap = await getSigners();
  let { platform, token, pool } = await deployContracts(accountMap);

  // 初始化用户状态
  initializeUserStates();

  for (let i = 1; i <= 100; i++) {
    await pool.connect(accountMap[`Account #${i}`]).deposit({value: ethers.parseEther("4.0")});
  }

  // 运行时间帧模拟
  for (let frame = 0; frame < TOTAL_FRAMES; frame++) {
    console.log(`\n=== 时间帧 ${frame + 1}/${TOTAL_FRAMES} ===`);
    
    updateUserLocations(frame);    // 1. 更新位置
    processBiddingOrders(frame);   // 2. 处理投标
    await processOrderAssignment(frame, accountMap, platform); // 3. 处理委派
    await processOrderPickup(frame, accountMap, platform);     // 4. 处理取货
    await processOrderCompletion(frame, accountMap, platform); // 5. 处理完成
    await generateOrders(frame, accountMap, platform);         // 6. 生成新订单
    await checkOrderCancellations(frame, accountMap, platform);// 7. 检查取消
    
    logSimulationState(frame);     // 打印状态
  }

  // 输出最终结果
  console.log("\n=== 模拟结果 ===");
  console.log(`总生成订单数: ${allOrders.length}`);
  console.log(`成功完成订单: ${orderStats.completed}`);
  console.log(`被取消订单: ${orderStats.canceled}`);
  console.log(`整体完成率: ${(orderStats.completionRate * 100).toFixed(1)}%`);

  console.log("\n用户移动统计:");
  accounts.forEach(user => {
    console.log(`${user.id.padEnd(10)}: 移动次数 ${user.moveCount.toString().padEnd(3)} 路线 ${user.movement.route.join('→')}`);
  });

  // 添加移动与订单比例分析
  const totalMoves = accounts.reduce((sum, user) => sum + user.moveCount, 0);
  console.log(`\n移动次数/订单数量比例: ${(totalMoves / allOrders.length).toFixed(2)}`);
}


main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});