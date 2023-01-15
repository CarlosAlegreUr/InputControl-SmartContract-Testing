// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

error UseCaseContract__OnlyIFMCanCallThisContract();

// Uncomment this line to use console.log
// import "hardhat/console.sol";

import "./InputControl.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

// AccessControl.sol is not used in this contract but here it is if
// you want to play with it. (:D)
import "@openzeppelin/contracts/access/AccessControl.sol";

/**
 * @title Example of contract using InputControl.
 * @author Carlos Alegre Urquizú (GitHub --> https://github.com/CarlosAlegreUr)
 *
 * @dev To use InputControl make your contract inherit InputControl and add the isAllowedInput()
 * modifier in the functions you desire to control their inputs. The '_input' parameter of the
 * modifier must be = keccak256(abi.encodePacked(inputs)).
 *
 * @dev Additionally you can override callAllowInputsFor() if you please mixing this functionality with,
 * for example, other useful ones like Owner or AccessControl contracts from OpenZeppelin.
 */
contract UseCaseContract is InputControl, Ownable {
    uint256 private s_incrediblyAmazingNumber;
    address private s_someAddress;

    // Any function in your own smart contract.
    function myFuncInSequence(
        uint256 _newNumber,
        address _anAddress
    )
        external
        isAllowedInput(
            "myFuncInSequence(uint256, address)", // <--- Look here!
            msg.sender, // <--- Look here!
            keccak256(abi.encodePacked(_newNumber, _anAddress)), // <--- Look here!
            true // <--- Look here!
        )
    {
        s_incrediblyAmazingNumber = _newNumber;
        s_someAddress = _anAddress;
    }

    // Any function in your own smart contract.
    function myFuncUnordered(
        uint256 _newNumber,
        address _anAddress
    )
        external
        isAllowedInput(
            "myFuncUnordered(uint256, address)",
            msg.sender,
            keccak256(abi.encodePacked(_newNumber, _anAddress)),
            false // <--- Look here!
        )
    {
        s_incrediblyAmazingNumber = _newNumber;
        s_someAddress = _anAddress;
    }

    // Overriding function and using OnlyOwner, now only owner(in this case owner = deployer address)
    // of this contract can control inputs' control.
    function callAllowInputsFor(
        address _client,
        bytes32[] calldata _validInputs,
        string calldata _funcSignature,
        bool _isSequence
    ) public override onlyOwner {
        allowInputsFor(_client, _validInputs, _funcSignature, _isSequence);
    }

    function getNumber() public view returns (uint256) {
        return s_incrediblyAmazingNumber;
    }
}
