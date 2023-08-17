// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

import {Test} from "../../../lib/forge-std/src/Test.sol";
import "../../../lib/forge-std/src/console.sol";

// Composite (Global) version
import {InputControlComposite} from "../../../contracts/owned/compositeVersion/InputControlComposite.sol";
import {IInputControlComposite} from "../../../contracts/owned/compositeVersion/IInputControlComposite.sol";
import {UseCaseContractComposite} from "../../../contracts/owned/compositeVersion/UseCaseContractComposite.sol";

contract FuzzTestICC is Test {
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

    function setUp() public {
        // Deployment of the contracts
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

    /**
     *
     *  TESTS
     *
     */

    // If properly implemented with ICC: Only contracts can give permissions to its users.
    function testFuzz_ICC_SetInputsPermissionOnlyContract(address _attacker, address _attacker2) public {
        // Checks that make sure that all scenarios make sense
        if (_attacker == address(0)) _attacker = address(69);
        if (_attacker == address(c1)) _attacker = address(69);
        if (_attacker2 == address(0)) _attacker2 = address(6969);
        if (_attacker == _attacker2) {
            _attacker = address(6969);
            _attacker2 = address(69);
        }

        // No one but allowed user can eventually execute permissions in properly set contracts
        IInputControlComposite.Permission memory p = _createPermission(_attacker, address(c1), myFuncSelec, _attacker);
        bytes32[] memory input = new bytes32[](1);
        input[0] = input0.id;

        // User tries to give himself permissions
        vm.expectRevert(IInputControlComposite.InputControlComposite__OnlyAdmin.selector);
        vm.startPrank(_attacker);
        inputCComposite.setInputsPermission(p, input, false);
        vm.expectRevert(IInputControlComposite.InputControlComposite__PermissionDoesntExist.selector);
        c1.myFunc(input0.num, input0.addr);

        vm.expectRevert(IInputControlComposite.InputControlComposite__OnlyAdmin.selector);
        inputCComposite.setInputsPermission(p, input, true);
        vm.expectRevert(IInputControlComposite.InputControlComposite__PermissionDoesntExist.selector);
        c1.myFunc(input0.num, input0.addr);
        vm.stopPrank();

        // Now owner gives him permissions
        vm.prank(owner1);
        c1.giveInputPermission(_attacker, input, myFuncSig, false);
        // Another _attacker tris to use other person's inputs
        vm.expectRevert(IInputControlComposite.InputControlComposite__PermissionDoesntExist.selector);
        vm.prank(_attacker2);
        c1.myFunc(input0.num, input0.addr);
        // Allowed user calls function and works
        vm.prank(_attacker);
        c1.myFunc(input0.num, input0.addr);
    }
}
