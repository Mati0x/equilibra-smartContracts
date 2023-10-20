// // SPDX-License-Identifier: MIT
// pragma solidity ^0.8.17;

// import "forge-std/Test.sol";
// import "../src/pool/Pool.sol";
// import "../src/ProjectRegistry.sol";
// import "../src/manager/Manager.sol";

// import {UpgradeableBeacon} from "@oz/proxy/beacon/UpgradeableBeacon.sol";

// import {TestUtils} from "./utils/TestUtils.sol";

// import {SetupScript} from "../script/SetupScript.sol";
// import {ICFAv1Forwarder} from "../src/interfaces/ICFAv1Forwarder.sol";
// import {ISuperToken} from "../src/interfaces/ISuperToken.sol";
// import {FormulaParams} from "../src/Formula.sol";
// // import {FormulaParams} from "../../src/Formula.sol"

// import {StableMock} from "./mocks/StableMock.sol";
// import {GovTokenMock} from "./mocks/GovTokenMock.sol";

// abstract contract BaseSetup is SetupScript, Test, TestUtils {
//     bool LOCAL_HOST = true;

//     uint256 VERSION = 1;
//     address GOV_TOKEN;

//     // fork env
//     uint256 GOERLI_FORK_BLOCK_NUMBER = 8689679; // Mime token factory deployment block
//     string GOERLI_RPC_URL =
//         vm.envOr("GOERLI_RPC_URL", string("https://rpc.ankr.com/eth_goerli"));

//     // Goerli test deps
//     address constant CFA_V1_FORWARDER_ADDRESS =
//         0xcfA132E353cB4E398080B9700609bb008eceB125;
//     address FUNDING_TOKEN_ADDRESS = 0xF2d68898557cCb2Cf4C10c3Ef2B034b2a69DAD00; // DAIx

//     ICFAv1Forwarder constant CFA_FORWARDER =
//         ICFAv1Forwarder(CFA_V1_FORWARDER_ADDRESS);
//     ISuperToken FUNDING_TOKEN = ISuperToken(FUNDING_TOKEN_ADDRESS);

//     FormulaParams FORMULA_PARAMS =
//         FormulaParams({
//             decay: 999999197747000000, // 10 days (864000 seconds) to reach 50% of targetRate
//             drop: 2,
//             maxFlow: 19290123456, // 5% of Common Pool per month = Math.floor(0.05e18 / (30 * 24 * 60 * 60))
//             minStakeRatio: 25000000000000000 // 2.5% of Total Support = the minimum stake to start receiving funds
//         });

//     // function setUpUpgradeScripts() internal override {
//     //     UPGRADE_SCRIPTS_BYPASS = true; // deploys contracts without any checks whatsoever
//     // }

//     function forkGoerli() internal {
//         LOCAL_HOST = false;
//     }

//     function setUp() public virtual {
//         // setUpUpgradeScripts();
//         if (!LOCAL_HOST) {
//             // if in fork mode create and select fork
//             vm.createSelectFork(GOERLI_RPC_URL, GOERLI_FORK_BLOCK_NUMBER);

//             vm.label(CFA_V1_FORWARDER_ADDRESS, "cfaForwarder");
//             vm.label(FUNDING_TOKEN_ADDRESS, "fundingToken");
//         } else {
//             FUNDING_TOKEN_ADDRESS = address(
//                 new StableMock(["USDC_MOCK", "mUSDC"])
//             );
//             GOV_TOKEN = address(new GovTokenMock(["EQUI_DAO", "EQ"]));
//         }
//     }
// }

