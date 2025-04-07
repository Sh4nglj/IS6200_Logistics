async function main() {
    const MyContract = await ethers.getContractFactory("HelloWorld");
    const contract = await MyContract.attach("0xdc64a140aa3e981100a9beca4e685f962f0cf6c9");
    await contract.message();
    console.log(msg);
}
