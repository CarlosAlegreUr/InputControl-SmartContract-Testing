
module.exports = async ({ getNamedAccounts, deployments }) => {
  const { deploy } = deployments;
  const { deployer } = await getNamedAccounts();

  await deploy("InputControl", {
    from: deployer,
    args: [],
    log: true,
    waitConfirmations: 1,
  });
};

module.exports.tags = ["all", "inputControl"];
