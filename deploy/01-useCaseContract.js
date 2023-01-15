
module.exports = async ({ getNamedAccounts, deployments }) => {
  const { deploy } = deployments;
  const { deployer } = await getNamedAccounts();

  await deploy("UseCaseContract", {
    from: deployer,
    args: [],
    log: true,
    waitConfirmations: 1,
  });
};

module.exports.tags = ["all", "useCase"];
