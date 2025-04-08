# Version: 2025.04.07 v2.0
_Author: Ladaballe Takahashi_

## Description:
- LogisticPlatform.sol: 运输平台智能合约的主要部分，主要包括整个主要运输流程
- CollateralPool.sol: 抵押池智能合约，用于存储质押eth并铸造LogiToken
- LogiToken.sol: LogiToken, 无法转账
- QueryCollateralPool.sol: 专门用于查询抵押池的智能合约

## Done:
- 主要功能的大部分

## To Do:
- 将合约部署起来的javascript脚本
- 将抵押查询功能结合到主智能合约中
- 完善类的设计


# Version: 2025.04.07 v2.1
_Author: Ladaballe Takahashi_

## Description:
- contracts:
    - LogisticPlatform.sol: 运输平台智能合约的主要部分，主要包括整个主要运输流程，主要流程经过测试已经完成
    - CollateralPool.sol: 抵押池智能合约，用于存储质押eth并铸造LogiToken, 增加对已经抵押和尚未抵押token的判断
    - LogiToken.sol: LogiToken, 无法转账
    - QueryCollateralPool.sol: 专门用于查询抵押池的智能合约
- scripts:
    - deploy.js: 使用hardhat 进行智能合约部署脚本，需要安装@nomicfoundation/hardhat-toolbox和hardhat
- test:
    - test_LogisticPlatform.js: 主要运输流程的测试，已经完成

## Done:
- 主要功能的大部分
- 针对主要功能的测试
- 将主要合约部署起来的javascript脚本

## To Do:
- 将抵押池合约部署起来的javascript脚本
- 将抵押查询功能结合到主智能合约中
- 完善类的设计

# Version: 2025.04.07 v2.2
_Author: Ladaballe Takahashi_

## Description:
- contracts:
    - LogisticPlatform.sol: 运输平台智能合约的主要部分，主要包括整个主要运输流程，主要流程经过测试已经完成
    - CollateralPool.sol: 抵押池智能合约，用于存储质押eth并铸造LogiToken, 增加对已经抵押和尚未抵押token的判断
    - LogiToken.sol: LogiToken, 无法转账
    - QueryCollateralPool.sol: 专门用于查询抵押池的智能合约
- scripts:
    - deploy.js: 使用hardhat 进行智能合约部署脚本，需要安装@nomicfoundation/hardhat-toolbox和hardhat
- test:
    - test_LogisticPlatform.js: 主要运输流程的测试，已经完成
    - test_CollateralPool.js: 抵押池的测试，尚未完成

## Done:
- 主要功能的大部分
- 针对主要功能的测试
- 将主要合约部署起来的javascript脚本
- 抵押池抵押机制与奖励机制的初步设计

## To Do:
- 将抵押池合约部署起来的javascript脚本
- 将抵押查询功能结合到主智能合约中
- 完善类的设计

# Version: 2025.04.08 v3.0
_Author: Ladaballe Takahashi_

## Description:
- contracts:
    - LogisticPlatform.sol: 运输平台智能合约的主要部分，主要包括整个主要运输流程，主要流程经过测试已经完成
    - CollateralPool.sol: 抵押池智能合约，用于存储质押eth并铸造LogiToken, 增加对已经抵押和尚未抵押token的判断
    - LogiToken.sol: LogiToken, 无法转账
    - QueryCollateralPool.sol: 专门用于查询抵押池的智能合约
- scripts:
    - deploy.js: 使用hardhat 进行智能合约部署脚本，需要安装@nomicfoundation/hardhat-toolbox和hardhat
- test:
    - test_LogisticPlatform.js: 主要运输流程的测试，已经完成
    - test_CollateralPool.js: 抵押池的测试，尚未完成

## Done:
- 主要功能的大部分
- 针对主要功能的测试
- 将主要合约部署起来的javascript脚本
- 抵押池抵押机制与奖励机制的初步设计
- 抵押池和代币的铸造和销毁机制的设计
- 抵押池和代币的铸造和销毁机制的测试

## To Do:
- 将抵押池合约部署起来的javascript脚本
- 抵押池的转账和分成处理
- 将抵押查询功能结合到主智能合约中
- 信誉机制的设计
- 信誉机制的实现
- 信誉机制预言机的实现

# Version: 2025.04.08 v3.0
_Author: Ladaballe Takahashi_

## Description:
- contracts:
    - LogisticPlatform.sol: 运输平台智能合约的主要部分，主要包括整个主要运输流程，主要流程经过测试已经完成
    - CollateralPool.sol: 抵押池智能合约，用于存储质押eth并铸造LogiToken, 增加对已经抵押和尚未抵押token的判断
    - LogiToken.sol: LogiToken, 无法转账
    - QueryCollateralPool.sol: 专门用于查询抵押池的智能合约
- scripts:
    - deploy.js: 使用hardhat 进行智能合约部署脚本，需要安装@nomicfoundation/hardhat-toolbox和hardhat
- test:
    - test_LogisticPlatform.js: 主要运输流程的测试，已经完成
    - test_CollateralPool.js: 抵押池的测试，尚未完成

## Done:
- 主要功能的大部分
- 针对主要功能的测试
- 将主要合约部署起来的javascript脚本
- 抵押池抵押机制与奖励机制的初步设计
- 抵押池和代币的铸造和销毁机制的设计
- 抵押池和代币的铸造和销毁机制的测试

## To Do:
- 将抵押池合约部署起来的javascript脚本
- 抵押池的转账和分成处理
- 将抵押查询功能结合到主智能合约中
- 信誉机制的设计
- 信誉机制的实现
- 信誉机制预言机的实现


# Version: 2025.04.09 v3.3
_Author: Ladaballe Takahashi_

## Description:
- contracts:
    - LogisticPlatform.sol: 运输平台智能合约的主要部分，主要包括整个主要运输流程，主要流程经过测试已经完成
    - CollateralPool.sol: 抵押池智能合约，用于存储质押eth并铸造LogiToken, 增加对已经抵押和尚未抵押token的判断
    - LogiToken.sol: LogiToken, 无法转账
    - QueryCollateralPool.sol: 专门用于查询抵押池的智能合约
- scripts:
    - deploy.js: 使用hardhat 进行智能合约部署脚本，需要安装@nomicfoundation/hardhat-toolbox和hardhat
- test:
    - test_LogisticPlatform.js: 主要运输流程的测试，已经完成
    - test_CollateralPool.js: 抵押池的测试，尚未完成

## Done:
- 主要功能的大部分
- 针对主要功能的测试
- 将主要合约部署起来的javascript脚本
- 抵押池抵押机制与奖励机制的初步设计
- 抵押池和代币的铸造和销毁机制的设计
- 抵押池和代币的铸造和销毁机制的测试
- 抵押事件的定义
- 抵押机制的测试

## To Do:
- 将抵押池合约部署起来的javascript脚本
- 抵押池的转账和分成处理
- 将抵押查询功能结合到主智能合约中
- 信誉机制的设计
- 信誉机制的实现
- 信誉机制预言机的实现