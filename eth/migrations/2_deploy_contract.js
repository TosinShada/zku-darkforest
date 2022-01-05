const Verifier = artifacts.require("Verifier");
const DarkForestCore = artifacts.require("DarkForestCore");

module.exports = function (deployer) {
  deployer.deploy(Verifier).then(function () {
    return deployer.deploy(DarkForestCore, Verifier.address);
  });
};
