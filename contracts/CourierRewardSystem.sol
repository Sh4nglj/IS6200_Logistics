// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.20;

import "./CollateralPool.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

/**
 * @title 快递员奖励系统合约
 * @dev 管理快递员评分和分润机制
 */
contract CourierRewardSystem is Ownable {
    // 状态变量
    CollateralPool public collateralPool;
    address public platformCore;
    
    uint256 public constant DISTRIBUTE_INTERVAL = 30 days; // 分润间隔
    uint256 public lastDistributeTime; // 上一次分润时间
    address[] public ratedCourierList;

    // 映射
    mapping(address => uint16) private courierCreditMap;
    
    // 事件
    event OrderRated(address indexed courier, uint8 rating);
    event ProfitDistributed(uint256 indexed timestamp, uint256 bonusPoolAmount, string message);

    // 修饰符
    modifier onlyPlatform() {
        require(msg.sender == platformCore, "Only platform can call");
        _;
    }

    /**
     * @dev 构造函数
     */
    constructor() Ownable(msg.sender) {}
    
    /**
     * @dev 设置抵押池合约地址
     */
    function setCollateralPool(address poolAddress) external onlyOwner {
        require(poolAddress != address(0), "Invalid pool address");
        collateralPool = CollateralPool(poolAddress);
    }
    
    /**
     * @dev 设置平台核心合约地址
     */
    function setPlatformCore(address coreAddress) external onlyOwner {
        require(coreAddress != address(0), "Invalid core address");
        platformCore = coreAddress;
    }
    
    /**
     * @dev 记录快递员评分
     * @param courier 快递员地址
     * @param rating 评分(1-5)
     */
    function recordRating(address courier, uint8 rating) external onlyPlatform {
        require(rating >= 1 && rating <= 5, "Invalid rating");
        
        // 记录评分
        ratedCourierList.push(courier);
        courierCreditMap[courier] += rating;
        
        emit OrderRated(courier, rating);
    }
    
    /**
     * @dev 分发平台奖金给快递员
     */
    function distributeProfit() external {
        require(collateralPool.owner() == msg.sender, "Only owner can distribute profit");
        require(block.timestamp - lastDistributeTime >= DISTRIBUTE_INTERVAL, "Not time to distribute");     

        // 获取奖金池总额
        uint256 bonusPoolAmount = collateralPool.getBonusPool();
        require(bonusPoolAmount > 0, "No profit to distribute");
        
        // 确保有快递员被评分
        uint256 courierCount = ratedCourierList.length;
        require(courierCount > 0, "No rated couriers");
        
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
                courierScores[i] = calculateScore(courierCreditMap[courier]);
                totalScore += courierScores[i];
            }
            
            // 分配奖金
            if (totalScore > 0) {
                string memory message = "";
                uint256 totalDistributed = 0;
                
                // 第一步：计算每个快递员应得奖金
                uint256[] memory bonusAmounts = new uint256[](totalCouriers);
                
                for (uint256 i = 0; i < totalCouriers; i++) {
                    uint256 shareRatio = (courierScores[i] * 1e18) / totalScore;
                    bonusAmounts[i] = (bonusPoolAmount * shareRatio) / 1e18;
                    totalDistributed += bonusAmounts[i];
                }
                
                // 第二步：处理剩余奖金
                uint256 remainder = bonusPoolAmount - totalDistributed;
                if (remainder > 0) {
                    uint16 highestCredit = 0;
                    uint256 highestCourierIndex = 0;
                    
                    for (uint256 i = 0; i < totalCouriers; i++) {
                        uint16 credit = courierCreditMap[uniqueCouriers[i]];
                        if (credit > highestCredit) {
                            highestCredit = credit;
                            highestCourierIndex = i;
                        }
                    }
                    
                    bonusAmounts[highestCourierIndex] += remainder;
                }
                
                // 第三步：实际分配奖金
                for (uint256 i = 0; i < totalCouriers; i++) {
                    address courier = uniqueCouriers[i];
                    
                    uint256 courierBonus = collateralPool.distributeExactBonusTo(courier, bonusAmounts[i]);
                    message = string.concat(message, ";", Strings.toHexString(uint160(courier), 20), "_", Strings.toString(courierBonus));
                }
                
                // 触发分润完成事件
                emit ProfitDistributed(lastDistributeTime, bonusPoolAmount, message);
                
                // 重置评分数据
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
     */
    function calculateScore(uint16 _totalCredit) public pure returns (uint256) {
        // 确保至少有1分
        if (_totalCredit == 0) {
            _totalCredit = 1;
        }
        
        // 基础分固定为100
        uint256 baseScore = 100;
        uint256 logScore;
        
        // 分段模拟对数曲线
        if (_totalCredit <= 3) {
            logScore = uint256(_totalCredit) * 60;
        } else if (_totalCredit <= 15) {
            logScore = 180 + (uint256(_totalCredit) - 3) * 40;
        } else if (_totalCredit <= 50) {
            logScore = 660 + (uint256(_totalCredit) - 15) * 20;
        } else if (_totalCredit <= 100) {
            logScore = 1360 + (uint256(_totalCredit) - 50) * 10;
        } else {
            logScore = 1860 + (uint256(_totalCredit) - 100) * 5;
        }
        
        return baseScore + logScore;
    }

    /**
     * 获取唯一的快递员地址列表
     */
    function getUniqueCouriers() private view returns (address[] memory) {
        uint256 courierCount = ratedCourierList.length;
        
        address[] memory allCouriers = new address[](courierCount);
        uint256 uniqueCount = 0;
        
        for (uint256 i = 0; i < courierCount; i++) {
            address courier = ratedCourierList[i];
            bool found = false;
            
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
        
        address[] memory uniqueCouriers = new address[](uniqueCount);
        for (uint256 i = 0; i < uniqueCount; i++) {
            uniqueCouriers[i] = allCouriers[i];
        }
        
        return uniqueCouriers;
    }

    /**
     * @dev 获取快递员当前信用评分
     */
    function getCourierCredit(address _courier) external view returns (uint16) {
        return courierCreditMap[_courier];
    }
}