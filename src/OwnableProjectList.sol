// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import {Ownable} from "@oz/access/Ownable.sol";

import {IProjectList,IProjectRegistry, Project, PROJECT_ALREADY_IN_LIST, PROJECT_DOES_NOT_EXIST, PROJECT_NOT_IN_LIST} from "./interfaces/IProjectList.sol";


contract OwnableProjectList is Ownable, IProjectList {
    string public name;
    IProjectRegistry public projectRegistry;

    mapping(uint256 => bool) internal isProjectIncluded;

    /* *************************************************************************************************************************************/
    /* ** Events                                                                                                                         ***/
    /* *************************************************************************************************************************************/

    event ListUpdated(uint256 indexed projectId, bool included);

    /* *************************************************************************************************************************************/
    /* ** Modifiers                                                                                                                      ***/
    /* *************************************************************************************************************************************/

    modifier isValidProject(uint256 _projectId) {
        _isValidProject(_projectId);
        _;
    }

    constructor(
        address _projectRegistry,
        address _newOwner,
        string memory _name
    ) Ownable(_newOwner) {
        projectRegistry = IProjectRegistry(_projectRegistry);
        name = _name;
    }

    /* *************************************************************************************************************************************/
    /* ** Project Functions                                                                                                              ***/
    /* *************************************************************************************************************************************/

    function addProject(
        uint256 _projectId
    ) external onlyOwner isValidProject(_projectId) {
        _addProject(_projectId);
    }

    

    function removeProject(
        uint256 _projectId
    ) external onlyOwner isValidProject(_projectId) {
        _removeProject(_projectId);
    }

    function addProjects(uint256[] calldata _projectIds) external onlyOwner {
        for (uint256 i = 0; i < _projectIds.length; i++) {
            uint256 projectId = _projectIds[i];
            _isValidProject(projectId);
            _addProject(projectId);
        }
    }

    function removeProjects(uint256[] calldata _projectIds) external onlyOwner {
        for (uint256 i = 0; i < _projectIds.length; i++) {
            uint256 projectId = _projectIds[i];
            _isValidProject(projectId);
            _removeProject(projectId);
        }
    }
    
    function _isValidProject(uint _projectId) internal view {
        if (!projectRegistry.projectExists(_projectId)) revert PROJECT_DOES_NOT_EXIST(_projectId);
    }
    function _addProject(uint _projectId) internal {
        if (isProjectIncluded[_projectId]) {
            revert PROJECT_ALREADY_IN_LIST(_projectId);
        }

        isProjectIncluded[_projectId] = true;

        emit ListUpdated(_projectId, true);
    }

    function _removeProject(uint _projectId) internal {
        if (!isProjectIncluded[_projectId]) {
            revert PROJECT_NOT_IN_LIST(_projectId);
        }

        isProjectIncluded[_projectId] = false;

        emit ListUpdated(_projectId, false);
    }

    /* *************************************************************************************************************************************/
    /* ** IProjectList Functions                                                                                                         ***/
    /* *************************************************************************************************************************************/

    function getProject(
        uint256 _projectId
    ) external view returns (Project memory) {
        if (isProjectIncluded[_projectId]) {
            return projectRegistry.getProject(_projectId);
        }
        revert PROJECT_NOT_IN_LIST(_projectId);
    }

    function projectExists(uint256 _projectId) external view returns (bool) {
        return isProjectIncluded[_projectId];
    }
}
