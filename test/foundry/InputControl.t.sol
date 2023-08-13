// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

import {Test} from "../../lib/forge-std/src/Test.sol";
import "../../lib/forge-std/src/console.sol";

// Composite version
import {InputControl} from "contracts/owned/inheritanceVersion/InputControl.sol";
import {IInputControl} from "contracts/owned/inheritanceVersion/IInputControl.sol";
import {UseCaseContract} from "contracts/owned/inheritanceVersion/UseCaseContract.sol";

contract UnitTestICI is Test {
    /**
     *
     *  DATA STRUCTURES USED
     *
     */

    struct UseCaseContractInputs {
        uint256 num;
        address addr;
        bytes32 id;
    }

    // Addresses used
    address public owner1 = makeAddr("owner1");
    address public user1 = makeAddr("user1");
    address public user2 = makeAddr("user2");

    // Contracts used
    UseCaseContract public c1;

    // Functions used (only 1 so far myFunc)
    string public myFuncSig = "myFunc(uint256,address)";
    bytes4 public myFuncSelec = bytes4(keccak256(bytes(myFuncSig)));

    // Inputs used
    UseCaseContractInputs public input0 =
        UseCaseContractInputs({num: 0, addr: address(0), id: keccak256(abi.encode(address(0), 0))});
    UseCaseContractInputs public input1 =
        UseCaseContractInputs({num: 1, addr: address(1), id: keccak256(abi.encode(address(1), 1))});
    UseCaseContractInputs public input2 =
        UseCaseContractInputs({num: 2, addr: address(2), id: keccak256(abi.encode(address(2), 2))});

    // Events used
    event InputControl__InputsPermissionGranted(
        IInputControl.Permission indexed permission, IInputControl.PermissionState state
    );

    // Shortened states access
    IInputControl.PermissionState public unordered = IInputControl.PermissionState.IS_UNORDERED;
    IInputControl.PermissionState public sequence = IInputControl.PermissionState.IS_SEQUENCE;
    IInputControl.PermissionState public notExisting = IInputControl.PermissionState.IS_NOT_EXISTING;

    function setUp() public {
        // Deployment of the contracts
        // c1 --> Owned by user1
        vm.prank(owner1);
        c1 = new UseCaseContract();
    }

    /**
     *
     *  HELPER FUNCTIONS
     *
     */
    function _createPermission(address _allower, bytes4 _functionSelector, address _caller)
        private
        pure
        returns (IInputControl.Permission memory)
    {
        IInputControl.Permission memory p =
            IInputControl.Permission({allower: _allower, functionSelector: _functionSelector, caller: _caller});
        return p;
    }

    function _compareArrays(bytes32[] memory arr1, bytes32[] memory arr2) private pure returns (bool areEqual) {
        if (arr1.length != arr2.length) return false;
        areEqual = true;
        for (uint256 i = 0; i < arr1.length; i++) {
            if (arr1[i] != arr2[i]) {
                areEqual = false;
                break;
            }
        }
        return areEqual;
    }

    /**
     *
     *  TESTS
     *
     */

    // If properly implemented with ICI: Only contracts can give permissions to its users.
    function testICI_SetInputsPermissionOnlyAdmin() public {
        // Users can't eventually execute permissions in properly set contracts
        IInputControl.Permission memory p = _createPermission(address(c1), myFuncSelec, user1);
        bytes32[] memory input = new bytes32[](1);
        input[0] = input0.id;

        // User tries to give himself permissions, he has never been an admin, shouldnt work
        vm.expectRevert();
        vm.startPrank(user1);
        c1.myFunc(input0.num, input0.addr);

        vm.expectRevert();
        c1.myFunc(input0.num, input0.addr);
        vm.stopPrank();

        // Onwer1 used to be an admin but not anymore, shoudnt work.
        vm.expectRevert();
        vm.startPrank(owner1);
        c1.myFunc(input0.num, input0.addr);

        vm.expectRevert();
        c1.myFunc(input0.num, input0.addr);
        vm.stopPrank();

        // Now owner gives him permissions through the admin contract
        vm.prank(owner1);
        c1.callSetInputsPermission(p, input, false);
        // User2 tries to use inputs of user1
        vm.expectRevert(IInputControl.InputControl__PermissionDoesntExist.selector);
        vm.prank(user2);
        c1.myFunc(input0.num, input0.addr);
        // User 1 calls function and works
        vm.prank(user1);
        c1.myFunc(input0.num, input0.addr);
    }

    // Order of sequence inputs calls is correct
    function testICI_InputsSequencesOnlyAllowsCorrectOrder() public {
        IInputControl.Permission memory p = _createPermission(address(c1), myFuncSelec, user1);
        bytes32[] memory input = new bytes32[](2);
        input[0] = input0.id;
        input[1] = input1.id;

        // Giving permissions
        vm.prank(owner1);
        c1.callSetInputsPermission(p, input, true);

        // Using incorrect input (no permissions for input 2)
        vm.expectRevert(IInputControl.InputControl__NotAllowedInput.selector);
        vm.prank(user1);
        c1.myFunc(input2.num, input2.addr);

        // Using incorrect input
        vm.expectRevert(IInputControl.InputControl__NotAllowedInput.selector);
        vm.prank(user1);
        c1.myFunc(input1.num, input1.addr);

        // Using correct input
        vm.prank(user1);
        c1.myFunc(input0.num, input0.addr);

        // Using incorrect input
        vm.expectRevert(IInputControl.InputControl__NotAllowedInput.selector);
        vm.prank(user1);
        c1.myFunc(input0.num, input0.addr);

        // Using correct input
        vm.prank(user1);
        c1.myFunc(input1.num, input1.addr);

        // Using incorrect input
        vm.expectRevert(IInputControl.InputControl__PermissionDoesntExist.selector);
        vm.prank(user1);
        c1.myFunc(input0.num, input0.addr);
    }

    // Order of unordered inputs calls is correct
    function testICI_InputsUnorderedOnlyAllowsCorrectCalls() public {
        IInputControl.Permission memory p = _createPermission(address(c1), myFuncSelec, user1);
        // We can use input id 1 twice and id input 0 once.
        bytes32[] memory input = new bytes32[](3);
        input[0] = input0.id;
        input[1] = input1.id;
        input[2] = input1.id;

        // Giving permissions
        vm.prank(owner1);
        c1.callSetInputsPermission(p, input, false);

        // Using incorrect input (no permissions for input 2)
        vm.expectRevert(IInputControl.InputControl__NotAllowedInput.selector);
        vm.prank(user1);
        c1.myFunc(input2.num, input2.addr);

        // Using correct input: Times for id0 left = 0
        vm.prank(user1);
        c1.myFunc(input0.num, input0.addr);

        // Using incorrect input
        vm.expectRevert(IInputControl.InputControl__NotAllowedInput.selector);
        vm.prank(user1);
        c1.myFunc(input0.num, input0.addr);

        // Using correct input: Times for id1 left = 1
        vm.prank(user1);
        c1.myFunc(input1.num, input1.addr);

        // Using incorrect input
        vm.expectRevert(IInputControl.InputControl__NotAllowedInput.selector);
        vm.prank(user1);
        c1.myFunc(input0.num, input0.addr);

        // Using correct input: Times for id1 left = 0
        vm.prank(user1);
        c1.myFunc(input1.num, input1.addr);

        // Using incorrect input
        vm.expectRevert(IInputControl.InputControl__PermissionDoesntExist.selector);
        vm.prank(user1);
        c1.myFunc(input0.num, input0.addr);
    }

    // Permissions are set and updated correctly.
    function testICI_SetInputsPermissionPermissionsAreManagedCorrectly() public {
        bytes32[] memory input = new bytes32[](2);
        input[0] = input0.id;
        input[1] = input1.id;

        // Now checking if inputs update correctly while users use them
        IInputControl.Permission memory p2 = _createPermission(address(c1), myFuncSelec, user1);
        vm.prank(owner1);
        c1.callSetInputsPermission(p2, input, true);

        // InputsIds where saved correctly
        bytes32[] memory saved = c1.getAllowedInputs(p2);
        bool areEqual = _compareArrays(saved, input);
        assertTrue(areEqual);
        // State updated correctly
        IInputControl.PermissionState state = c1.getPermissionState(p2);
        assertTrue(state == sequence);

        // Using first input
        vm.prank(user1);
        c1.myFunc(input0.num, input0.addr);

        // Checks
        bytes32[] memory input1UsedArray = new bytes32[](2);
        input1UsedArray[0] = bytes32(0);
        input1UsedArray[1] = input[1];
        saved = c1.getAllowedInputs(p2);
        areEqual = _compareArrays(saved, input1UsedArray);
        assertTrue(areEqual);
        state = c1.getPermissionState(p2);
        assertTrue(state == sequence);

        // Using second input
        vm.prank(user1);
        c1.myFunc(input1.num, input1.addr);

        saved = c1.getAllowedInputs(p2);
        assertTrue(saved.length == 0);
        state = c1.getPermissionState(p2);
        assertTrue(state == notExisting);

        // Same process but for unordered
        vm.prank(owner1);
        c1.callSetInputsPermission(p2, input, false);

        // InputsIds where saved correctly
        saved = c1.getAllowedInputs(p2);
        areEqual = _compareArrays(saved, input);
        assertTrue(areEqual);
        state = c1.getPermissionState(p2);
        assertTrue(state == unordered);

        // Using one input
        vm.prank(user1);
        c1.myFunc(input1.num, input1.addr);

        // Checks
        bytes32[] memory input2UsedArray = new bytes32[](2);
        input2UsedArray[0] = input[0];
        input2UsedArray[1] = bytes32(0);
        saved = c1.getAllowedInputs(p2);
        areEqual = _compareArrays(saved, input2UsedArray);
        assertTrue(areEqual);
        state = c1.getPermissionState(p2);
        assertTrue(state == unordered);

        // Using second input
        vm.prank(user1);
        c1.myFunc(input0.num, input0.addr);
        saved = c1.getAllowedInputs(p2);
        assertTrue(saved.length == 0);
        state = c1.getPermissionState(p2);
        assertTrue(state == notExisting);

        // Now we are gonna check if new inputs granted, the array of allowed
        // inputs should be replaced by the new one

        // In sequence
        vm.prank(owner1);
        c1.callSetInputsPermission(p2, input, true);

        // Using one input
        vm.prank(user1);
        c1.myFunc(input0.num, input0.addr);

        // Giving new inputs
        bytes32[] memory inputs2 = new bytes32[](2);
        inputs2[0] = input2.id;
        inputs2[1] = input1.id;
        vm.prank(owner1);
        c1.callSetInputsPermission(p2, inputs2, true);

        // Checks
        saved = c1.getAllowedInputs(p2);
        areEqual = _compareArrays(saved, inputs2);
        assertTrue(areEqual);
        state = c1.getPermissionState(p2);
        assertTrue(state == sequence);

        // Same but in unordered
        vm.prank(owner1);
        c1.callSetInputsPermission(p2, input, false);

        // Using one input
        vm.prank(user1);
        c1.myFunc(input1.num, input1.addr);

        // Giving new inputs
        vm.prank(owner1);
        c1.callSetInputsPermission(p2, inputs2, false);

        // Checks
        saved = c1.getAllowedInputs(p2);
        areEqual = _compareArrays(saved, inputs2);
        assertTrue(areEqual);
        state = c1.getPermissionState(p2);
        assertTrue(state == unordered);
    }
}
