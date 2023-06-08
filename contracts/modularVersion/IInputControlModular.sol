// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

/**
 * @title Interface Input Control Modular.
 * @author Carlos Alegre Urquizú (GitHub --> https://github.com/CarlosAlegreUr)
 *
 * @notice IInputControlModular is an interfice for InputControlModular created for cases
 * where inheriting the traditional InputControl contract results in a: too large contract
 * size to be deployed error.
 *
 * @dev Check the InputControlModular.sol implementation here:
 * https://github.com/CarlosAlegreUr/InputControl-SmartContract-DesignPattern/blob/main/contracts/modularVersion/InputControlModular.sol
 *
 * @dev Check an usecase at UseCaseContractModular.sol where it's also shown how to mix this
 * contract with other useful ones like Ownable by OpenZeppelin:
 * https://github.com/CarlosAlegreUr/InputControl-SmartContract-DesignPattern/blob/main/contracts/modularVersion/UseCaseModular.sol
 *
 */
interface IInputControlModular {
    /**
     * @dev Event emmited when calling allowInputsFor() with it's parameters
     * in order to help keeping track of the contract actions.
     */
    event InputControlModular__AllowedInputsGranted(
        address indexed caller,
        bytes4 indexed funcSelec,
        bytes32[] validInputs,
        bool isSequence
    );

    /**
     * @return Returns wheter the `_callerAddress` must use intputs for `_funcSignature` in a
     * sequence or an unordered manner.
     */
    function getIsSequence(
        string calldata _funcSignature,
        address _callerAddress
    ) external view returns (bool);

    /**
     * @return Allowed inputs from `_callerAddress` when calling `_funcSignature`.
     *
     * @notice If any of the values is the 0 value it most probably mean the value has been used.
     * Or in a really rare circumstance it means that your input has a hashed value of 0
     * and you won't be able to relize wheter it's used or not by seeing the 0 value
     * in the array.
     *
     * Thats why I recommend checking before calling this contract if any
     * of the inputs is hashed to 0, in order to later know precisely which inputs have
     * already been used.
     *
     * The contract logic will work no matter what the hash of your input is though, this
     * reommenation is just for making sure you always can precisely check what someone has or hasn't
     * used in the contract.
     */
    function getAllowedInputs(
        string calldata _funcSignature,
        address _callerAddress
    ) external view returns (bytes32[] memory);

    /**
     * @dev Checks if `_callerAddress` can call `_funcSelec` with `_input`.
     * If needed this modifier automatically takes charge of reseting variables' values
     * or the whole data structure of inputSequence or inputUnordered for `_callerAddress`
     * at `_funcSelec`.
     */
    function isAllowedInput(
        bytes4 _funcSelec,
        address _callerAddress,
        bytes32 _input
    ) external;

    /**
     * @dev Must be only callable by current admin. 
     *
     * @notice In order for allowInputsFor() not be callable by who knows who
     * we need an admin we control. For that there is a simple admin implementation
     * required. Check it out in InputControlModular.sol.
     * 
     * First admin will be the deployer of the interface implementation and then the
     * deployer will be able to update it to the desired contract if needed using this 
     * function.
     *
     * @param _nextAdmin is the next desired admin.
     */
    function setAdmin(address _nextAdmin) external;

    /**
     * @dev Allows `_callerAddress` to call `_funcSignature` with `_validInputs`
     * values. If `_callerAddress` has some `_validInputs` to call left but this
     * function is called to give new ones, old permission will be overwritten.
     *
     * @param _validInputs Each element must correspond to the equivalent of
     * executing in solidity the following functions with the inputs' values:
     * validInputUniqueIdentifier = keccak256(abi.encode(input))
     *
     * @notice Maybe an input has a keccak256(abi.encode(input)) == the empty
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
    ) external;
}
