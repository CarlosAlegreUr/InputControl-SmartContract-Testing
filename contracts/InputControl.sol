// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

/* Customed Errors */
error InputControl__NotAllowedInput();
error InputControl_HashCollisionWith0Value();

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
 * @dev Check an example of use on a contract at UseCaseContract.sol on the github repo:
 * https://github.com/CarlosAlegreUr/InputControl-SmartContract-DesignPattern/blob/main/contracts/UseCaseContract.sol
 *
 */
contract InputControl {
    /* Types */

    /**
     * @dev inputSequence struct allows the user tho call any input in the inputs array
     * but it has to be done in the order they are indexed.
     *
     * Example => First the input at index 0, then the one at index 1, then the index 2 value etc...
     */
    struct inputSequence {
        uint256 numOfCalls;
        bytes32[] inputs;
        uint256 actualCall;
    }

    /**
     * @dev inputUnordered struct allows the user to call any input in the inputs array
     * in any order. If desired to call twice the function with the sme input, add the input
     * twice in the array.
     */
    struct inputUnordered {
        uint256 numOfCalls;
        bytes32[] inputs;
    }

    /* State Variables */

    mapping(string => mapping(address => inputSequence)) s_funcSignatureToAllowedInputSequence;
    mapping(string => mapping(address => inputUnordered)) s_funcSignatureToAllowedinputUnordered;

    /* Events */
    event InputControl__AllowedInputsGranted(
        address indexed client,
        string indexed funcSig,
        bytes32[] validInputs
    );

    /* Modifiers */

    /**
     * @dev Checks if `_client` can call `_funcSignature` with `_input`.
     * If `_client` has used all it's calls, this modifier resets the
     * inputSequence or inputUnordered for a `_client` in a `_funcSignature`.
     */
    modifier isAllowedInput(
        string memory _funcSig,
        address _clientAddress,
        bytes32 _input,
        bool _isSequence
    ) {
        if (_isSequence) {
            inputSequence memory seq = s_funcSignatureToAllowedInputSequence[
                _funcSig
            ][_clientAddress];
            if (seq.numOfCalls != 0) {
                if (seq.inputs[seq.actualCall] != _input) {
                    revert InputControl__NotAllowedInput();
                }

                if ((seq.actualCall + 1) == seq.numOfCalls) {
                    delete s_funcSignatureToAllowedInputSequence[_funcSig][
                        _clientAddress
                    ];
                } else {
                    s_funcSignatureToAllowedInputSequence[_funcSig][
                        _clientAddress
                    ].actualCall += 1;
                }
            } else {
                revert InputControl__NotAllowedInput();
            }
        } else {
            inputUnordered memory spec = s_funcSignatureToAllowedinputUnordered[
                _funcSig
            ][_clientAddress];
            if (spec.numOfCalls != 0) {
                uint256 i = 0;
                bool found = false;
                while (!found && i < spec.inputs.length) {
                    if (spec.inputs[i] == _input) {
                        delete s_funcSignatureToAllowedinputUnordered[_funcSig][
                            _clientAddress
                        ].inputs[i];
                        spec.numOfCalls -= 1;
                        found = true;
                        if (spec.numOfCalls == 0) {
                            delete s_funcSignatureToAllowedinputUnordered[
                                _funcSig
                            ][_clientAddress];
                        }
                    } else {
                        i += 1;
                    }
                }
                if (!found) {
                    revert InputControl__NotAllowedInput();
                }
            } else {
                revert InputControl__NotAllowedInput();
            }
        }
        _;
    }

    /* Functions */

    /* Public functions */
    /* Getters */

    /**
     * @return Allowed inputs from `_address` when calling `_funcSignature`. If `_isSequence` == true
     * the indexes of inputs at the inputs array show in which order when calling `_funcSignature` those
     * inputs' values can be used. If `_isSequence` == false then inputs at the array can be called in any
     * order.
     */
    function getAllowedInputs(
        string memory _funcSignature,
        address _address,
        bool _isSequence
    ) public view returns (bytes32[] memory) {
        if (_isSequence) {
            return
                s_funcSignatureToAllowedInputSequence[_funcSignature][_address]
                    .inputs;
        } else {
            return
                s_funcSignatureToAllowedinputUnordered[_funcSignature][_address]
                    .inputs;
        }
    }

    /* Internal functions */

    /**
     * @dev Override this function in your contract to use
     * allowInputsFor() mixed with other useful contracts and
     * modifiers like Owner and AccessControl contracts of
     * OpenZeppelin.
     *
     * See param specifications in allowInputsFor() docs.
     */
    function callAllowInputsFor(
        address _client,
        bytes32[] calldata _validInputs,
        string calldata _funcSignature,
        bool _isSequence
    ) public virtual {
        allowInputsFor(_client, _validInputs, _funcSignature, _isSequence);
    }

    /**
     * @dev Allows `_client` to call `_funcSignature` with `_validInputs`
     * values.
     * 
     * @param _validInputs Each element must correspond to the equivalent of
     * executing in solidity the following funtions with inputs' values:
     * validInputUniqueIdentifier = keccak256(abi.encodePacked(input))
     * 
     * @dev Maybe an input has a keccak256(abi.encodePacked(input)) == the empty
     * value for bytes32 in solidity. This is the value that InputControl uses to
     * know if an input in the inputUnordered structure has been used, so in the unlikely but
     * posible case of "collision"; the input used for `_funcSig` should be slightly changed.
     *
     * @param _funcSignature should be a name you want to give to your function,
     * could be any but for consistency I recommend putting the name of the function
     * with it's datatypes =>  _funcSignature = funcName(arg1, arg2, ...)
     *
     * Example:
     * For allowInputsFor() function => _funcSignature = "allowInputsFor(address, bytes32[], string)"
     *
     * @param _isSequence is a boolean. If `_isSequence` == true => You are saving allowed inputs
     * in a sequence that must be followed when calling the function in order to use them. If == false;
     * you are saving allowed inputs that will be able to be used in any order.
     */
    function allowInputsFor(
        address _client,
        bytes32[] calldata _validInputs,
        string calldata _funcSignature,
        bool _isSequence
    ) internal {
        if (_isSequence) {
            s_funcSignatureToAllowedInputSequence[_funcSignature][_client]
                .numOfCalls = _validInputs.length;
            s_funcSignatureToAllowedInputSequence[_funcSignature][_client]
                .actualCall = 0;
            s_funcSignatureToAllowedInputSequence[_funcSignature][_client]
                .inputs = _validInputs;
        } else {
            for (uint256 i = 0; i < _validInputs.length; i++) {
                if (
                    _validInputs[i] ==
                    0x0000000000000000000000000000000000000000000000000000000000000000
                ) {
                    revert InputControl_HashCollisionWith0Value();
                }
            }
            s_funcSignatureToAllowedinputUnordered[_funcSignature][_client]
                .numOfCalls = _validInputs.length;
            s_funcSignatureToAllowedinputUnordered[_funcSignature][_client]
                .inputs = _validInputs;
        }

        emit InputControl__AllowedInputsGranted(
            _client,
            _funcSignature,
            _validInputs
        );
    }
}
