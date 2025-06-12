// SPDX-License-Identifier: MIT

// This test should have our invariant a.k.a. properties that should always hold true

// What are our invariants?
// 1. The total supply of DSC should be less than the total value of collateral.
// 2. Getter View functions should never revert <- evergreen invariant.
// 3. Collateral Deposits and minted Can't Be Negative
// 4. Collateral Tokens Are Registered

pragma solidity ^0.8.18;

import {Test, console} from "forge-std/Test.sol";
import {StdInvariant} from "forge-std/StdInvariant.sol";
import {DeployDSC} from "script/DeployDSC.s.sol";
import {DSCEngine} from "src/DSCEngine.sol";
import {DecentralizedStableCoin} from "src/DecentralizedStableCoin.sol";
import {HelperConfig} from "script/HelperConfig.s.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {Handler} from "test/fuzz/Handler.t.sol";

contract Invariants is StdInvariant, Test {
    DeployDSC deployer;
    DSCEngine dscE;
    DecentralizedStableCoin dsc;
    HelperConfig config;
    address weth;
    address wbtc;

    Handler handler;

    address public USER = makeAddr("user");

    function setUp() external {
        deployer = new DeployDSC();
        (dsc, dscE, config) = deployer.run();
        (,, weth, wbtc,) = config.activeNetworkConfig();

        handler = new Handler(dscE, dsc);
        targetContract(address(handler));

        // hey, don't call redeemcollateral, unless there is collateral to redeem
    }

    function invariant_protocolMustHaveMoreValueThanTotalSuppply() public view {
        uint256 totalSupply = dsc.totalSupply();
        uint256 totalWethDeposited = IERC20(weth).balanceOf(address(dscE));
        uint256 totalWbtcDeposited = IERC20(wbtc).balanceOf(address(dscE));

        uint256 wethValue = dscE.getUsdValue(weth, totalWethDeposited);
        uint256 wbtcValue = dscE.getUsdValue(wbtc, totalWbtcDeposited);

        console.log("weth value: ", wethValue);
        console.log("wbtc value: ", wbtcValue);
        console.log("total supply: ", totalSupply);
        console.log("Times mint is called: ", handler.timesMintIsCalled());
        assert(wethValue + wbtcValue >= totalSupply);
    }

    function invariant_getterViewFunctionsShouldNotRevert() public view {
        uint256 totalWethDeposited = IERC20(weth).balanceOf(address(dscE));
        uint256 totalWbtcDeposited = IERC20(wbtc).balanceOf(address(dscE));
        uint256 indexOfWeth = 0;
        uint256 indexOfWbtc = 1;

        dscE.getCollateralTokens();
        dscE.getLiquidationBonus();
        dscE.getCollateralTokensLength();
        dscE.getDscAddress();
        dscE.getLiquidationPrecision();
        dscE.getLiquidationThreshold();
        dscE.getMinHealthFactor();
        dscE.getPrecision();

        dscE.getAccountCollateralValue(address(handler));
        dscE.getAccountInformation(address(handler));
        dscE.getCollateralDeposited(address(handler), weth);
        dscE.getCollateralDeposited(address(handler), wbtc);
        dscE.getCollateralToken(indexOfWeth);
        dscE.getCollateralToken(indexOfWbtc);
        dscE.getDscMinted(address(handler));
        dscE.getHealthFactor(address(handler));
        dscE.getPriceFeed(weth);
        dscE.getPriceFeed(wbtc);
        dscE.getTokenAmountFromUsd(weth, totalWethDeposited);
        dscE.getTokenAmountFromUsd(wbtc, totalWbtcDeposited);
        dscE.getUsdValue(weth, totalWethDeposited);
        dscE.getUsdValue(wbtc, totalWbtcDeposited);
    }

    function invariant_collateralDepositsAndMintedCantBeNegative() public view {
        uint256 wethDeposited = dscE.getCollateralDeposited(address(handler), weth);
        uint256 wbtcDeposited = dscE.getCollateralDeposited(address(handler), wbtc);
        uint256 dscMinted = dscE.getDscMinted(address(handler));

        assert(wethDeposited >= 0);
        assert(wbtcDeposited >= 0);
        assert(dscMinted >= 0);
    }

    function invariant_allCollateralTokensAreRegistered() public view {
        uint256 totalCollateralTokens = dscE.getCollateralTokensLength();

        for (uint256 i = 0; i < totalCollateralTokens; i++) {
            address collateralToken = dscE.getCollateralToken(i);
            address priceFeed = dscE.getPriceFeed(collateralToken);
            console.log("Collateral token: ", collateralToken);
            console.log("Price feed: ", priceFeed);
            assert(priceFeed != address(0));
        }
    }
}
