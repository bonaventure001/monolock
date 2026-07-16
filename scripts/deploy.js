const hre = require("hardhat");

async function main() {
  const MonadEscrow = await hre.ethers.getContractFactory("MonadEscrow");
  const escrow = await MonadEscrow.deploy();
  await escrow.waitForDeployment();

  const address = await escrow.getAddress();
  console.log("MonadEscrow deployed to:", address);
  console.log("Network:", hre.network.name);
  console.log("\nSave this address — you'll need it for the frontend.");
}

main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});
