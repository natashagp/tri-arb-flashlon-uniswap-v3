const { ethers } = require("hardhat");

async function main() {
  const [deployer] = await ethers.getSigners();

  // https://docs.uniswap.org/contracts/v3/reference/deployments/ethereum-deployments
  const SWAP_ROUTER = "0x68b3465833fb72A70ecDF485E0e4C7bD8665Fc45";
  const FACTORY = "0x1F98431c8aD98523631AE4a59f267346ea31F984";

  console.log("Deploying contracts with the account:", deployer.address);

  const TriArbFlashloan = await ethers.getContractFactory("TriArbFlashloan");
  triArbFlashoan = await TriArbFlashloan.deploy(FACTORY, SWAP_ROUTER);
  await triArbFlashoan.waitForDeployment();

  console.log("Tri Arb Flashloan address:", triArbFlashoan.address);
}

main()
  .then(() => process.exit(0))
  .catch((error) => {
    console.error(error);
    process.exit(1);
  });
