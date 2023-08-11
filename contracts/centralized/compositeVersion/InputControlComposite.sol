// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

/* Customed Errors */
error InputControlComposite__NotAllowedInput();
error InputControlComposite__OnlyAdmin();
error InputControlComposite__CantMakeZeroAddressAdmin();

import "./IInputControlComposite.sol";

// Uncomment this line to use console.log
// import "hardhat/console.sol";

/**
 * @title Input Control Modular.
 * @author Carlos Alegre Urquizú (GitHub --> https://github.com/CarlosAlegreUr)
 *
 * @notice InputControlComposite is an implementation of IInputControlComposite. It's been created
 * for cases where inheriting the inheritance version of InputControl contract results in a too large
 * contract size to be deployed error.
 *
 * @notice As we are not inheriting, we need some way of controlling who is giving permissions to out
 * contracts. Thats why there is a simple admin system implementation compatible with Ownable or AccessControl
 * by OpenZeppelin.
 *
 * @dev To check an usecase check UseCaseContractModular.sol:
 * https://github.com/CarlosAlegreUr/InputControl-SmartContract-DesignPattern/blob/main/contracts/modularVersion/UseCaseContractModular.sol
 */
contract InputControlComposite is IInputControlComposite {
    /* Types */

    /**
     * @dev inputSequence struct allows the user tho call any input in the inputs array
     * but it has to be done in the order they are indexed.
     *
     * Example => First call must be done with the input at index 0, then the one at index 1,
     * then the index 2 value etc...
     */
    struct InputSequence {
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
    struct InputUnordered {
        bytes32[] inputs;
        uint256 inputsToUse;
        mapping(bytes32 => uint256) inputToTimesToUse;
        mapping(bytes32 => uint256) inputToPosition;
    }

    /* State Variables */

    // Admin state variables
    uint256 private s_adminCounter;
    mapping(address => bool) s_isAdmin;

    // Input permissions variables
    mapping(bytes32 => InputSequence) s_inputsSequences;
    mapping(bytes32 => InputUnordered) s_inputsUnordered;
    mapping(bytes32 => IInputControlComposite.PermissionState) s_permissionState;

    /* Modifiers */

    modifier onlyAdmin() {
        if (!s_isAdmin[msg.sender]) {
            revert InputControlComposite__OnlyAdmin();
        }
        _;
    }

    /* Constructor */
    constructor() {
        s_isAdmin[msg.sender] = true;
    }

    /* Functions */

    /**
     * @dev See documentation for the following public or external functions in IInputControlComposite.sol:
     * (TODO: add link)
     *
     * @dev Private functions docs can be found here, down below.
     */

    /* Public functions */
    /* Getters */

    function getPermissionId(Permission memory _p) public pure returns (bytes32) {
        return keccak256(abi.encode(_p.functionSelector, _p.caller));
    }

    function getPermissionState(Permission calldata _p) public view returns (IInputControlComposite.PermissionState) {
        return s_permissionState[getPermissionId(_p)];
    }

    function getIsAdmin(address _someone) public view returns (bool) {
        return s_isAdmin[_someone];
    }

    function getAllowedInputs(Permission calldata _p) public view returns (bytes32[] memory) {
        bytes32 pId = getPermissionId(_p);
        PermissionState pstate = s_permissionState[pId];
        if (pstate == PermissionState.IS_SEQUENCE) {
            return s_inputsSequences[pId].inputs;
        }
        if (pstate == PermissionState.IS_UNORDERED) {
            return s_inputsUnordered[pId].inputs;
        }
        return new bytes32[](0);
    }

    function getAdminCount() public view returns (bool) {
        return s_adminCounter;
    }

    /* Setters */

    function setInputsPermission(Permission calldata _p, bytes32[] calldata _inputsIds, bool _isSequence)
        public
        onlyAdmin
    {
        bytes32 pId = getPermissionId(_p);

        // Check if there is some storage to clean up.
        PermissionState currentState = s_permissionState[pId];
        if (currentState == PermissionState.IS_SEQUENCE) {
            _hanldeDeletionOfSequence(pId);
        }
        if (currentState == PermissionState.IS_UNORDERED) {
            _hanldeDeletionOfUnordered(pId);
        }

        // After cleaning up storage, or if the user is using control for the first time
        // sets the structs properly.
        if (_isSequence) {
            _handleNewSequencePermission(pId, _inputsIds);
        } else {
            _handleNewUnorderedPermission(pId, _inputsIds);
        }

        emit InputControlComposite__InputsPermissionGranted(_p, s_permissionState[pId]);
    }

    /* External functions */

    function setAdmin(address _newAdmin, bool _newIsAdmin) external onlyAdmin {
        // Set new admin state for the new admin
        s_isAdmin[_newAdmin] = _newIsAdmin;

        // Update admin counter and state that signals if contract has admins
        if (_newIsAdmin) {
            s_adminCounter++;
            s_HAS_ADMINS = true;
        } else {
            if (s_adminCounter > 0) {
                s_adminCounter--;
            } else {
                s_HAS_ADMINS = false;
            }
        }
    }

    function isAllowedInput(Permission calldata _p, bytes32 _input) external returns (bool) {
        // Getting permission values needed
        bytes32 pId = getPermissionId(_p);
        PermissionState currentState = s_permissionState[pId];

        // Checking permission state, only exeute if existing permission
        if (currentState == PermissionState.IS_NOT_EXISTING) {
            revert InputControlComposite__NotAllowedInput();
        }

        // Use the proper checking for each structure
        // Return false statements should never execute, they are added just in case.
        if (currentState == PermissionState.IS_SEQUENCE) {
            _hanldeSequenceCheck(pId, _input);
            return false;
        }
        if (currentState == PermissionState.IS_UNORDERED) {
            _hanldeUnorderedCheck(pId, _input);
            return false;
        }

        return true;
    }

    /* Private functions */

    /**
     * @dev This function creates a new InputSequence struct and indexes it with the `_permissionId` given.
     * Also updates the state for that permission ID to IS_SEQUENCE.
     *
     * @param _permissionId is the id of the permission being created.
     * @param _inputsIds is an array of the input hashes (ids) that want to be allowed.
     */
    function _handleNewSequencePermission(bytes32 _permissionId, bytes32[] calldata _inputsIds) private {
        // Saving values in a InputSequence structure
        InputSequence memory newSequence =
            InputSequence({inputs: _inputsIds, inputsToUse: _inputsIds.length, currentCall: 0});
        s_inputsSequences[_permissionId] = newSequence;

        // Updating permission state
        s_permissionState[_permissionId] = PermissionState.IS_SEQUENCE;
    }

    /**
     * @dev This function creates a new InputUnordered struct and indexes it with the `_permissionId` given.
     * Also updates the state for that permission ID to IS_UNORDERED.
     *
     * @param _permissionId is the id of the permission being created.
     * @param _inputsIds is an array of the input hashes (ids) that want to be allowed.
     */
    function _handleNewUnorderedPermission(bytes32 _permissionId, bytes32[] calldata _inputsIds) private {
        // Saving values in an InputUnordered structure
        s_inputsUnordered[_permissionId].inputs = _inputsIds;
        s_inputsUnordered[_permissionId].inputsToUse = _inputsIds.length;

        // Initializing the mapping values
        for (uint256 i = 0; i < _inputsIds.length; ++i) {
            s_inputsUnordered[_permissionId].inputToPosition[_inputsIds[i]] = i + 1;
            s_inputsUnordered[_permissionId].inputToTimesToUse[_inputsIds[i]] += 1;
        }

        // Updating permission state
        s_permissionState[_permissionId] = PermissionState.IS_UNORDERED;
    }

    /**
     * @dev Restes all values from the InputUnordered struct to 0
     * and sets the state of the `_permssionId` to IS_NOT_EXISTING.
     *
     * @notice Unordered structs are more expensive due to clearing up
     * mappings in storage.
     *
     * @param _permissionId is the id of the permission which struct
     * wants to be deleted (reseted to default 0 values)
     */
    function _hanldeDeletionOfUnordered(bytes32 _permissionId) private {
        bytes32[] memory inputs = s_inputsUnordered[_permissionId].inputs;

        // Resets map values
        for (uint256 i = 0; i < inputs.length; ++i) {
            delete s_inputsUnordered[_permissionId].inputToTimesToUse[inputs[i]];
            delete s_inputsUnordered[_permissionId].inputToPosition[inputs[i]];
        }
        // Reset other variables
        delete s_inputsUnordered[_permissionId].inputs;
        delete s_inputsUnordered[_permissionId].inputsToUse;

        // Reset permission state
        s_permissionState[_permissionId] = PermissionState.IS_NOT_EXISTING;
    }

    /**
     * @dev Restes all values from the InputSequence struct to 0
     * and sets the state of the `_permssionId` to IS_NOT_EXISTING.
     *
     * @param _permissionId is the id of the permission which struct
     * wants to be deleted (reseted to default 0 values)
     */
    function _hanldeDeletionOfSequence(bytes32 _permissionId) private {
        // Reset sequence struct
        delete s_inputsSequences[_permissionId];

        // Reset permission state
        s_permissionState[_permissionId] = PermissionState.IS_NOT_EXISTING;
    }

    /**
     * @dev This function, apart from checking if an input is valid, updates the
     * InputSequence parameters and handles proper storage deletion once an input
     * is used and once all of them are.
     *
     * @param _permissionId is the permission ID that points to the permission that wants to be checked.
     * @param _input is the hash representation (id) of the input being used by the caller.
     */
    function _hanldeSequenceCheck(bytes32 _permissionId, bytes32 _input) private {
        // Hanlding case deleted inputSequence case
        if (s_inputsSequences[_permissionId].inputsToUse == 0) {
            revert InputControlComposite__NotAllowedInput();
        }

        // The main input check
        if (s_inputsSequences[_permissionId].inputs[s_inputsSequences[_permissionId].currentCall] != _input) {
            revert InputControlComposite__NotAllowedInput();
        }

        // Updating inputSequence values
        s_inputsSequences[_permissionId].currentCall += 1;
        s_inputsSequences[_permissionId].inputsToUse -= 1;

        if (s_inputsSequences[_permissionId].inputsToUse != 0) {
            // Setting to bytes(0) value the input used in the input array.
            delete s_inputsSequences[_permissionId].inputs[
                        s_inputsSequences[_permissionId].currentCall - 1
                    ];
        } else {
            // All inputs used, reset struct.
            _hanldeDeletionOfSequence(_permissionId);
        }
    }

    /**
     * @dev This function, apart from checking if an input is valid, updates the
     * InputUnordered parameters and handles proper storage deletion once an input
     * is used and once all of them are.
     *
     * @param _permissionId is the permission ID that points to the permission that wants to be checked.
     * @param _input is the hash representation (id) of the input being used by the caller.
     */
    function _hanldeUnorderedCheck(bytes32 _permissionId, bytes32 _input) private {
        // Checking if the input exists or if has been used.
        if (
            s_inputsUnordered[_permissionId].inputToTimesToUse[_input] == 0
                || s_inputsUnordered[_permissionId].inputsToUse == 0
        ) {
            revert InputControlComposite__NotAllowedInput();
        }

        // Updating InputUnordered structure values
        s_inputsUnordered[_permissionId].inputToTimesToUse[_input] -= 1;
        s_inputsUnordered[_permissionId].inputsToUse -= 1;

        if (s_inputsUnordered[_permissionId].inputsToUse != 0) {
            // Setting to bytes(0) value the input used in the input array.
            delete s_inputsUnordered[_permissionId].inputs[
                        s_inputsUnordered[_permissionId].
                            inputToPosition[_input] - 1
                    ];
        } else {
            // All imputs have been used, reset struct.
            _hanldeDeletionOfUnordered(_permissionId);
        }
    }
}
