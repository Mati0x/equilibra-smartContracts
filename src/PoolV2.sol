// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import {OwnableUpgradeable} from "@oz-upgradeable/access/OwnableUpgradeable.sol";
import {ReentrancyGuardUpgradeable} from "@oz-upgradeable/utils/ReentrancyGuardUpgradeable.sol";

import {IERC20} from "@oz/token/ERC20/IERC20.sol";
import {ISuperToken} from "./interfaces/ISuperToken.sol";

import {ICFAv1Forwarder} from "./interfaces/ICFAv1Forwarder.sol";
import {IProjectList, Project, ProjectNotInList} from "./interfaces/IProjectList.sol";
import {Formula, FormulaParams} from "./Formula.sol";
import {Manager} from "./Manager.sol";

error INVALID_PROJECT_LIST();
// error InvalidgovToken();
error SUPPORT_UNDERFLOW();
error PROJECT_ALREADY_ACTIVE(uint256 _projectId);
error PROJECT_NEEDS_MORE_STAKE(
    uint256 _projectId,
    uint256 _projectStake,
    uint256 _requiredStake
);
error NOT_ENOUGH_STAKED();
error WRONG_AMOUNT_OF_PROJECTS(uint _sent, uint _max);
error NOT_ENOUGH_ALLOENCE(uint _totAllowence, uint _amReq);
/* *************************************************************************************************************************************/
/* ** Structs                                                                                                                        ***/
/* *************************************************************************************************************************************/
struct ProjectSupport {
    uint256 projectId;
    int256 deltaSupport;
}
struct SupportInfo {
    uint200 amount;
    uint56 time;
}
struct ParticipantInfo {
    int amountStaked;
    int freeSTake;
    // projectId -> SupportInfo
    mapping(uint => SupportInfo) supportAt;
    // projectId -> support
    // mapping(uint => bool) supportAt;
}
struct PoolProject {
    uint totalSupport;
    uint256 flowLastRate;
    uint256 flowLastTime;
    bool active;
    address beneficiary;
    // participant -> SupportInfo
    mapping(address => SupportInfo) participantSupportAt;
}

contract Pool is OwnableUpgradeable, ReentrancyGuardUpgradeable, Formula {
    address public immutable cfaForwarder;
    address public immutable controller;
    
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

    // round => total support
    // mapping(uint256 => uint256) private totalSupportAt;
    // projectId => total support
    // mapping(uint256 => uint256) private totalSupportAt;
    // round => participant => total support
    /**
     * @custom:change
     * Information is in participantAmountStaked
     */
    // mapping(uint256 => mapping(address => uint256))
    //     private totalParticipantSupportAt;


    /* *************************************************************************************************************************************/
    /* ** Events                                                                                                                         ***/
    /* *************************************************************************************************************************************/

    event ProjectActivated(uint256 indexed projectId);
    event ProjectDeactivated(uint256 indexed projectId);
    event ProjectSupportUpdated(
        uint256 indexed projectId,
        address participant,
        int256 delta
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
    constructor(address _cfaForwarder, address _controller) {
        _disableInitializers();

        require(
            (cfaForwarder = _cfaForwarder) != address(0),
            "Zero CFA Forwarder"
        );
        require((controller = _controller) != address(0), "Zero Controller");
    }

    function initialize(
        address _fundingToken,
        address _newOwner,
        address _govToken,
        address _projectList,
        FormulaParams calldata _params
    ) public initializer {
        __Ownable_init(_newOwner);
        __ReentrancyGuard_init();
        _Formula_init(_params);
        require(
            (fundingToken = _fundingToken) != address(0),
            "Zero Funding Token"
        );

        if (Manager(controller).isList(_projectList)) {
            projectList = _projectList;
        } else {
            revert INVALID_PROJECT_LIST();
        }
        /**
         * @custom:change
         * The token that will be used as governace MUST be valid
         * No security checks are being made, so responsability relies on users
         */
        // if (Manager(controller).isToken(_govToken)) {
        govToken = IERC20(_govToken);

    }

    /* *************************************************************************************************************************************/
    /* ** Participant Support Function                                                                                                   ***/
    /* *************************************************************************************************************************************/

    /**
     *
     * @custom:problema cualquiera activa Suportear projectos!
     * @custom:discusion Eso deberia ser con el Owner, aca entra la GNOSIS_SAFE
     * @custom:discusion Para esto es el MIME_TOKEN, para suportear proyectos, quiza se tenga que aplocar pero directo en la POOL
     * Emitiendo X cantidad de shares que este asociada a la cantidad de tokens de governanza, y que haya un limite , pero que limita que haya gente que vote 2 veces?
     * Y como garantizamos el conviction voting? Salvo que sea la POOL y la multisig quien aloque los tokens de voto a los usuarios o que haya un airdrop por cada
     */

    // [] -> Revierte
    // ['100'] -> if (l==1) array[0]
    // ['0','100',...n] -> else
    function unsupportProjects(
        ProjectSupport[] calldata _projectSupports
    ) external nonReentrant {
        _unsupportProjects(_projectSupports);
    }

    
    function stakeGov(uint _amount) external nonReentrant {
        _stakeGov(_amount);
    }

    /**
     *
     */
    function unstakeAndUnsupport(
        uint _amount,
        ProjectSupport[] calldata _projectSupports
    ) external nonReentrant {
        _unsupportProjects(_projectSupports);
        _unstakeGov(_amount);
    }

    function unstakeGov(uint _amount) external nonReentrant {
        _unstakeGov(_amount);
    }

    /**
     * @custom:newfeature
     * This function allowes participants  to stake `_amountToStake` and inmedialtelly support the amount of projects desired
     */
    function stakeAndSupport(
        uint _amountToStake,
        ProjectSupport[] calldata _projectSupports
    ) external nonReentrant {
        _stakeGov(_amountToStake);
        _supportProjects(_projectSupports);
    }

    /**
     * @custom:important
     * It's important to make this fucntion work with the changes we've made into the structure of the contract and how operates the storage
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

    function activateProject(uint256 _projectId) public {
        if (!IProjectList(projectList).projectExists(_projectId)) {
            revert ProjectNotInList(_projectId);
        }

        uint256 projectSupport = _getProjectSupport(_projectId);

        uint256 minSupport = type(uint256).max;
        uint256 minIndex = 0;

        for (uint256 i = 0; i < activeProjectIds.length; i++) {
            if (activeProjectIds[i] == _projectId) {
                revert PROJECT_ALREADY_ACTIVE(_projectId);
            }

            // If position i is empty, use it
            if (activeProjectIds[i] == 0) {
                _activateProject(i, _projectId);
                return;
            }

            uint256 currentProjectSupport = _getProjectSupport(
                activeProjectIds[i]
            );
            if (currentProjectSupport < minSupport) {
                minSupport = _getProjectSupport(activeProjectIds[i]);
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
        // round += 1;
        for (uint256 i = 0; i < activeProjectIds.length; i++) {
            uint256 projectId = activeProjectIds[i];
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

    function setFormulaParams(FormulaParams calldata _params) public onlyOwner {
        _setFormulaParams(_params);
    }

    function setFormulaDecay(uint256 _decay) public onlyOwner {
        _setFormulaDecay(_decay);
    }

    function setFormulaDrop(uint256 _drop) public onlyOwner {
        _setFormulaDrop(_drop);
    }

    function setFormulaMaxFlow(uint256 _minStakeRatio) public onlyOwner {
        _setFormulaMaxFlow(_minStakeRatio);
    }

    function setFormulaMinStakeRatio(uint256 _minFlow) public onlyOwner {
        _setFormulaMinStakeRatio(_minFlow);
    }

    /* *************************************************************************************************************************************/
    /* ** View Functions                                                                                                                 ***/
    /* *************************************************************************************************************************************/
    /**
     * @custom:change
     * Rounds are not used in V2 {delete function}
     */
    // function getCurrentRound() public view returns (uint256) {
    //     return round;
    // }
    /**
     * @custom:refactor
     * Information is in poolProjects.totalSupport instead of poolProjects.projectSupportAt[round()]
     */
    function getProjectSupport(
        uint256 _projectId
    ) external view returns (uint256) {
        return _getProjectSupport(_projectId);
    }

    /**
     * @custom:refactor
     * Information is in participantAmountStaked[_participant].supportAt[projectId]
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
     * @custom:refactor
     * Information is in totalSupport {uint}
     */
    function getTotalSupport() public view returns (uint256) {
        return totalSupport;
    }

    /**
     * @custom:change
     * This function now returns 2 values, the amount staked by the participant and the amount that is not being used to support a project
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
     * @custom:refactor ???
     * `_getCurrentRate()`
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
     function _unstakeGov(uint _amount) internal {
        int staked = participantAmountStaked[msg.sender].amountStaked;
        if (uint(staked) < _amount)
            revert NOT_ENOUGH_ALLOENCE(uint(staked), _amount);
        govToken.transferFrom(msg.sender, address(this), _amount);
        ///@custom:assambly es menos costroso en terminos de gas
        participantAmountStaked[msg.sender].amountStaked -= int(_amount);
    }
    function _unsupportProjects(
        ProjectSupport[] calldata _projectSupports
    ) internal {
        uint amountOfProjects_ = _revertIfInvalidProjectsLegth(
            _projectSupports
        );

        ParticipantInfo storage participantInfo_ = participantAmountStaked[
            msg.sender
        ];

        if (amountOfProjects_ == 1) {
            uint projectId = _projectSupports[0].projectId;
            int delta = _projectSupports[0].deltaSupport;
            if (!IProjectList(projectList).projectExists(projectId)) {
                revert ProjectNotInList(projectId);
            }
            ///@custom:funcionbytes

            /**
             * @custom:refactor 
             * Overflow checked in `_applyDelta()`
             * uint currentSupport = 
                uint(
                    participantInfo_
                        .supportAt[projectId]
                        .amount
                );
             * 
             * if (currentSupport + _projectSupports[0].deltaSupport < 0)
                revert("NOT_ENOUGH_SUPPORT_TO_ID")

                
             */
            //
            SupportInfo memory _newParticipantSupportId = SupportInfo(
                uint200(_applyDelta(_getProjectSupport(projectId), delta)),
                uint56(block.timestamp)
            );
            participantInfo_.supportAt[projectId] = _newParticipantSupportId;
            participantInfo_.freeSTake += delta;

            poolProjects[projectId].participantSupportAt[
                    msg.sender
                ] = _newParticipantSupportId;
            poolProjects[projectId].totalSupport -= uint(delta);

            emit ProjectSupportUpdated(projectId, msg.sender, delta);
        } else {
            for (uint i = 0; i < amountOfProjects_; i++) {
                uint projectId = _projectSupports[i].projectId;
                if (!IProjectList(projectList).projectExists(projectId)) {
                    revert ProjectNotInList(projectId);
                }
            }
            for (uint i = 0; i < amountOfProjects_; i++) {
                uint projectId = _projectSupports[i].projectId;
                int delta = _projectSupports[i].deltaSupport;

                SupportInfo memory _newParticipantSupportId = SupportInfo(
                    uint200(_applyDelta(_getProjectSupport(projectId), delta)),
                    uint56(block.timestamp)
                );

                participantInfo_.supportAt[
                    projectId
                ] = _newParticipantSupportId;

                poolProjects[projectId].participantSupportAt[
                        msg.sender
                    ] = _newParticipantSupportId;
                poolProjects[projectId].totalSupport -= uint(delta);

                emit ProjectSupportUpdated(projectId, msg.sender, delta);
            }
        }
    }


    function _supportProjects(
        ProjectSupport[] calldata _projectSupports
    ) internal {
        /**
         * @custom:vul
         * Here the function must check if the length of _projectSupports does exceeds the max amount of projects supported by the pool (25)
         */
        uint amountOfProjects_ = _revertIfInvalidProjectsLegth(
            _projectSupports
        );

        /**
         * @custom:change
         * As in V2 we are errasing the concept of rounds, this variable is useless, it will be errased
         */
        // uint256 currentRound = getCurrentRound();
        /**
         * @custom:change
         * In V2 instead of using mime tokens balance of participants, this is based on staked tokens
         */

        ParticipantInfo storage participantInfo_ = participantAmountStaked[
            msg.sender
        ];

        if (participantInfo_.amountStaked == 0) revert NOT_ENOUGH_STAKED();
        /**
         * @custom:add
         * Needs to keep track of the totalSupport amount
         */

        int256 deltaSupportSum = 0;
        if (amountOfProjects_ == 1) {
            /**
             * @custom:change
             * Case of amountOfProjects_==1 added to avoid breaking the for loop
             */
            if (
                !IProjectList(projectList).projectExists(
                    _projectSupports[0].projectId
                )
            ) {
                revert ProjectNotInList(_projectSupports[0].projectId);
            }

            deltaSupportSum += _projectSupports[0].deltaSupport;
        } else {
            for (uint256 i = 0; i < _projectSupports.length; i++) {
                if (
                    !IProjectList(projectList).projectExists(
                        _projectSupports[i].projectId
                    )
                ) {
                    revert ProjectNotInList(_projectSupports[i].projectId);
                }

                deltaSupportSum += _projectSupports[i].deltaSupport;
            }
        }
        /**
         * @custom:change
         * Needs to check if participants balance of freeStake is enough to cover deltaSupport of ALL _projectSupports
         */
        if (participantInfo_.freeSTake < deltaSupportSum)
            revert NOT_ENOUGH_STAKED();
        /**
         * @custom:revision ???
         * Needs revision
         *  uint256 newTotalParticipantSupport = _applyDelta(
            participantInfo_.amountStaked,
            deltaSupportSum
        );
         */
        participantInfo_.amountStaked += deltaSupportSum;
        participantInfo_.freeSTake -= deltaSupportSum;

        // Check that the sum of support is not greater than the participant balance
        /**
         * @custom:change
         * This is checked above in the if statement
         * require(
            newTotalParticipantSupport <= participantInfo_,
            "NOT_ENOUGH_BALANCE"
        );
         */

        /**
         * @custom:change
         * This information will be located inside ParticipantInfo struct inisde participantAmountStaked mapping
         * totalParticipantSupportAt[currentRound][
            msg.sender
        ] = newTotalParticipantSupport;
         */

        /**
         * @custom:change
         * @custom:refactor
         * This information is uselles due a lack of rounds
         * mapping(uint projectId => uint totalSupport)
         * 
         * totalSupportAt[currentRound] = _applyDelta(
            getTotalSupport(),
            deltaSupportSum
        );
         */

        for (uint256 i = 0; i < amountOfProjects_; i++) {
            uint256 projectId = _projectSupports[i].projectId;
            int256 delta = _projectSupports[i].deltaSupport;

            PoolProject storage project = poolProjects[projectId];

            SupportInfo memory _newParticipantSupportId = SupportInfo(
                uint200(_applyDelta(_getProjectSupport(projectId), delta)),
                uint56(block.timestamp)
            );

            project.participantSupportAt[msg.sender] = _newParticipantSupportId;
            participantInfo_.supportAt[projectId] = _newParticipantSupportId;

            emit ProjectSupportUpdated(projectId, msg.sender, delta);
        }
    }

    function _stakeGov(uint _amount) internal {
        uint allowance = govToken.allowance(msg.sender, address(this));
        if (allowance < _amount) revert NOT_ENOUGH_ALLOENCE(allowance, _amount);
        govToken.transferFrom(msg.sender, address(this), _amount);
        ///@custom:assambly es menos costroso en terminos de gas
        participantAmountStaked[msg.sender].amountStaked += int(_amount);
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
        uint256 _support,
        int256 _delta
    ) internal pure returns (uint256) {
        int256 result = int256(_support) + _delta;

        if (result < 0) {
            revert SUPPORT_UNDERFLOW();
        }
        return uint256(result);
    }

    // function _bytesDecoding(bytes32 _param) internal returns (uint40, uint200) {
    //     return (type(uint16).max, type(uint96).max);
    // }

    // function _bytesEncoding(
    //     uint40 _time,
    //     uint _amount
    // ) internal returns (bytes32) {
    //     return (keccak256(abi.encode(type(uint16).max, type(uint96).max)));
    // }
    // struct ParticipantInfo {
    //     uint amountStaked;
    //     uint freeSTake;
    //     // support[i]:=
    //     // Tiempo :=uint40  (1.1e12) [05/32]
    //     // Buffer :=uint16  (1.1e12) [07/32]
    //     // Amount :=uint200 (1.6e60) [32/32]
    //     // mapping(uint => bytes32) supportAt;
    //     mapping(uint => SupportInfo) supportAt;
    // }
    // function name(uint40 _time,uint200 _amount)  returns () {
    //     assambly{
    //         let var;
    //         mstore(0,5,_time);
    //         mstore(8,32,_amount);
    //         sload()
    //     }
    // }
    // Slot 0
    // uint40 tiempo;
    // uint16 buffer;
    // uint200 amount;
    // bytes32(tiempo,buffer,amount)
    //     struct PoolProject {
    //     uint totalSupport;
    //     uint256 flowLastRate;
    //     uint256 flowLastTime;
    //     bool active;
    //     address beneficiary;
    //     /**
    //      * @dev Here you'll have the following:
    //      * Slot [00-05] := timeSuported {uint40:max-> 1.1e12}
    //      * Slot [06-07] := buffer       {uint16:max-> 6.5e5 }
    //      * Slot [08-32] := ammountSupported {uint200:max-> 1.6e60}
    //      * 0x0000000000027272727BBBBBB0000000aaaaaaaaaaä...qqqqq
    //      */
    //     // mapping(address => bytes32) participantSupportAt;
    //     mapping(address => SupportInfo) participantSupportAt;
    // }
}
