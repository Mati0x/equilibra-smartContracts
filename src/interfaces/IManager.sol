// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;
import {PoolInitParams, SafeSetUp} from "../structs.sol";

/**
 * @title IManager
 * @notice The interface of ManagerV1
 */
interface IManager {
    // ------------------------------------ //
    //              ADDR_GETTERS_FUNCS
    // ------------------------------------ //
    /**
     * @dev Retruns if `_isPool` is registered as a pool
     */
    function isPool(address _isPool) external view returns (bool) ;
    /**
     * @dev Retruns if `_isList` is registered as a list
     */
    function isList(address _isList)external view returns(bool);
    /**
     * @dev Retruns if `_isMultisig` is registered as a list
     */
    function isMultisig(address _isMultisig) external view returns (bool) ;
    // ------------------------------------ //
    //              CREATION_FUNCS
    // ------------------------------------ //

    /**
     *
     * @param _initPoolData Struct that contains data necessary to init a PoolProxy
     * @custom:descrition
     * As V1, this bytes will be encoded from:
     * PoolInitParams -> (address[5], FromulaParams)
     * and function initialize(address[5],FormulaParams)
     * _initPoolData -> abi.encode('initialize(address[5],(uint256,uint256,uint256,uint256))',address[5],FromulaParams(uint256,uint256,uint256,uint256))
     */
    function createPool(
        PoolInitParams memory _initPoolData
    ) external  returns (address pool_);

    /**
     *
     * @param _initPoolData Struct that contains data necessary to init a PoolProxy
     * @custom:descrition
     * As V1, this bytes will be encoded from:
     * PoolInitParams -> (address[5], FromulaParams)
     * and function initialize(address[5],FormulaParams)
     * _initPoolData -> abi.encode('initialize(address[5],(uint256,uint256,uint256,uint256))',address[5],FromulaParams(uint256,uint256,uint256,uint256))
     * @param _initSafeData Struct that contains data necessary to init a SafeProxy
     * @custom:descrition
     *
     *
     */
    function createPoolMultiSig(
        SafeSetUp calldata _initSafeData,
        PoolInitParams memory _initPoolData
    ) external returns (address pool_, address multiSig_);

    /**
     * 
     * @param _newOwner Address that will own (Ownable.owner()) the project list being created
     * @param _name Name of the list to be created
     * @custom:modifier whenNotPaused()
     */
    function createProjectList(
        address _newOwner,
        string calldata _name
    ) external  returns (address list_) ;
    // ------------------------------------ //
    //              OWNER_FUNCS
    // ------------------------------------ //
    /**
     * @dev Unpauses all operations
     * @custom:modifers onlyOwner()
     */
    function unpause() external;
    /**
     * @dev Pauses all operations
     * @custom:modifers onlyOwner()
     */
    function pause() external ;
    // ------------------------------------ //
    //              PROXYS_FUNCS
    // ------------------------------------ //
    /**
     * @dev Returns the current Managers proxy implementation
     */
    function implementation() external view returns (address);
    /**
     * @dev Returns the current Pool proxy implementation
     */
    function poolImplementation() external view returns (address);
    /**
     * @dev Returns the current Safe(multisig) proxy implementation
     */
    function safeImplementation() external view returns (address);
}