// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

// Comment out if not debugging
import "../../../lib/forge-std/src/console.sol";

import "./IInputControlComposite.sol";
import "../../../lib/openzeppelin-contracts/contracts/access/Ownable.sol";

// AccessControl.sol is not used in this contract but here it is if
// you want to play around with it. (:D)
// import "../../../lib/openzeppelin-contracts/contracts/access/AccessControl.sol";

/**
 * @title Example of contract using InputControlComposite.
 * @author Carlos Alegre Urquizú (GitHub --> https://github.com/CarlosAlegreUr)
 *
 * @dev To use InputControlComposite services instantiate a reference to an IInputControlComposite
 * contract address.
 *
 * @dev You can wrap setInputsPermission() call in a function that uses your own useful
 * modfiers. This will allow mixing this functionalities with other useful ones like Ownable or
 * AccessControl contracts from OpenZeppelin.
 *
 * Same thing with the function isAllowedInput(), you can just call i_inputControl.isAllowedInput()
 * from inside your functions but using a modifier or function to wrap it up allows for
 * personalizations. For example this UseCaseContract has a locker variable that activates and
 * deactivate input checkings.
 */
contract UseCaseContractComposite is Ownable {
    /// @notice Instantiation of the InputControlComposite contract
    IInputControlComposite immutable i_inputControl;

    constructor(address _inputControlCompositeAddress) {
        i_inputControl = IInputControlComposite(_inputControlCompositeAddress);
    }

    // @notice Features built on top of InputControl variables

    // @notice Locker for activating or deactivating controls
    bool private s_inputControlDisabled;

    // @notice Only owner variables
    uint256 private s_incrediblyAmazingNumber;
    address private s_someAddress;

    // @notice Matchmaking feature variables
    mapping(address => address) private s_playerToOpponent;
    mapping(address => bytes32) private s_playerToMatchState;

    // Look here!
    modifier checkInputControl(string memory _funcSig, address _callerAddress, bytes32 _input) {
        if (!s_inputControlDisabled) {
            bytes4 _funcSelec = bytes4(keccak256(bytes(_funcSig)));
            IInputControlComposite.Permission memory p = IInputControlComposite.Permission({
                allower: address(this), // <-- We are checking that this address 🟠
                contractAddress: address(this), // <-- has given permissions to call inside this contract
                functionSelector: _funcSelec, // <-- this function with the _input
                caller: _callerAddress // <-- to this address
            });
            /// @notice Caller should always be address(this), thats why is marked as essential with the orange circle.
            i_inputControl.isAllowedInput(p, _input);
        }
        _;
    }

    /// @dev Mixing InputControl with other useful contracts like Ownable in this case.
    /// Now you are using public infrastructure in your contract but only owner can decide
    /// who gives permissions.
    function giveInputPermission(
        address _callerAddress,
        bytes32[] calldata _validInputs,
        string calldata _funcSignature,
        bool _isSequence
    ) external onlyOwner /* <-- InputControl features compatibility with Ownable.sol*/ {
        bytes4 _funcSelec = bytes4(keccak256(bytes(_funcSignature)));

        /// @notice For best practices, this filtering should be made a modifier.
        /// Its written like this for visual purposes as an example.
        if (_funcSelec == bytes4(keccak256(bytes("myFunc(uint256,address)")))) {
            // Only the owner decides who to give input permissions in myFunc.
            require(msg.sender == this.owner());
        }

        if (_funcSelec == bytes4(keccak256(bytes("startMatch(address,bytes32)")))) {
            // You cannot give input permissions to yourself so you can start matches with whoever you want.
            require(_callerAddress != msg.sender);
        }

        bytes4 funcSelec = bytes4(keccak256(bytes(_funcSignature)));
        IInputControlComposite.Permission memory p = IInputControlComposite.Permission({
            allower: address(this), // <-- We will say to InputControlComposite that this address 🟠
            contractAddress: address(this), // <-- in this contract
            functionSelector: funcSelec, // <-- is giving permission for this function to be called with the inputs _validInputs
            caller: _callerAddress // <-- by this address
        });
        i_inputControl.setInputsPermission(p, _validInputs, _isSequence);
    }

    /// @dev The followig are any of the functions in your own smart contract.
    /// These functions are not needed in order to use InputControl,
    /// they are just example features that can be build on top of it.

    /// @dev myFunc is some function in your contract that only owner or privileged roles
    /// can give inpit permissions to.
    function myFunc(uint256 _newNumber, address _anAddress)
        external
        // Modifier that will call InputControlComposite
        checkInputControl(
            "myFunc(uint256,address)", //<---- Look here!
            msg.sender, //<---- Look here! 🟠
            keccak256(abi.encode(_newNumber, _anAddress)) //<---- Look here!
        )
    {
        s_incrediblyAmazingNumber = _newNumber;
        s_someAddress = _anAddress;
    }

    /// @dev Simple matchmaking function feature built on top of InputControl system.
    function startMatch(address _opponent, bytes32 _complexFirstStateOfMatch)
        external
        // Modifier that will call InputControlComposite
        checkInputControl(
            "startMatch(address,bytes32)", //<---- Look here!
            msg.sender, //<---- Look here! 🟠
            keccak256(abi.encode(_opponent, _complexFirstStateOfMatch)) //<---- Look here!
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
