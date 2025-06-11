// SPDX-License-Identifier: MIT

pragma solidity ^0.8.18;

import {Test} from "forge-std/Test.sol";
import {DecentralizedStableCoin} from "src/DecentralizedStableCoin.sol";

contract DecentralizedStableCoinTest is Test {
    DecentralizedStableCoin dsc;
    address owner;
    address user;

    function setUp() public {
        owner = address(this); // the test contract is the owner
        user = makeAddr("user");
        dsc = new DecentralizedStableCoin(owner);
    }

    function testInitialOwnerIsCorrect() public view {
        assertEq(dsc.owner(), owner);
    }

    function testMintFailsIfToZeroAddress() public {
        uint256 mintAmount = 100 ether;

        vm.expectRevert(DecentralizedStableCoin.DecentralizedStableCoin_NotZeroAddress.selector);
        dsc.mint(address(0), mintAmount);
    }

    function testMintFailsIfAmountIsZero() public {
        uint256 mintAmount = 0;

        vm.expectRevert(DecentralizedStableCoin.DecentralizedStableCoin_MustBeMoreThanZero.selector);
        dsc.mint(user, mintAmount);
    }

    function testMintSucceeds() public {
        uint256 mintAmount = 100 ether;

        bool success = dsc.mint(user, mintAmount);

        assertTrue(success);
        assertEq(dsc.balanceOf(user), mintAmount);
    }

    modifier dscMints() {
        uint256 mintAmount = 100 ether;
        dsc.mint(owner, mintAmount);
        _;
    }

    function testBurnFailsIfAmountIsZero() public dscMints {
        uint256 burnAmount = 0;

        vm.expectRevert(DecentralizedStableCoin.DecentralizedStableCoin_MustBeMoreThanZero.selector);
        dsc.burn(burnAmount);
    }

    function testBurnFailsIfAmountExceedsBalance() public dscMints {
        uint256 burnAmount = 200 ether;

        vm.expectRevert(DecentralizedStableCoin.DecentralizedStableCoin_BurnAmountExceedsBalance.selector);
        dsc.burn(burnAmount);
    }

    function testBurnSucceeds() public dscMints {
        uint256 balanceBeforeBurn = dsc.balanceOf(owner);
        uint256 burnAmount = 50 ether;

        dsc.burn(burnAmount);
        assertEq(dsc.balanceOf(owner), balanceBeforeBurn - burnAmount);
    }

    function testOnlyOwnerCanMint() public {
        uint256 mintAmount = 100 ether;

        vm.prank(user);
        vm.expectRevert();
        dsc.mint(user, mintAmount);
    }

    function testOnlyOwnerCanBurn() public {
        uint256 mintAmount = 100 ether;
        uint256 burnAmount = 100 ether;

        dsc.mint(user, mintAmount);
        vm.prank(user);
        vm.expectRevert();
        dsc.burn(burnAmount);
    }
}
