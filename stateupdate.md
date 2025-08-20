Perfect — here’s your **Solidity State Update Cheat Sheet** 👇
*(keep this open when coding your smart contracts — it will help you write clean, event-emitting contracts)*

---

# 🧾 **Solidity State Update Cheat Sheet**

---

### 1️⃣ ✅ **When you change balances (tokens, ETH, assets)**

| Situation          | Example State Change                                | Event Example                                    |
| ------------------ | --------------------------------------------------- | ------------------------------------------------ |
| Mint tokens        | `totalSupply += amount; balances[to] += amount;`    | `emit Mint(to, amount);`                         |
| Burn tokens        | `totalSupply -= amount; balances[from] -= amount;`  | `emit Burn(from, amount);`                       |
| Transfer tokens    | `balances[from] -= amount; balances[to] += amount;` | `emit Transfer(from, to, amount);`               |
| Withdraw ETH       | `payable(to).transfer(amount);`                     | `emit Withdrawal(to, amount);`                   |
| Deposit collateral | `s_collateralDeposited[user][token] += amount;`     | `emit CollateralDeposited(user, token, amount);` |

---

### 2️⃣ ✅ **When you change ownership or roles**

| Situation             | Example State Change        | Event Example                                    |
| --------------------- | --------------------------- | ------------------------------------------------ |
| Change contract owner | `owner = newOwner;`         | `emit OwnershipTransferred(oldOwner, newOwner);` |
| Add admin/role        | `isAdmin[account] = true;`  | `emit AdminAdded(account);`                      |
| Remove admin/role     | `isAdmin[account] = false;` | `emit AdminRemoved(account);`                    |

---

### 3️⃣ ✅ **When you update key mappings or structs**

| Situation             | Example State Change                   | Event Example                            |
| --------------------- | -------------------------------------- | ---------------------------------------- |
| Update user profile   | `users[user].nickname = nickname;`     | `emit UserUpdated(user, nickname);`      |
| Set approvals         | `allowances[owner][spender] = amount;` | `emit Approval(owner, spender, amount);` |
| Update oracle address | `priceFeeds[token] = feed;`            | `emit PriceFeedUpdated(token, feed);`    |

---

### 4️⃣ ✅ **When you liquidate, redeem or repay**

| Situation         | Example State Change              | Event Example                                                 |
| ----------------- | --------------------------------- | ------------------------------------------------------------- |
| Liquidation       | Reduce debt + transfer collateral | `emit Liquidation(liquidator, borrower, amount, collateral);` |
| Redeem collateral | Reduce user deposits              | `emit CollateralRedeemed(user, token, amount);`               |
| Repay loan        | Reduce debt                       | `emit LoanRepaid(user, amount);`                              |

---

### 5️⃣ ✅ **When you pause or upgrade the contract**

| Situation        | Example State Change                  | Event Example                               |
| ---------------- | ------------------------------------- | ------------------------------------------- |
| Pause contract   | `paused = true;`                      | `emit Paused(msg.sender);`                  |
| Unpause contract | `paused = false;`                     | `emit Unpaused(msg.sender);`                |
| Upgrade logic    | `implementation = newImplementation;` | `emit ContractUpgraded(newImplementation);` |

---

# 🚀 **Golden Rule:**

> **If users, frontends, or indexers might need to know → emit an event.**

---

# 🚫 **When you usually don't need events:**

* Internal calculations only (`uint temp = ...`)
* Pure view function results
* Reverts and require checks

---

✅ **Bonus Tip:**
Events are almost free in gas, but extremely useful for transparency.

---

If you want, I can also give you:

* 🔧 **Event Naming Best Practices**
* 🔧 **Minimal Event Templates**

👉 Just say: *“give me event templates”* and I’ll prepare your Solidity event boilerplate.




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
5. Do Revision From the first Lesson and make sure you understand everything ✅
6. Improve the ReadMe ✅
7. Read the Security Preaparation and understand everything ✅
8. Research Lens protocol
9. Do the Exercises 
10. 