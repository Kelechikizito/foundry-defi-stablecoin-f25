// // SPDX-License-Identifier: MIT

// // This test should have our invariant a.k.a. properties that should always hold true

// // What are our invariants?
// // 1. The total supply of DSC should be less than the total value of collateral.
// // 2. Getter View functions should never revert <- evergreen invariant.

// pragma solidity ^0.8.18;

// import {Test, console} from "forge-std/Test.sol";
// import {StdInvariant} from "forge-std/StdInvariant.sol";
// import {DeployDSC} from "script/DeployDSC.s.sol";
// import {DSCEngine} from "src/DSCEngine.sol";
// import {DecentralizedStableCoin} from "src/DecentralizedStableCoin.sol";
// import {HelperConfig} from "script/HelperConfig.s.sol";
// import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";

// contract OpenInvariantsTest is StdInvariant, Test {
//     DeployDSC deployer;
//     DSCEngine dscE;
//     DecentralizedStableCoin dsc;
//     HelperConfig config;
//     address weth;
//     address wbtc;

//     function setUp() external {
//         deployer = new DeployDSC();
//         (dsc, dscE, config) = deployer.run();
//         (,, weth, wbtc,) = config.activeNetworkConfig();
//         targetContract(address(dscE));
//     }

//     function invariant_protocolMustHaveMoreValueThanTotalSuppply() public view {
//         uint256 totalSupply = dsc.totalSupply();
//         uint256 totalWethDeposited = IERC20(weth).balanceOf(address(dscE));
//         uint256 totalWbtcDeposited = IERC20(wbtc).balanceOf(address(dscE));

//         uint256 wethValue = dscE.getUsdValue(weth, totalWethDeposited);
//         uint256 wbtcValue = dscE.getUsdValue(wbtc, totalWbtcDeposited);

//         console.log(wethValue);
//         console.log(wbtcValue);
//         console.log(totalSupply);
//         assert(wethValue + wbtcValue >= totalSupply);
//     }
// }
