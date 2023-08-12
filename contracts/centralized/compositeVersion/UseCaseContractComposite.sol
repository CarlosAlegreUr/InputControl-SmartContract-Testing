// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

// // Uncomment this line to use console.log
// // import "hardhat/console.sol";

// import "./IInputControlComposite.sol";
// import "@openzeppelin/contracts/access/Ownable.sol";

// // AccessControl.sol is not used in this contract but here it is if
// // you want to play with it. (:D)
// import "@openzeppelin/contracts/access/AccessControl.sol";

// /**
//  * @title Example of contract using InputControl.
//  * @author Carlos Alegre Urquizú (GitHub --> https://github.com/CarlosAlegreUr)
//  *
//  * @dev To use InputControlComposite instantiate a reference to an InputControlComposite
//  * contract address.
//  *
//  * @notice The implementation can be vary depending on what you need, in this contract
//  * the reference is an immutable variable though you could implement it without it, for example
//  * , in case you desire to be capable of updating the reference at some point just in case a vulnerability
//  * is found. Any implementation would work though! :D
//  *
//  * Same thing with the modifier checkInputControl(), you can just call i_inputControl.isAllowedInput()
//  * from inside your functions you want to control but using a modifier is just cleaner.
//  * Any implementation would work though! :D
//  *
//  * @notice For now there are no official implementation addresses in mainnets or testnets
//  * due to code has not been audited yet. So when testing in local or testnet you will have to
//  * deploy InputControlComposite first and use it's resulting address.
//  *
//  * @dev Additionally you can wrap allowInputsFor() call in a function that uses your own useful
//  * modfiers. This will allow mixing this functionalities with, for example, other useful ones like
//  * Owner or AccessControl contracts from OpenZeppelin.
//  */
// contract UseCaseContractModular is Ownable {
//     IInputControlComposite immutable i_inputControl; // <---- Look here!
//     uint256 private s_incrediblyAmazingNumber;
//     address private s_someAddress;

//     constructor(address _inputControlAddress) {
//         i_inputControl = IInputControlComposite(_inputControlAddress); // <---- Look here!
//     }

//     // Look here!
//     modifier checkInputControl(bytes4 _funcSelec, address _callerAddress, bytes32 _input) {
//         i_inputControl.isAllowedInput(_funcSelec, _callerAddress, _input);
//         _;
//     }

//     // Look here! Mixing InputControl with other useful
//     // contracts like Ownable in this case.
//     function giveInputPermission(
//         address _callerAddress,
//         bytes32[] calldata _validInputs,
//         string calldata _funcSignature,
//         bool _isSequence
//     ) external onlyOwner /* <---- Look here! */ {
//         i_inputControl.allowInputsFor(_callerAddress, _validInputs, _funcSignature, _isSequence);
//     }

//     function changeAdmin(address _newAdmin) external onlyOwner {
//         i_inputControl.setAdmin(_newAdmin);
//     }

//     // Any function in your own smart contract.
//     function myFunc(uint256 _newNumber, address _anAddress)
//         external
//         checkInputControl(
//             bytes4(keccak256(bytes("myFunc(uint256,address)"))), //<---- Look here!
//             msg.sender, //<---- Look here!
//             keccak256(abi.encode(_newNumber, _anAddress)) //<---- Look here!
//         )
//     {
//         s_incrediblyAmazingNumber = _newNumber;
//         s_someAddress = _anAddress;
//     }

//     function getNumber() public view returns (uint256) {
//         return s_incrediblyAmazingNumber;
//     }
// }
