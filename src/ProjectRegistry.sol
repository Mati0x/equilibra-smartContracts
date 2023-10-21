// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import {OwnableUpgradeable} from "@oz-upgradeable/access/OwnableUpgradeable.sol";
import {Initializable} from "@oz-upgradeable/proxy/utils/Initializable.sol";
import {UUPSUpgradeable, ERC1967Utils} from "@oz-upgradeable/proxy/utils/UUPSUpgradeable.sol";

import {IProjectList, Project} from "./interfaces/IProjectList.sol";


contract ProjectRegistry is
    Initializable,
    OwnableUpgradeable,
    UUPSUpgradeable,
    IProjectList
{
    error UNAUTHORIZED_PROJECT_ADMIN(address _expected,address _sent);
    error INVALID_BENEFICIARY(string _razon,address _benef);

    uint256 public  version;

    uint256 public nextProjectId;

    mapping(uint256 => Project) projects;
    mapping(address => bool) internal registeredBeneficiaries;

    /* *************************************************************************************************************************************/
    /* ** Events                                                                                                                         ***/
    /* *************************************************************************************************************************************/

    event ProjectUpdated(
        uint256 indexed projectId,
        address admin,
        address beneficiary,
        bytes contenthash
    );

    /* *************************************************************************************************************************************/
    /* ** Modifiers                                                                                                                      ***/
    /* *************************************************************************************************************************************/

    modifier isValidBeneficiary(address _beneficiary) {
        if (_beneficiary==address(0)) revert INVALID_BENEFICIARY('ZER0_ADDR',_beneficiary);
        else if (registeredBeneficiaries[_beneficiary]) {
            revert INVALID_BENEFICIARY('ALREADY_EXISTS',_beneficiary);
        }
        else _;
            
    }

    modifier onlyAdmin(uint256 _projectId) {
        address _expected=projects[_projectId].admin;
        if (_expected != msg.sender) {
            revert UNAUTHORIZED_PROJECT_ADMIN(_expected,msg.sender);
        }
        _;
    }
    
    constructor(uint256 _version) {
        _disableInitializers();
        version = _version;
    }

    function initialize(address _newOwner) public initializer {
        __Ownable_init(_newOwner);
        __UUPSUpgradeable_init();
        // version = _version;
        nextProjectId = 1;
    }

    /* *************************************************************************************************************************************/
    /* ** Upgradeability Functions                                                                                                       ***/
    /* *************************************************************************************************************************************/

    function implementation() external view returns (address) {
        return ERC1967Utils.getImplementation();
    }

    function _authorizeUpgrade(
        address newImplementation
    ) internal override onlyOwner {}

    /* *************************************************************************************************************************************/
    /* ** Project Functions                                                                                                              ***/
    /* *************************************************************************************************************************************/

    function registerProject(
        address _beneficiary,
        bytes memory _contenthash
    ) public isValidBeneficiary(_beneficiary) returns (uint256 _projectId) {
        _projectId = nextProjectId++;

        _updateProject(_projectId, msg.sender, _beneficiary, _contenthash);
    }

    function updateProject(
        uint256 _projectId,
        address _newAdmin,
        address _beneficiary,
        bytes calldata _contenthash
    ) external onlyAdmin(_projectId) isValidBeneficiary(_beneficiary) {
       if (_newAdmin==address(0)) revert INVALID_BENEFICIARY('NEW_ADMIN_ZER0_ADDR',_newAdmin);
        _updateProject(_projectId, _newAdmin, _beneficiary, _contenthash);
    }

    /* *************************************************************************************************************************************/
    /* ** Internal Project Functions                                                                                                     ***/
    /* *************************************************************************************************************************************/

    function _updateProject(
        uint256 _projectId,
        address _admin,
        address _beneficiary,
        bytes memory _contenthash
    ) internal {
        address oldBeneficiary = projects[_projectId].beneficiary;
        registeredBeneficiaries[oldBeneficiary] = false;

        projects[_projectId] = Project({
            admin: _admin,
            beneficiary: _beneficiary,
            contenthash: _contenthash
        });
        registeredBeneficiaries[_beneficiary] = true;

        emit ProjectUpdated(_projectId, _admin, _beneficiary, _contenthash);
    }

    /* *************************************************************************************************************************************/
    /* ** IProjectList Functions                                                                                                         ***/
    /* *************************************************************************************************************************************/
    /**
     * 
     * @param _projectId id to gather Project informatoin
     */
    function getProject(
        uint256 _projectId
    ) public view returns (Project memory) {
        return projects[_projectId];
    }
    /**
     * 
     * @param _projectId  id to be checked if exist
     */
    function projectExists(uint256 _projectId) external view returns (bool) {
        return projects[_projectId].beneficiary != address(0);
    }
}
