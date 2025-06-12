# DEFI Stablecoin powered by Decentralized Stablecoin Engine (DSCEngine)

[![License: MIT](https://img.shields.io/badge/License-MIT-green.svg)](https://opensource.org/licenses/MIT)

## Overview

The **DSCEngine** is the core smart contract powering a minimalistic decentralized stablecoin system, designed and authored by Kelechi Kizito Ugwu. Additionally, the project built as part of my portfolio, following the Cyfrin Updraft tutorial by Patrick Collins.

This protocol aims to maintain a stablecoin pegged to the US Dollar (1 DSC = \$1), backed by exogenous collateral such as WETH and WBTC, ensuring over-collateralization at all times to guarantee system solvency.

### Key Characteristics:

* **Exogenously Collateralized:** Backed by real assets (e.g., WETH, WBTC).
* **Dollar Pegged:** 1 DSC token is always intended to equal \$1.
* **Algorithmically Stable:** Maintains stability via collateral and minting/burning mechanisms.
* **No Governance & No Fees:** Simplified system focusing on core stablecoin functionality.
* **Inspired by MakerDAO:** Similar in spirit to MakerDAO DSS, but simpler.

---

## Motivation

I built this project to strengthen my understanding of smart contract development, DeFi concepts, and Solidity testing. It’s a hands-on demonstration of a stablecoin backed by collateral with automated liquidation logic. The project follows the Cyfrin Updraft tutorial by Patrick Collins.

---

## Technology Stack

* **Foundry** — Framework for compiling, deploying, and testing Solidity contracts.
* **OpenZeppelin Contracts** — Used for secure and battle-tested ERC-20 token implementations.
* **Chainlink Price Feeds** — Used to obtain decentralized price data to value collateral assets.
* **MockV3Aggregator** — Mock contract simulating Chainlink’s AggregatorV3Interface for testing.

---

## Features

* **Collateral Management:** Users can deposit approved ERC20 tokens(WETH & WBTC) as collateral.
* **Minting & Burning:** Mint DSC tokens against deposited collateral and burn DSC tokens to redeem collateral.
* **Health Factor Enforcement:** Ensures users maintain sufficient collateralization; prevents minting or redemption actions that would break minimum health factors.
* **Liquidation Mechanism:** Allows liquidators to repay under-collateralized users' DSC debt in exchange for collateral plus a liquidation bonus.
* **Price Oracle Integration:** Uses Chainlink price feeds for real-time collateral valuation.
* **Security:** Implements checks-effects-interactions pattern and uses OpenZeppelin’s `ReentrancyGuard`.
* Comprehensive unit and fuzz tests using Foundry

---

## Contract Details

* **Contract Name:** `DSCEngine`
* **Language:** Solidity ^0.8.18
* **Imports:**

  * Chainlink price feeds (`AggregatorV3Interface`)
  * OpenZeppelin `ReentrancyGuard` and `IERC20`
  * Custom `DecentralizedStableCoin` and `OracleLib`

---

## Testing

* Unit tests cover core functionalities.
* Fuzz (invariant) tests ensure the system behaves correctly under a wide range of inputs.
* A MockV3Aggregator contract is used to simulate Chainlink Price Feeds in test environments.

---

## System Architecture

### Core State Variables

* `s_priceFeeds`: Maps approved collateral tokens to their Chainlink price feeds.
* `s_collateralDeposited`: Tracks per-user collateral balances by token.
* `s_DSCMinted`: Tracks DSC minted per user.
* `s_collateralTokens`: Array of all collateral tokens allowed.
* `i_dsc`: Reference to the DSC token contract.

### Important Constants

* `MIN_HEALTH_FACTOR`: Minimum required health factor to avoid liquidation.
* `LIQUIDATION_THRESHOLD`: Percentage used to calculate safe collateralization.
* `LIQUIDATION_BONUS`: Bonus given to liquidators.

### Important Functions

* `depositCollateralAndMintDSCTokens()`: Convenience function to deposit collateral and mint DSC in one call.
* `depositCollateral()`: Deposit ERC20 tokens as collateral.
* `redeemCollateralForDsc()`: Burn DSC and redeem collateral simultaneously.
* `mintDsc()`: Mint DSC tokens if collateralization is sufficient.
* `burnDsc()`: Burn DSC tokens.
* `liquidate()`: Liquidate undercollateralized users, rewarding liquidators with a bonus.
* `getUsdValue()`, `getTokenAmountFromUsd()`: Utility functions for price conversion using oracles.
* Internal functions to enforce health factor and prevent unsafe operations.

---

## External Dependencies

* [OpenZeppelin Contracts](https://github.com/OpenZeppelin/openzeppelin-contracts)
* [Chainlink Contracts](https://github.com/smartcontractkit/chainlink)

---

## Security Considerations

* Health factor is checked and enforced before/after minting, burning, collateral redemption, and liquidation.
* Reentrancy protection via OpenZeppelin's `ReentrancyGuard`.
* Only allowed tokens (with price feeds) can be used as collateral.
* Transfers are checked for success; failures revert transactions.
* Liquidation only possible if user is below minimum health factor.

---

## FlowChart

[FlowChart](Flowchart.png)

---

## Getting Started

### Prerequisites

* Solidity 0.8.18 or compatible compiler
* Chainlink Price Feeds for collateral tokens
* OpenZeppelin Contracts library

### Deployment

1. Deploy the `DecentralizedStableCoin` contract first.
2. Deploy `DSCEngine` with:

   * Array of allowed collateral token addresses.
   * Corresponding Chainlink price feed addresses.
   * Address of the deployed DSC token contract.

### Interaction

* Users deposit collateral, then mint DSC tokens.
* Users maintain their health factor above 1.0 (scaled by 1e18).
* If health factor falls below the minimum, other users can liquidate them.

---

## Usage Example (Pseudocode)

```solidity
// Deposit 10 WETH and mint 100 DSC
dscEngine.depositCollateralAndMintDSCTokens(wethAddress, 10 ether, 100 ether);

// Burn 50 DSC to redeem collateral
dscEngine.burnDsc(50 ether);
dscEngine.redeemCollateral(wethAddress, 5 ether);

// Liquidate a user with debt to cover 100 DSC
dscEngine.liquidate(wethAddress, userAddress, 100 ether);
```

---

## Error Handling

* Reverts if:

  * Amounts are zero.
  * Unsupported tokens used as collateral.
  * Transfers fail.
  * Health factor constraints are violated.
  * Minting or burning fails.
  * Liquidation does not improve user's health factor.

---

## Security Notes

* This project is for learning and portfolio purposes only.
* Not audited for production use.
* Use caution and test extensively before deploying on mainnet.

---

## Contribution

Feel free to fork, raise issues, or submit pull requests! I welcome collaboration and feedback.

---

## License

This project is licensed under the MIT License.

