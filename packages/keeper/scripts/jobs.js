const { Worker } = require('bullmq');
const config = require('../src/config');
const mintsProcessor = require('../src/mints-processor');

(async () => {
  const worker = new Worker(config.MINTS_QUEUE_NAME, mintsProcessor, {
    concurrency: config.MINTS_QUEUE_CONCURRENCY,
    connection: {
      host: config.REDIS_HOST,
      port: config.REDIS_PORT,
    },
  });

  worker
    .on('completed', (job) => console.log('completed: ', JSON.stringify(job)))
    .on('error', (err) => console.error(err))
    .on('failed', (job) => console.log('failed: ', JSON.stringify(job)));

  await worker.waitUntilReady();

  console.log(' - worker started - ');
})();
