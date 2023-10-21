// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import './utils/Utils.sol';
import '../src/ProjectRegistry.sol';
import '../src/OwnableProjectList.sol';
import '@oz/utils/Strings.sol';
contract ManagerMock {
    event ProjectListCreated(address indexed list);
    address projectRegistry;

    constructor(address _projectRegistry){
        projectRegistry=_projectRegistry;
    }
    /**
     *
     * @param _newOwner Address that will own (Ownable.owner()) the project list being created
     * @param _name Name of the list to be created
     * @custom:modifier whenNotPaused()
     */
    function createProjectList(
        address _newOwner,
        string calldata _name
    ) external returns (address list_) {
        list_ = address(
            new OwnableProjectList(projectRegistry, _newOwner, _name)
        );

        // OwnableProjectList(list_).transferOwnership(msg.sender);

        // addressInfo[list_].isList = true;

        emit ProjectListCreated(list_);
    }
}
// forge test --match-contract RegistryTest
contract RegistryTest is Utils_Test {
    uint constant VERSION=1;

    ManagerMock mockManager;

    ProjectRegistry registryimpl;
    /**
     * @dev this is the variable being used to test
     */
    ProjectRegistry registryProxyC;
    BeaconProxy registryProxy;
    UpgradeableBeacon registryBeacon;
    address registryOwner;
    address registryBeaconOwner;

    function setUp()external  {

        registryOwner=makeAddr('regPROXY_OWNER');
        registryBeaconOwner=makeAddr('regBEACON_OWNER');

        registryimpl= new ProjectRegistry(VERSION);
        bytes memory initData=abi.encodeWithSignature('initialize(address)',registryOwner);

        (registryBeacon,registryProxy)=createBeaconAndProxy(address(registryimpl),registryBeaconOwner,initData);
        mockManager= new ManagerMock(address(registryProxy));
        registryProxyC=ProjectRegistry(address(registryProxy));

    }
    //  forge test --match-contract RegistryTest --match-test test_registerProject -vvvv
    function test_registerProject(uint _adminSeed,uint _benefSeed) external {
        bytes memory _contenthash= abi.encode(_adminSeed,_benefSeed);
        address _benef=makeAddr(Strings.toString(_adminSeed));
        vm.label(_benef,'PROJECT_BENEF');
        vm.startPrank(makeAddr('PRANKIST'));
        vm.expectRevert();//invalidBeneficiary(address(0))
        _registerProject(address(0),_contenthash);
        // Success
        _registerProject(_benef,_contenthash);
        vm.expectRevert();//alreadyRegisted
        _registerProject(_benef,_contenthash);

        vm.stopPrank();


    }

    function _registerProject(address _benef,bytes memory _contenthash)  internal {
        registryProxyC.registerProject(_benef,_contenthash);
    }
    //  forge test --match-contract RegistryTest --match-test test_updateProject -vvvv
    function test_updateProject(uint _adminSeed,uint _benefSeed) external {
        bytes memory _contenthash= abi.encode(_adminSeed,_benefSeed);
        address _benef=makeAddr(Strings.toString(_adminSeed));
        address _prankist=makeAddr('PRANKIST');
        vm.label(_benef,'PROJECT_BENEF');
        vm.prank(_prankist);
        registryProxyC.registerProject(_benef,_contenthash);

        vm.warp(block.timestamp + 3 days);
        address _newAdmin=makeAddr('NewAdmin');
        address _newBenef=makeAddr('NewBenef');
        bytes memory _newcontenthash=abi.encode(_newAdmin,_newBenef,_contenthash);

        vm.prank(makeAddr('OTHER_PRANKIST'));
        vm.expectRevert();// projectId > currProjectId & notAdmin
        registryProxyC.updateProject(_adminSeed,_newAdmin,_newBenef,_newcontenthash);
        vm.startPrank(_prankist);
        vm.expectRevert();//invalidBeneficiary
        registryProxyC.updateProject(1,address(0),address(0),_newcontenthash);
        vm.expectRevert();//alreadyRegistered
        registryProxyC.updateProject(1,_newAdmin,_benef,_newcontenthash);
        vm.expectRevert();//invalidNewAdmin
        registryProxyC.updateProject(1,address(0),_newBenef,_newcontenthash);
        registryProxyC.updateProject(1,_newAdmin,_newBenef,_newcontenthash);
        vm.stopPrank();

    }


    //  forge test --match-contract RegistryTest --match-test test_OwnableList_modProject -vvvv
    function test_OwnableList_modProject(uint32 _adminSeed,uint _benefSeed) external {
        vm.assume(_adminSeed!=0);
        vm.assume(_benefSeed!=0);
        bytes memory _contenthash= abi.encode(_adminSeed,_benefSeed);
        address _benef=makeAddr(Strings.toString(_adminSeed));
        address _listOwner=makeAddr(Strings.toString(type(uint40).max));
        string memory _listName=string.concat('LIST_#1');
        vm.label(_benef,'PROJECT_BENEF');
        vm.label(_listOwner,'LIST_OWNER');
        vm.prank(makeAddr('PRANKIST'));
        _registerProject(_benef,_contenthash);
        //Create List
        address _list= _createList(_listOwner,_listName);
        OwnableProjectList list=OwnableProjectList(_list);

        // add: Not owner
        vm.prank(makeAddr('WANA_OWNER'));
        vm.expectRevert();
        list.addProject(2);

        vm.startPrank(_listOwner);
        // add: Not valid project
        vm.expectRevert();
        list.addProject(2);

        // add: success
        list.addProject(1);

        // add: Already registered
        vm.expectRevert();
        list.addProject(1);
        vm.stopPrank();
        _projectListExteral(list);


        // remmove: Not owner
        vm.prank(makeAddr('WANA_OWNER'));
        vm.expectRevert();
        list.removeProject(1);

        vm.startPrank(_listOwner);
        // remmove: Not valid project
        vm.expectRevert();
        list.addProject(2);

        // remmove: success

        list.removeProject(1);

        // remove: Not registered
        vm.expectRevert();
        list.removeProject(1);
        vm.stopPrank();

    }

    function _projectListExteral(OwnableProjectList list)internal {
        list.getProject(1);
        list.projectExists(111);
        emit log_named_string('LIST_NAME ',list.name());
        emit log_named_address('REGISTRY ',address(list.projectRegistry()));
    }
    function _createList(address _newOwner,string memory _listName) internal returns (address) {
        return mockManager.createProjectList(_newOwner,_listName);
    }

    /**
     * ProjectRegistry:
     * implementation()     [view]
     * registerProject()    [ok]
     * - invalidBeneficiary
     *      - address(0)
     *      - registeredBeneficiaries[_beneficiary]
     * - success
     * updateProject()    [ok]
     * - projectId > currProjectId  (notAdmin)
     * - notAdmin
     * - invalidBeneficiary
     *      - address(0)
     *      - registeredBeneficiaries[_beneficiary]
     * - invalidNewAdmin
     * - success
     * 
     * 
     */
    /**
     * OwnableProjectList:
     * getProject()         [view]
     * projectExists()      [view]
     * 
     * addProject()    
     * - notOwner
     * - invalidProjectId
     * - ProjectAlreadyInList
     * - success
     * 
     * removeProject()    
     * - notOwner
     * - invalidProjectId
     * - ProjectNotInList
     * - success
     * 
     * addProjects()  
     * - notOwner
     * for:=  
     * - invalidProjectId
     * - ProjectAlreadyInList
     * - success
     * 
     * removeProjects()  
     * - notOwner
     * for:=  
     * - invalidProjectId
     * - ProjectAlreadyInList
     * - success
     * 
     * 
     */


}