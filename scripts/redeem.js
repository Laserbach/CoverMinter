const coverageProviderAddr = "0x81320a26282CD03827a737c8cA5565Aa8820236f";

async function main() {
  const CoverageProvider = await ethers.getContractFactory("CoverageProvider");
  coverageProvider = CoverageProvider.attach(coverageProviderAddr);

  console.log("Trying to redeem $NOCLAIM for $DAI ...");
  console.log("Redeem fails if coverage is still active!");

  try {
    await coverageProvider.redeem();
  }
  catch(_ex) {
    console.log("Transaction reverted! Coverage not expired!");
  }
}

main()
  .then(() => process.exit(0))
  .catch(error => {
    console.error(error);
    process.exit(1);
  });
