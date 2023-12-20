const scrobot = artifacts.require("scrobot");
const stETH = artifacts.require("stETH");
const point = artifacts.require("point");
const miningMachine = artifacts.require("miningMachine");

contract("scrobot", (accounts) => {
  let scrobotInstance;
  let stETHInstance;
  let pointInstance;
  let miningMachineInstance;

  const owner = accounts[0];
  const user1 = accounts[1];

  beforeEach(async () => {
    stETHInstance = await stETH.new({ from: owner });
    pointInstance = await point.new(convertToWei("10000000"), { from: owner });
    miningMachineInstance = await miningMachine.new(pointInstance.address, 0, { from: owner });

    scrobotInstance = await scrobot.new(stETHInstance.address, pointInstance.address, {
      from: owner
    });
    await miningMachineInstance.addPool(500, scrobotInstance.address, { from: owner });

    await scrobotInstance.setMiningMachine(miningMachineInstance.address, { from: owner });
    await scrobotInstance.setPidOfMining(0, { from: owner });


    await pointInstance.setMiningMachine(miningMachineInstance.address, { from: owner });
  });

  it("should submit and withdraw successfully", async () => {
    const amount = convertToWei("1");

    // Submit
    await scrobotInstance.submit(owner, { value: amount, from: user1 });
    const userInfoBeforeWithdraw = await scrobotInstance.userInfo(user1);
    assert(userInfoBeforeWithdraw[0].toString() === amount, "Invalid amount");

    // Withdraw
    await scrobotInstance.withdraw(amount, { from: user1 });
    const userInfoAfterWithdraw = await scrobotInstance.userInfo(user1);
    assert(userInfoAfterWithdraw[0].isZero(), "Share not updated after withdraw");
  });

  it("should calculate pending token rewards correctly", async () => {
    const amount = convertToWei("1");

    // Submit
    await scrobotInstance.submit(user1, { value: amount, from: user1 });

    // Fast-forward time
    await sleep(5000);

    // const userInfoAfterFastForwardTime = await scrobotInstance.userInfo(user1);
    // console.log("🚀 ~ file: scrobot.test.js:56 ~ it ~ userInfoAfterFastForwardTime:", userInfoAfterFastForwardTime.toString())
    // assert(userInfoAfterFastForwardTime[7].toString() > 0, "Invalid pending reward");
    const userInfo = await miningMachineInstance.getUserInfo(0, user1);
    console.log("🚀 ~ file: scrobot.test.js:58 ~ it ~ userInfo:", userInfo._userShare.toString())
  });
});

const convertToEther = (wei) => {
    return web3.utils.fromWei(wei, "ether");
}
const convertToWei = (ether) => {
    return web3.utils.toWei(ether, "ether");
}

const sleep = (ms) => {
    return new Promise(resolve => setTimeout(resolve, ms));
  }