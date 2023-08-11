// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {Test} from "forge-std/Test.sol";
import "forge-std/console.sol";

// Composite (modular) version
import {InputControlModular} from "../../contracts/modularVersion/InputControlModular.sol";
import {IInputControlModular} from "../../contracts/modularVersion/IInputControlModular.sol";
import {UseCaseContractModular} from "../../contracts/modularVersion/UseCaseContractModular.sol";

contract FuzzInputControlModular is Test {
    address public owner = makeAddr("owner");
    address public userOne = makeAddr("user1");
    UseCaseContractModular public c;
    IInputControlModular inputCModular;

    function setUp() public {
        vm.startPrank(owner);
        inputCModular = IInputControlModular(new InputControlModular());
        c = new UseCaseContractModular(address(inputCModular));
        inputCModular.setAdmin(address(c));
        vm.stopPrank();
    }

    function giveInputsPermission(address user, bytes32[] memory inputs, string memory funcSignature, bool isSequence)
        private
    {
        vm.prank(owner);
        c.giveInputPermission(user, inputs, funcSignature, isSequence);
    }

    function testFuzzOnlyAllowedUser(address user) public {
        vm.assume(user != userOne);

        // Creating inputs identifier
        bytes32 input = keccak256(abi.encode(1, userOne));
        bytes32[] memory inputs = new bytes32[](1);
        inputs[0] = input;

        // Giving permissions
        giveInputsPermission(userOne, inputs, "myFunc(uint256,address)", false);

        vm.expectRevert();
        vm.prank(user);
        c.myFunc(1, userOne);
    }

    function testFuzzInputsArraySavesCorrectly(uint256 size, uint256 inputBytesRandomizer) public {
        // Setting up realistic fuzz values
        if (inputBytesRandomizer == 0) {
            inputBytesRandomizer = size;
        }
        size = bound(size, 1, 100);

        // Filling up with random inputs' ids
        bytes32[] memory inputs = new bytes32[](size);
        uint256 randomizerHelper;
        for (uint256 i = 0; i < size; i++) {
            randomizerHelper = i + 1;
            inputs[i] = bytes32(inputBytesRandomizer % randomizerHelper);
        }

        console.log("For passed");

        // Giving permissions
        giveInputsPermission(userOne, inputs, "myFunc(uint256,address)", false);

        // Reading inputs from contract and checking if all equal
        bytes32[] memory savedInputs = inputCModular.getAllowedInputs("myFunc(uint256,address)", userOne);
        for (uint256 i = 0; i < size; i++) {
            assertEq(inputs[i], savedInputs[i]);
        }
    }

    function testFuzzSequenceOrNotSavesCorrectly(bool isSeq) public {
        bytes32[] memory inputs = new bytes32[](1);
        uint256 v = 69;
        inputs[0] = bytes32(v);
        giveInputsPermission(userOne, inputs, "myFunc(uint256,address)", isSeq);

        bool saved = inputCModular.getIsSequence("myFunc(uint256,address)", userOne);
        assertEq(saved, isSeq);
    }

    function testFuzzAdminChangesCoorectly(address newAdmin) public {
        vm.prank(owner);
        if (newAdmin == address(0)) {
            vm.expectRevert();
            c.changeAdmin(newAdmin);
        } else {
            c.changeAdmin(newAdmin);
            address changedTo = inputCModular.getAdmin();
            assertEq(newAdmin, changedTo);

            // Resetting values
            vm.prank(newAdmin);
            inputCModular.setAdmin(owner);
        }
    }
}
