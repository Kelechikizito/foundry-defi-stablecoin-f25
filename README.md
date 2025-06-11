1. (Relative Stability) Anchored or Pegged => $1.00
   1. Chainlink Price Feed.
   2. Set a function to exchange ETH & BTC => $$$
2. Stability Mechanism (Minting): Algorithmic (Decentralized)
   1. People can only mint the stablecoin with enough collateral (coded)
3. Collateral: Exogenous (Crypto)
    1. wETH
    2. wBTC

- calculate health factor function
- set health factor if debt is 0
- Added a bunch of view/getter functions

1. What are our invariants/properties?
   
1. Some proper oracle use ✅
2. Write more tests, incoming
   1. DecentralizedStableCoin Test ✅
   2. 
3. Fix the price drop invariant test ✅
4. Find ways to improve the project
   1. Gas Optmization ✅
   2. Fallback and Receieve functions? ✅
   3. Chainlink Network Downtime ✅
   4. Are there any fallback mechanisms, manual interventions, or pause functionalities for Chainlink Downtimes
      1. Add Fallback Oracles
      2. Implement a Pause Mechanism
      3. Test Downtime Scenarios
      4. Dynamic Timeout Adjustment ✅
      5. Price Deviation Checks
   5. Dectralized Governance Model ✅
5. Do Revision From the first Lesson and make sure you understand everything
6. Check out Lens Protocol
7. Improve the ReadMe
8. Read the Security Preaparation and understand everything
9.  Research Lens protocol
10. Smart Contract Audit Preparation
11. Do the Exercises