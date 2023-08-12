// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

import {Test} from "../../lib/forge-std/src/Test.sol";
import "../../lib/forge-std/src/console.sol";

// Composite (Global) version
import {InputControlGlobal} from "contracts/decentralized/globalVersion/InputControlGlobal.sol";
import {IInputControlGlobal} from "contracts/decentralized/globalVersion/IInputControlGlobal.sol";
import {UseCaseContractGlobal} from "contracts/decentralized/globalVersion/UseCaseContractGlobal.sol";

contract UnitTestICG is Test {
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
    UseCaseContractGlobal public c1;
    IInputControlGlobal inputCGlobal;

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
    event InputControlGlobal__InputsPermissionGranted(
        IInputControlGlobal.Permission indexed permission, IInputControlGlobal.PermissionState state
    );

    // Shortened states access
    IInputControlGlobal.PermissionState public unordered = IInputControlGlobal.PermissionState.IS_UNORDERED;
    IInputControlGlobal.PermissionState public sequence = IInputControlGlobal.PermissionState.IS_SEQUENCE;
    IInputControlGlobal.PermissionState public notExisting = IInputControlGlobal.PermissionState.IS_NOT_EXISTING;

    function setUp() public {
        // Deployment of the contracts
        // inputCGlobal --> Cant have owners
        // c1 --> Owned by user1
        vm.startPrank(owner1);
        inputCGlobal = IInputControlGlobal(new InputControlGlobal());
        c1 = new UseCaseContractGlobal(address(inputCGlobal));
        vm.stopPrank();
    }

    /**
     *
     *  HELPER FUNCTIONS
     *
     */
    function _createPermission(address _allower, address _contractAddress, bytes4 _functionSelector, address _caller)
        private
        pure
        returns (IInputControlGlobal.Permission memory)
    {
        IInputControlGlobal.Permission memory p = IInputControlGlobal.Permission({
            allower: _allower,
            contractAddress: _contractAddress,
            functionSelector: _functionSelector,
            caller: _caller
        });
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

    // If properly implemented with ICG: Only contracts can give permissions to its users.
    function test_SetInputsPermissionOnlyContract() public {
        // Users can't eventually execute permissions in properly set contracts
        IInputControlGlobal.Permission memory p = _createPermission(user1, address(c1), myFuncSelec, user1);
        bytes32[] memory input = new bytes32[](1);
        input[0] = input0.id;

        // User tries to give himself permissions
        vm.startPrank(user1);
        inputCGlobal.setInputsPermission(p, input, false);
        vm.expectRevert(IInputControlGlobal.InputControlGlobal__PermissionDoesntExist.selector);
        c1.myFunc(input0.num, input0.addr);

        inputCGlobal.setInputsPermission(p, input, true);
        vm.expectRevert(IInputControlGlobal.InputControlGlobal__PermissionDoesntExist.selector);
        c1.myFunc(input0.num, input0.addr);
        vm.stopPrank();

        // Now owner gives him permissions
        vm.prank(owner1);
        c1.giveInputPermission(user1, input, myFuncSig, false);
        // User2 tries to use inputs of user1
        vm.expectRevert(IInputControlGlobal.InputControlGlobal__PermissionDoesntExist.selector);
        vm.prank(user2);
        c1.myFunc(input0.num, input0.addr);
        // User 1 calls function and works
        vm.prank(user1);
        c1.myFunc(input0.num, input0.addr);
    }

    // Impersonation is not posible.
    function test_SetInputsPermissionImpersonationNotPosible() public {
        // User 1 impersonating user 2
        IInputControlGlobal.Permission memory p = _createPermission(user2, address(c1), myFuncSelec, user1);
        bytes32[] memory input = new bytes32[](1);
        input[0] = input0.id;

        // User tries impersonating
        vm.prank(user1);
        vm.expectRevert(IInputControlGlobal.InputControlGlobal__AllowerIsNotSender.selector);
        inputCGlobal.setInputsPermission(p, input, false);
    }

    // Order of sequence inputs calls is correct
    function test_InputsSequencesOnlyAllowsCorrectOrder() public {
        bytes32[] memory input = new bytes32[](2);
        input[0] = input0.id;
        input[1] = input1.id;

        // Giving permissions
        vm.prank(owner1);
        c1.giveInputPermission(user1, input, myFuncSig, true);

        // Using incorrect input (no permissions for input 2)
        vm.expectRevert(IInputControlGlobal.InputControlGlobal__NotAllowedInput.selector);
        vm.prank(user1);
        c1.myFunc(input2.num, input2.addr);

        // Using incorrect input
        vm.expectRevert(IInputControlGlobal.InputControlGlobal__NotAllowedInput.selector);
        vm.prank(user1);
        c1.myFunc(input1.num, input1.addr);

        // Using correct input
        vm.prank(user1);
        c1.myFunc(input0.num, input0.addr);

        // Using incorrect input
        vm.expectRevert(IInputControlGlobal.InputControlGlobal__NotAllowedInput.selector);
        vm.prank(user1);
        c1.myFunc(input0.num, input0.addr);

        // Using correct input
        vm.prank(user1);
        c1.myFunc(input1.num, input1.addr);

        // Using incorrect input
        vm.expectRevert(IInputControlGlobal.InputControlGlobal__PermissionDoesntExist.selector);
        vm.prank(user1);
        c1.myFunc(input0.num, input0.addr);
    }

    // Order of unordered inputs calls is correct
    function test_InputsUnorderedOnlyAllowsCorrectCalls() public {
        // We can use input id 1 twice and id input 0 once.
        bytes32[] memory input = new bytes32[](3);
        input[0] = input0.id;
        input[1] = input1.id;
        input[2] = input1.id;

        // Giving permissions
        vm.prank(owner1);
        c1.giveInputPermission(user1, input, myFuncSig, false);

        // Using incorrect input (no permissions for input 2)
        vm.expectRevert(IInputControlGlobal.InputControlGlobal__NotAllowedInput.selector);
        vm.prank(user1);
        c1.myFunc(input2.num, input2.addr);

        // Using correct input: Times for id0 left = 0
        vm.prank(user1);
        c1.myFunc(input0.num, input0.addr);

        // Using incorrect input
        vm.expectRevert(IInputControlGlobal.InputControlGlobal__NotAllowedInput.selector);
        vm.prank(user1);
        c1.myFunc(input0.num, input0.addr);

        // Using correct input: Times for id1 left = 1
        vm.prank(user1);
        c1.myFunc(input1.num, input1.addr);

        // Using incorrect input
        vm.expectRevert(IInputControlGlobal.InputControlGlobal__NotAllowedInput.selector);
        vm.prank(user1);
        c1.myFunc(input0.num, input0.addr);

        // Using correct input: Times for id1 left = 0
        vm.prank(user1);
        c1.myFunc(input1.num, input1.addr);

        // Using incorrect input
        vm.expectRevert(IInputControlGlobal.InputControlGlobal__PermissionDoesntExist.selector);
        vm.prank(user1);
        c1.myFunc(input0.num, input0.addr);
    }

    // Permissions are set and updated correctly.
    function test_SetInputsPermissionPermissionsAreManagedCorrectly() public {
        IInputControlGlobal.Permission memory p = _createPermission(user1, address(c1), myFuncSelec, user1);
        bytes32[] memory input = new bytes32[](2);
        input[0] = input0.id;
        input[1] = input1.id;

        // Check permissions ID calculation is correct inside the contract getter
        bytes32 expectedId = keccak256(abi.encode(p.allower, p.contractAddress, p.functionSelector, p.caller));
        assertTrue(expectedId == inputCGlobal.getPermissionId(p));

        // Not saved, not exsting
        IInputControlGlobal.PermissionState state = inputCGlobal.getPermissionState(p);
        assertTrue(notExisting == state);

        // Saving in unordered
        vm.prank(user1);
        inputCGlobal.setInputsPermission(p, input, false);
        // State check
        state = inputCGlobal.getPermissionState(p);
        assertTrue(unordered == state);
        // Inputs array check
        bytes32[] memory saved = inputCGlobal.getAllowedInputs(p);
        bool areEqual = _compareArrays(saved, input);
        assertTrue(areEqual);

        // Saving in ordered
        vm.prank(user1);
        inputCGlobal.setInputsPermission(p, input, true);
        state = inputCGlobal.getPermissionState(p);
        assertTrue(sequence == state);
        saved = inputCGlobal.getAllowedInputs(p);
        areEqual = _compareArrays(saved, input);
        assertTrue(areEqual);

        // Now checking if inputs update correctly while users use them
        IInputControlGlobal.Permission memory p2 = _createPermission(address(c1), address(c1), myFuncSelec, user1);
        vm.prank(owner1);
        c1.giveInputPermission(user1, input, myFuncSig, true);

        // InputsIds where saved correctly
        saved = inputCGlobal.getAllowedInputs(p2);
        areEqual = _compareArrays(saved, input);
        assertTrue(areEqual);
        // State updated correctly
        state = inputCGlobal.getPermissionState(p2);
        assertTrue(state == sequence);

        // Using first input
        vm.prank(user1);
        c1.myFunc(input0.num, input0.addr);

        // Checks
        bytes32[] memory input1UsedArray = new bytes32[](2);
        input1UsedArray[0] = bytes32(0);
        input1UsedArray[1] = input[1];
        saved = inputCGlobal.getAllowedInputs(p2);
        areEqual = _compareArrays(saved, input1UsedArray);
        assertTrue(areEqual);
        state = inputCGlobal.getPermissionState(p2);
        assertTrue(state == sequence);

        // Using second input
        vm.prank(user1);
        c1.myFunc(input1.num, input1.addr);

        saved = inputCGlobal.getAllowedInputs(p2);
        assertTrue(saved.length == 0);
        state = inputCGlobal.getPermissionState(p2);
        assertTrue(state == notExisting);

        // Same process but for unordered
        vm.prank(owner1);
        c1.giveInputPermission(user1, input, myFuncSig, false);

        // InputsIds where saved correctly
        saved = inputCGlobal.getAllowedInputs(p2);
        areEqual = _compareArrays(saved, input);
        assertTrue(areEqual);
        state = inputCGlobal.getPermissionState(p2);
        assertTrue(state == unordered);

        // Using one input
        vm.prank(user1);
        c1.myFunc(input1.num, input1.addr);

        // Checks
        bytes32[] memory input2UsedArray = new bytes32[](2);
        input2UsedArray[0] = input[0];
        input2UsedArray[1] = bytes32(0);
        saved = inputCGlobal.getAllowedInputs(p2);
        areEqual = _compareArrays(saved, input2UsedArray);
        assertTrue(areEqual);
        state = inputCGlobal.getPermissionState(p2);
        assertTrue(state == unordered);

        // Using second input
        vm.prank(user1);
        c1.myFunc(input0.num, input0.addr);
        saved = inputCGlobal.getAllowedInputs(p2);
        assertTrue(saved.length == 0);
        state = inputCGlobal.getPermissionState(p2);
        assertTrue(state == notExisting);

        // Now we are gonna check if new inputs granted, the array of allowed
        // inputs should be replaced by the new one

        // In sequence
        vm.prank(owner1);
        c1.giveInputPermission(user1, input, myFuncSig, true);

        // Using one input
        vm.prank(user1);
        c1.myFunc(input0.num, input0.addr);

        // Giving new inputs
        bytes32[] memory inputs2 = new bytes32[](2);
        inputs2[0] = input2.id;
        inputs2[1] = input1.id;
        vm.prank(owner1);
        c1.giveInputPermission(user1, inputs2, myFuncSig, true);

        // Checks
        saved = inputCGlobal.getAllowedInputs(p2);
        areEqual = _compareArrays(saved, inputs2);
        assertTrue(areEqual);
        state = inputCGlobal.getPermissionState(p2);
        assertTrue(state == sequence);

        // Same but in unordered
        vm.prank(owner1);
        c1.giveInputPermission(user1, input, myFuncSig, false);

        // Using one input
        vm.prank(user1);
        c1.myFunc(input1.num, input1.addr);

        // Giving new inputs
        vm.prank(owner1);
        c1.giveInputPermission(user1, inputs2, myFuncSig, false);

        // Checks
        saved = inputCGlobal.getAllowedInputs(p2);
        areEqual = _compareArrays(saved, inputs2);
        assertTrue(areEqual);
        state = inputCGlobal.getPermissionState(p2);
        assertTrue(state == unordered);
    }
}
