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
