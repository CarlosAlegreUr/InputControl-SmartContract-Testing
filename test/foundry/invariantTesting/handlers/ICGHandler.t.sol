// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

// TODO: ON DEVELOPMENT

// import {Test} from "../../../../lib/forge-std/src/Test.sol";
// import "../../../../lib/forge-std/src/console.sol";

// import {IInputControlPublic} from "contracts/public/IInputControlPublic.sol";
// import {UseCaseContractPublic} from "contracts/public/UseCaseContractPublic.sol";

// // We supose contracts implemented ICG correctly.
// contract HandlerICG is Test {
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

//     // Functions used (only 1 so far myFunc)
//     string public myFuncSig = "myFunc(uint256,address)";
//     bytes4 public myFuncSelec = bytes4(keccak256(bytes(myFuncSig)));

//     // Events used
//     event InputControlPublic__InputsPermissionGranted(
//         IInputControlPublic.Permission indexed permission, IInputControlPublic.PermissionState state
//     );

//     // Shortened states access
//     IInputControlPublic.PermissionState public unordered = IInputControlPublic.PermissionState.IS_UNORDERED;
//     IInputControlPublic.PermissionState public sequence = IInputControlPublic.PermissionState.IS_SEQUENCE;
//     IInputControlPublic.PermissionState public notExisting = IInputControlPublic.PermissionState.IS_NOT_EXISTING;

//     uint256 public constant NUM_OF_INPUTS_ALLOWED = 10;
//     UseCaseContractInputs[] public inputs;
//     address[] public ownersOfContracts;
//     address[] public contractsImplemetingICG;
//     address public callersUsed;
//     IInputControlPublic public inputControlPublic;

//     // A strcut used to keep track user interactions with contracts to later check in invariants
//     // if any of them lead to a bad interaction.
//     struct UserState {
//         address user;
//         address contractAddr;
//         address ownerOfContract;
//         bytes4 funcSelec;
//         IInputControlPublic.PermissionState lastState;
//     }

//     mapping(bytes32 => UserState) public interactionsJudge;

//     bool public DETECTED_BAD_STATE_CHANGE = false;
//     bool public DETECTED_USED_CONTRACT_WITHOUT_PERMISSION = false;
//     bool public DETECTED_BAD_STORAGE_CLEAN_UP = false;

//     struct ValidInteraction {
//         address contractAddr;
//         uint256 inputsNum;
//         bool isSequence;
//     }

//     struct UserProfile {
//         bool hasCalls;
//         uint256 callsLeft;
//         ValidInteraction[] validInteractions;
//         uint256[] invalidInteractionsIndexes;
//     }

//     address[] public usersWithProfiles;
//     mapping(address => UserProfile) public usersProfiles;

//     constructor(
//         address[] memory _contractsImplemetingICG,
//         address[] memory _ownersOfContracts,
//         address inputControlAddress
//     ) {
//         for (uint256 i = 0; i < _contractsImplemetingICG.length; i++) {
//             contractsImplemetingICG.push(_contractsImplemetingICG[i]);
//             ownersOfContracts.push(_ownersOfContracts[i]);
//         }

//         for (uint256 i = 0; i < NUM_OF_INPUTS_ALLOWED; i++) {
//             UseCaseContractInputs memory u = UseCaseContractInputs({
//                 num: i,
//                 addr: address(uint160(i)),
//                 id: keccak256(abi.encode(address(uint160(i)), i))
//             });
//             inputs.push(u);
//         }

//         inputControlPublic = IInputControlPublic(inputControlAddress);
//     }

//     /**
//      *
//      *  HELPER FUNCTIONS
//      *
//      */

//     function _createPermission(address _allower, address _contractAddress, bytes4 _functionSelector, address _caller)
//         private
//         pure
//         returns (IInputControlPublic.Permission memory)
//     {
//         IInputControlPublic.Permission memory p = IInputControlPublic.Permission({
//             allower: _allower,
//             contractAddress: _contractAddress,
//             functionSelector: _functionSelector,
//             caller: _caller
//         });
//         return p;
//     }

//     function _compareArrays(bytes32[] memory arr1, bytes32[] memory arr2) private pure returns (bool areEqual) {
//         if (arr1.length != arr2.length) return false;
//         areEqual = true;
//         for (uint256 i = 0; i < arr1.length; i++) {
//             if (arr1[i] != arr2[i]) {
//                 areEqual = false;
//                 break;
//             }
//         }
//         return areEqual;
//     }

//     function _getUserStateId(UserState memory _u) private pure returns (bytes32) {
//         return keccak256(abi.encode(_u.user, _u.contractAddr, _u.ownerOfContract, _u.funcSelec, _u.lastState));
//     }

//     function _updateUserState(
//         address _user,
//         address _contractAddress,
//         address _contractOwner,
//         bytes4 _funcSelec,
//         IInputControlPublic.PermissionState _expectedState
//     ) private {
//         // Saving interaction state
//         IInputControlPublic.Permission memory p =
//             _createPermission(_contractAddress, _contractAddress, myFuncSelec, _user);
//         IInputControlPublic.PermissionState ps = inputControlPublic.getPermissionState(p);
//         UserState memory us = UserState({
//             user: _user,
//             contractAddr: _contractAddress,
//             ownerOfContract: _contractOwner,
//             funcSelec: _funcSelec,
//             lastState: ps
//         });
//         bytes32 id = _getUserStateId(us);
//         interactionsJudge[id] = us;

//         if (_expectedState != ps) {
//             DETECTED_BAD_STATE_CHANGE = true;
//         }
//     }

//     function _updateUserProfileInteractionIncrease(address _user, ValidInteraction memory _v) private {
//         UserProfile memory up = usersProfiles[_user];

//         up.callsLeft += _v.inputsNum;
//         up.hasCalls = true;

//         usersProfiles[_user] = up;
//         usersProfiles[_user].validInteractions.push(_v);
//     }

//     function _updateUserProfileInteractionDecrese(address _user, ValidInteraction memory _interactionConsumed)
//         private
//     {
//         UserProfile memory up = usersProfiles[_user];

//         if (up.callsLeft > 0) {
//             up.callsLeft -= 1;
//         }
//         if (up.callsLeft == 0) {
//             up.hasCalls = false;
//         }

//         usersProfiles[_user] = up;
//         ValidInteraction[] memory validInteractions = up.validInteractions;
//         for (uint256 i = 0; i < validInteractions.length; i++) {
//             if (_checkEqualInteraction(validInteractions[i], _interactionConsumed)) {
//                 delete usersProfiles[_user].validInteractions[i];
//                 usersProfiles[_user].invalidInteractionsIndexes.push(i);
//             }
//         }
//         usersProfiles[_user] = up;
//     }

//     function _checkEqualInteraction(ValidInteraction memory _v1, ValidInteraction memory _v2)
//         private
//         pure
//         returns (bool)
//     {
//         bool equal = true;
//         if (_v1.contractAddr != _v2.contractAddr) equal = false;
//         if (_v1.inputsNum != _v2.inputsNum) equal = false;
//         if (_v1.isSequence != _v2.isSequence) equal = false;
//         return equal;
//     }

//     /**
//      * INTERACTIONS
//      */

//     function contractGivesPermission(uint256 _randomIndex, address _someone, uint256 _numOfInputs, bool _isSeq)
//         public
//     {
//         if (_someone == address(0)) _someone = address(69);
//         _numOfInputs = bound(_numOfInputs, 0, 10);
//         uint256 i = _randomIndex % contractsImplemetingICG.length;
//         UseCaseContractPublic c = UseCaseContractPublic(contractsImplemetingICG[i]);
//         address owner = ownersOfContracts[i];

//         bytes32[] memory inputsIds = new bytes32[](_numOfInputs);
//         for (i = 0; i < inputsIds.length; i++) {
//             inputsIds[i] = inputs[i].id;
//         }

//         vm.prank(owner);
//         c.giveInputPermission(_someone, inputsIds, myFuncSig, _isSeq);

//         IInputControlPublic.PermissionState expected;
//         if (_isSeq) {
//             expected = IInputControlPublic.PermissionState.IS_SEQUENCE;
//         } else {
//             expected = IInputControlPublic.PermissionState.IS_UNORDERED;
//         }
//         _updateUserState(_someone, address(c), owner, myFuncSelec, expected);
//         usersWithProfiles.push(_someone);
//         ValidInteraction memory v =
//             ValidInteraction({contractAddr: address(c), inputsNum: _numOfInputs, isSequence: _isSeq});
//         _updateUserProfileInteractionIncrease(_someone, v);
//     }

//     // TODO
//     // function executingPermittedCall(uint256 _randomIndex) public {
//     //     if (usersWithProfiles.length == 0) return;

//     //     uint256 i = _randomIndex % usersWithProfiles.length;
//     //     address user = usersWithProfiles[i];
//     //     UserProfile memory up = usersProfiles[user];

//     //     // Iterate over users till finding one, if after all check none has, return
//     //     // while(!up.hasCalls) {

//     //     // }
//     //     // i = _randomIndex % up.validInteractions.length;
//     //     // Same here, iterate over validInteractions until finding one
//     //     // ValidInteraction memory vi = up.validInteractions[i];
//     // }

//     // TODO
//     // Someone gives permissions in a not owned contract
//     // Execute random call, if invalid just expect revert
// }
