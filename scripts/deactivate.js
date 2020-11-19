const coverageProviderAddr = "0x81320a26282CD03827a737c8cA5565Aa8820236f";
const noClaimTokenAddr = "0x72c0ed36a98e09df1c0f5c273bb2c3d9bd592e3b";
const address = "0xb7a56C00aE5B60f54335496F4A4D09804678B5C5";

async function main() {
  const CoverageProvider = await ethers.getContractFactory("CoverageProvider");
  coverageProvider = CoverageProvider.attach(coverageProviderAddr);

  const ERC20_NOCLAIM = await ethers.getContractFactory('ERC20');
  noClaim = ERC20_NOCLAIM.attach(noClaimTokenAddr);

  console.log("Release funds and destroy contracts ... ");

  let balanceNoClaim = await noClaim.balanceOf(address);
  console.log("Depositor $NOCLAIM balance before shutdown: " + ethers.utils.formatEther(balanceNoClaim).toString());
  await coverageProvider.deactivate();
  balanceNoClaim = await noClaim.balanceOf(address);
  console.log("Depositor $NOCLAIM balance after shutdown: " + ethers.utils.formatEther(balanceNoClaim).toString());
  console.log("==========================================================");
  console.log("♪♫ (V) (°,,,,°) (V) ♪♫ ♪♫ ♪♫  ♪♫ ♪♫ ♪♫ (V) (°,,,,°) (V) ♪♫");
  console.log("♪♫ (V) (°,,,,°) (V) CONTRACTS ARE GONE (V) (°,,,,°) (V) ♪♫");
  console.log("♪♫ (V) (°,,,,°) (V) ♪♫ ♪♫ ♪♫  ♪♫ ♪♫ ♪♫ (V) (°,,,,°) (V) ♪♫");
  console.log("==========================================================");
}

main()
  .then(() => process.exit(0))
  .catch(error => {
    console.error(error);
    process.exit(1);
  });
