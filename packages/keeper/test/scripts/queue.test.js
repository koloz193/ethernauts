const { ethers } = require('hardhat');

describe('scripts/queue.js', function () {
  let owner, Ethernauts;

  before('identify signers', async () => {
    [owner] = await ethers.getSigners();
  });

  before('deploy contract', async () => {
    const factory = await ethers.getContractFactory('Ethernauts');
    Ethernauts = await factory.deploy({
      maxGiftable: 5,
      maxTokens: 100,
      batchSize: 10,
      mintPrice: ethers.utils.parseEther('0.2'),
      earlyMintPrice: ethers.utils.parseEther('0.015'),
      initialCouponSigner: owner.address,
    });
  });
});
