// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

// import "hardhat/console.sol";

import "./IInputControlPublic.sol";
import "../../lib/openzeppelin-contracts/contracts/access/Ownable.sol";

import "../../lib/forge-std/src/console.sol";

// AccessControl.sol is not used in this contract but here it is if
// you want to play with it. (:D)
// import "@openzeppelin/contracts/access/AccessControl.sol";

/**
 * @title Example of contract using InputControlPublic public services.
 * @author Carlos Alegre Urquizú (GitHub --> https://github.com/CarlosAlegreUr)
 */
contract UseCaseMatchmakerContract {
    IInputControlPublic immutable i_inputControl; // <---- Look here!
    uint256 private s_incrediblyAmazingNumber;
    address private s_someAddress;

    mapping(address => address) s_playerToOpponent;
    mapping(address => bytes32) s_playerToMatchState;

    constructor(address _inputControlPublicAddress) {
        // Instantiation of the InputControlPublic service
        i_inputControl = IInputControlPublic(_inputControlPublicAddress); // <---- Look here!
    }

    // Look here!
    modifier checkInputControl(string memory _funcSig, address _callerAddress, bytes32 _input) {
        bytes4 _funcSelec = bytes4(keccak256(bytes(_funcSig)));
        IInputControlPublic.Permission memory p = IInputControlPublic.Permission({
            allower: address(this), // <-- We are checking if this address
            contractAddress: address(this), // <-- in this contract
            functionSelector: _funcSelec, // <-- allows this function with the _input
            caller: _callerAddress // <-- to be called by this address
        });
        i_inputControl.isAllowedInput(p, _input);
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
    ) external {
        require(_callerAddress != msg.sender); // You cannot give exec permissions to yourself
        bytes4 funcSelec = bytes4(keccak256(bytes(_funcSignature)));
        IInputControlPublic.Permission memory p = IInputControlPublic.Permission({
            allower: address(this), // <-- We will say to InputControlPublic that this address
            contractAddress: address(this), // <-- in this contract
            functionSelector: funcSelec, // <-- is giving permission for this function to be called with the inputs _validInputs
            caller: _callerAddress // <-- by this address
        });
        i_inputControl.setInputsPermission(p, _validInputs, _isSequence);
    }

    // Any function in your own smart contract.
    function startMatch(address _opponent, bytes32 _complexFirstStateOfMatch)
        external
        // Modifier that will call InputControlPublic
        checkInputControl(
            "startMatch(address,bytes32)", //<---- Look here!
            msg.sender, //<---- Look here!
            keccak256(abi.encode(_opponent)) //<---- Look here!
        )
    {
        s_playerToOpponent[msg.sender] = _opponent;
        s_playerToMatchState[msg.sender] = _complexFirstStateOfMatch;
        s_playerToMatchState[_opponent] = _complexFirstStateOfMatch;
    }

    function getOpponent(address _opponentOf) public view returns (address) {
        return s_playerToOpponent[_opponentOf];
    }
}
