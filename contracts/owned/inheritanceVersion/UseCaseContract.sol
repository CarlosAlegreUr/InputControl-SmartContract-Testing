// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

// Comment out if not debugging
import "../../../lib/forge-std/src/console.sol";

import "./InputControl.sol";
import "../../../lib/openzeppelin-contracts/contracts/access/Ownable.sol";

// AccessControl.sol is not used in this contract but here it is if
// you want to play with it. (:D)
// import "../../../lib/openzeppelin-contracts/contracts/access/AccessControl.sol";

/**
 * @title Example of contract using InputControl.
 * @author Carlos Alegre Urquizú (GitHub --> https://github.com/CarlosAlegreUr)
 *
 * @dev To use InputControl make your contract inherit InputControl and add the isAllowedInput()
 * modifier in the functions you desire to control their inputs. The '_input' parameter of the
 * modifier must be = keccak256(abi.encode(inputs)).
 *
 * It's essential that you use abi.enconde() and not abi.encodePakced() because abi.encodePakced()
 * can give the same output to different inputs.
 *
 * @dev Additionally you can override callSetInputsPermission() if you please mixing this functionality with,
 * for example, other useful ones like Owner or AccessControl contracts from OpenZeppelin.
 *
 * ALLOWS CONTRACT OWNER TO HAVE TOTAL CONTROL OF INPUTS
 */
contract UseCaseContract is InputControl, Ownable {
    uint256 private s_incrediblyAmazingNumber;
    address private s_someAddress;

    // Any function in your own smart contract.
    function myFunc(uint256 _newNumber, address _anAddress)
        external
        isAllowedInput(
            address(this),
            bytes4(keccak256(bytes("myFunc(uint256,address)"))), // <--- Look here!
            msg.sender, // <--- Look here!
            keccak256(abi.encode(_newNumber, _anAddress)) // <--- Look here!
        )
    {
        s_incrediblyAmazingNumber = _newNumber;
        s_someAddress = _anAddress;
    }

    // Overriding function and using OnlyOwner, now only owner(in this case owner = deployer address)
    // of this contract can control inputs control.
    function callSetInputsPermission(Permission calldata _p, bytes32[] calldata _validInputs, bool _isSequence)
        public
        override
        onlyOwner
    {
        super.callSetInputsPermission(_p, _validInputs, _isSequence);
    }

    function getNumber() public view returns (uint256) {
        return s_incrediblyAmazingNumber;
    }
}
