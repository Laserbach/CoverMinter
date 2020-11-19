const daiTokenAddr = "0x4f96fe3b7a6cf9725f59d353f723c1bdb64ca6aa";
const coverageProviderAddr = "0x81320a26282CD03827a737c8cA5565Aa8820236f";

async function main() {

  const daiToDeposit = 1;
  console.log("Deposit "+daiToDeposit.toString()+" $DAI to mint coverage ...");

  const CoverageProvider = await ethers.getContractFactory("CoverageProvider");
  coverageProvider = CoverageProvider.attach(coverageProviderAddr);

  const ERC20_DAI = await ethers.getContractFactory('ERC20');
  dai = ERC20_DAI.attach(daiTokenAddr);

  const daiAmount = ethers.utils.parseEther(daiToDeposit.toString());
  const daiApprove = await dai.approve(coverageProvider.address, daiAmount);
  await daiApprove.wait();

  await coverageProvider.deposit(daiAmount);

  console.log("Success!");
}

main()
  .then(() => process.exit(0))
  .catch(error => {
    console.error(error);
    process.exit(1);
  });
