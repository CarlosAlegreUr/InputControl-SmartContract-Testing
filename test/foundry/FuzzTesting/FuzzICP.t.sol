// // SPDX-License-Identifier: MIT
// pragma solidity ^0.8.18;

// import {Test} from "../../../lib/forge-std/src/Test.sol";
// import "../../../lib/forge-std/src/console.sol";

// // Composite (Global) version
// import {InputControlGlobal} from "contracts/decentralized/globalVersion/InputControlGlobal.sol";
// import {IInputControlGlobal} from "contracts/decentralized/globalVersion/IInputControlGlobal.sol";
// import {UseCaseContractGlobal} from "contracts/decentralized/globalVersion/UseCaseContractGlobal.sol";

// contract FuzzTestICG is Test {
//     /**
//      *
//      *  DATA STRUCTURES USED
//      *
//      */

//     struct UseCaseContractInputs {
//         uint256 num;
//         address addr;
//         bytes32 id;
//     }

//     // Addresses used
//     address public owner1 = makeAddr("owner1");

//     // Contracts used
//     UseCaseContractGlobal public c1;
//     IInputControlGlobal inputCGlobal;

//     // Functions used (only 1 so far myFunc)
//     string public myFuncSig = "myFunc(uint256,address)";
//     bytes4 public myFuncSelec = bytes4(keccak256(bytes(myFuncSig)));

//     // Inputs used
//     UseCaseContractInputs public input0 =
//         UseCaseContractInputs({num: 0, addr: address(0), id: keccak256(abi.encode(address(0), 0))});
//     UseCaseContractInputs public input1 =
//         UseCaseContractInputs({num: 1, addr: address(1), id: keccak256(abi.encode(address(1), 1))});

//     function setUp() public {
//         // Deployment of the contracts
//         // inputCGlobal --> Cant have owners
//         // c1 --> Owned by user1
//         vm.startPrank(owner1);
//         inputCGlobal = IInputControlGlobal(new InputControlGlobal());
//         c1 = new UseCaseContractGlobal(address(inputCGlobal));
//         vm.stopPrank();
//     }

//     /**
//      *
//      *  HELPER FUNCTIONS
//      *
//      */
//     function createPermission(address _allower, address _contractAddress, bytes4 _functionSelector, address _caller)
//         private
//         pure
//         returns (IInputControlGlobal.Permission memory)
//     {
//         IInputControlGlobal.Permission memory p = IInputControlGlobal.Permission({
//             allower: _allower,
//             contractAddress: _contractAddress,
//             functionSelector: _functionSelector,
//             caller: _caller
//         });
//         return p;
//     }

//     /**
//      *
//      *  TESTS
//      *
//      */

//     // If properly implemented with ICG: Only contracts can give permissions to its users.
//     function testFuzz_SetInputsPermissionOnlyContract(address _attacker, address _attacker2) public {
//         if (_attacker == address(0)) _attacker = address(69);
//         if (_attacker2 == address(0)) _attacker2 = address(6969);

//         // No one but allowed user can eventually execute permissions in properly set contracts
//         IInputControlGlobal.Permission memory p = createPermission(_attacker, address(c1), myFuncSelec, _attacker);
//         bytes32[] memory input = new bytes32[](1);
//         input[0] = input0.id;

//         // User tries to give himself permissions
//         vm.startPrank(_attacker);
//         inputCGlobal.setInputsPermission(p, input, false);
//         vm.expectRevert(IInputControlGlobal.InputControlGlobal__PermissionDoesntExist.selector);
//         c1.myFunc(input0.num, input0.addr);

//         inputCGlobal.setInputsPermission(p, input, true);
//         vm.expectRevert(IInputControlGlobal.InputControlGlobal__PermissionDoesntExist.selector);
//         c1.myFunc(input0.num, input0.addr);
//         vm.stopPrank();

//         // Now owner gives him permissions
//         vm.prank(owner1);
//         c1.giveInputPermission(_attacker, input, myFuncSig, false);
//         // Another _attacker tris to use other person's inputs
//         vm.expectRevert(IInputControlGlobal.InputControlGlobal__PermissionDoesntExist.selector);
//         vm.prank(_attacker2);
//         c1.myFunc(input0.num, input0.addr);
//         // Allowed user calls function and works
//         vm.prank(_attacker);
//         c1.myFunc(input0.num, input0.addr);
//     }

//     // Impersonation is not posible.
//     function testFuzz_SetInputsPermissionImpersonationNotPosible(address _attacker, address _victim) public {
//         // Attacker impersonating user victim
//         IInputControlGlobal.Permission memory p = createPermission(_victim, address(c1), myFuncSelec, _attacker);
//         bytes32[] memory input = new bytes32[](1);
//         input[0] = input0.id;

//         // User tries impersonating
//         vm.prank(_attacker);
//         vm.expectRevert(IInputControlGlobal.InputControlGlobal__AllowerIsNotSender.selector);
//         inputCGlobal.setInputsPermission(p, input, false);
//     }
// }
