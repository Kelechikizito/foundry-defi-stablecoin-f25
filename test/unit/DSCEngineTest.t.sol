// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

import {Test, console, console2} from "forge-std/Test.sol";
import {DeployDSC} from "script/DeployDSC.s.sol";
import {DecentralizedStableCoin} from "src/DecentralizedStableCoin.sol";
import {DSCEngine} from "src/DSCEngine.sol";
import {HelperConfig} from "script/HelperConfig.s.sol";
import {ERC20Mock} from "@openzeppelin/contracts/mocks/token/ERC20Mock.sol";
import {MockV3Aggregator} from "test/mocks/MockV3Aggregator.sol";

contract DSCEngineTest is Test {
    DeployDSC deployer;
    DecentralizedStableCoin dsc;
    DSCEngine dscE;
    HelperConfig config;
    address ethUsdPriceFeed;
    address btcUsdPriceFeed;
    address weth;

    // uint256 amountCollateral = 10 ether;
    // uint256 amountToMint = 100 ether;

    address public USER = makeAddr("user");
    address public LIQUIDATOR = makeAddr("liquidator");
    uint256 public constant AMOUNT_COLLATERAL = 10 ether;
    uint256 public constant STARTING_ERC20_BALANCE = 10 ether;
    uint256 public constant LIQUIDATOR_AMOUNT_COLLATERAL = 20 ether;

    uint256 public constant AMOUNT_DSC_TO_MINT = 100 ether;
    uint256 public constant AMOUNT_DSC_TO_BURN = 0.1 ether;
    uint256 public constant MIN_HEALTH_FACTOR = 1e18;
    uint256 public constant LIQUIDATION_BONUS = 10; // 10%
    uint256 public constant LIQUIDATION_PRECISION = 100;

    event CollateralDeposited(address indexed user, address indexed token, uint256 indexed amountCollateral);
    event CollateralRedeemed(
        address indexed redeemedFrom, address indexed redeemedTo, address indexed token, uint256 amount
    );

    function setUp() public {
        deployer = new DeployDSC();
        (dsc, dscE, config) = deployer.run();
        (ethUsdPriceFeed, btcUsdPriceFeed, weth,,) = config.activeNetworkConfig();

        ERC20Mock(weth).mint(USER, STARTING_ERC20_BALANCE);

        // _setupLiquidatorWithDSC();
    }

    ///////////////////////
    //Constructor Tests////
    ///////////////////////
    address[] public tokenAddresses;
    address[] public priceFeedAddresses;

    function testRevertsIfTokenLengthDoesntMatchPriceFeeds() public {
        tokenAddresses.push(weth);
        priceFeedAddresses.push(ethUsdPriceFeed);
        priceFeedAddresses.push(btcUsdPriceFeed);

        vm.expectRevert(DSCEngine.DSCEngine__TokenAddressesAndPriceFeedAddressesMustBeSameLength.selector);
        new DSCEngine(tokenAddresses, priceFeedAddresses, address(dsc));
    }

    /////////////////
    //Price Tests////
    /////////////////

    function testGetUsdValue() public view {
        uint256 ethAmount = 15e18;
        uint256 expectedUsdValue = 30000e18;
        uint256 actualUsd = dscE.getUsdValue(weth, ethAmount);

        assertEq(expectedUsdValue, actualUsd);
    }

    function testGetTokenAmountFromUsd() public view {
        uint256 usdValue = 30000e18;
        uint256 expectedWethAmount = 15e18;
        uint256 actualWeth = dscE.getTokenAmountFromUsd(weth, usdValue);

        assertEq(expectedWethAmount, actualWeth);
    }

    /////////////////////////////
    //depositCollateral Tests////
    /////////////////////////////

    function testRevertsIfCollateralIsZero() public {
        vm.startPrank(USER);
        ERC20Mock(weth).approve(address(dscE), AMOUNT_COLLATERAL);

        vm.expectRevert(DSCEngine.DSCEngine__NeedsMoreThanZero.selector);
        dscE.depositCollateral(weth, 0);
        vm.stopPrank();
    }

    function testRevertsWithUnapprovedCollateral() public {
        ERC20Mock ranToken = new ERC20Mock();
        vm.startPrank(USER);
        vm.expectRevert(DSCEngine.DSCEngine__NotAllowedToken.selector);
        dscE.depositCollateral(address(ranToken), AMOUNT_COLLATERAL);
        vm.stopPrank();
    }

    modifier depositedCollateral() {
        vm.startPrank(USER);
        ERC20Mock(weth).approve(address(dscE), AMOUNT_COLLATERAL);
        dscE.depositCollateral(weth, AMOUNT_COLLATERAL);
        vm.stopPrank();
        _;
    }

    modifier depositedCollateralAndMintDsce() {
        vm.startPrank(USER);
        ERC20Mock(weth).approve(address(dscE), AMOUNT_COLLATERAL);
        dscE.depositCollateral(weth, AMOUNT_COLLATERAL);
        dscE.mintDsc(AMOUNT_DSC_TO_MINT); // Mint 1000 DSC
        vm.stopPrank();
        _;
    }

    function testCanDepositCollateralAndGetAccountInfo() public depositedCollateral {
        (uint256 totalDscMinted, uint256 collateralValueInUsd) = dscE.getAccountInformation(USER);

        uint256 expectedTotalDscMinted = 0;
        uint256 expectedDepositAmount = dscE.getTokenAmountFromUsd(weth, collateralValueInUsd);

        assertEq(totalDscMinted, expectedTotalDscMinted);
        assertEq(AMOUNT_COLLATERAL, expectedDepositAmount);
    }

    function testRevertsIfDepositCollateralWithZeroAddress() public {
        vm.startPrank(USER);
        ERC20Mock(weth).approve(address(dscE), AMOUNT_COLLATERAL);

        vm.expectRevert(DSCEngine.DSCEngine__NotAllowedToken.selector);
        dscE.depositCollateral(address(0), AMOUNT_COLLATERAL);
        vm.stopPrank();
    }

    function testDepositsCollateralAndEmitsEvent() public {
        vm.startPrank(USER);
        ERC20Mock(weth).approve(address(dscE), AMOUNT_COLLATERAL);

        vm.expectEmit(true, true, true, false, address(dscE));
        emit CollateralDeposited(USER, weth, AMOUNT_COLLATERAL);

        dscE.depositCollateral(weth, AMOUNT_COLLATERAL);
        vm.stopPrank();
    }

    /////////////////////////////
    //healthFactor Tests     ////
    /////////////////////////////

    function testHealthFactorIsCorrect() public depositedCollateralAndMintDsce {
        (uint256 totalDscMinted, uint256 collateralValueInUsd) = dscE.getAccountInformation(USER);

        uint256 collateralAdjustedForThreshold =
            (collateralValueInUsd * dscE.getLiquidationThreshold()) / dscE.getLiquidationPrecision();
        uint256 calculatedHealthFactor = (collateralAdjustedForThreshold * dscE.getPrecision()) / totalDscMinted;
        uint256 expectedHealthFactor = dscE.getHealthFactor(USER);

        assertEq(expectedHealthFactor, calculatedHealthFactor);
    }

    function testHealthFactorWhenNoDscIsMinted() public depositedCollateral {
        uint256 healthFactor = dscE.getHealthFactor(USER);
        assertEq(healthFactor, type(uint256).max);
    }

    // function testRevertsIfHealthFactorIsBroken() public depositedCollateralAndMintDsce {
    //     (, int256 price,,,) = MockV3Aggregator(ethUsdPriceFeed).latestRoundData();
    //     amountToMint = (amountCollateral * (uint256(price) * dsce.getAdditionalFeedPrecision())) / dsce.getPrecision();

    //     vm.startPrank(user);
    //     uint256 expectedHealthFactor =
    //         dscE.calculateHealthFactor(amountToMint, dsce.getUsdValue(weth, amountCollateral));
    //     vm.expectRevert(abi.encodeWithSelector(DSCEngine.DSCEngine__BreaksHealthFactor.selector, expectedHealthFactor));
    //     dsce.mintDsc(amountToMint);
    //     vm.stopPrank();
    // }

    /////////////////////////////
    //redeemCollateral Tests////
    /////////////////////////////
    function testRevertsIfRedeemCollateralIsZero() public depositedCollateral {
        vm.startPrank(USER);
        vm.expectRevert(DSCEngine.DSCEngine__NeedsMoreThanZero.selector);
        dscE.redeemCollateral(weth, 0);
        vm.stopPrank();
    }

    function testRedeemCollateralWorks() public depositedCollateralAndMintDsce {
        uint256 redeemAmount = 5 ether;
        uint256 userBalanceBefore = ERC20Mock(weth).balanceOf(USER);
        uint256 contractBalanceBefore = ERC20Mock(weth).balanceOf(address(dscE));

        vm.startPrank(USER);
        dscE.redeemCollateral(weth, redeemAmount);
        vm.stopPrank();

        uint256 userBalanceAfter = ERC20Mock(weth).balanceOf(USER);
        uint256 contractBalanceAfter = ERC20Mock(weth).balanceOf(address(dscE));

        assertEq(userBalanceAfter, userBalanceBefore + redeemAmount);
        assertEq(contractBalanceAfter, contractBalanceBefore - redeemAmount);
    }

    function testRedeemCollateralAndEmitsEvent() public depositedCollateralAndMintDsce {
        uint256 redeemAmount = 5 ether;

        vm.startPrank(USER);
        vm.expectEmit(true, true, true, false, address(dscE));
        emit CollateralRedeemed(USER, USER, weth, redeemAmount);
        dscE.redeemCollateral(weth, redeemAmount);
        vm.stopPrank();
    }

    function testRedeemCollateralForDsc() public depositedCollateralAndMintDsce {
        uint256 redeemAmount = 5 ether;

        vm.startPrank(USER);
        dsc.approve(address(dscE), AMOUNT_DSC_TO_BURN);
        dscE.redeemCollateralForDsc(weth, redeemAmount, AMOUNT_DSC_TO_BURN);
        vm.stopPrank();
    }

    function testCanGetCollateralTokens() public depositedCollateralAndMintDsce {
        address[] memory tokens = dscE.getCollateralTokens();
        // console.log(tokens);
        // assertEq(tokens.length, 1);
        assertEq(tokens[0], weth);
    }

    function testRedeemAllCollateralAfterBurn() public depositedCollateralAndMintDsce {
        vm.startPrank(USER);
        dsc.approve(address(dscE), AMOUNT_DSC_TO_MINT);
        dscE.burnDsc(AMOUNT_DSC_TO_MINT);

        vm.expectEmit(true, true, true, false, address(dscE));
        emit CollateralRedeemed(USER, USER, weth, AMOUNT_COLLATERAL);
        dscE.redeemCollateral(weth, AMOUNT_COLLATERAL);
        vm.stopPrank();

        uint256 userCollateral = dscE.getCollateralDeposited(USER, weth);
        uint256 userWethBalance = ERC20Mock(weth).balanceOf(USER);
        assertEq(userCollateral, 0);
        assertEq(userWethBalance, STARTING_ERC20_BALANCE);
    }

    /////////////////////////////
    //mintDsc Tests          ////
    /////////////////////////////

    function testRevertsIfMintedDscBreaksHealthFactor() public {
        (, int256 price,,,) = MockV3Aggregator(ethUsdPriceFeed).latestRoundData();
        uint256 amountToMint =
            (AMOUNT_COLLATERAL * (uint256(price) * dscE.getAdditionalFeedPrecision())) / dscE.getPrecision();
        console.log("amountToMint: %s", amountToMint);
        vm.startPrank(USER);
        ERC20Mock(weth).approve(address(dscE), AMOUNT_COLLATERAL);

        uint256 expectedHealthFactor =
            dscE.calculateHealthFactor(amountToMint, dscE.getUsdValue(weth, AMOUNT_COLLATERAL));
        vm.expectRevert(abi.encodeWithSelector(DSCEngine.DSCEngine__BreaksHealthFactor.selector, expectedHealthFactor));
        dscE.depositCollateralAndMintDSCTokens(weth, AMOUNT_COLLATERAL, amountToMint);
        vm.stopPrank();
    }

    function testRevertsIfMintsZeroDsc() public depositedCollateral {
        vm.startPrank(USER);
        vm.expectRevert(DSCEngine.DSCEngine__NeedsMoreThanZero.selector);
        dscE.mintDsc(0);
        vm.stopPrank;
    }

    function testMintDscWorks() public depositedCollateralAndMintDsce {
        vm.startPrank(USER);
        // Check that USER received the DSC tokens
        uint256 userDscBalance = dsc.balanceOf(USER);
        assertEq(userDscBalance, AMOUNT_DSC_TO_MINT, "User DSC balance should equal minted amount");

        vm.stopPrank();
    }

    function testMintMaximumDsc() public depositedCollateral {
        uint256 collateralValue = dscE.getUsdValue(weth, AMOUNT_COLLATERAL);
        uint256 maxDsc = (collateralValue * dscE.getLiquidationThreshold()) / dscE.getPrecision();

        vm.startPrank(USER);
        dscE.mintDsc(maxDsc);
        vm.stopPrank();

        assertEq(dsc.balanceOf(USER), maxDsc);
        assert(dscE.getHealthFactor(USER) >= MIN_HEALTH_FACTOR);
    }

    /////////////////////////////
    //burnDsc Tests          ////
    /////////////////////////////

    function testRevertsIfBurnZeroDsc() public depositedCollateralAndMintDsce {
        vm.startPrank(USER);
        vm.expectRevert(DSCEngine.DSCEngine__NeedsMoreThanZero.selector);
        dscE.burnDsc(0);
        vm.stopPrank;
    }

    function testBurnDscWorks() public depositedCollateralAndMintDsce {
        vm.startPrank(USER);

        // User should have already minted this much via modifier
        // Approve the engine to spend DSC for burning
        dsc.approve(address(dscE), AMOUNT_DSC_TO_BURN);

        // Act - burn only part of the minted DSC
        dscE.burnDsc(AMOUNT_DSC_TO_BURN);

        // Assert
        uint256 userDscBalanceAfter = dsc.balanceOf(USER);
        uint256 expectedBalance = AMOUNT_DSC_TO_MINT - AMOUNT_DSC_TO_BURN;
        assertEq(userDscBalanceAfter, expectedBalance);
        vm.stopPrank();
    }

    ///////////////////////////////
    //liquidate Tests          ////
    ///////////////////////////////

    modifier liquidated() {
        vm.startPrank(USER);
        ERC20Mock(weth).approve(address(dscE), AMOUNT_COLLATERAL);
        dscE.depositCollateralAndMintDSCTokens(weth, AMOUNT_COLLATERAL, AMOUNT_DSC_TO_MINT);
        vm.stopPrank();

        int256 ethUsdUpdatedPrice = 18e8;

        MockV3Aggregator(ethUsdPriceFeed).updateAnswer(ethUsdUpdatedPrice);
        uint256 userHealthFactor = dscE.getHealthFactor(USER);

        ERC20Mock(weth).mint(LIQUIDATOR, LIQUIDATOR_AMOUNT_COLLATERAL);

        vm.startPrank(LIQUIDATOR);
        ERC20Mock(weth).approve(address(dscE), LIQUIDATOR_AMOUNT_COLLATERAL);
        dscE.depositCollateralAndMintDSCTokens(weth, LIQUIDATOR_AMOUNT_COLLATERAL, AMOUNT_DSC_TO_MINT);
        dsc.approve(address(dscE), AMOUNT_DSC_TO_MINT);
        dscE.liquidate(weth, USER, AMOUNT_DSC_TO_MINT);
        vm.stopPrank();
        _;
    }

    function testRevertsIfLiquidateWithUnapprovedCollateral() public depositedCollateralAndMintDsce {
        // Arrange: Create an unapproved token
        ERC20Mock unapprovedToken = new ERC20Mock();

        // Manipulate price feed to make USER liquidatable
        int256 lowPrice = 18e8; // Low price to break health factor
        MockV3Aggregator(ethUsdPriceFeed).updateAnswer(lowPrice);

        // Act/Assert: Attempt to liquidate with unapproved token
        vm.startPrank(LIQUIDATOR);
        vm.expectRevert(DSCEngine.DSCEngine__NotAllowedToken.selector);
        dscE.liquidate(address(unapprovedToken), USER, AMOUNT_DSC_TO_MINT);
        vm.stopPrank();
    }

    function testRevertsIfLiquidateWithZeroDebtAmount() public depositedCollateralAndMintDsce {
        vm.startPrank(USER);
        vm.expectRevert(DSCEngine.DSCEngine__NeedsMoreThanZero.selector);
        dscE.liquidate(weth, USER, 0);
        vm.stopPrank();
    }

    function testLiquidateRevertsIfHealthFactorIsOkay() public depositedCollateralAndMintDsce {
        uint256 amountToLiquidate = 100e18; // Amount of DSC to liquidate

        vm.prank(LIQUIDATOR);
        vm.expectRevert(DSCEngine.DSCEngine__HealthFactorOkay.selector);
        dscE.liquidate(weth, USER, amountToLiquidate);
    }

    function testLiquidationPayoutIsCorrect() public liquidated {
        uint256 liquidatorWethBalance = ERC20Mock(weth).balanceOf(LIQUIDATOR);
        uint256 expectedWeth = dscE.getTokenAmountFromUsd(weth, AMOUNT_DSC_TO_MINT)
            + (
                dscE.getTokenAmountFromUsd(weth, AMOUNT_DSC_TO_MINT) * dscE.getLiquidationBonus()
                    / dscE.getLiquidationPrecision()
            );
        uint256 hardCodedExpected = 6_111_111_111_111_111_110;
        assertEq(liquidatorWethBalance, hardCodedExpected);
        assertEq(liquidatorWethBalance, expectedWeth);
    }

    function testLiquidatorTakesOnUsersDebt() public liquidated {
        (uint256 liquidatorDscMinted,) = dscE.getAccountInformation(LIQUIDATOR);
        assertEq(liquidatorDscMinted, AMOUNT_DSC_TO_MINT);
    }

    function testUserHasNoMoreDebt() public liquidated {
        (uint256 userDscMinted,) = dscE.getAccountInformation(USER);
        assertEq(userDscMinted, 0);
    }

    ////////////////////////////////////////////////
    //Storage Variable and Getter Function Tests////
    ////////////////////////////////////////////////

    function testGetStorageVariables() public view {
        uint256 liquidationThreshold = 50;
        uint256 liquidationPrecision = 100;
        uint256 liquidationBonus = 10;

        assertEq(liquidationThreshold, dscE.getLiquidationThreshold());
        assertEq(liquidationPrecision, dscE.getLiquidationPrecision());
        assertEq(liquidationBonus, dscE.getLiquidationBonus());
    }

    function testGetAccountCollateralValueReturnsCorrectValue() public {
        // Arrange
        uint256 depositAmount = 10e18; // 10 WETH
        int256 wethUsdPrice = 2000e8; // $2000/ETH
        address token = weth;

        // Set price feed
        MockV3Aggregator(ethUsdPriceFeed).updateAnswer(wethUsdPrice);

        // Mint WETH to USER and approve
        vm.startPrank(USER);
        ERC20Mock(token).mint(USER, depositAmount);
        ERC20Mock(token).approve(address(dscE), depositAmount);

        // Deposit collateral
        dscE.depositCollateral(token, depositAmount);
        vm.stopPrank();

        // Act
        uint256 collateralValue = dscE.getAccountCollateralValue(USER);

        // Assert: 10 WETH * $2000 = $20,000 = 20,000e18
        uint256 expectedUsdValue = 20000e18;
        assertEq(collateralValue, expectedUsdValue);
        console2.log("this is the value returned", dscE.getAccountCollateralValue(USER));
    }

    function testGetCollateralTokensReturnsCorrectList() public view {
        address[] memory tokens = dscE.getCollateralTokens();

        // Check that the array is not empty
        assertGt(tokens.length, 0, "Collateral token list should not be empty");

        // Optional: Check that known token (e.g., WETH) is included
        bool wethFound = false;
        for (uint256 i = 0; i < tokens.length; i++) {
            if (tokens[i] == address(weth)) {
                wethFound = true;
                break;
            }
        }
        assertTrue(wethFound, "WETH should be in collateral tokens");
    }

    function testGetCollateralTokensLength() public view {
        // Arrange: get the value from the public getter
        uint256 expectedLength = dscE.getCollateralTokens().length;

        // Act: call the internal getter function
        uint256 actualLength = dscE.getCollateralTokensLength();

        // Assert: they should be equal
        assertEq(actualLength, expectedLength, "Collateral token length mismatch");
    }

    function testGetCollateralTokenPriceFeed() public view {
        address priceFeed = dscE.getPriceFeed(weth);
        assertEq(priceFeed, ethUsdPriceFeed);
    }

    function testGetDscAddress() public view {
        address expectedDscAddress = address(dsc);

        assertEq(expectedDscAddress, dscE.getDscAddress());
    }

    function testGetDscMinted() public depositedCollateralAndMintDsce {
        assertEq(dscE.getDscMinted(USER), AMOUNT_DSC_TO_MINT);
    }

    function testGetCollateralDeposited() public depositedCollateral {
        assertEq(dscE.getCollateralDeposited(USER, weth), AMOUNT_COLLATERAL);
    }

    function testGetMinHealthFactor() public view {
        assertEq(dscE.getMinHealthFactor(), MIN_HEALTH_FACTOR);
    }

    function testGetCollateralToken() public view {
        assertEq(dscE.getCollateralToken(0), weth);
    }

    /////////////////////////////
    // Edge Case Tests         //
    /////////////////////////////

    function testDepositMinimalCollateral() public {
        uint256 minimalCollateral = 1 wei;
        vm.startPrank(USER);
        ERC20Mock(weth).mint(USER, minimalCollateral);
        ERC20Mock(weth).approve(address(dscE), minimalCollateral);
        dscE.depositCollateral(weth, minimalCollateral);
        vm.stopPrank();
        assertEq(dscE.getCollateralDeposited(USER, weth), minimalCollateral);
    }

    // function testDepositMinimalCollateralReverts() public {
    //     uint256 minimalCollateral = 1 wei;
    //     vm.startPrank(USER);
    //     ERC20Mock(weth).mint(USER, minimalCollateral);
    //     ERC20Mock(weth).approve(address(dscE), minimalCollateral);
    //     vm.expectRevert(DSCEngine.DSCEngine__TransferFailed.selector);
    //     dscE.depositCollateral(weth, minimalCollateral);
    //     vm.stopPrank();
    //     // assertEq(dscE.getCollateralDeposited(USER, weth), minimalCollateral);
    // }

    /////////////////////////////
    // HelperConfig Tests      //
    /////////////////////////////
    // function testGetSepoliaEthConfig() public view {
    //     HelperConfig.NetworkConfig memory configT = config.getSepoliaEthConfig();
    //     assertEq(configT.wethUsdPriceFeed, 0x694AA1769357215DE4FAC081bf1f309aDC325306);
    //     assertEq(configT.wbtcUsdPriceFeed, 0x1b44F3514812d835EB1BDB0acB33d3fA3351Ee43);
    //     assertEq(configT.weth, 0xdd13E55209Fd76AfE204dBda4007C227904f0a81);
    //     assertEq(configT.wbtc, 0x8f3Cf7ad23Cd3CaDbD9735AFf958023239c6A063);
    // }

    function testLiquidateRevertsIfHealthFactorNotImproved() public {
        // Arrange: User deposits collateral and mints near max DSC
        uint256 amountCollateral = 10 ether;
        uint256 amountToMint = 10000 ether; // Max mintable at initial price of $2000 (20000 USD collateral * 50% = 10000 DSC)

        vm.startPrank(USER);
        ERC20Mock(weth).approve(address(dscE), amountCollateral);
        dscE.depositCollateralAndMintDSCTokens(weth, amountCollateral, amountToMint);
        vm.stopPrank();

        // Drop price to $1100 to make collateral USD = 11000, ratio = 1.1, health factor = 0.55 < 1
        int256 newPrice = 1100e8;
        MockV3Aggregator(ethUsdPriceFeed).updateAnswer(newPrice);

        // Verify user is liquidatable
        uint256 userHealthFactor = dscE.getHealthFactor(USER);
        assertLt(userHealthFactor, MIN_HEALTH_FACTOR);

        // Setup liquidator: Deposit collateral, mint some DSC, approve
        uint256 liquidatorCollateral = 10 ether;
        uint256 liquidatorMint = 5000 ether; // Enough for partial liquidation

        ERC20Mock(weth).mint(LIQUIDATOR, liquidatorCollateral);

        vm.startPrank(LIQUIDATOR);
        ERC20Mock(weth).approve(address(dscE), liquidatorCollateral);
        dscE.depositCollateralAndMintDSCTokens(weth, liquidatorCollateral, liquidatorMint);
        dsc.approve(address(dscE), type(uint256).max);
        vm.stopPrank();

        // Act/Assert: Attempt partial liquidation, expect revert because health factor doesn't improve
        uint256 debtToCover = 100 ether; // Partial, small relative to total debt

        vm.prank(LIQUIDATOR);
        vm.expectRevert(DSCEngine.DSCEngine__HealthFactorNotImproved.selector);
        dscE.liquidate(weth, USER, debtToCover);
    }

    // function testSepoliaConfig() public view {
    //     HelperConfig.NetworkConfig memory sepoliaConfig = config.getSepoliaEthConfig();

    //     assertEq(sepoliaConfig.wethUsdPriceFeed, 0x694AA1769357215DE4FAC081bf1f309aDC325306);
    //     assertEq(sepoliaConfig.wbtcUsdPriceFeed, 0x1b44F3514812d835EB1BDB0acB33d3fA3351Ee43);
    //     assertEq(sepoliaConfig.weth, 0xdd13E55209Fd76AfE204dBda4007C227904f0a81);
    //     assertEq(sepoliaConfig.wbtc, 0x8f3Cf7ad23Cd3CaDbD9735AFf958023239c6A063);
    //     // deployerKey not asserted as it depends on env
    // }
}

// WRITE MORE GETTER FUNCTIONS IN THE DSCEngine.sol CONTRACT ✅
// WRITE MORE TESTS FOR THE DSCEngine.sol CONTRACT ✅

// I JUST FOUND A BUG WHILE TESTING, THE BUG IS THAT THE CONTRACT ALLOWS US TO LIQUIDATE AN UNAPPROVED COLLATERAL I HAVE FIXED THIS ISSUE IN THE DSCEngine.sol CONTRACT BY ADDING THE NOTALLOWEDTOKEN MODIFIER

// THE TRANSFER FAILED AND MINT FAILED ERROR WOULDN'T HIT
