////////////////////////////////////////////////////////////////////
//  THESE TEST WERE WRITTEN FOR PREVIOUS VERSIONS OF THE CODE     //
//  THEY NO LONGER HOLD DUE TO ARCHITERTURAL CHANGES IN THE CODE  //
//  THEIR ADAPTION SHOULDN'T BE VERY HARD YET I DIDNT CODE IT YET //
////////////////////////////////////////////////////////////////////
const { assert, expect } = require("chai");
const { ethers, getNamedAccounts } = require("hardhat");

describe("InputControlModular.sol tests", function () {
  let deployer,
    client1,
    client2,
    inputControlModularContract,
    allowedInputsEventFilter,
    useCaseModularContract,
    useCaseContractModularClient1,
    validInputs,
    validInputs2;

  beforeEach(async function () {
    const {
      deployer: dep,
      client1: c1,
      client2: c2,
    } = await getNamedAccounts();
    deployer = dep;
    client1 = c1;
    client2 = c2;
    inputControlModularContract = await ethers.getContract(
      "InputControlModular"
    );
    useCaseModularContract = await ethers.getContract(
      "UseCaseContractModular",
      deployer
    );

    allowedInputsEventFilter = await inputControlModularContract.filters
      .InputControlModular__AllowedInputsGranted;

    validInputs = await ethers.utils.defaultAbiCoder.encode(
      ["uint256", "address"],
      [1, "0x000000000000000000000000000000000000dEaD"]
    );
    validInputs = await ethers.utils.keccak256(validInputs);

    validInputs2 = await ethers.utils.defaultAbiCoder.encode(
      ["uint256", "address"],
      ["3", "0x000000000000000000000000000000000000dEaD"]
    );
    validInputs2 = await ethers.utils.keccak256(validInputs2);
  });

  describe("Tests when inputs must be called in a sequence.", function () {
    describe("Internal functionalities tests.", function () {
      it("Allowed input is stored and accessed correctly and isSequence map updates correctly.", async () => {
        // Values for functions are stored correctly and event is emitted.
        let txResponse = await useCaseModularContract.giveInputPermission(
          client1,
          [validInputs],
          "func()",
          true
        );
        let txReceipt = await txResponse.wait();
        let txBlock = txReceipt.blockNumber;
        let query = await inputControlModularContract.queryFilter(
          allowedInputsEventFilter,
          txBlock
        );

        let validInputsEmitted = query[0].args[2][0];
        assert.equal(validInputsEmitted, validInputs);

        let allowedInputs = await inputControlModularContract.getAllowedInputs(
          "func()",
          client1
        );
        assert.equal(allowedInputs, validInputs);

        let sequence = await inputControlModularContract.getIsSequence(
          "func()",
          client1
        );
        assert.equal(sequence, true);

        // Same values for same function but different client are stored correctly.
        await useCaseModularContract.giveInputPermission(
          client2,
          [validInputs],
          "func()",
          true
        );

        allowedInputs = await inputControlModularContract.getAllowedInputs(
          "func()",
          client2
        );
        assert.equal(allowedInputs, validInputs);
      });

      it("When allowing multiple calls with inputs' sequence, array stored and accessed correctly.", async () => {
        await useCaseModularContract.giveInputPermission(
          client1,
          [validInputs, validInputs2],
          "func()",
          true
        );

        let allowedInputs = await inputControlModularContract.getAllowedInputs(
          "func()",
          client1
        );
        assert.equal(allowedInputs[0], validInputs);
        assert.equal(allowedInputs[1], validInputs2);
      });
    });

    describe("InputControlModular functionalities implemented in other contract tests.", function () {
      beforeEach(async function () {
        useCaseContractModularClient1 = await ethers.getContract(
          "UseCaseContractModular",
          client1
        );
      });

      it("Using InputControlModular in other contract.", async () => {
        // Permission not given yet, must revert.
        await expect(
          useCaseContractModularClient1.myFunc(
            1,
            "0x000000000000000000000000000000000000dEaD"
          )
        ).revertedWithCustomError(
          inputControlModularContract,
          "InputControlModular__NotAllowedInput"
        );

        await useCaseModularContract.giveInputPermission(
          client1,
          [validInputs, validInputs2, validInputs],
          "myFunc(uint256,address)",
          true
        );

        // Permission given but calling in different order, must revert.
        await expect(
          useCaseContractModularClient1.myFunc(
            3,
            "0x000000000000000000000000000000000000dEaD"
          )
        ).revertedWithCustomError(
          inputControlModularContract,
          "InputControlModular__NotAllowedInput"
        );

        // Calling in correct order, should execute correctly.
        await useCaseContractModularClient1.myFunc(
          1,
          "0x000000000000000000000000000000000000dEaD"
        );
        let number = await useCaseContractModularClient1.getNumber();
        assert.equal(1, number);

        await useCaseContractModularClient1.myFunc(
          3,
          "0x000000000000000000000000000000000000dEaD"
        );
        number = await useCaseContractModularClient1.getNumber();
        assert.equal(3, number);

        await useCaseContractModularClient1.myFunc(
          1,
          "0x000000000000000000000000000000000000dEaD"
        );
        number = await useCaseContractModularClient1.getNumber();
        assert.equal(1, number);

        // After calling correctly, if calling again must revert.
        await expect(
          useCaseContractModularClient1.myFunc(
            1,
            "0x000000000000000000000000000000000000dEaD"
          )
        ).revertedWithCustomError(
          inputControlModularContract,
          "InputControlModular__NotAllowedInput"
        );

        await expect(
          useCaseContractModularClient1.myFunc(
            3,
            "0x000000000000000000000000000000000000dEaD"
          )
        ).revertedWithCustomError(
          inputControlModularContract,
          "InputControlModular__NotAllowedInput"
        );

        await expect(
          useCaseContractModularClient1.myFunc(
            1,
            "0x000000000000000000000000000000000000dEaD"
          )
        ).revertedWithCustomError(
          inputControlModularContract,
          "InputControlModular__NotAllowedInput"
        );
      });
    });
  });

  describe("Tests when inputs can be called in any order.", function () {
    describe("Internal functionalities tests.", function () {
      it("Allowed input is stored and accessed correctly.", async () => {
        // Values for functions are stored correctly and event is emitted.
        let txResponse = await useCaseModularContract.giveInputPermission(
          client1,
          [validInputs],
          "func()",
          false
        );
        let txReceipt = await txResponse.wait();
        let txBlock = txReceipt.blockNumber;
        let query = await inputControlModularContract.queryFilter(
          allowedInputsEventFilter,
          txBlock
        );

        let validInputsEmitted = query[0].args[2][0];
        assert.equal(validInputsEmitted, validInputs);

        let allowedInputs = await inputControlModularContract.getAllowedInputs(
          "func()",
          client1
        );
        assert.equal(allowedInputs, validInputs);

        let sequence = await inputControlModularContract.getIsSequence(
          "func()",
          client1
        );
        assert.equal(sequence, false);

        // Same values for same function but different client are stored correctly.
        await useCaseModularContract.giveInputPermission(
          client2,
          [validInputs],
          "func()",
          false
        );

        allowedInputs = await inputControlModularContract.getAllowedInputs(
          "func()",
          client2
        );
        assert.equal(allowedInputs, validInputs);
      });
    });

    describe("InputControlModular functionalities implemented in other contract tests.", function () {
      beforeEach(async function () {
        useCaseContractModularClient1 = await ethers.getContract(
          "UseCaseContractModular",
          client1
        );
      });

      it("Only Admin can call.", async () => {
        // Admin now is UseCaseContract, should revert if calling with deployer.
        inputControlModularContract = await ethers.getContract(
          "InputControlModular",
          deployer
        );

        await expect(
          inputControlModularContract.allowInputsFor(
            client1,
            [validInputs, validInputs2, validInputs],
            "myFunc(uint256,address)",
            false
          )
        ).revertedWithCustomError(
          inputControlModularContract,
          "InputControlModular__OnlyAdmin"
        );
      });

      it("Using InputControlModular in other contract.", async () => {
        // Permission not given yet, must revert.
        await expect(
          useCaseContractModularClient1.myFunc(
            1,
            "0x000000000000000000000000000000000000dEaD"
          )
        ).revertedWithCustomError(
          inputControlModularContract,
          "InputControlModular__NotAllowedInput"
        );

        await useCaseModularContract.giveInputPermission(
          client1,
          [validInputs, validInputs2, validInputs],
          "myFunc(uint256,address)",
          false
        );

        // Permission given, should not revert.
        await useCaseContractModularClient1.myFunc(
          3,
          "0x000000000000000000000000000000000000dEaD"
        );
        let number = await useCaseContractModularClient1.getNumber();
        assert.equal(3, number);

        await useCaseContractModularClient1.myFunc(
          1,
          "0x000000000000000000000000000000000000dEaD"
        );
        number = await useCaseContractModularClient1.getNumber();
        assert.equal(1, number);

        await useCaseContractModularClient1.myFunc(
          1,
          "0x000000000000000000000000000000000000dEaD"
        );
        number = await useCaseContractModularClient1.getNumber();
        assert.equal(1, number);

        // Inputs already used, must revert.
        await expect(
          useCaseContractModularClient1.myFunc(
            3,
            "0x000000000000000000000000000000000000dEaD"
          )
        ).revertedWithCustomError(
          inputControlModularContract,
          "InputControlModular__NotAllowedInput"
        );

        await expect(
          useCaseContractModularClient1.myFunc(
            1,
            "0x000000000000000000000000000000000000dEaD"
          )
        ).revertedWithCustomError(
          inputControlModularContract,
          "InputControlModular__NotAllowedInput"
        );

        await expect(
          useCaseContractModularClient1.myFunc(
            1,
            "0x000000000000000000000000000000000000dEaD"
          )
        ).revertedWithCustomError(
          inputControlModularContract,
          "InputControlModular__NotAllowedInput"
        );
      });

      it("Correct inputToTimesToUse mapping reset test.", async () => {
        await useCaseModularContract.giveInputPermission(
          client1,
          [validInputs, validInputs2, validInputs],
          "myFunc(uint256,address)",
          false
        );

        // Permission given, should not revert.
        await useCaseContractModularClient1.myFunc(
          3,
          "0x000000000000000000000000000000000000dEaD"
        );
        let number = await useCaseContractModularClient1.getNumber();
        assert.equal(3, number);

        await useCaseContractModularClient1.myFunc(
          1,
          "0x000000000000000000000000000000000000dEaD"
        );
        number = await useCaseContractModularClient1.getNumber();
        assert.equal(1, number);

        // Client didn't finish but new permissions overwritten.
        await useCaseModularContract.giveInputPermission(
          client1,
          [validInputs, validInputs2, validInputs],
          "myFunc(uint256,address)",
          false
        );

        await useCaseContractModularClient1.myFunc(
          1,
          "0x000000000000000000000000000000000000dEaD"
        );
        number = await useCaseContractModularClient1.getNumber();
        assert.equal(1, number);

        await useCaseContractModularClient1.myFunc(
          1,
          "0x000000000000000000000000000000000000dEaD"
        );
        number = await useCaseContractModularClient1.getNumber();
        assert.equal(1, number);

        // Even though didn't use the last 1 value previously, as
        // overwrites, should revert.
        await expect(
          useCaseContractModularClient1.myFunc(
            1,
            "0x000000000000000000000000000000000000dEaD"
          )
        ).revertedWithCustomError(
          inputControlModularContract,
          "InputControlModular__NotAllowedInput"
        );

        await useCaseContractModularClient1.myFunc(
          3,
          "0x000000000000000000000000000000000000dEaD"
        );
        number = await useCaseContractModularClient1.getNumber();
        assert.equal(3, number);

        // Inputs already used, must revert.
        await expect(
          useCaseContractModularClient1.myFunc(
            3,
            "0x000000000000000000000000000000000000dEaD"
          )
        ).revertedWithCustomError(
          inputControlModularContract,
          "InputControlModular__NotAllowedInput"
        );
      });
    });
  });
});
