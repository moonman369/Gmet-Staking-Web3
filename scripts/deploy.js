const { deployGmetStaking } = require("./deployFunctions");

const GMET_TOKEN_ADDRESS = "0x80A851805C15fcC9768CAe21287b2Ec4DbD3fD94";

const main = async () => {
  const [deployer] = await ethers.getSigners();
  const gmetStaking = await deployGmetStaking(
    deployer.address,
    GMET_TOKEN_ADDRESS
  );
};

main()
  .then(() => {
    process.exit(0);
  })
  .catch((error) => console.error(error));
