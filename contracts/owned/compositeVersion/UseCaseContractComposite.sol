// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

// Comment out if not debugging
import "../../../lib/forge-std/src/console.sol";

import "./IInputControlComposite.sol";
import "../../../lib/openzeppelin-contracts/contracts/access/Ownable.sol";

// AccessControl.sol is not used in this contract but here it is if
// you want to play with it. (:D)
// import "../../../lib/openzeppelin-contracts/contracts/access/AccessControl.sol";

/**
 * @title Example of contract using InputControlPublic public services.
 * @author Carlos Alegre Urquizú (GitHub --> https://github.com/CarlosAlegreUr)
 *
 * @dev To use InputControlPublic services instantiate a reference to an IInputControlComposite
 * contract address. Check official addresses here: (TODO)
 *
 * @notice For now there are no official implementation addresses in mainnets or testnets
 * because the code has not been audited yet. So when testing in local or testnet you will have to
 * deploy InputControlPublic first and use its resulting address.
 *
 * @dev Additionally you can wrap setInputsPermission() call in a function that uses your own useful
 * modfiers. This will allow mixing this functionalities with other useful ones like Ownable or
 * AccessControl contracts from OpenZeppelin.
 *
 * Same thing with the function isAllowedInput(), you can just call i_inputControl.isAllowedInput()
 * from inside your functions but using a modifier or function to wrap it up allows for
 * personalizations. For example this UseCaseContract has a locker variable that activates and
 * deactivate input checkings.
 */
contract UseCaseContractComposite is Ownable {
    IInputControlComposite immutable i_inputControl; // <---- Look here!
    bool private s_inputControlDisabled; // <--- The locker variable mentioned above
    uint256 private s_incrediblyAmazingNumber;
    address private s_someAddress;

    constructor(address _inputControlPublicAddress) {
        // Instantiation of the InputControlPublic service
        i_inputControl = IInputControlComposite(_inputControlPublicAddress); // <---- Look here!
    }

    // Look here!
    modifier checkInputControl(string memory _funcSig, address _callerAddress, bytes32 _input) {
        if (!s_inputControlDisabled) {
            bytes4 _funcSelec = bytes4(keccak256(bytes(_funcSig)));
            IInputControlComposite.Permission memory p = IInputControlComposite.Permission({
                allower: address(this), // <-- We are checking that this address
                contractAddress: address(this), // <-- has given permissions to call inside this contract
                functionSelector: _funcSelec, // <-- this function with the _input
                caller: _callerAddress // <-- to this address
            });
            i_inputControl.isAllowedInput(p, _input);
        }
        _;
    }

    // Look here! Mixing InputControl with other useful
    // contracts like Ownable in this case.
    // Now you are using public infrastructure in your contract
    // but only owner can decide who gives permissions.
    function giveInputPermission(
        address _callerAddress,
        bytes32[] calldata _validInputs,
        string calldata _funcSignature,
        bool _isSequence
    ) external onlyOwner /* <---- Look here! */ {
        bytes4 funcSelec = bytes4(keccak256(bytes(_funcSignature)));
        IInputControlComposite.Permission memory p = IInputControlComposite.Permission({
            allower: address(this), // <-- We will say to InputControlPublic that this address
            contractAddress: address(this), // <-- has given permissions to call inside this contract
            functionSelector: funcSelec, // <-- this function with the inputs _validInputs
            caller: _callerAddress // <-- to this address
        });
        i_inputControl.setInputsPermission(p, _validInputs, _isSequence);
    }

    // Any function in your own smart contract.
    function myFunc(uint256 _newNumber, address _anAddress)
        external
        // <--- Modifier that will call InputControlPublic
        checkInputControl(
            "myFunc(uint256,address)", //<---- Look here!
            msg.sender, //<---- Look here!
            keccak256(abi.encode(_newNumber, _anAddress)) //<---- Look here!
        )
    {
        s_incrediblyAmazingNumber = _newNumber;
        s_someAddress = _anAddress;
    }

    function getNumber() public view returns (uint256) {
        return s_incrediblyAmazingNumber;
    }

    // Just a function to activate or deactivate the input checkings.
    function setInputControlState(bool _set) public onlyOwner {
        s_inputControlDisabled = _set;
    }
}
