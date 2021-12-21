/**
 *
 * @param {Object} job
 * @param {string} job.to
 * @param {string} job.tokenId
 */
module.exports = async function mintsProcessor(job) {
  // TODO: Get job data and if a new batch was triggered, upload the necessary
  //       resources to the IPFS server.
  console.log('processed: ', JSON.stringify(job));
};
