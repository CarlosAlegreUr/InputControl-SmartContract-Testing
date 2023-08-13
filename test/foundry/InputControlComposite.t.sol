// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

import {Test} from "../../lib/forge-std/src/Test.sol";
import "../../lib/forge-std/src/console.sol";

// Composite version
import {InputControlComposite} from "contracts/owned/compositeVersion/InputControlComposite.sol";
import {IInputControlComposite} from "contracts/owned/compositeVersion/IInputControlComposite.sol";
import {UseCaseContractComposite} from "contracts/owned/compositeVersion/UseCaseContractComposite.sol";

contract UnitTestICC is Test {
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
    UseCaseContractComposite public c1;
    IInputControlComposite inputCComposite;

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
    event InputControlComposite__InputsPermissionGranted(
        IInputControlComposite.Permission indexed permission, IInputControlComposite.PermissionState state
    );

    // Shortened states access
    IInputControlComposite.PermissionState public unordered = IInputControlComposite.PermissionState.IS_UNORDERED;
    IInputControlComposite.PermissionState public sequence = IInputControlComposite.PermissionState.IS_SEQUENCE;
    IInputControlComposite.PermissionState public notExisting = IInputControlComposite.PermissionState.IS_NOT_EXISTING;

    function setUp() public {
        // Deployment of the contracts
        // inputCComposite --> Setting only admin to be c1 contract instead of owner1 deployer
        // c1 --> Owned by user1
        vm.startPrank(owner1);
        inputCComposite = IInputControlComposite(new InputControlComposite());
        c1 = new UseCaseContractComposite(address(inputCComposite));
        inputCComposite.setAdmin(address(c1), true);
        inputCComposite.setAdmin(owner1, false);
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
        returns (IInputControlComposite.Permission memory)
    {
        IInputControlComposite.Permission memory p = IInputControlComposite.Permission({
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

    // If properly implemented with ICC: Only contracts can give permissions to its users.
    function testICC_SetInputsPermissionOnlyAdmin() public {
        // Users can't eventually execute permissions in properly set contracts
        IInputControlComposite.Permission memory p = _createPermission(user1, address(c1), myFuncSelec, user1);
        bytes32[] memory input = new bytes32[](1);
        input[0] = input0.id;

        // User tries to give himself permissions, he has never been an admin, shouldnt work
        vm.expectRevert(IInputControlComposite.InputControlComposite__OnlyAdmin.selector);
        vm.startPrank(user1);
        inputCComposite.setInputsPermission(p, input, false);
        vm.expectRevert();
        c1.myFunc(input0.num, input0.addr);

        vm.expectRevert(IInputControlComposite.InputControlComposite__OnlyAdmin.selector);
        inputCComposite.setInputsPermission(p, input, true);
        vm.expectRevert();
        c1.myFunc(input0.num, input0.addr);
        vm.stopPrank();

        // Onwer1 used to be an admin but not anymore, shoudnt work.
        vm.expectRevert(IInputControlComposite.InputControlComposite__OnlyAdmin.selector);
        vm.startPrank(owner1);
        inputCComposite.setInputsPermission(p, input, false);
        vm.expectRevert();
        c1.myFunc(input0.num, input0.addr);

        vm.expectRevert(IInputControlComposite.InputControlComposite__OnlyAdmin.selector);
        inputCComposite.setInputsPermission(p, input, true);
        vm.expectRevert();
        c1.myFunc(input0.num, input0.addr);
        vm.stopPrank();

        // Now owner gives him permissions through the admin contract
        vm.prank(owner1);
        c1.giveInputPermission(user1, input, myFuncSig, false);
        // User2 tries to use inputs of user1
        vm.expectRevert(IInputControlComposite.InputControlComposite__PermissionDoesntExist.selector);
        vm.prank(user2);
        c1.myFunc(input0.num, input0.addr);
        // User 1 calls function and works
        vm.prank(user1);
        c1.myFunc(input0.num, input0.addr);
    }

    // Order of sequence inputs calls is correct
    function testICC_InputsSequencesOnlyAllowsCorrectOrder() public {
        bytes32[] memory input = new bytes32[](2);
        input[0] = input0.id;
        input[1] = input1.id;

        // Giving permissions
        vm.prank(owner1);
        c1.giveInputPermission(user1, input, myFuncSig, true);

        // Using incorrect input (no permissions for input 2)
        vm.expectRevert(IInputControlComposite.InputControlComposite__NotAllowedInput.selector);
        vm.prank(user1);
        c1.myFunc(input2.num, input2.addr);

        // Using incorrect input
        vm.expectRevert(IInputControlComposite.InputControlComposite__NotAllowedInput.selector);
        vm.prank(user1);
        c1.myFunc(input1.num, input1.addr);

        // Using correct input
        vm.prank(user1);
        c1.myFunc(input0.num, input0.addr);

        // Using incorrect input
        vm.expectRevert(IInputControlComposite.InputControlComposite__NotAllowedInput.selector);
        vm.prank(user1);
        c1.myFunc(input0.num, input0.addr);

        // Using correct input
        vm.prank(user1);
        c1.myFunc(input1.num, input1.addr);

        // Using incorrect input
        vm.expectRevert(IInputControlComposite.InputControlComposite__PermissionDoesntExist.selector);
        vm.prank(user1);
        c1.myFunc(input0.num, input0.addr);
    }

    // Order of unordered inputs calls is correct
    function testICC_InputsUnorderedOnlyAllowsCorrectCalls() public {
        // We can use input id 1 twice and id input 0 once.
        bytes32[] memory input = new bytes32[](3);
        input[0] = input0.id;
        input[1] = input1.id;
        input[2] = input1.id;

        // Giving permissions
        vm.prank(owner1);
        c1.giveInputPermission(user1, input, myFuncSig, false);

        // Using incorrect input (no permissions for input 2)
        vm.expectRevert(IInputControlComposite.InputControlComposite__NotAllowedInput.selector);
        vm.prank(user1);
        c1.myFunc(input2.num, input2.addr);

        // Using correct input: Times for id0 left = 0
        vm.prank(user1);
        c1.myFunc(input0.num, input0.addr);

        // Using incorrect input
        vm.expectRevert(IInputControlComposite.InputControlComposite__NotAllowedInput.selector);
        vm.prank(user1);
        c1.myFunc(input0.num, input0.addr);

        // Using correct input: Times for id1 left = 1
        vm.prank(user1);
        c1.myFunc(input1.num, input1.addr);

        // Using incorrect input
        vm.expectRevert(IInputControlComposite.InputControlComposite__NotAllowedInput.selector);
        vm.prank(user1);
        c1.myFunc(input0.num, input0.addr);

        // Using correct input: Times for id1 left = 0
        vm.prank(user1);
        c1.myFunc(input1.num, input1.addr);

        // Using incorrect input
        vm.expectRevert(IInputControlComposite.InputControlComposite__PermissionDoesntExist.selector);
        vm.prank(user1);
        c1.myFunc(input0.num, input0.addr);
    }

    // Permissions are set and updated correctly.
    function testICC_SetInputsPermissionPermissionsAreManagedCorrectly() public {
        bytes32[] memory input = new bytes32[](2);
        input[0] = input0.id;
        input[1] = input1.id;

        // Now checking if inputs update correctly while users use them
        IInputControlComposite.Permission memory p2 = _createPermission(address(c1), address(c1), myFuncSelec, user1);
        vm.prank(owner1);
        c1.giveInputPermission(user1, input, myFuncSig, true);

        // InputsIds where saved correctly
        bytes32[] memory saved = inputCComposite.getAllowedInputs(p2);
        bool areEqual = _compareArrays(saved, input);
        assertTrue(areEqual);
        // State updated correctly
        IInputControlComposite.PermissionState state = inputCComposite.getPermissionState(p2);
        assertTrue(state == sequence);

        // Using first input
        vm.prank(user1);
        c1.myFunc(input0.num, input0.addr);

        // Checks
        bytes32[] memory input1UsedArray = new bytes32[](2);
        input1UsedArray[0] = bytes32(0);
        input1UsedArray[1] = input[1];
        saved = inputCComposite.getAllowedInputs(p2);
        areEqual = _compareArrays(saved, input1UsedArray);
        assertTrue(areEqual);
        state = inputCComposite.getPermissionState(p2);
        assertTrue(state == sequence);

        // Using second input
        vm.prank(user1);
        c1.myFunc(input1.num, input1.addr);

        saved = inputCComposite.getAllowedInputs(p2);
        assertTrue(saved.length == 0);
        state = inputCComposite.getPermissionState(p2);
        assertTrue(state == notExisting);

        // Same process but for unordered
        vm.prank(owner1);
        c1.giveInputPermission(user1, input, myFuncSig, false);

        // InputsIds where saved correctly
        saved = inputCComposite.getAllowedInputs(p2);
        areEqual = _compareArrays(saved, input);
        assertTrue(areEqual);
        state = inputCComposite.getPermissionState(p2);
        assertTrue(state == unordered);

        // Using one input
        vm.prank(user1);
        c1.myFunc(input1.num, input1.addr);

        // Checks
        bytes32[] memory input2UsedArray = new bytes32[](2);
        input2UsedArray[0] = input[0];
        input2UsedArray[1] = bytes32(0);
        saved = inputCComposite.getAllowedInputs(p2);
        areEqual = _compareArrays(saved, input2UsedArray);
        assertTrue(areEqual);
        state = inputCComposite.getPermissionState(p2);
        assertTrue(state == unordered);

        // Using second input
        vm.prank(user1);
        c1.myFunc(input0.num, input0.addr);
        saved = inputCComposite.getAllowedInputs(p2);
        assertTrue(saved.length == 0);
        state = inputCComposite.getPermissionState(p2);
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
        saved = inputCComposite.getAllowedInputs(p2);
        areEqual = _compareArrays(saved, inputs2);
        assertTrue(areEqual);
        state = inputCComposite.getPermissionState(p2);
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
        saved = inputCComposite.getAllowedInputs(p2);
        areEqual = _compareArrays(saved, inputs2);
        assertTrue(areEqual);
        state = inputCComposite.getPermissionState(p2);
        assertTrue(state == unordered);
    }
}
