// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;
/**
 * @title IPool
 * @notice The interface of PoolV1
 */
import {ProjectSupport,FormulaParams}from '../structs.sol';
interface IPool {
    //------------------------------------ //
    //              POJECT_FUNCS
    // ------------------------------------ //
    /**
     * @param _projectId Id of the project to retireve the total support made by participants
     */
    function getProjectSupport(
        uint256 _projectId
    ) external view returns (uint256) ;
     /**
     * 
     * @param _projectId Id of the project to see participant's support
     * @param _participant address of the participant to see it's support
     */
    function getParticipantSupport(
        uint256 _projectId,
        address _participant
    ) external view returns (uint256);
     /**
     * @dev Gets the total amount (in full units) being staked in this pool, thus the amount of support.
     */
    function getTotalSupport() external view returns (uint256);

    /**
     * @param _participant Address of a participant to retrieve amounts being staked
     * (amStaked,freeStaked)
     * @custom:amstaked Total amount being staked by participant in this contract
     * @custom:freestake Amount of that stake that is left without being used. This means that is the result of = amstaked- amSupported
     */
    function getTotalParticipantSupport(
        address _participant
    ) external view returns (uint, uint) ;
     /**
     * @dev Gets the target rate of funds that is projected to be  sent to `_projectId` per interval of time
     */
    function getTargetRate(uint256 _projectId) external view returns (uint256);
    /**
     * @dev Gets the rate of funds being sent to `_projectId` per interval of time
     */
    function getCurrentRate(
        uint256 _projectId
    ) external view returns (uint256) ;
    //------------------------------------ //
    //              FORMULA_FUNCS
    // ------------------------------------ //
    /**
     * @param _params a custom struct that defines the formula variables related to the pool
     * @custom:modifers onlyOwner
     */
    function setFormulaParams(FormulaParams calldata _params) external ;
     /**
     * @param _decay new decay param for the contract 
     * @custom:modifers onlyOwner
     */
    function setFormulaDecay(uint256 _decay) external;
     /**
     * m _drop new drop param for the contract 
     * @custom:modifers onlyOwner
     */
    function setFormulaDrop(uint256 _drop) external;
    /**
     * @param _minStakeRatio new minStakeRatio param for the contract 
     * @custom:modifers onlyOwner
     */
    function setFormulaMaxFlow(uint256 _minStakeRatio) external;
     /**
     * @param _minFlow new minFlow param for the contract 
     * @custom:modifers onlyOwner
     */
    function setFormulaMinStakeRatio(uint256 _minFlow) external; 

    //------------------------------------ //
    //              SUPPORT_FUNCS
    // ------------------------------------ //
    /**
     * 
     * @param _amount amout to be unstaked (GovToken)
     * @custom:modifers nonReentrant
     * @custom:requires 
     * 1. freeStake of msg.sender >= `_amount`
     */
    function unstakeGov(uint _amount) external ; 
    /**
     * 
     * @param _projectSupports Array of structs that carries information about certain project and the delta suport from each user
     * @custom:modifers nonReentrant
     * @custom:requires 
     * 1. msg.sender has staked enough GovTokens
     * 2. msg.sender has enough support for each _projectSupports[i] to subtract the support and still be > 0 (∂support[i]>=0)
     */
    function unsupportProjects(
        ProjectSupport[] calldata _projectSupports
    ) external ;
    /**
     * 
     * @param _amount amout to be unstaked (GovToken)
     * @param _projectSupports Array of structs that carries information about certain project and the delta suport from each user
     * 
     * @custom:modifers nonReentrant
     * @custom:requires 
     * 1. msg.sender has staked =>`_amount`
     * 2. ∂support is <= amount staked by the participant
     * 2. allowence of address(this) in msg.sender context >= `_amount`
     * 3. ALL projectsIds are being supported by msg.sender 
     * 4. ∂support[i] is <= projectId[i]'s support by sender && >=0 
     */
    function unstakeAndUnsupport(
        uint _amount,
        ProjectSupport[] calldata _projectSupports
    ) external;
    
    /**
     * 
     * @param _amount amout to be staked (GovToken)
     * @custom:modifers nonReentrant
     * @custom:requires 
     * 1. msg.sender has enough balance
     * 2. allowence of address(this) in msg.sender context >= `_amount`
     */
    function stakeGov(uint _amount) external ;
    /**
     * 
     * @param _amountToStake amout to be staked (GovToken)
     * @param _projectSupports Array of structs that carries information about certain project and the delta suport from each user
     * 
     * @custom:modifers nonReentrant
     * @custom:requires 
     * 1. msg.sender has enough balance
     * 2. allowence of address(this) in msg.sender context >= `_amount`
     * 3. ALL projectsIds are validis 
     * 4. ∂support is <= amount staked by the participant
     */
    function stakeAndSupport(
        uint _amountToStake,
        ProjectSupport[] calldata _projectSupports
    ) external ;
    /**
     *  @param _projectSupports Array of structs that carries information about certain project and the delta suport from each user
     * 
     * @custom:modifers nonReentrant
     * @custom:requires 
     * 
     * 1. ALL projectsIds are validis 
     * 2. ∂support is <= amount staked(and not used to support any project) by the participant
     */
    function supportProjects(
        ProjectSupport[] calldata _projectSupports
    ) external;
}