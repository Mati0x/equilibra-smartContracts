// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import {OwnableUpgradeable} from "@oz-upgradeable/access/OwnableUpgradeable.sol";
import {Initializable} from "@oz-upgradeable/proxy/utils/Initializable.sol";
import {MerkleProof} from "@oz/utils/cryptography/MerkleProof.sol";

import {IMimeToken} from "./IMimeToken.sol";

error AlreadyClaimed();
error InvalidProof();
error NonTransferable();

contract MimeToken is Initializable, OwnableUpgradeable, IMimeToken {
    uint256 private _currentRound;
    string private _name;
    string private _symbol;
    uint256 private _initialTimestamp;
    uint256 private _roundDuration;

    // round => merkle root.
    mapping(uint256 => bytes32) private _merkleRootAt;
    // round => total supply.
    mapping(uint256 => uint256) private _totalSupplyAt;
    // round => account => balance.
    mapping(uint256 => mapping(address => uint256)) private _balancesAt;
    // This is a packed array of booleans per round.
    mapping(uint256 => mapping(uint256 => uint256)) private _claimedBitMapAt;

    constructor() {
        _disableInitializers();
    }

    function initialize(
        string memory name_,
        string memory symbol_,
        bytes32 merkleRoot_,
        uint256 timestamp_,
        uint256 roundDuration_
    ) public initializer {
        require(timestamp_ <= block.timestamp, "MimeTokenWithDuration: timestamp can not be in the future");
        require(roundDuration_ > 0, "MimeTokenWithDuration: round duration must be greater than 0");

        __Ownable_init();

        _name = name_;
        _symbol = symbol_;
        _initialTimestamp = timestamp_;
        _roundDuration = roundDuration_;
        _merkleRootAt[round()] = merkleRoot_;
    }

    /* *************************************************************************************************************************************/
    /* ** Only Owner Functions                                                                                                           ***/
    /* *************************************************************************************************************************************/

    function setNewRound(bytes32 merkleRoot_) public onlyOwner {
        uint256 nextRound = round() + 1;
        require(
            _merkleRootAt[nextRound] == bytes32(0), "MimeTokenWithDuration: merkle root already set for the next round"
        );
        _merkleRootAt[nextRound] = merkleRoot_;

        emit NewRound(nextRound, merkleRoot_);
    }

    /* *************************************************************************************************************************************/
    /* ** ERC20 Functions                                                                                                                ***/
    /* *************************************************************************************************************************************/

    function totalSupply() public view override returns (uint256) {
        return _totalSupplyAt[round()];
    }

    function balanceOf(address account) public view override returns (uint256) {
        return _balancesAt[round()][account];
    }

    function transfer(address to, uint256 amount) public override returns (bool) {
        revert NonTransferable();
    }

    function allowance(address owner, address spender) public view override returns (uint256) {
        revert NonTransferable();
    }

    function approve(address spender, uint256 amount) public override returns (bool) {
        revert NonTransferable();
    }

    function transferFrom(address from, address to, uint256 amount) public override returns (bool) {
        revert NonTransferable();
    }

    function _mint(address account, uint256 amount) private {
        require(account != address(0), "MimeToken: mint to the zero address");

        _totalSupplyAt[round()] += amount;
        unchecked {
            // Overflow not possible: balance + amount is at most totalSupply + amount, which is checked above.
            _balancesAt[round()][account] += amount;
        }
    }

    /* *************************************************************************************************************************************/
    /* ** Claim Functions                                                                                                                ***/
    /* *************************************************************************************************************************************/

    function isClaimed(uint256 index) public view returns (bool) {
        uint256 claimedWordIndex = index / 256;
        uint256 claimedBitIndex = index % 256;
        uint256 claimedWord = _claimedBitMapAt[round()][claimedWordIndex];
        uint256 mask = (1 << claimedBitIndex);
        return claimedWord & mask == mask;
    }

    function _setClaimed(uint256 index) private {
        uint256 claimedWordIndex = index / 256;
        uint256 claimedBitIndex = index % 256;
        _claimedBitMapAt[round()][claimedWordIndex] =
            _claimedBitMapAt[round()][claimedWordIndex] | (1 << claimedBitIndex);
    }

    function claim(uint256 index, address account, uint256 amount, bytes32[] calldata merkleProof) public {
        if (isClaimed(index)) revert AlreadyClaimed();

        // Verify the merkle proof.
        bytes32 node = keccak256(abi.encodePacked(index, account, amount));
        if (!MerkleProof.verify(merkleProof, merkleRoot(), node)) revert InvalidProof();

        // Mark it claimed and mint tokens for current round.
        _setClaimed(index);
        _mint(account, amount);

        emit Claimed(round(), index, account, amount);
    }

    /* *************************************************************************************************************************************/
    /* ** View Functions                                                                                                                 ***/
    /* *************************************************************************************************************************************/

    function round() public view returns (uint256) {
        return (block.timestamp - _initialTimestamp) / _roundDuration;
    }

    function timestamp() public view returns (uint256) {
        return _initialTimestamp;
    }

    function roundDuration() public view returns (uint256) {
        return _roundDuration;
    }

    function merkleRoot() public view returns (bytes32) {
        return _merkleRootAt[round()];
    }

    function name() public view returns (string memory) {
        return _name;
    }

    function symbol() public view returns (string memory) {
        return _symbol;
    }

    function decimals() public pure returns (uint8) {
        return 18;
    }
}