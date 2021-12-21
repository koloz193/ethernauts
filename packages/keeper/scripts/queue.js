const { Queue } = require('bullmq');
const { getContractFromAbi } = require('@ethernauts/hardhat/src/utils/hardhat');
const config = require('../src/config');
const parseMintEvent = require('../src/parse-mint-event');

const mintsQueue = new Queue(config.MINTS_QUEUE_NAME, {
  connection: {
    host: config.REDIS_HOST,
    port: config.REDIS_PORT,
  },
});

async function main() {
  const Ethernauts = await getContractFromAbi('Ethernauts');

  const batchSize = await Ethernauts.batchSize();

  console.log({ batchSize });

  console.log(`Listening for events on Ethernauts token at ${Ethernauts.address}`);

  Ethernauts.on('Transfer', (...args) => {
    const result = parseMintEvent(...args);

    if (result) {
      const { tokenId, to } = result;
      mintsQueue.add('mints', { tokenId, to });
      console.log(`Mint detected, tokenId: ${tokenId}`);
    }
  });
}

main().catch((err) => {
  console.error(err);
  process.exit(1);
});
