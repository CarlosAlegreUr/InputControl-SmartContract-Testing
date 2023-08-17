// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

// TODO: ON DEVELOPMENT

// import {Test} from "../../../lib/forge-std/src/Test.sol";
// import "../../../lib/forge-std/src/console.sol";

// // Composite (Global) version
// import {InputControlPublic} from "contracts/public/InputControlPublic.sol";
// import {IInputControlPublic} from "contracts/public/IInputControlPublic.sol";
// import {UseCaseContractPublic} from "contracts/public/UseCaseContractPublic.sol";

// import {HandlerICG} from "./handlers/ICGHandler.t.sol";

// contract InvariantsICG is Test {
//     uint256 public constant NUM_OF_PARTICIPANT_CONTRACTS = 10;
//     address[] public owners;
//     address[] public contracts;
//     address public neverCalled;
//     address public ownerNeverCalled;

//     IInputControlPublic inputCGlobal;
//     HandlerICG public handler;

//     function setUp() public {
//         inputCGlobal = IInputControlPublic(new InputControlPublic());
//         _deployXUseCaseContracts(NUM_OF_PARTICIPANT_CONTRACTS);
//         HandlerICG h = new HandlerICG(contracts, owners, address(inputCGlobal));
//         targetContract(address(h));
//         excludeSender(ownerNeverCalled);
//     }

//     // Setting functions
//     function _deployXUseCaseContracts(uint256 x) private {
//         for (uint256 i = 0; i < x; i++) {
//             address owner;
//             owner = address(uint160(i));
//             vm.prank(owner);
//             UseCaseContractPublic c = new UseCaseContractPublic(address(inputCGlobal));
//             contracts.push(address(c));
//             owners.push(owner);
//         }
//     }

//     // Invariants
//     function invariant_StatesChangedCorectly() public {
//         bool detected = handler.DETECTED_BAD_STATE_CHANGE();
//         assertFalse(detected);
//     }

//     function invariant_ContractsAccessedOnlyWithPermission() public {
//         bool detected = handler.DETECTED_USED_CONTRACT_WITHOUT_PERMISSION();
//         assertFalse(detected);
//     }

//     function invariant_NonExistingStatesOccupyNoStorage() public {
//         bool detected = handler.DETECTED_BAD_STORAGE_CLEAN_UP();
//         assertFalse(detected);
//     }
// }
