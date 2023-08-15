<hr/>
<hr/>

<a name="readme-top"></a>

# [Input Control Contract](https://github.com/CarlosAlegreUr/InputControl-SmartContract-DesignPattern)

<hr/>

# Tests for the different InputControl implementations.

Check the contract code here => [(click)](https://github.com/CarlosAlegreUr/InputControl-SmartContract-DesignPattern)

Check the npm repository => [(click)](https://www.npmjs.com/package/input-control-contract)

If further elaboration, development or testing please mention me in your work or open PRs to this repo.

😉 https://github.com/CarlosAlegreUr 😉

## Types of InputControls implementations:

**Input Control (IC)**

### Owned:

- **Inheritance (ICI)**
- **Composite (ICC)**

### Public:

- **Global (ICP)**

---

## Input Control Tests State:

> **Legend:**
>
> 🟢 => Done, high coverage, feel free to improve though
>
> 🔵 => Done, but not revised, coverage high
>
> 🟡 => Updating
>
> 🔴 => Not even started

---

| **InputControl Implementation** | **Unit Testing** | **Fuzz Testing** | **Invariant Testing** | **Testnet testing** | **Audited** |
| ------------------------------- | ---------------- | ---------------- | --------------------- | ------------------- | ----------- |
| ICI                             | 🔵               | 🔴               | 🔴                    | 🔴                  | 🔴          |
| ICC                             | 🔵               | 🔴               | 🔴                    | 🔴                  | 🔴          |
| ICP                             | 🟢               | 🟢               | 🟡                    | 🔴                  | 🔴          |

<hr/>

## 📰 Last Changes 📰

- Admin based (centralized) or nor admin based (decentralized) version are in develompent. All code has been refactored, old hardhat test should eventually be refactored too. New updated foundry tests exits though.

## 🎉 FUTURE IMPROVEMENTS 🎉

- Test in testnet.

- Write tests for hash with bytes32(0) value. Wheter for inputs or permissions ids.

- 1 Fuzz test not passing, check it out.

- Add new feature. Now if granted new input permissions, old ones get overwritten. Make it so user can add or
  remove existing ones without overwriting.

- Protect agains DoS attacks by abusing the contract's storage in the public version.

- Self-audit with automated tools.

- Audit.

## 📨 Contact 📨

Carlos Alegre Urquizú - calegreu@gmail.com

<hr/>

## ☕ Buy me a CryptoCoffee ☕

Buy me a crypto coffe in ETH, MATIC or BNB ☕🧐☕
(or tokens if you please :p )

0x2365bf29236757bcfD141Fdb5C9318183716d866

<hr/>

## 📜 License 📜

Distributed under the MIT License. See [LICENSE](https://github.com/CarlosAlegreUr/InputControl-SmartContract-DesignPattern/blob/main/LICENSE) in the repository for more information.

([back to top](#🙀-the-problem-🙀))
