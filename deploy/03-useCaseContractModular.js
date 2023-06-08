module.exports = async ({ getNamedAccounts, deployments }) => {
  const { deploy } = deployments;
  const { deployer } = await getNamedAccounts();

  const inputControlModularContract = await deployments.get(
    "InputControlModular"
  );

  await deploy("UseCaseContractModular", {
    from: deployer,
    args: [inputControlModularContract.address],
    log: true,
    waitConfirmations: 1,
  });
};

module.exports.tags = ["all", "useCaseModular"];
