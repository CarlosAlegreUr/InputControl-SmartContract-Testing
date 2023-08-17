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
 * can potentially give the same output to different inputs.
 *
 * @dev Additionally you can override callSetInputsPermission() if you please mixing this functionality with,
 * for example, other useful ones like Owner or AccessControl contracts from OpenZeppelin.
 *
 */
contract UseCaseContract is InputControl, Ownable {
    // @notice Variables of features built on top of InputControl

    // @notice Locker for activating or deactivating controls
    bool private s_inputControlDisabled;

    // @notice Only owner variables
    uint256 private s_incrediblyAmazingNumber;
    address private s_someAddress;

    // @notice Matchmaking feature variables
    mapping(address => address) private s_playerToOpponent;
    mapping(address => bytes32) private s_playerToMatchState;

    /// @dev Mixing InputControl with other useful contracts like Ownable in this case.
    /// Now you are using public infrastructure in your contract but only owner can decide
    /// who gives permissions.
    function callSetInputsPermission(Permission calldata _p, bytes32[] calldata _validInputs, bool _isSequence)
        public
        override
    {
        bytes4 _funcSelec = _p.functionSelector;

        /// @notice For best practices, this filtering should be made a modifier.
        /// Its written like this for visual purposes as an example.
        if (_funcSelec == bytes4(keccak256(bytes("myFunc(uint256,address)")))) {
            // Only the owner decides who to give input permissions in myFunc.
            require(msg.sender == this.owner()); /* <-- InputControl features compatibility with Ownable.sol*/
        }

        if (_funcSelec == bytes4(keccak256(bytes("startMatch(address,bytes32)")))) {
            // You cannot give input permissions to yourself so you can start matches with whoever you want.
            require(_p.caller != msg.sender);
        }
        super.callSetInputsPermission(_p, _validInputs, _isSequence);
    }

    /// @dev The followig are any of the functions in your own smart contract.
    /// These functions are not needed in order to use InputControl,
    /// they are just example features that can be build on top of it.

    /// @dev myFunc is some function in your contract that only owner or privileged roles
    /// can give inpit permissions to.
    function myFunc(uint256 _newNumber, address _anAddress)
        external
        // Modifier that will call InputControlPublic
        isAllowedInput(
            this.owner(),
            bytes4(keccak256(bytes("myFunc(uint256,address)"))), // <--- Look here!
            msg.sender, // <--- Look here!
            keccak256(abi.encode(_newNumber, _anAddress)) // <--- Look here!
        )
    {
        s_incrediblyAmazingNumber = _newNumber;
        s_someAddress = _anAddress;
    }

    /// @dev Simple matchmaking function feature built on top of InputControl system.
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

    /// @notice Just a function to activate or deactivate the input checkings.
    function setInputControlState(bool _set) public onlyOwner {
        s_inputControlDisabled = _set;
    }

    // Getters
    function getNumber() public view returns (uint256) {
        return s_incrediblyAmazingNumber;
    }

    function getAmazingAddress() public view returns (address) {
        return s_someAddress;
    }

    function getOpponent(address _opponentOf) public view returns (address) {
        return s_playerToOpponent[_opponentOf];
    }

    function getMatchState(address _player) public view returns (bytes32) {
        return s_playerToMatchState[_player];
    }
}
