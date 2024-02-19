// We require the Hardhat Runtime Environment explicitly here. This is optional
// but useful for running the script in a standalone fashion through `node <script>`.
//
// You can also run a script with `npx hardhat run <script>`. If you do that, Hardhat
// will compile your contracts, add the Hardhat Runtime Environment's members to the
// global scope, and execute the script.

const { ethers } = require("hardhat");

const deployGmetStaking = async (deployerAddress, gmetTokenAddress) => {
  try {
    const deployer = await ethers.getSigner(deployerAddress);

    const GmetStaking = await ethers.getContractFactory("GmetStaking");

    const gmetStaking = await GmetStaking.connect(deployer).deploy(
      gmetTokenAddress
    );

    await gmetStaking.waitForDeployment();

    console.log(
      `GmetStaking contract has been deployed at address: ${gmetStaking.target}`
    );

    return gmetStaking;
  } catch (error) {
    console.error(error);
  }
};

module.exports = {
  deployGmetStaking,
};
