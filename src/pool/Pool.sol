// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import {OwnableUpgradeable} from "@oz-upgradeable/access/OwnableUpgradeable.sol";
import {ReentrancyGuardUpgradeable} from "@oz-upgradeable/utils/ReentrancyGuardUpgradeable.sol";

import {IERC20} from "@oz/token/ERC20/IERC20.sol";
import {ISuperToken} from "../interfaces/ISuperToken.sol";

import {ICFAv1Forwarder} from "../interfaces/ICFAv1Forwarder.sol";
import {IProjectList, Project, PROJECT_NOT_IN_LIST} from "../interfaces/IProjectList.sol";
import {Formula, FormulaParams} from "../Formula.sol";
// import {Manager} from "./Manager.sol";
import {IManager} from "../interfaces/IManager.sol";
import {ProjectSupport, SupportInfo, ParticipantInfo, PoolProject} from "../structs.sol";

error INVALID_PROJECT_LIST();
// error InvalidgovToken();
error SUPPORT_UNDERFLOW(uint _currSupport,uint _delta);
error PROJECT_ALREADY_ACTIVE(uint256 _projectId);
error PROJECT_NEEDS_MORE_STAKE(
    uint256 _projectId,
    uint256 _projectStake,
    uint256 _requiredStake
);
error NOT_ENOUGH_STAKED();
error WRONG_AMOUNT_OF_PROJECTS(uint _sent, uint _max);
error NOT_ENOUGH_ALLOWENCE(uint _totAllowence, uint _amReq);
error INVALID_ADDRESS();
error EXCEEDS_PARTICIPANT_BALANCE(uint _pBalance, uint _delta);

// forge inspect src/PoolV2.sol:Pool bytecode
contract Pool is OwnableUpgradeable, ReentrancyGuardUpgradeable, Formula {
    address public cfaForwarder;
    address public manager;

    uint40 internal val;
    uint8 public constant MAX_ACTIVE_PROJECTS = 25;

    address public projectList;
    address public fundingToken;
    IERC20 public govToken;

    // uint round;
    /**
     * @custom:change
     * Instead of using the mapping, asi rounds are not used, we store all the support inside a variable
     */
    uint totalSupport;

    uint256[MAX_ACTIVE_PROJECTS] internal activeProjectIds;

    mapping(address => ParticipantInfo) participantAmountStaked;

    // projectId => PoolProject [MAX_25]
    mapping(uint256 => PoolProject) public poolProjects;

    /* *************************************************************************************************************************************/
    /* ** Events                                                                                                                         ***/
    /* *************************************************************************************************************************************/

    event ProjectActivated(uint256 indexed projectId);
    event ProjectDeactivated(uint256 indexed projectId);
    event ProjectSupportUpdated(
        uint256 indexed projectId,
        address participant,
        string action,
        uint256 delta
    );
    event FlowSynced(
        uint256 indexed projectId,
        address beneficiary,
        uint256 flowRate
    );

    /**
     * @custom:executes
     * This is being executed when the implementation is deployed, only once
     */
    constructor(address _cfaForwarder) {
        _disableInitializers();

        require(
            (cfaForwarder = _cfaForwarder) != address(0),
            "Zero CFA Forwarder"
        );
    }

    // error ZERO_CFA();
    /**
     *
     * @param _addresses Array of addresses
     * @custom:addresses-explained :=
     * _addresses[0]:= PoolOwner
     * _addresses[1]:= Manager address
     * _addresses[2]:= Funding token address
     * _addresses[3]:= List address
     * _addresses[4]:= GovTokenAddress
     * @param _params Formula params
     * @custom:params-explained :=
     * _params.decay
     * _params.drop
     * _params.maxFlow
     * _params.minStakeRatio
     */
    function initialize(
        // address _fundingToken,
        // address _newOwner,
        // address _govToken,
        // address _projectList,
        // // address _cfaForwarder,
        // address _manager,
        address[5] calldata _addresses,
        FormulaParams calldata _params
    ) public initializer {
        /**
         * @custom:fix hay que arreglar que solo lo pueda iniciar el manager sino estamos en la b
         */
        // if (msg.sender!= _addresses[1])revert('NO_ADDR_ALLOWED');

        __Ownable_init(_addresses[0]);
        __ReentrancyGuard_init();
        _Formula_init(_params);
        require((manager = _addresses[1]) != address(0), "Zero Manager");
        require(
            (fundingToken = _addresses[2]) != address(0),
            "Zero Funding Token"
        );

        if (IManager(manager).isList(_addresses[3])) {
            projectList = _addresses[3];
        } else {
            revert INVALID_PROJECT_LIST();
        }
        if (_addresses[4] == address(0)) revert INVALID_ADDRESS();
        /**
         * @custom:change
         * The token that will be used as governace MUST be valid
         * No security checks are being made, so responsability relies on users
         */
        // if (Manager(manager).isToken(_govToken)) {
        govToken = IERC20(_addresses[4]);
    }

    /* *************************************************************************************************************************************/
    /* ** Participant Support Function                                                                                                   ***/
    /* *************************************************************************************************************************************/

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
    ) external nonReentrant {
        _unsupportProjects(_projectSupports);
    }

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
    ) external nonReentrant {
        _unsupportProjects(_projectSupports);
        _unstakeGov(_amount);
    }

    /**
     *
     * @param _amount amout to be unstaked (GovToken)
     * @custom:modifers nonReentrant
     * @custom:requires
     * 1. freeStake of msg.sender >= `_amount`
     */
    function unstakeGov(uint _amount) external nonReentrant {
        _unstakeGov(_amount);
    }

    /**
     *
     * @param _amount amout to be staked (GovToken)
     * @custom:modifers nonReentrant
     * @custom:requires
     * 1. msg.sender has enough balance
     * 2. allowence of address(this) in msg.sender context >= `_amount`
     */
    function stakeGov(uint _amount) external nonReentrant {
        _stakeGov(_amount);
    }

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
    ) external nonReentrant {
        _stakeGov(_amountToStake);
        _supportProjects(_projectSupports);
    }

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
    ) external nonReentrant {
        _supportProjects(_projectSupports);
    }

    /* *************************************************************************************************************************************/
    /* ** Project Activation Function                                                                                                    ***/
    /* *************************************************************************************************************************************/
    ///@custom:problema cualquiera activa proyectos! Pero si no tiene suficiente stake esto revierte
    ///@custom:discusion Eso deberia ser con el Owner, aca entra la GNOSIS_SAFE
    /**
     * @custom:change
     * - Visibility can be changed to external rather than public
     * - Anyone can activate a project (even a non-community member)
     * -
     */

    function activateProject(uint256 _projectId) external {
        _checkProjectExist(_projectId);

        uint256 projectSupport = _getProjectSupport(_projectId);

        uint256 minSupport = type(uint256).max;
        uint256 minIndex = 0;
        uint[25] memory _activeIds=activeProjectIds;

        for (uint256 i = 0; i < _activeIds.length; i++) {
            if (_activeIds[i] == _projectId) {
                revert PROJECT_ALREADY_ACTIVE(_projectId);
            }

            // If position i is empty, use it
            if (_activeIds[i] == 0) {
                _activateProject(i, _projectId);
                return;
            }

            uint256 currentProjectSupport = _getProjectSupport(
                _activeIds[i]
            );
            if (currentProjectSupport < minSupport) {
                minSupport = _getProjectSupport(_activeIds[i]);
                minIndex = i;
            }
        }

        if (projectSupport < minSupport) {
            revert PROJECT_NEEDS_MORE_STAKE(
                _projectId,
                projectSupport,
                minSupport
            );
        }

        _deactivateProject(minIndex);
        _activateProject(minIndex, _projectId);
    }

    /* *************************************************************************************************************************************/
    /* ** Flow Syncronization Function                                                                                                   ***/
    /* *************************************************************************************************************************************/
    /**
     * @custom:problema Aca si el allowence es 0 no revierte, y eso deberia ser
     * @custom:quien llama la funcion (chainlnk, push)
     * @custom:revisar la gilada del stake como cambia aca las cosas
     */
    function sync() external {
        uint256 allowance = ISuperToken(fundingToken).allowance(
            owner(),
            address(this)
        );
        /**
         * @custom:now
         * $EQ ->  owner()[multisig_gnosis]
         * A -> Manager[$EQc] ---> balanceOf(owner())+= $EQc
         * @custom:idea
         *
         * A -> Manager[$EQc] ---> balanceOf(address(this))+= $EQc
         *
         */
        if (allowance > 0) {
            ISuperToken(fundingToken).transferFrom(
                owner(),
                address(this),
                allowance
            );
        }
        /**
         * @custom:change
         * Agregamos una variable que haga de tracker al balance que se deposita y se usa y cada vez que se `sync` que se fije si lo siquiente pasa
         *
         * if(syncedBalance<funds)
         * @custom:pensar
         */

        uint256 funds = ISuperToken(fundingToken).balanceOf(address(this));
        uint[25] memory _activeIds=activeProjectIds;

        for (uint256 i = 0; i < _activeIds.length; i++) {
            uint256 projectId = _activeIds[i];
            if (
                projectId == 0 ||
                poolProjects[projectId].flowLastTime == block.timestamp
            ) {
                continue; // Empty or rates already updated
            }

            // Check the beneficiary doesn't change
            Project memory project = IProjectList(projectList).getProject(
                projectId
            );

            address beneficiary = project.beneficiary;
            address oldBeneficiary = poolProjects[projectId].beneficiary;

            if (oldBeneficiary != beneficiary) {
                // Remove the flow from the old beneficiary if it has changed
                if (oldBeneficiary != address(0)) {
                    ICFAv1Forwarder(cfaForwarder).setFlowrate(
                        ISuperToken(fundingToken),
                        oldBeneficiary,
                        0
                    );
                }
                // We don't have to update the flow rate because it will be updated next
                poolProjects[projectId].beneficiary = beneficiary;
            }

            uint256 currentRate = _getCurrentRate(projectId, funds);
            ICFAv1Forwarder(cfaForwarder).setFlowrate(
                ISuperToken(fundingToken),
                beneficiary,
                int96(int256(currentRate))
            );

            poolProjects[projectId].flowLastRate = currentRate;
            poolProjects[projectId].flowLastTime = block.timestamp;

            emit FlowSynced(projectId, beneficiary, currentRate);
        }
    }

    /* *************************************************************************************************************************************/
    /* ** Formula Params Functions                                                                                                       ***/
    /* *************************************************************************************************************************************/
    /**
     * @param _params a custom struct that defines the formula variables related to the pool
     * @custom:modifers onlyOwner
     */
    function setFormulaParams(FormulaParams calldata _params) public onlyOwner {
        _setFormulaParams(_params);
    }

    /**
     * @param _decay new decay param for the contract
     * @custom:modifers onlyOwner
     */
    function setFormulaDecay(uint256 _decay) public onlyOwner {
        _setFormulaDecay(_decay);
    }

    /**
     * m _drop new drop param for the contract
     * @custom:modifers onlyOwner
     */
    function setFormulaDrop(uint256 _drop) public onlyOwner {
        _setFormulaDrop(_drop);
    }

    /**
     * @param _minStakeRatio new minStakeRatio param for the contract
     * @custom:modifers onlyOwner
     */
    function setFormulaMaxFlow(uint256 _minStakeRatio) public onlyOwner {
        _setFormulaMaxFlow(_minStakeRatio);
    }

    /**
     * @param _minFlow new minFlow param for the contract
     * @custom:modifers onlyOwner
     */
    function setFormulaMinStakeRatio(uint256 _minFlow) public onlyOwner {
        _setFormulaMinStakeRatio(_minFlow);
    }

    /* *************************************************************************************************************************************/
    /* ** View Functions                                                                                                                 ***/
    /* *************************************************************************************************************************************/
    /**
     * @param _projectId Id of the project to retireve the total support made by participants
     */
    function getProjectSupport(
        uint256 _projectId
    ) external view returns (uint256) {
        return _getProjectSupport(_projectId);
    }

    /**
     *
     * @param _projectId Id of the project to see participant's support
     * @param _participant address of the participant to see it's support
     */
    function getParticipantSupport(
        uint256 _projectId,
        address _participant
    ) public view returns (uint256) {
        uint200 participantSupportAt_ = participantAmountStaked[_participant]
            .supportAt[_projectId]
            .amount;
        return uint(participantSupportAt_);
    }

    /**
     * @dev Gets the total amount (in full units) being staked in this pool, thus the amount of support.
     */
    function getTotalSupport() public view returns (uint256) {
        return totalSupport;
    }

    /**
     * @param _participant Address of a participant to retrieve amounts being staked
     * (amStaked,freeStaked)
     * @custom:amstaked Total amount being staked by participant in this contract
     * @custom:freestake Amount of that stake that is left without being used. This means that is the result of = amstaked- amSupported
     */
    function getTotalParticipantSupport(
        address _participant
    ) public view returns (uint, uint) {
        uint _amountSupported = uint(
            participantAmountStaked[_participant].amountStaked
        );
        uint _freeStake = uint(participantAmountStaked[_participant].freeSTake);
        return (_amountSupported, _freeStake);
    }

    /**
     * @dev Gets the rate of funds being sent to `_projectId` per interval of time
     */
    function getCurrentRate(
        uint256 _projectId
    ) external view returns (uint256) {
        return
            _getCurrentRate(
                _projectId,
                ISuperToken(fundingToken).balanceOf(address(this))
            );
    }

    /**
     * @dev Gets the target rate of funds that is projected to be  sent to `_projectId` per interval of time
     */
    function getTargetRate(uint256 _projectId) external view returns (uint256) {
        return
            _getTargetRate(
                _projectId,
                ISuperToken(fundingToken).balanceOf(address(this))
            );
    }

    /* *************************************************************************************************************************************/
    /* ** Internal Project Activation and Deactivation Functions                                                                         ***/
    /* *************************************************************************************************************************************/

    function _checkProjectExist(uint _projectId) internal view {
        if (!IProjectList(projectList).projectExists(_projectId)) {
            revert PROJECT_NOT_IN_LIST(_projectId);
        }
    }

    function _unstakeGov(uint _amount) internal {
        uint freestake = participantAmountStaked[msg.sender].freeSTake;
        if (freestake < _amount)
            revert EXCEEDS_PARTICIPANT_BALANCE(freestake, _amount);
        govToken.transfer(msg.sender, _amount);
        ///@custom:assambly es menos costroso en terminos de gas
        participantAmountStaked[msg.sender].freeSTake -= _amount;
        participantAmountStaked[msg.sender].amountStaked -= _amount;
    }
    /**
     * @custom:problema
     * QUe pasa si el usuario manda un array del mismo id? La funcion deberia revertir pero no lo hace
     * @custom:solucion 
     * Se puede resolver con un bitmap
     */
    function _unsupportProjects(
        ProjectSupport[] calldata _projectSupports
    ) internal {
        uint amountOfProjects_ = _revertIfInvalidProjectsLegth(
            _projectSupports
        );

        ParticipantInfo storage participantInfo_ = participantAmountStaked[
            msg.sender
        ];
        uint delta;
        if (amountOfProjects_ == 1) {
            delta = _projectSupports[0].deltaSupport;
            uint projectId = _projectSupports[0].projectId;
            if (participantInfo_.amountStaked < delta)
                revert EXCEEDS_PARTICIPANT_BALANCE(
                    participantInfo_.amountStaked,
                    delta
                );
            _checkProjectExist(projectId);

            _supportDecrease(projectId, delta, participantInfo_);
            participantInfo_.freeSTake+=delta;
        } else {
            for (uint i = 0; i < amountOfProjects_; i++) {
                uint projectId = _projectSupports[i].projectId;
                _checkProjectExist(projectId);
                delta += _projectSupports[i].deltaSupport;
            }
            if (participantInfo_.amountStaked < delta)
                revert EXCEEDS_PARTICIPANT_BALANCE(
                    participantInfo_.amountStaked,
                    delta
                );
            participantInfo_.freeSTake+=delta;


            for (uint i = 0; i < amountOfProjects_; i++) {
                uint projectId = _projectSupports[i].projectId;
                uint _delta = _projectSupports[i].deltaSupport;

                _supportDecrease(projectId, _delta, participantInfo_);
            }
        }
    }

    function _supportDecrease(
        uint _projectId,
        uint _delta,
        ParticipantInfo storage _participant
    ) internal {
        SupportInfo memory _currParticipation = poolProjects[_projectId].participantSupportAt[msg.sender];

        SupportInfo memory _newParticipantSupportId = SupportInfo(
            uint200(_applyDelta(false, _currParticipation.amount, _delta)),
            uint56(block.timestamp)
        );

        _participant.supportAt[_projectId] = _newParticipantSupportId;

        poolProjects[_projectId].participantSupportAt[msg.sender] = _newParticipantSupportId;
        poolProjects[_projectId].totalSupport -= _delta;

        emit ProjectSupportUpdated(
            _projectId,
            msg.sender,
            "DECREASE_SUPPORT",
            _delta
        );
    }
    
    function _supportProjects(
        ProjectSupport[] calldata _projectSupports
    ) internal {
        uint amountOfProjects_ = _revertIfInvalidProjectsLegth(
            _projectSupports
        );

        ParticipantInfo storage participantInfo_ = participantAmountStaked[
            msg.sender
        ];

        if (participantInfo_.amountStaked == 0) revert NOT_ENOUGH_STAKED();

        uint256 deltaSupportSum = 0;
        if (amountOfProjects_ == 1) {
            /**
             * @custom:change
             * Case of amountOfProjects_==1 added to avoid breaking the for loop
             */
            _checkProjectExist(_projectSupports[0].projectId);

            deltaSupportSum += _projectSupports[0].deltaSupport;
            if (participantInfo_.freeSTake < deltaSupportSum)
                revert NOT_ENOUGH_STAKED();

            participantInfo_.freeSTake -= deltaSupportSum;

            uint256 projectId = _projectSupports[0].projectId;
            uint256 delta = _projectSupports[0].deltaSupport;
            _supportIncrease(projectId, delta, participantInfo_);
        } else {
            for (uint256 i = 0; i < _projectSupports.length; i++) {
                _checkProjectExist(_projectSupports[i].projectId);
                deltaSupportSum += _projectSupports[i].deltaSupport;
            }

            if (participantInfo_.freeSTake < deltaSupportSum)
                revert NOT_ENOUGH_STAKED();

            participantInfo_.freeSTake -= deltaSupportSum;

            for (uint256 i = 0; i < amountOfProjects_; i++) {
                uint256 projectId = _projectSupports[i].projectId;
                uint256 delta = _projectSupports[i].deltaSupport;
                _supportIncrease(projectId, delta, participantInfo_);
            }
        }
    }

    function _supportIncrease(
        uint _projectId,
        uint _delta,
        ParticipantInfo storage _participant
    ) internal {
        PoolProject storage project = poolProjects[_projectId];
        SupportInfo memory _currParticipation = project
            .participantSupportAt[msg.sender];

        SupportInfo memory _newParticipantSupportId = SupportInfo(
            uint200(_applyDelta(true, _currParticipation.amount, _delta)),
            uint56(block.timestamp)
        );

        project.participantSupportAt[msg.sender] = _newParticipantSupportId;
        _participant.supportAt[_projectId] = _newParticipantSupportId;
        poolProjects[_projectId].totalSupport += _delta;


        emit ProjectSupportUpdated(
            _projectId,
            msg.sender,
            "INCREASE_SUPPORT",
            _delta
        );
    }

    function _stakeGov(uint _amount) internal {
        uint allowance = govToken.allowance(msg.sender, address(this));
        if (allowance < _amount)
            revert NOT_ENOUGH_ALLOWENCE(allowance, _amount);
        govToken.transferFrom(msg.sender, address(this), _amount);
        ///@custom:assambly es menos costroso en terminos de gas
        participantAmountStaked[msg.sender].amountStaked += _amount;
        participantAmountStaked[msg.sender].freeSTake += _amount;
    }

    function _activateProject(uint256 _index, uint256 _projectId) internal {
        activeProjectIds[_index] = _projectId;
        poolProjects[_projectId].active = true;
        poolProjects[_projectId].flowLastTime = block.timestamp;

        emit ProjectActivated(_projectId);
    }

    function _deactivateProject(uint256 _index) internal {
        uint256 projectId = activeProjectIds[_index];
        poolProjects[projectId].active = false;
        Project memory project = IProjectList(projectList).getProject(
            projectId
        );
        ICFAv1Forwarder(cfaForwarder).setFlowrate(
            ISuperToken(fundingToken),
            project.beneficiary,
            0
        );

        emit ProjectDeactivated(projectId);
    }

    function _getProjectSupport(
        uint256 _projectId
    ) internal view returns (uint256) {
        return poolProjects[_projectId].totalSupport;
    }

    /* *************************************************************************************************************************************/
    /* ** Internal Flow Rate Calculation Functions                                                                                       ***/
    /* *************************************************************************************************************************************/
    /**
     * @custom:change
     * Instead of invoking `getTotalSupport()` we are reading the variable directly from the stack {totalSupport}
     */
    function _getTargetRate(
        uint256 _projectId,
        uint256 _funds
    ) internal view returns (uint256) {
        return
            calculateTargetRate(
                _funds,
                _getProjectSupport(_projectId),
                totalSupport
            );
    }

    function _getCurrentRate(
        uint256 _projectId,
        uint256 _funds
    ) internal view returns (uint256 _rate) {
        PoolProject storage project = poolProjects[_projectId];
        assert(project.flowLastTime <= block.timestamp);
        uint256 timePassed = block.timestamp - project.flowLastTime;

        return
            _rate = calculateRate(
                timePassed, // we assert it doesn't overflow above
                project.flowLastRate,
                _getTargetRate(_projectId, _funds)
            );
    }

    function _revertIfInvalidProjectsLegth(
        ProjectSupport[] calldata _projectSupports
    ) internal pure returns (uint) {
        uint amountOfProjects_ = _projectSupports.length;

        if (amountOfProjects_ == 0)
            revert WRONG_AMOUNT_OF_PROJECTS(
                amountOfProjects_,
                MAX_ACTIVE_PROJECTS
            );
        if (amountOfProjects_ > 25)
            revert WRONG_AMOUNT_OF_PROJECTS(
                amountOfProjects_,
                MAX_ACTIVE_PROJECTS
            );
        return amountOfProjects_;
    }

    /* *************************************************************************************************************************************/
    /* ** Internal Helpers Functions                                                                                                     ***/
    /* *************************************************************************************************************************************/

    function _applyDelta(
        bool _isSum,
        uint256 _support,
        uint256 _delta
    ) internal pure returns (uint256) {
        if (_isSum) return (_support + _delta);
        else {
            if (_support< _delta) revert SUPPORT_UNDERFLOW(_support,_delta);
            return (_support - _delta);
        }
    }
}
