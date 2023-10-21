// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

struct FormulaParams {
    uint256 decay;
    uint256 drop;
    uint256 maxFlow;
    uint256 minStakeRatio;
}

struct ProjectSupport {
    uint256 projectId;
    uint256 deltaSupport;
}
struct SupportInfo {
    uint200 amount;
    uint56 time;
}
struct ParticipantInfo {
    uint amountStaked;
    uint freeSTake;
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
/**
 * @dev This struct is used to initialize a pool proxy
 * @custom:addr
 * addr[0]:= PoolOwner    
 * addr[1]:= Manager address
 * addr[2]:= Funding token address
 * addr[3]:= List address
 * addr[4]:= GovTokenAddress
 * @custom:fparams
 * fparams[0]:=decay
 * fparams[1]:=drop
 * fparams[2]:=maxFlow
 * fparams[3]:=minStakeRatio
 */
struct PoolInitParams {
    address[5] addr;
    uint[4] fParams;
    // FormulaParams fParams;
}

struct SafeSetUp {
    address[]  _owners;
    uint256 _threshold;
    address to;
    bytes  data;
    address fallbackHandler;
    address paymentToken;
    uint256 payment;
    address payable paymentReceiver;
}