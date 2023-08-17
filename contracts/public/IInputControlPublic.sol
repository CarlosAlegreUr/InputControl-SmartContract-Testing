// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

/**
 * @title Input Control Global Interface
 * @author Carlos Alegre Urquizú (GitHub --> https://github.com/CarlosAlegreUr)
 * @notice This interface defines a system for controlling the sequence and set of inputs
 * addresses can send to a contract's functions. It allows total control on function call input values.
 *
 * @dev For an interface implementation, refer to the contract InputControlPublic.sol:
 * (TODO: add link)
 * @dev For a use-case example, refer to the contract UseCaseContractGlobal.sol:
 * (TODO: add link)
 */
interface IInputControlPublic {
    /* Customed Errors */
    error InputControlPublic__NotAllowedInput();
    error InputControlPublic__PermissionDoesntExist();
    error InputControlPublic__AllowerIsNotSender();

    /* Types */

    /// @notice Represents the various states a permission can be in.
    /// Represents if permission exists and if so to which kind of
    /// allowed input points to.
    enum PermissionState {
        IS_NOT_EXISTING,
        IS_SEQUENCE,
        IS_UNORDERED
    }

    /// @notice Defines a set of parameters to control permissions
    /// @param allower The address granting permissions
    //  @param contractAddress The address of the contract whose function will be called.
    /// @param functionSelector The function selector for the target function in the contract
    /// @param caller The address being granted the permission
    struct Permission {
        address allower;
        address contractAddress;
        bytes4 functionSelector;
        address caller;
    }

    /* Events */

    /// @notice Event emitted when permissions for inputs are granted
    /// @param permission The associated permission details
    /// @param state The state of the permission (sequence or unordered)
    event InputControlPublic__InputsPermissionGranted(Permission indexed permission, PermissionState state);

    /* Functions */

    /// @notice Calculates a unique ID for a permission
    /// @param _p The permission details
    /// @return The unique ID of the permission
    function getPermissionId(Permission memory _p) external pure returns (bytes32);

    /// @notice Fetches the state of a permission
    /// @param _p The permission details
    /// @return The state of the given permission
    function getPermissionState(Permission calldata _p) external view returns (PermissionState);

    /// @notice Retrieves the allowed input IDs for a permission
    /// @param _p The permission details
    /// @return List of allowed input IDs
    function getAllowedInputs(Permission calldata _p) external view returns (bytes32[] memory);

    /// @notice Sets the permissions for specific input IDs
    /// @param _p The permission details
    /// @param _inputsIds List of input IDs to permit
    /// @param _isSequence Whether the inputs should be used in sequence or not
    function setInputsPermission(Permission calldata _p, bytes32[] calldata _inputsIds, bool _isSequence) external;

    /// @notice Checks if a specific input is allowed for a permission
    /// @param _p The permission details
    /// @param _input The input to check
    function isAllowedInput(Permission calldata _p, bytes32 _input) external;
}
