// // SPDX-License-Identifier: MIT
// pragma solidity ^0.8.17;

// import {OwnableUpgradeable} from "@oz-upgradeable/access/OwnableUpgradeable.sol";
// import {PausableUpgradeable} from "@oz-upgradeable/utils/PausableUpgradeable.sol";
// import {Initializable} from "@oz-upgradeable/proxy/utils/Initializable.sol";
// import {UUPSUpgradeable,ERC1967Utils} from "@oz-upgradeable/proxy/utils/UUPSUpgradeable.sol";

// import {BeaconProxy} from "@oz/proxy/beacon/BeaconProxy.sol";
// import {UpgradeableBeacon} from "@oz/proxy/beacon/UpgradeableBeacon.sol";

// //import {MimeToken, MimeTokenFactory} from "mime-token/MimeTokenFactory.sol";

// import {OwnableProjectList} from "../OwnableProjectList.sol";

// import {Pool, FormulaParams} from "../pool/PoolOld.sol";

// contract Manager is
//     Initializable,
//     OwnableUpgradeable,
//     PausableUpgradeable,
//     UUPSUpgradeable
// {
//     uint256 public immutable version;
//     uint256 public immutable claimTimestamp;
//     address public immutable projectRegistry;
//     address public immutable mimeTokenFactory;
//     UpgradeableBeacon public immutable beacon;

//     uint256 public claimDuration;

//     mapping(address => bool) public isPool;
//     mapping(address => bool) public isList;
//     mapping(address => bool) public isToken;


//     /* *************************************************************************************************************************************/
//     /* ** Events                                                                                                                         ***/
//     /* *************************************************************************************************************************************/

//     //event MimeTokenCreated(address indexed token);

//     event PoolCreated(address indexed pool);
//     event ProjectListCreated(address indexed list);

//     constructor(
//         uint256 _version,
//         address _pool,
//         address _beaconOwner,
//         address _projectRegistry,
//         address _mimeTokenFactory
//     ) {
//         _disableInitializers();

//         beacon = new UpgradeableBeacon(_pool,_beaconOwner);
//         // We transfer the ownership of the beacon to the deployer
//         beacon.transferOwnership(msg.sender);

//         version = _version;
//         claimTimestamp = block.timestamp;
//         projectRegistry = _projectRegistry;
//         mimeTokenFactory = _mimeTokenFactory;
//     }

//     function initialize(address _newOwner,uint256 _claimDuration) public initializer {
//         __Pausable_init();
//         __Ownable_init(_newOwner);
//         __UUPSUpgradeable_init();

//         claimDuration = _claimDuration;
//         // We set the registry as the default list
//         isList[projectRegistry] = true;
//     }

//     /* *************************************************************************************************************************************/
//     /* ** Pausability Functions                                                                                                          ***/
//     /* *************************************************************************************************************************************/

//     function pause() public onlyOwner {
//         _pause();
//     }

//     function unpause() public onlyOwner {
//         _unpause();
//     }

//     /* *************************************************************************************************************************************/
//     /* ** Upgradeability Functions                                                                                                       ***/
//     /* *************************************************************************************************************************************/

//     function implementation() external view returns (address) {
//         return ERC1967Utils.getImplementation();
//     }

//     function poolImplementation() external view returns (address) {
//         return beacon.implementation();
//     }

//     function _authorizeUpgrade(
//         address newImplementation
//     ) internal override onlyOwner {}

//     /* *************************************************************************************************************************************/
//     /* ** Setter Functions                                                                                                               ***/
//     /* *************************************************************************************************************************************/

//     function setClaimDuration(uint256 _claimDuration) external onlyOwner {
//         claimDuration = _claimDuration;
//     }

//     /* *************************************************************************************************************************************/
//     /* ** Creation Functions                                                                                                             ***/
//     /* *************************************************************************************************************************************/

//     function createProjectList(
//         address _newOwner,
//         string calldata _name
//     ) external whenNotPaused returns (address list_) {
//         list_ = address(new OwnableProjectList(projectRegistry,_newOwner ,_name));

//         OwnableProjectList(list_).transferOwnership(msg.sender);

//         isList[list_] = true;

//         emit ProjectListCreated(list_);
//     }
//     /**
//      * @custom:change
//      * Add params to the function 
//      * Add creation of a GNOSIS
//      * Add creation of a list
//      */
//     function createPool(
//         bytes calldata _initPayload
//     ) external whenNotPaused returns (address pool_) {
//         pool_ = address(new BeaconProxy(address(beacon), _initPayload));

//         PoolV2(pool_).transferOwnership(msg.sender);
//         // Que cree una lista de forma automatica
//         // Que cree una SAFE

//         isPool[pool_] = true;

//         emit PoolCreated(pool_);
//     }

//     // function createMimeToken(
//     //     bytes calldata _initPayload
//     // ) external whenNotPaused returns (address token_) {
//     //     token_ = MimeTokenFactory(mimeTokenFactory).createMimeToken(
//     //         _initPayload
//     //     );

//     //     require(
//     //         MimeToken(token_).timestamp() == claimTimestamp,
//     //         "OsmoticController: Invalid timestamp for token"
//     //     );
//     //     require(
//     //         MimeToken(token_).roundDuration() == claimDuration,
//     //         "OsmoticController: Invalid round duration for token"
//     //     );

//     //     MimeToken(token_).transferOwnership(msg.sender);

//     //     isToken[token_] = true;

//     //     emit MimeTokenCreated(token_);
//     // }
// }
