module.exports = async ({ getNamedAccounts, deployments }) => {
  const { deploy } = deployments;
  const { deployer } = await getNamedAccounts();

  const inputControlModularContract = await ethers.getContract(
    "InputControlModular",
    deployer
  );

  await deploy("UseCaseContractModular", {
    from: deployer,
    args: [inputControlModularContract.address],
    log: true,
    waitConfirmations: 1,
  });

  const useCaseContract = await deployments.get("UseCaseContractModular");

  await inputControlModularContract.setAdmin(useCaseContract.address);
};

module.exports.tags = ["all", "useCaseModular"];
