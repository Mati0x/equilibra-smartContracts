// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import {OwnableUpgradeable} from "@oz-upgradeable/access/OwnableUpgradeable.sol";
import {PausableUpgradeable} from "@oz-upgradeable/utils/PausableUpgradeable.sol";
import {Initializable} from "@oz-upgradeable/proxy/utils/Initializable.sol";
import {UUPSUpgradeable, ERC1967Utils} from "@oz-upgradeable/proxy/utils/UUPSUpgradeable.sol";

import {BeaconProxy} from "@oz/proxy/beacon/BeaconProxy.sol";
import {UpgradeableBeacon} from "@oz/proxy/beacon/UpgradeableBeacon.sol";

//import {MimeToken, MimeTokenFactory} from "mime-token/MimeTokenFactory.sol";

import {OwnableProjectList} from "../OwnableProjectList.sol";

import {PoolInitParams, SafeSetUp} from "../structs.sol";

contract Manager is
    Initializable,
    OwnableUpgradeable,
    PausableUpgradeable,
    UUPSUpgradeable
{
    uint256 public immutable version;
    ///@custom:refactor
    address public immutable projectRegistry;
    UpgradeableBeacon public immutable poolBeacon;
    UpgradeableBeacon public immutable safeBeacon;
    bool safeCustomizable;

    /**
     * @dev Just in case we need those storage slots and to avoid getting clashes on future versions
     */
    uint[50] internal __storageGap;

    // mapping(address => bool) public isPool;
    // mapping(address => bool) public isList;
    // mapping(address => bool) public isToken;
    /**
     * @custom:refactor
     * Instead of using 3 different mappings to we pack all information inside one due a better use of the storage
     */
    struct AddressInfo {
        bool isPool;
        bool isList;
        bool isToken;
        bool isMultisig;
    }

    mapping(address => AddressInfo) addressInfo;

    /* *************************************************************************************************************************************/
    /* ** Events                                                                                                                         ***/
    /* *************************************************************************************************************************************/

    event PoolCreated(address indexed pool);
    event ProjectListCreated(address indexed list);

    constructor(
        uint256 _version,
        address _poolImplementation,
        address _gnosisSafeImplementation,
        // address _beaconOwner,
        address _projectRegistry
    ) {
        _disableInitializers();

        poolBeacon = new UpgradeableBeacon(_poolImplementation, msg.sender);
        safeBeacon = new UpgradeableBeacon(
            _gnosisSafeImplementation,
            msg.sender
        );
        version = _version;
        projectRegistry = _projectRegistry;
    }

    function initialize(address _newOwner) public initializer {
        __Pausable_init();
        __Ownable_init(_newOwner);
        __UUPSUpgradeable_init();
        // We set the registry as the default list
        addressInfo[projectRegistry].isList = true;
    }

    /* *************************************************************************************************************************************/
    /* ** Getters Functions                                                                                                          ***/
    /* *************************************************************************************************************************************/
    /**
     * @dev Retruns if `_isPool` is registered as a pool
     */
    function isPool(address _isPool) external view returns (bool) {
        return addressInfo[_isPool].isPool;
    }

    /**
     * @dev Retruns if `_isList` is registered as a list
     */
    function isList(address _isList) external view returns (bool) {
        return addressInfo[_isList].isList;
    }

    /**
     * @dev Retruns if `_isMultisig` is registered as a list
     */
    function isMultisig(address _isMultisig) external view returns (bool) {
        return addressInfo[_isMultisig].isMultisig;
    }

    function getAddressInfo(
        address _address
    ) external view returns (AddressInfo memory) {
        return addressInfo[_address];
    }

    function isSafeCustomizationAllowed() external view returns (bool) {
        return safeCustomizable;
    }

    /* *************************************************************************************************************************************/
    /* ** Pausability Functions                                                                                                          ***/
    /* *************************************************************************************************************************************/
    /**
     * @dev Pauses all operations
     * @custom:modifers onlyOwner()
     */
    function pause() public onlyOwner {
        _pause();
    }

    /**
     * @dev Unpauses all operations
     * @custom:modifers onlyOwner()
     */
    function unpause() public onlyOwner {
        _unpause();
    }

    /* *************************************************************************************************************************************/
    /* ** Upgradeability Functions                                                                                                       ***/
    /* *************************************************************************************************************************************/
    /**
     * @dev Returns the current Managers proxy implementation
     */
    function implementation() external view returns (address) {
        return ERC1967Utils.getImplementation();
    }

    /**
     * @dev Returns the current Pool proxy implementation
     */
    function poolImplementation() external view returns (address) {
        return poolBeacon.implementation();
    }

    /**
     * @dev Returns the current Safe(multisig) proxy implementation
     */
    function safeImplementation() external view returns (address) {
        return safeBeacon.implementation();
    }

    function _authorizeUpgrade(
        address newImplementation
    ) internal override onlyOwner {}

    /* *************************************************************************************************************************************/
    /* ** Creation Functions                                                                                                             ***/
    /* *************************************************************************************************************************************/
    /**
     *
     * @param _newOwner Address that will own (Ownable.owner()) the project list being created
     * @param _name Name of the list to be created
     * @custom:modifier whenNotPaused()
     */
    function createProjectList(
        address _newOwner,
        string calldata _name
    ) external whenNotPaused returns (address list_) {
        list_ = address(
            new OwnableProjectList(projectRegistry, _newOwner, _name)
        );

        // OwnableProjectList(list_).transferOwnership(msg.sender);

        addressInfo[list_].isList = true;

        emit ProjectListCreated(list_);
    }

    /**
     *
     * @param _initPoolData Bytes needed to init a PoolProxy
     * @custom:descrition
     * As V1, this bytes will be encoded from:
     * PoolInitParams -> (address[5], FromulaParams)
     * and function initialize(address[5],FormulaParams)
     * _initPoolData -> abi.encode('initialize(address[5],(uint256,uint256,uint256,uint256))',address[5],FromulaParams(uint256,uint256,uint256,uint256))
     * @param _initSafeData Bytes needed to init a SafeProxy
     * @custom:descrition
     *
     *
     */
    function createPoolMultiSig(
        SafeSetUp calldata _initSafeData,
        PoolInitParams memory _initPoolData
    ) external whenNotPaused returns (address pool_, address multiSig_) {
        
        bytes memory encodedSafeInit=_enocodeSafeInit(_initSafeData);
       
        multiSig_ = address(
            new BeaconProxy(address(safeBeacon), encodedSafeInit)
        );
        _initPoolData.addr[0]=address(multiSig_);
        bytes memory encodedPoolInit = _enocodePoolInit(_initPoolData);

        // bytes memory initPool=_enocodePoolInit(_initPoolData);
        /**
         * address[5] memory _poolAddresses
         * Formulaparams calldata _params
         * https://excalidraw.com/#room=783439dcd8a3edf12dda,yH2CLCbaPncsjGPmjKu70g
         * Armar diagrama
         * https://excalidraw.com/
         */
        pool_ = address(new BeaconProxy(address(poolBeacon), encodedPoolInit));
        
        addressInfo[pool_].isPool = true;
        addressInfo[multiSig_].isMultisig = true;

        emit PoolCreated(pool_);
    }

    function _enocodePoolInit(
        PoolInitParams memory _initPoolData
    ) internal view returns (bytes memory) {
        address[5] memory _adr = _initPoolData.addr;
        _adr[1]=address(this);
        uint[4] memory _fparams = _initPoolData.fParams;
        return
            abi.encodeWithSignature(
                "initialize(address[5],(uint256,uint256,uint256,uint256))",
                _adr,
                _fparams[0],
                _fparams[1],
                _fparams[2],
                _fparams[3]
            );
    }

    function _enocodeSafeInit(
        SafeSetUp memory _initSafeData
    ) internal view returns (bytes memory) {
        ///@dev This implies that only params `_owners` & `_threshold` are used
        if (!safeCustomizable) {
            address zero = address(0);
            bytes memory empty;
            return
                abi.encodeWithSignature(
                    "setup(address[],uint256,address,bytes,address,address,uint256,address payable)",
                    _initSafeData._owners,
                    _initSafeData._threshold,
                    zero,
                    empty,
                    zero,
                    zero,
                    0,
                    payable(zero)
                );
        } else {
            return
                abi.encodeWithSignature(
                    "setup(address[],uint256,address,bytes,address,address,uint256,address payable)",
                    _initSafeData._owners,
                    _initSafeData._threshold,
                    _initSafeData.to,
                    _initSafeData.data,
                    _initSafeData.fallbackHandler,
                    _initSafeData.paymentToken,
                    _initSafeData.payment,
                    _initSafeData.paymentReceiver
                );
        }
    }

    /**
     *
     * @param _initPoolData Bytes needed to init a PoolProxy
     * @custom:descrition
     * As V1, this bytes will be encoded from:
     * PoolInitParams -> (address[5], FromulaParams)
     * and function initialize(address[5],FormulaParams)
     * _initPoolData -> abi.encode('initialize(address[5],(uint256,uint256,uint256,uint256))',address[5],FromulaParams(uint256,uint256,uint256,uint256))
     */
    function createPool(
        PoolInitParams memory _initPoolData
    ) external whenNotPaused returns (address pool_) {
        bytes memory encodedInit = _enocodePoolInit(_initPoolData);
        pool_ = address(new BeaconProxy(address(poolBeacon), encodedInit));
        // Probar si funciona con la interfaz
        // PoolV2(pool_).transferOwnership(msg.sender);
        // Que cree una lista de forma automatica
        // Que cree una SAFE
        addressInfo[pool_].isPool = true;
        emit PoolCreated(pool_);
    }
}
