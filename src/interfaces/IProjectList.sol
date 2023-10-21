// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;


error PROJECT_ALREADY_IN_LIST(uint256 projectId);
error PROJECT_DOES_NOT_EXIST(uint256 projectId);
error PROJECT_NOT_IN_LIST(uint256 projectId);

struct Project {
    address admin;
    address beneficiary;
    bytes contenthash;
}
interface IProjectRegistry {

    /**
     * 
     * @param _projectId  id to be checked if exist
     */
    function projectExists(uint256 _projectId) external view returns (bool);
    /**
     * 
     * @param _projectId id to gather Project informatoin
     */
    function getProject(
        uint256 _projectId
    ) external view returns (Project memory);

}

interface IProjectList {
    function getProject(
        uint256 _projectId
    ) external view returns (Project memory);

    function projectExists(uint256 _projectId) external view returns (bool);
}
