const coverageProviderAddr = "0x81320a26282CD03827a737c8cA5565Aa8820236f";
const address = "0xb7a56C00aE5B60f54335496F4A4D09804678B5C5";

async function main() {
  const CoverageProvider = await ethers.getContractFactory("CoverageProvider");
  coverageProvider = CoverageProvider.attach(coverageProviderAddr);

  console.log("Checking user balance of $NOCLAIM (locked in contract till expiry) ... ");

  const balance = await coverageProvider.getBalance(address);

  console.log("Contract holds "+ethers.utils.formatEther(balance).toString()+" $NOCLAIM on behalf of "+address);
}

main()
  .then(() => process.exit(0))
  .catch(error => {
    console.error(error);
    process.exit(1);
  });
