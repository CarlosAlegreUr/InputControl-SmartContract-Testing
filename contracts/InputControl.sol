// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

/* Customed Errors */
error InputControl__NotAllowedInput();

// Uncomment this line to use console.log
// import "hardhat/console.sol";

/**
 * @title Input Control.
 * @author Carlos Alegre Urquizú (GitHub --> https://github.com/CarlosAlegreUr)
 *
 * @notice InputControl can be used to control which inputs can some addresses send to
 * your smart contracts' functions. Even more: in case of needing an specific order of inputs
 * in multiple calls to the same function, it's also handeled by InputControl.
 *
 * @dev Check an usecase on a contract at UseCaseContract.sol on the github repo:
 * https://github.com/CarlosAlegreUr/InputControl-SmartContract-DesignPattern/blob/main/contracts/UseCaseContract.sol
 *
 */
contract InputControl {
    /* Types */

    /**
     * @dev inputSequence struct allows the user tho call any input in the inputs array
     * but it has to be done in the order they are indexed.
     *
     * Example => First call must be done with the input at index 0, then the one at index 1, then the index 2 value etc...
     */
    struct inputSequence {
        bytes32[] inputs;
        uint256 inputsToUse;
        uint256 currentCall;
    }

    /**
     * @dev inputUnordered struct allows the user to call any input in the inputs array
     * in any order. If desired to call twice the function with the same input, add the input
     * twice in the array and so on.
     *
     * @dev The only reason why `inputs` exists is to be more 'off-chain-user-friendly' and let the user
     * consult which inputs can still use.
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

    mapping(bytes4 => mapping(address => bool)) s_funcToIsSequence;
    mapping(bytes4 => mapping(address => inputSequence)) s_funcToInputSequence;
    mapping(bytes4 => mapping(address => inputUnordered)) s_funcToInputUnordered;

    /* Events */

    event InputControl__AllowedInputsGranted(
        address indexed client,
        bytes4 indexed funcSelec,
        bytes32[] validInputs,
        bool isSequence
    );

    /* Modifiers */

    /**
     * @dev Checks if `_callerAddress` can call `_funcSelec` with `_input`.
     * If needed this modifier automatically takes charge of reseting variables' values
     * or the whole data structure of inputSequence or inputUnordered for `_callerAddress`
     * at `_funcSelec`.
     */
    modifier isAllowedInput(
        bytes4 _funcSelec,
        address _callerAddress,
        bytes32 _input
    ) {
        if (s_funcToIsSequence[_funcSelec][_callerAddress] == true) {
            if (
                s_funcToInputSequence[_funcSelec][_callerAddress].inputsToUse ==
                0
            ) {
                revert InputControl__NotAllowedInput();
            }

            if (
                s_funcToInputSequence[_funcSelec][_callerAddress].inputs[
                    s_funcToInputSequence[_funcSelec][_callerAddress]
                        .currentCall
                ] != _input
            ) {
                revert InputControl__NotAllowedInput();
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
                    .inputToTimesToUse[_input] == 0
            ) {
                revert InputControl__NotAllowedInput();
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
        _;
    }

    /* Functions */

    /* Public functions */
    /* Getters */

    /**
     * @return Allowed inputs from `_callerAddress` when calling `_funcSignature`. If `_isSequence` == true
     * it returns the inputs' sequence allowed, otherwise it returns the unordered inputs allowed.
     *
     * If any of the values is the 0 value it most probably mean the value has been used.
     * Or in a really rare circumstance it means that you found the input that has a hashed value of 0.
     */
    function getAllowedInputs(
        string calldata _funcSignature,
        address _callerAddress,
        bool _isSequence
    ) public view returns (bytes32[] memory) {
        bytes4 funcSelector = bytes4(keccak256(bytes(_funcSignature)));
        if (_isSequence) {
            return s_funcToInputSequence[funcSelector][_callerAddress].inputs;
        } else {
            return s_funcToInputUnordered[funcSelector][_callerAddress].inputs;
        }
    }

    /* Internal functions */

    /**
     * @dev Override this function in your contract to use
     * allowInputsFor() mixed with other useful contracts and
     * modifiers like Owner and AccessControl contracts from
     * OpenZeppelin.
     *
     * See param specifications in allowInputsFor() docs.
     */
    function callAllowInputsFor(
        address _callerAddress,
        bytes32[] calldata _validInputs,
        string calldata _funcSignature,
        bool _isSequence
    ) public virtual {
        allowInputsFor(
            _callerAddress,
            _validInputs,
            _funcSignature,
            _isSequence
        );
    }

    /**
     * @dev Allows `_callerAddress` to call `_funcSignature` with `_validInputs`
     * values.
     *
     * @param _validInputs Each element must correspond to the equivalent of
     * executing in solidity the following functions with the inputs' values:
     * validInputUniqueIdentifier = keccak256(abi.encode(input))
     *
     * @dev Maybe an input has a keccak256(abi.encode(input)) == the empty
     * value for bytes32 in solidity. So in the unlikely but posible case of
     * "collision" the 'off-chain-user' should take into account he is using the
     * 'colliding' value when using getAllowedInputs().
     *
     * @param _funcSignature The function signature of a function is determined by
     * its name and parameter datatypes:
     *                      _funcSignature = funcName(arg1, arg2, ...)
     *
     * Example:
     * For allowInputsFor() function => _funcSignature = "allowInputsFor(address,bytes32[],string,bool)"
     *
     * @param _isSequence is a boolean.
     *
     * If `_isSequence` == true: You are saving allowed inputs in a sequence as the order they are in
     * `_validInputs`. The order will have to be followed when calling the function in order to use them.
     *
     * If == false: you are saving allowed inputs that will be able to be used in any order.
     */
    function allowInputsFor(
        address _callerAddress,
        bytes32[] calldata _validInputs,
        string calldata _funcSignature,
        bool _isSequence
    ) internal {
        bytes4 funcSelector = bytes4(keccak256(bytes(_funcSignature)));

        s_funcToIsSequence[funcSelector][_callerAddress] = _isSequence;

        if (_isSequence) {
            s_funcToInputSequence[funcSelector][_callerAddress]
                .inputsToUse = _validInputs.length;
            s_funcToInputSequence[funcSelector][_callerAddress].currentCall = 0;
            s_funcToInputSequence[funcSelector][_callerAddress]
                .inputs = _validInputs;
        } else {
            s_funcToInputUnordered[funcSelector][_callerAddress]
                .inputs = _validInputs;
            s_funcToInputUnordered[funcSelector][_callerAddress]
                .inputsToUse = _validInputs.length;
            for (uint256 i = 0; i < _validInputs.length; i++) {
                s_funcToInputUnordered[funcSelector][_callerAddress]
                    .inputToPosition[_validInputs[i]] = i + 1;
                s_funcToInputUnordered[funcSelector][_callerAddress]
                    .inputToTimesToUse[_validInputs[i]] += 1;
            }
        }

        emit InputControl__AllowedInputsGranted(
            _callerAddress,
            funcSelector,
            _validInputs,
            _isSequence
        );
    }
}
