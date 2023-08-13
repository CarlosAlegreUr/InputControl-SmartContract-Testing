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
 */
contract UseCaseMatchmakerContract is InputControl, Ownable {
    uint256 private s_incrediblyAmazingNumber;
    address private s_someAddress;

    mapping(address => address) s_playerToOpponent;
    mapping(address => bytes32) s_playerToMatchState;

    error UseCaseMatchmakerContract__AllowerIsNotSender();
    error UseCaseMatchmakerContract__OnlyOwnerGrantsPermissionsToThisFunc();

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

    // Any function in your own smart contract.
    function startMatch(address _opponent, bytes32 _complexFirstStateOfMatch)
        external
        // Modifier that will call InputControlPublic
        isAllowedInput(
            _opponent,
            bytes4(keccak256(bytes("startMatch(address,bytes32)"))), // <--- Look here!
            msg.sender, // <--- Look here!
            keccak256(abi.encode(_opponent, _complexFirstStateOfMatch)) // <--- Look here!
        )
    {
        s_playerToOpponent[msg.sender] = _opponent;
        s_playerToMatchState[msg.sender] = _complexFirstStateOfMatch;
        s_playerToMatchState[_opponent] = _complexFirstStateOfMatch;
    }

    // Overriding function and using OnlyOwner, now only owner(in this case owner = deployer address)
    // of this contract can control inputs control.
    function callSetInputsPermission(Permission calldata _p, bytes32[] calldata _validInputs, bool _isSequence)
        public
        override
    {
        if (_p.functionSelector == bytes4(keccak256(bytes("startMatch(address,bytes32)")))) {
            if (msg.sender != _p.allower) {
                revert UseCaseMatchmakerContract__AllowerIsNotSender();
            }
        }
        if (_p.functionSelector == bytes4(keccak256(bytes("myFunc(uint256,address)")))) {
            if (msg.sender != this.owner()) {
                revert UseCaseMatchmakerContract__OnlyOwnerGrantsPermissionsToThisFunc();
            }
        }
        super.callSetInputsPermission(_p, _validInputs, _isSequence);
    }

    function getNumber() public view returns (uint256) {
        return s_incrediblyAmazingNumber;
    }

    function getOpponent(address _opponentOf) public view returns (address) {
        return s_playerToOpponent[_opponentOf];
    }
}
