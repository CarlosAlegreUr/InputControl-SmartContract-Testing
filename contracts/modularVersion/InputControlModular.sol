// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

/* Customed Errors */
error InputControlModular__NotAllowedInput();
error InputControlModular__OnlyAdmin();

import "./IInputControlModular.sol";

// Uncomment this line to use console.log
// import "hardhat/console.sol";

/**
 * @title Input Control Modular.
 * @author Carlos Alegre Urquizú (GitHub --> https://github.com/CarlosAlegreUr)
 *
 * @notice InputControlModular is an implementation of IInputControlModular. It's been reated 
 * for cases where inheriting the traditional InputControl contract results in a too large 
 * contract size to be deployed error.
 * 
 * @notice Make sure to implement a modifier that controls the acces to allowInputsFor().
 * For that in this implementation I've built a simple admin creaton and management code 
 * where the deployer address becomes the one who grants becomes admin. And admin in this
 * implementation is the only one who can pass the admin role to other address.
 * 
 * I think this option is better because it makes InputControlModular decoupled from other packages,
 * so to better implement AccessControl or Ownable from OpenZeppelin wiht InputControlModular check 
 * the UseCaseContract link just down below:
 *
 * @dev To check an usecase at UseCaseContractModular.sol:
 * https://github.com/CarlosAlegreUr/InputControl-SmartContract-DesignPattern/blob/main/contracts/modularVersion/UseCaseContractModular.sol

 * @dev To check the classic InputControl.sol contract that works with inheritance:
 * https://github.com/CarlosAlegreUr/InputControl-SmartContract-DesignPattern/blob/main/contracts/InputControl.sol
 * 
 */
contract InputControlModular is IInputControlModular {
    /* Types */

    /**
     * @dev inputSequence struct allows the user tho call any input in the inputs array
     * but it has to be done in the order they are indexed.
     *
     * Example => First call must be done with the input at index 0, then the one at index 1,
     * then the index 2 value etc...
     */
    struct inputSequence {
        bytes32[] inputs;
        uint256 inputsToUse;
        uint256 currentCall;
    }

    /**
     * @dev inputUnordered struct allows the user to call any input in the inputs array
     * in any order. If desired to call the function with the same input twice, add the input
     * 2 times in the array and so on.
     *
     * @dev The only reason why `inputs` exists is to be more 'off-chain-user-friendly' and let the user
     * consult which inputs they can still use.
     *
     * @dev The only reason why `inputToPosition` exists is for a better storage space management of `inputs`
     * array when an input is used.
     *
     * @notice If anytime the input value is hashed and collides with 0 value in solidity, then inputs
     * array may not show properly the hashes of the inputs you can't and can use. Functionality will be
     * correct but off-chain user will have to take into account that one of the inputs is the colliding
     * with 0 one when analyzing their allowed inputs.
     */
    struct inputUnordered {
        bytes32[] inputs;
        uint256 inputsToUse;
        mapping(bytes32 => uint) inputToTimesToUse;
        mapping(bytes32 => uint) inputToPosition;
    }

    /* State Variables */
    address private s_ADMIN_ADDRESS;

    mapping(bytes4 => mapping(address => bool)) s_funcToIsSequence;
    mapping(bytes4 => mapping(address => inputSequence)) s_funcToInputSequence;
    mapping(bytes4 => mapping(address => inputUnordered)) s_funcToInputUnordered;

    constructor() {
        s_ADMIN_ADDRESS = msg.sender;
    }

    /* Modifiers */

    modifier onlyAdmin() {
        if (msg.sender != s_ADMIN_ADDRESS) {
            revert InputControlModular__OnlyAdmin();
        }
        _;
    }

    /* Functions */

    /* Public functions */
    /* Getters */

    /**
     * @dev See documentation for the following functions in IInputControlModular.sol:
     * (https://github.com/CarlosAlegreUr/InputControl-SmartContract-DesignPattern/blob/main/contracts/modularVersion/IInputControlModular.sol
)
     */
    function getIsSequence(
        string calldata _funcSignature,
        address _callerAddress
    ) public view returns (bool) {
        bytes4 funcSelec = bytes4(keccak256(bytes(_funcSignature)));
        return s_funcToIsSequence[funcSelec][_callerAddress];
    }

    function getAllowedInputs(
        string calldata _funcSignature,
        address _callerAddress
    ) public view returns (bytes32[] memory) {
        bytes4 funcSelector = bytes4(keccak256(bytes(_funcSignature)));
        if (s_funcToIsSequence[funcSelector][_callerAddress]) {
            return s_funcToInputSequence[funcSelector][_callerAddress].inputs;
        } else {
            return s_funcToInputUnordered[funcSelector][_callerAddress].inputs;
        }
    }

    /* External functions */
    function setAdmin(address _nextAdmin) external onlyAdmin {
        s_ADMIN_ADDRESS = _nextAdmin;
    }

    function isAllowedInput(
        bytes4 _funcSelec,
        address _callerAddress,
        bytes32 _input
    ) external {
        if (s_funcToIsSequence[_funcSelec][_callerAddress] == true) {
            if (
                s_funcToInputSequence[_funcSelec][_callerAddress].inputsToUse ==
                0
            ) {
                revert InputControlModular__NotAllowedInput();
            }

            if (
                s_funcToInputSequence[_funcSelec][_callerAddress].inputs[
                    s_funcToInputSequence[_funcSelec][_callerAddress]
                        .currentCall
                ] != _input
            ) {
                revert InputControlModular__NotAllowedInput();
            }

            s_funcToInputSequence[_funcSelec][_callerAddress].currentCall += 1;

            s_funcToInputSequence[_funcSelec][_callerAddress].inputsToUse -= 1;

            if (
                s_funcToInputSequence[_funcSelec][_callerAddress].inputsToUse ==
                0
            ) {
                delete s_funcToInputSequence[_funcSelec][_callerAddress];
            } else {
                delete s_funcToInputSequence[_funcSelec][_callerAddress].inputs[
                        s_funcToInputSequence[_funcSelec][_callerAddress]
                            .currentCall - 1
                    ];
            }
        } else {
            if (
                s_funcToInputUnordered[_funcSelec][_callerAddress]
                    .inputToTimesToUse[_input] ==
                0 ||
                s_funcToInputUnordered[_funcSelec][_callerAddress]
                    .inputsToUse ==
                0
            ) {
                revert InputControlModular__NotAllowedInput();
            }

            s_funcToInputUnordered[_funcSelec][_callerAddress]
                .inputToTimesToUse[_input] -= 1;

            s_funcToInputUnordered[_funcSelec][_callerAddress].inputsToUse -= 1;

            if (
                s_funcToInputUnordered[_funcSelec][_callerAddress]
                    .inputsToUse != 0
            ) {
                delete s_funcToInputUnordered[_funcSelec][_callerAddress]
                    .inputs[
                        s_funcToInputUnordered[_funcSelec][_callerAddress]
                            .inputToPosition[_input] - 1
                    ];
            } else {
                delete s_funcToInputUnordered[_funcSelec][_callerAddress];
            }
        }
    }

    function allowInputsFor(
        address _callerAddress,
        bytes32[] calldata _validInputs,
        string calldata _funcSignature,
        bool _isSequence
    ) external onlyAdmin {
        bytes4 funcSelector = bytes4(keccak256(bytes(_funcSignature)));

        s_funcToIsSequence[funcSelector][_callerAddress] = _isSequence;

        if (_isSequence) {
            // Saving values in a inputSequence structure
            s_funcToInputSequence[funcSelector][_callerAddress]
                .inputsToUse = _validInputs.length;
            s_funcToInputSequence[funcSelector][_callerAddress].currentCall = 0;
            s_funcToInputSequence[funcSelector][_callerAddress]
                .inputs = _validInputs;
        } else {
            // Saving values in an inputUnordered structure
            s_funcToInputUnordered[funcSelector][_callerAddress]
                .inputs = _validInputs;
            s_funcToInputUnordered[funcSelector][_callerAddress]
                .inputsToUse = _validInputs.length;

            // Resets old map values
            for (uint256 i = 0; i < _validInputs.length; i++) {
                s_funcToInputUnordered[funcSelector][_callerAddress]
                    .inputToTimesToUse[_validInputs[i]] = 0;
            }

            for (uint256 i = 0; i < _validInputs.length; i++) {
                s_funcToInputUnordered[funcSelector][_callerAddress]
                    .inputToPosition[_validInputs[i]] = i + 1;
                s_funcToInputUnordered[funcSelector][_callerAddress]
                    .inputToTimesToUse[_validInputs[i]] += 1;
            }
        }

        emit InputControlModular__AllowedInputsGranted(
            _callerAddress,
            funcSelector,
            _validInputs,
            _isSequence
        );
    }
}
