const { ethers } = require('hardhat');

describe('scripts/queue.js', function () {
  let owner, Ethernauts;

  before('identify signers', async function () {
    [owner] = await ethers.getSigners();
  });

  before('deploy and prepare contract', async function () {
    const factory = await ethers.getContractFactory('contracts/Ethernauts.sol:Ethernauts');

    Ethernauts = await factory.deploy(
      ...Object.values({
        maxGiftable: 5,
        maxTokens: 100,
        batchSize: 10,
        mintPrice: ethers.utils.parseEther('0.2'),
        earlyMintPrice: ethers.utils.parseEther('0.015'),
        initialCouponSigner: owner.address,
      })
    );

    await Ethernauts.setSaleState(2);
  });

  it('enqueues a mint job when receiving a Transfer event', async function () {
    const tx = await Ethernauts.mint({
      value: hre.ethers.utils.parseEther('0.6'),
    });

    await tx.wait();
  });
});
