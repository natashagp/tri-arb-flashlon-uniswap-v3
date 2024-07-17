const { ethers } = require("hardhat");
const { expect } = require("chai");

const { impersonateFundErc20 } = require("../utils/utilities");

// ETHEREUM - UNISWAP V3
const SWAP_ROUTER = "0x68b3465833fb72A70ecDF485E0e4C7bD8665Fc45"; // https://docs.uniswap.org/contracts/v3/reference/deployments/ethereum-deployments
const FACTORY = "0x1F98431c8aD98523631AE4a59f267346ea31F984"; // https://docs.uniswap.org/contracts/v3/reference/deployments/ethereum-deployments
const WETH = "0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2";
const USDC = "0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48";
const POOL_FEE = 3000; // 0.30% fee tier
const USDC_WHALE = "0x7713974908be4bed47172370115e8b1219f4a5f0";
const DAI = "0x6B175474E89094C44Da98b954EedeAC495271d0F";
const CRV = "0xD533a949740bb3306d119CC777fa900bA034cd52";

// Values for triangular arbitrage
const SWAP1 = USDC;
const SWAP2 = WETH;
const SWAP3 = CRV;
const POOL1 = 500; // 0.05% fee tier
const POOL2 = 10000; // 1% fee tier
const POOL3 = 10000; // 1% fee tier

describe("TriArbFlash", function () {
  let BORROW_AMOUNT, receipt;
  const initialFundingHuman = "100";
  const amountToBorrow = "10";
  const DECIMALS = 6; // decimals of USDC

  // Execute before each test
  beforeEach(async function () {
    let usdc = await ethers.getContractAt("IERC20", USDC);
    BORROW_AMOUNT = ethers.parseUnits(amountToBorrow, DECIMALS);
    console.log("USDC balance of Whale: ", await usdc.balanceOf(USDC_WHALE));

    const TriArbFlashloan = await ethers.getContractFactory("TriArbFlashloan");
    triArbFlashoan = await TriArbFlashloan.deploy(FACTORY, SWAP_ROUTER);
    await triArbFlashoan.waitForDeployment();

    console.log("Impersonation started");
    await impersonateFundErc20(
      usdc,
      USDC_WHALE,
      triArbFlashoan.target,
      initialFundingHuman,
      DECIMALS
    );
    console.log("Impersonation finished");
  });

  it("ensures contract is funded", async () => {
    const balOfUSDCOnContract = await triArbFlashoan.tokenBalance(USDC);

    const flashSwapBalanceHuman = ethers.formatUnits(
      balOfUSDCOnContract,
      DECIMALS
    );

    expect(Number(flashSwapBalanceHuman)).equal(Number(initialFundingHuman));
  });

  it("borrow USDC flash loan, make triangular arbitrage and return money to pool that borrowed", async () => {
    const tx = await triArbFlashoan.initFlashLoanPool(
      USDC,
      WETH,
      POOL_FEE,
      BORROW_AMOUNT,
      0,
      SWAP1,
      SWAP2,
      SWAP3,
      POOL1,
      POOL2,
      POOL3
    );
    receipt = await tx.wait();

    console.log(`Borrowing ${BORROW_AMOUNT} USDC`);
    balance = await triArbFlashoan.tokenBalance(USDC);
    console.log(`Current balance of USDC = ${balance}`);

    expect(balance).not.equal(0);
  });

  it("Get Gas in USD", async () => {
    const gasPrice = receipt.gasPrice;
    const gasUsed = receipt.gasUsed;
    const gasUsedETH = gasPrice * gasUsed;
    const ethPriceTodayInUSD = 3396.19; // Price of ETH in USD -> 17/07/2024

    console.log(
      "Total Gas USD: " +
        ethers.formatEther(gasUsedETH.toString()) * ethPriceTodayInUSD
    );

    expect(gasUsedETH).not.equal(0);
  });
});
