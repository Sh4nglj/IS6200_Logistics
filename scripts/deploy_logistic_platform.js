const { ethers } = require("hardhat");

async function main() {
    // 使用hardhat的ethers实例
    const contractFactory = await ethers.getContractFactory("LogisticPlatform");
    
    // 部署合约
    const contract = await contractFactory.deploy();
    await contract.waitForDeployment();
    
    console.log("合约地址:", await contract.getAddress());
    console.log("部署交易哈希:", contract.deploymentTransaction().hash);
}

main().catch(error => {
    console.error(error);
    process.exitCode = 1;
});