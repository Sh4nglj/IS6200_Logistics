

async function main() {
    const address = '0x715c5727203e7e8b39ef5fd5725e72d74b742c1e'
    const provider = ethers.getDefaultProvider('http://localhost:8545'); // 连接本地节点
    const latestBlock = await provider.getBlockNumber();
  
    // 查询所有相关交易
    const filter = {
        fromBlock: 0,
        toBlock: latestBlock,
        address: address // 可以指定合约地址或留空查所有地址
    };

    // 3. 获取日志和交易
    const logs = await provider.getLogs(filter)

    console.log(logs);
}


main().catch((error) => {
    console.error(error);
    process.exitCode = 1;
  });