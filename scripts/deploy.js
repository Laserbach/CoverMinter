async function main() {

  const Minter = await hre.ethers.getContractFactory("Minter");
  const minter = await Minter.deploy();
  await minter.deployed();
  console.log("Minter deployed to:", minter.address);

  const Redeem = await hre.ethers.getContractFactory("Redeem");
  const redeem = await Redeem.deploy();
  await redeem.deployed();
  console.log("Redeem deployed to:", redeem.address);

  const daiTokenAddr = "0x4f96fe3b7a6cf9725f59d353f723c1bdb64ca6aa";
  const noClaimTokenAddr = "0x72c0ed36a98e09df1c0f5c273bb2c3d9bd592e3b";
  const minterAddr = minter.address;
  const redeemerAddr = redeem.address;
  const coveredProtocolAddr = "0x0e786ecb57c6c6d58ab2c24c07d865f56421eb6e"
  const balancerPoolAddr = "0xaa04ad2ac556dba7c90d3f7ca2577a479e0f7e09"
  const coverAddr = "0xC26D410200673D06C61eE49a3274597355A9016e"
  const claimTokenAddr = "0x4697451ebd678f82228ff3fb590ff9259a3cb378";
  const expirationTime = 1627603200

  const CoverageProvider = await hre.ethers.getContractFactory("CoverageProvider");
  coverageProvider = await CoverageProvider.deploy(daiTokenAddr, noClaimTokenAddr, minterAddr, redeemerAddr, coveredProtocolAddr, balancerPoolAddr, coverAddr, claimTokenAddr, expirationTime);

  await coverageProvider.deployed();
  console.log("CoverageProvider deployed to:", coverageProvider.address);
}

main()
  .then(() => process.exit(0))
  .catch(error => {
    console.error(error);
    process.exit(1);
  });
