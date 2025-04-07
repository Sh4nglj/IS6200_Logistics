const hre = require("hardhat");

async function main() {
    // const contract = await hre.ethers.getContractFactory("HelloWorld");
    const contractFactory = await hre.ethers.getContractFactory("LogisticPlatform");
    // 部署合约
    const contract = await contractFactory.deploy();
    await contract.waitForDeployment();  // 关键：等待部署完成[5](@ref)
    console.log("合约地址:", await contract.getAddress());
    console.log("部署交易哈希:", contract.deploymentTransaction().hash);
}

main().catch((error) => {
    console.error(error);
    process.exitCode = 1;
});