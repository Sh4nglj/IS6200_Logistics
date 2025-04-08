/** @type import('hardhat/config').HardhatUserConfig */
require("@nomicfoundation/hardhat-toolbox");
require("@openzeppelin/hardhat-upgrades"); // 新增这行

module.exports = {
  solidity: "0.8.28",
};
