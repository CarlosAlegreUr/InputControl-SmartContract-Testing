const { assert, expect, use } = require("chai");
const { ethers, getNamedAccounts } = require("hardhat");

describe("InputControl.sol tests", function () {
  let deployer,
    client1,
    client2,
    inputControlContract,
    allowedInputsEventFilter,
    useCaseContract,
    useCaseContractClient1;

  beforeEach(async function () {
    const {
      deployer: dep,
      client1: c1,
      client2: c2,
    } = await getNamedAccounts();
    deployer = dep;
    client1 = c1;
    client2 = c2;
    inputControlContract = await ethers.getContract("InputControl");
    allowedInputsEventFilter = await inputControlContract.filters
      .InputControl__AllowedInputsGranted;
  });

  describe("Tests when inputs must be called in a sequence.", function () {
    describe("Internal functionalities tests.", function () {
      it("Allowed input is stored and accessed correctly.", async () => {
        let validInputs = await ethers.utils.solidityPack(
          ["uint256", "string"],
          ["2", "valid"]
        );
        validInputs = await ethers.utils.keccak256(validInputs);

        // Values for functions are stored correctly and event is emitted.
        let txResponse = await inputControlContract.callAllowInputsFor(
          client1,
          [validInputs],
          "func()",
          true
        );
        let txReceipt = await txResponse.wait();
        let txBlock = txReceipt.blockNumber;
        let query = await inputControlContract.queryFilter(
          allowedInputsEventFilter,
          txBlock
        );

        let validInputsEmitted = query[0].args[2][0];
        assert.equal(validInputsEmitted, validInputs);

        let allowedInputs = await inputControlContract.getAllowedInputs(
          "func()",
          client1,
          true
        );
        assert.equal(allowedInputs, validInputs);

        // Same values for same function but different client are stored correctly.
        await inputControlContract.callAllowInputsFor(
          client2,
          [validInputs],
          "func()",
          true
        );

        allowedInputs = await inputControlContract.getAllowedInputs(
          "func()",
          client2,
          true
        );
        assert.equal(allowedInputs, validInputs);
      });

      it("When allowing multiple calls with inputs' sequence, array stored and accessed correctly.", async () => {
        let validInputs = await ethers.utils.solidityPack(
          ["uint256", "string"],
          ["2", "valid"]
        );
        let validInputs2 = await ethers.utils.solidityPack(
          ["uint256", "string"],
          ["3", "valid"]
        );
        validInputs = await ethers.utils.keccak256(validInputs);
        validInputs2 = await ethers.utils.keccak256(validInputs2);

        await inputControlContract.callAllowInputsFor(
          client1,
          [validInputs, validInputs2],
          "func()",
          true
        );

        let allowedInputs = await inputControlContract.getAllowedInputs(
          "func()",
          client1,
          true
        );
        assert.equal(allowedInputs[0], validInputs);
        assert.equal(allowedInputs[1], validInputs2);
      });
    });

    describe("InputControl functionalities implemented in other contract tests.", function () {
      beforeEach(async function () {
        useCaseContract = await ethers.getContract("UseCaseContract", deployer);
        useCaseContractClient1 = await ethers.getContract(
          "UseCaseContract",
          client1
        );
      });

      it("Using InputControl in other contract.", async () => {
        let validInputs = await ethers.utils.solidityPack(
          ["uint256", "address"],
          [1, "0x000000000000000000000000000000000000dEaD"]
        );
        validInputs = await ethers.utils.keccak256(validInputs);

        let validInputs2 = await ethers.utils.solidityPack(
          ["uint256", "address"],
          ["3", "0x000000000000000000000000000000000000dEaD"]
        );
        validInputs2 = await ethers.utils.keccak256(validInputs2);

        // Permission not given yet, must revert.
        await expect(
          useCaseContractClient1.myFuncInSequence(
            1,
            "0x000000000000000000000000000000000000dEaD"
          )
        ).revertedWithCustomError(
          useCaseContractClient1,
          "InputControl__NotAllowedInput"
        );

        await useCaseContract.callAllowInputsFor(
          client1,
          [validInputs, validInputs2],
          "myFuncInSequence(uint256, address)",
          true
        );

        // Permission given but calling in different order, must revert.
        await expect(
          useCaseContractClient1.myFuncInSequence(
            3,
            "0x000000000000000000000000000000000000dEaD"
          )
        ).revertedWithCustomError(
          useCaseContractClient1,
          "InputControl__NotAllowedInput"
        );

        // Calling in correct order, should execute correctly.
        await useCaseContractClient1.myFuncInSequence(
          1,
          "0x000000000000000000000000000000000000dEaD"
        );
        let number = await useCaseContractClient1.getNumber();
        assert.equal(1, number);

        await useCaseContractClient1.myFuncInSequence(
          3,
          "0x000000000000000000000000000000000000dEaD"
        );
        number = await useCaseContractClient1.getNumber();
        assert.equal(3, number);

        // After calling correctly, if calling again must revert.
        await expect(
          useCaseContractClient1.myFuncInSequence(
            1,
            "0x000000000000000000000000000000000000dEaD"
          )
        ).revertedWithCustomError(
          useCaseContractClient1,
          "InputControl__NotAllowedInput"
        );
      });
    });
  });

  describe("Tests when inputs can be called in any order.", function () {
    describe("Internal functionalities tests.", function () {
      it("Allowed input is stored and accessed correctly.", async () => {
        let validInputs = await ethers.utils.solidityPack(
          ["uint256", "string"],
          ["2", "valid"]
        );
        validInputs = await ethers.utils.keccak256(validInputs);

        // Values for functions are stored correctly and event is emitted.
        let txResponse = await inputControlContract.callAllowInputsFor(
          client1,
          [validInputs],
          "func()",
          false
        );
        let txReceipt = await txResponse.wait();
        let txBlock = txReceipt.blockNumber;
        let query = await inputControlContract.queryFilter(
          allowedInputsEventFilter,
          txBlock
        );

        let validInputsEmitted = query[0].args[2][0];
        assert.equal(validInputsEmitted, validInputs);

        let allowedInputs = await inputControlContract.getAllowedInputs(
          "func()",
          client1,
          false
        );
        assert.equal(allowedInputs, validInputs);

        // Same values for same function but different client are stored correctly.
        await inputControlContract.callAllowInputsFor(
          client2,
          [validInputs],
          "func()",
          false
        );

        allowedInputs = await inputControlContract.getAllowedInputs(
          "func()",
          client2,
          false
        );
        assert.equal(allowedInputs, validInputs);
      });

      it(`Simulating allowing input with "hash collision", must revert.`, async () => {
        let validInputs = await ethers.utils.solidityPack(
          ["uint256", "string"],
          ["2", "valid"]
        );
        validInputs = await ethers.utils.keccak256(validInputs);

        // Values for functions are stored correctly and event is emitted.
        await expect(
          inputControlContract.callAllowInputsFor(
            client1,
            [
              validInputs,
              "0x0000000000000000000000000000000000000000000000000000000000000000",
            ],
            "func()",
            false
          )
        ).revertedWithCustomError(
          inputControlContract,
          "InputControl_HashCollisionWith0Value"
        );
      });
    });

    describe("InputControl functionalities implemented in other contract tests.", function () {
      beforeEach(async function () {
        useCaseContract = await ethers.getContract("UseCaseContract", deployer);
        useCaseContractClient1 = await ethers.getContract(
          "UseCaseContract",
          client1
        );
      });

      it("Using InputControl in other contract.", async () => {
        let validInputs = await ethers.utils.solidityPack(
          ["uint256", "address"],
          [1, "0x000000000000000000000000000000000000dEaD"]
        );
        validInputs = await ethers.utils.keccak256(validInputs);

        let validInputs2 = await ethers.utils.solidityPack(
          ["uint256", "address"],
          ["3", "0x000000000000000000000000000000000000dEaD"]
        );
        validInputs2 = await ethers.utils.keccak256(validInputs2);

        // Permission not given yet, must revert.
        await expect(
          useCaseContractClient1.myFuncInSequence(
            1,
            "0x000000000000000000000000000000000000dEaD"
          )
        ).revertedWithCustomError(
          useCaseContractClient1,
          "InputControl__NotAllowedInput"
        );

        await useCaseContract.callAllowInputsFor(
          client1,
          [validInputs, validInputs2],
          "myFuncUnordered(uint256, address)",
          false
        );

        // Permission given, should not revert.
        await useCaseContractClient1.myFuncUnordered(
          3,
          "0x000000000000000000000000000000000000dEaD"
        );
        let number = await useCaseContractClient1.getNumber();
        assert.equal(3, number);

        await useCaseContractClient1.myFuncUnordered(
          1,
          "0x000000000000000000000000000000000000dEaD"
        );
        number = await useCaseContractClient1.getNumber();
        assert.equal(1, number);

        // Inputs already used, must revert.
        await expect(
          useCaseContractClient1.myFuncUnordered(
            3,
            "0x000000000000000000000000000000000000dEaD"
          )
        ).revertedWithCustomError(
          useCaseContractClient1,
          "InputControl__NotAllowedInput"
        );

        await expect(
          useCaseContractClient1.myFuncUnordered(
            1,
            "0x000000000000000000000000000000000000dEaD"
          )
        ).revertedWithCustomError(
          useCaseContractClient1,
          "InputControl__NotAllowedInput"
        );
      });

      it(`Simulating allowing input with "hash collision", must revert.`, async () => {
        let validInputs = await ethers.utils.solidityPack(
          ["uint256", "string"],
          ["2", "valid"]
        );
        validInputs = await ethers.utils.keccak256(validInputs);

        // Values for functions are stored correctly and event is emitted.
        await expect(
          useCaseContract.callAllowInputsFor(
            client1,
            [
              validInputs,
              "0x0000000000000000000000000000000000000000000000000000000000000000",
            ],
            "func()",
            false
          )
        ).revertedWithCustomError(
          useCaseContract,
          "InputControl_HashCollisionWith0Value"
        );
      });
    });
  });
});
