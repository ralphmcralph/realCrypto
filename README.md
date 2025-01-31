# RealCrypto ERC-20 Token

![Solidity](https://img.shields.io/badge/Solidity-0.8.24-blue?style=flat&logo=solidity)
![License](https://img.shields.io/badge/License-LGPL--3.0--only-green?style=flat)
![ERC20](https://img.shields.io/badge/Standard-ERC20-orange?style=flat)

RealCrypto is an ERC-20 token that implements transaction fees and automatic fund distribution. It includes a reward system for holders and a burn mechanism for controlled deflation.

## 🚀 Features

- 🔗 **ERC-20 Standard Compliance** based on OpenZeppelin.
- ⚙️ **Dynamic Fee System** with configurable fees for buy, sell, and transfer transactions.
- 💰 **Automatic Fee Distribution** among holders, liquidity, and burning.
- 🔥 **Burn Mechanism** to reduce circulating supply.
- 🛡️ **Fee Exclusion List** for privileged addresses.
- 🏦 **Wallet Management** for treasury and fee accumulation.

---

## 📜 Technical Specifications

- **Language:** Solidity `0.8.24`
- **Framework:** OpenZeppelin
- **Initial Supply:** `1,000,000,000` tokens
- **Default Fees:**
  - 🛒 **Transfer & Buy:** `1%`
  - 💸 **Sell:** `5%`
- **Fee Distribution:**
  - 🎁 `30%` to holders
  - 🔥 `30%` burned
  - 🌊 `40%` to liquidity

---

## 📂 Contract Structure

```solidity
contract RealCrypto is ERC20, Ownable
```
### 🔹 Main Variables
- `sellFee` → Sell fee (5%)
- `transferFee` → Buy/transfer fee (1%)
- `treasuryWallet` → Treasury address
- `feesWallet` → Wallet where fees accumulate
- `isExcludedFromFees` → Mapping for fee exclusion
- `holderList` → Dynamic list of active holders
- `accumulationPeriod` → Fee accumulation period (`7 days`)

### 🔹 Key Events
- `TransferWithFee` → Emitted when a transfer includes a fee
- `FeesCollected` → Emitted when fees are collected
- `FeesDistributed` → Emitted when accumulated funds are distributed

---

## 📌 Functionality

### 📤 Transfers with Fees

Transfers apply a dynamic fee based on whether the transaction is a buy, sell, or simple transfer. The fee is redirected to the `feesWallet`.

```solidity
function transfer(address recipient, uint256 amount) public override returns (bool)
```

### 🏦 Fee Distribution

Accumulated fees are automatically distributed among holders, burning, and liquidity every `7 days`.

```solidity
function distributeFees() external onlyOwner
```

### 📜 Holder Management

The contract maintains a dynamic list of holders and updates the list based on balances.

```solidity
function _updateHolders(address sender, address recipient) internal
```

---

## 📜 License
This project is licensed under **LGPL-3.0-only**.

