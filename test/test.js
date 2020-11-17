const { assert } = require("chai");

const coveredProtocolAddr = "0x7cdaC79c729aa5efA85a7510e44C24C58A4eDcAF";
const coverAddr = "0xf39654833a156cC7EEB9755DAdF3120504c245cF";
const mcdAddr = "0x6b175474e89094c44da98b954eedeac495271d0f";
const claimTokenAddr = "0x55a020a43d1c1c42c880fefb08dcec037f76f999";
const noClaimTokenAddr = "0xc0d3d2acd35c20e991adacdc00f0bd778ca1d06d";
const noClaimHolder = "0x2d2e31965cc5d89dfa0684079b4730800c36e993";
const wethAddr = "0xc02aaa39b223fe8d0a0e5c4f27ead9083c756cc2";
const balPoolAddrDaiWeth = "0x9b208194acc0a8ccb2a8dcafeacfbb7dcc093f81";
const balPoolAddrDaiClaim = "0x55a020a43d1c1c42c880fefb08dcec037f76f999";

let deployer;

// dex
let balancerTrader;
let balancerTraderCover;

// protocol instance
let protocol;

// cover
let cover;

// balances and minting amount
let daiAmount;
let balanceDai;
let balanceClaim;
let balanceNoClaim;

// erc20
let dai;
let claim;
let noClaim;

// setting the timestamp for each upcoming mined block (every Tx mines a block)
// needed to pass the timestamp require statement in the addCover function
// if not setting the timestamps manually the blocks are mined using
// the timestamp coming from our local machine, which fails the addCover require statement
let initialTimestamp = 1605186000;
async function setNextTimeStamp() {
  await hre.network.provider.request({
    method: "evm_setNextBlockTimestamp",
    params: [++initialTimestamp]
  });
}

describe("### Acquire DAI", function() {
  before(async () => {
    deployer = ethers.provider.getSigner(0);

    await setNextTimeStamp();
    const BalancerTrader = await ethers.getContractFactory("BalancerTrader");
    balancerTrader = await BalancerTrader.deploy(balPoolAddrDaiWeth,mcdAddr,wethAddr);
    await balancerTrader.deployed();

    await setNextTimeStamp();
    const BalancerTraderCover = await ethers.getContractFactory("BalancerTraderCover");
    balancerTraderCover = await BalancerTraderCover.deploy(balPoolAddrDaiClaim,mcdAddr,claimTokenAddr);
    await balancerTraderCover.deployed();

    const Protocol = await ethers.getContractFactory("Protocol");
    protocol = Protocol.attach(coveredProtocolAddr);

    const Cover = await ethers.getContractFactory("Cover");
    cover = Cover.attach(coverAddr);

    const ERC20_DAI = await ethers.getContractFactory('ERC20');
    dai = ERC20_DAI.attach(mcdAddr);

    const ERC20_CLAIM = await ethers.getContractFactory('ERC20');
    claim = ERC20_CLAIM.attach(claimTokenAddr);

    const ERC20_NOCLAIM = await ethers.getContractFactory('ERC20');
    noClaim = ERC20_NOCLAIM.attach(noClaimTokenAddr);
  });

  it("should allow us to swap ETH for DAI via Balancer (ETH - WETH - DAI)", async function() {
    await setNextTimeStamp();
    daiAmount = ethers.utils.parseEther("100");
    await balancerTrader.pay(daiAmount, {value: ethers.utils.parseEther("1")});
    balanceDai = await dai.balanceOf(deployer.getAddress());
    console.log("My DAI balance: " + ethers.utils.formatEther(balanceDai).toString());
    assert.equal(ethers.utils.formatEther(balanceDai), ethers.utils.formatEther(daiAmount));
  });
});

describe("### Provide Coverage: Mint NOCLAIM / CLAM and sell CLAIM", () => {
  it("should allow us using 100 DAI to mint 100 CLAIM and 100 NOCLAIM tokens", async function() {
    await setNextTimeStamp();
    daiAmount = 100;
    const txApprove = await dai.approve(coveredProtocolAddr, ethers.utils.parseEther(daiAmount.toString()));
    await txApprove.wait();

    await setNextTimeStamp();
    const expirationTime = 1605398400 // Nov 15th
    const txMint = await protocol.addCover(mcdAddr, expirationTime, ethers.utils.parseEther(daiAmount.toString()))
    await txMint.wait();

    balanceClaim = await claim.balanceOf(deployer.getAddress());
    balanceNoClaim = await noClaim.balanceOf(deployer.getAddress());
    balanceDai = await dai.balanceOf(deployer.getAddress());
    console.log("CLAIM: " + ethers.utils.formatEther(balanceClaim).toString() + " and NOCLAIM: " + ethers.utils.formatEther(balanceNoClaim).toString());
    console.log("DAI balance: " + ethers.utils.formatEther(balanceDai).toString());
    assert.equal(ethers.utils.formatEther(balanceClaim), "100.0");
  });

  it("should allow us selling all our minted CLAIM tokens on balancer", async function() {
    await claim.approve(balancerTraderCover.address, balanceClaim);
    await balancerTraderCover.sellClaim(balanceClaim);
    balanceClaim = await claim.balanceOf(deployer.getAddress());
    balanceNoClaim = await noClaim.balanceOf(deployer.getAddress());
    balanceDai = await dai.balanceOf(deployer.getAddress());
    console.log("### Sell CLAIM for DAI:")
    console.log("CLAIM: " + ethers.utils.formatEther(balanceClaim).toString() + " and NOCLAIM: " + ethers.utils.formatEther(balanceNoClaim).toString());
    console.log("DAI balance: " + ethers.utils.formatEther(balanceDai).toString());
    assert.equal(ethers.utils.formatEther(balanceClaim), "0.0");
  });

  it("should validate that coverage is active", async function() {
    const [...activeCoverageDetails] = await protocol.getProtocolDetails();
    // console.log("========= Coverage Details =========")
    // console.log(activeCoverageDetails);
    // console.log("Coverage is active: "+activeCoverageDetails[1]);
    assert.equal(activeCoverageDetails[1], true);
  });
});

describe("### Redeem NOCLAIM after expiry", () => {
  it("should not allow to redeem NOCLAIM prior to expiration date", async function() {
    await cover.redeemNoclaim();
    assert.equal(ethers.utils.formatEther(balanceNoClaim), "100.0");
  });

  it("should allow to redeem NOCLAIM after expiration date", async function() {
    // https://etherscan.io/tx/0xe99da3e3282661b85ba5ca88a8006fb198001eb29402b440edbd52708255da70
    await network.provider.request({
      method: "hardhat_reset",
      params: [{
        forking: {
          jsonRpcUrl: process.env.FORKING_URL,
          blockNumber: 11268100
        }
      }]
    })

    await hre.network.provider.request({
      method: "hardhat_impersonateAccount",
      params: [noClaimHolder] // holds 100 NoClaim
    });
    const signer = ethers.provider.getSigner(noClaimHolder);

    const noClaimBeforRedeem = await noClaim.balanceOf(signer.getAddress());
    const daiBeforRedeem = await dai.balanceOf(signer.getAddress());
    console.log("NOCLAIM balance befor redeeming: "+ethers.utils.formatEther(noClaimBeforRedeem).toString())

    await cover.connect(signer).redeemNoclaim();

    const noClaimAfterRedeem = await noClaim.balanceOf(signer.getAddress());
    const daiAfterRedeem = await dai.balanceOf(signer.getAddress());
    console.log("NOCLAIM balance after redeeming: "+ethers.utils.formatEther(noClaimAfterRedeem).toString())

    assert.equal(noClaimBeforRedeem - noClaimAfterRedeem, daiAfterRedeem - daiBeforRedeem );
  });
});
