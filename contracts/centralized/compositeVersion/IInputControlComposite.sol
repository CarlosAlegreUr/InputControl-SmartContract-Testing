// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

/**
 * @title Input Control Modular Interface
 * @author Carlos Alegre Urquizú (GitHub --> https://github.com/CarlosAlegreUr)
 * @notice This interface defines a system for controlling the sequence and set of inputs
 * addresses can send to contract functions. It allows total control on function call input values.
 *
 * @dev For an interface implementation, refer to the contract InputControlComposite.sol:
 * (TODO: add link)
 * @dev For an implementation example, refer to the contract UseCaseContractModular.sol:
 * (TODO: add link)
 */
interface IInputControlComposite {
    /// @notice Represents the various states a permission can be in
    /// Can represent if permission exists and if so to which kind of
    /// allowed input points to.
    enum PermissionState {
        IS_NOT_EXISTING,
        IS_SEQUENCE,
        IS_UNORDERED
    }

    /// @notice Defines a set of parameters to control permissions
    /// @param functionSelector The function selector for the target function in the contract
    /// @param caller The address being who is being granted the permission
    struct Permission {
        bytes4 functionSelector;
        address caller;
    }

    /* Events */
    
    /// @notice Event emitted when permissions for inputs are granted
    /// @param permission The associated permission details
    /// @param state The state of the permission (sequence or unordered)
    event InputControlComposite__InputsPermissionGranted(Permission indexed permission, PermissionState state);

    /* Getters */

    /// @notice Calculates a unique ID for a permission
    /// @param _p The permission details
    /// @return The unique ID of the permission
    function getPermissionId(Permission memory _p) external pure returns (bytes32);

    /// @notice Fetches the state of a permission
    /// @param _p The permission details
    /// @return The state of the given permission
    function getPermissionState(Permission calldata _p) external view returns (IInputControlComposite.PermissionState);

    /// @notice Retrieves the allowed input IDs for a permission
    /// @param _p The permission details
    /// @return List of allowed input IDs
    function getAllowedInputs(Permission calldata _p) external view returns (bytes32[] memory);

    /* Setters */

    /// @notice Sets the permissions for specific input IDs
    /// @param _p The permission details
    /// @param _inputsIds List of input IDs to permit
    /// @param _isSequence Whether the inputs should be used in sequence or not
    function setInputsPermission(Permission calldata _p, bytes32[] calldata _inputsIds, bool _isSequence) external;

    /* Admin related functions */

    /// @param someone The address to check
    /// @return Wheter `_someone` has admin permissions or not. True = It has, False = I hasnt
    function getIsAdmin(address _someone) external view returns (bool);

    /// @return Returns how many admins the contract has.
    function getAdminCount() public view returns (uint256) 

    /// @param _newAdmin The address to apply the change
    /// @param _newIsAdmin Wheter to make admin or not
    function setAdmin(address _newAdmin, bool _newIsAdmin) external;
}
