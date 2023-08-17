# [**Input Control Contract**](https://github.com/CarlosAlegreUr/InputControl-SmartContract-DesignPattern)

---

## Tests for the **different InputControl implementations**.

- 📁 Check the contracts' code [here](https://github.com/CarlosAlegreUr/InputControl-SmartContract-DesignPattern)
- 📦 Check the npm repo [here](https://www.npmjs.com/package/input-control-contract)

> 📘 **Note**: If you further elaborate, develop, or test, kindly consider [mentioning me](https://github.com/CarlosAlegreUr) in your work or opening PRs to this repo.

## Types of **InputControls implementations** 👪

<details> <summary> Types Legend ℹ️ </summary>

### Input Control (IC)

#### Owned:

- Inheritance (ICI)
- Composite (ICC)

#### Public:

- Public (ICP)
</details>

---

## **Input Control Current Tests' State** 📡

> **`Legend`**:
>
> 🟢 => High coverage, but there's always room for improvement!
>
> 🔵 => Needs revision, but has high or near high coverage.
>
> 🟡 => Currently being updated.
>
> 🔴 => Yet to be started.

---

| InputControl Implementation | Unit Testing | Fuzz Testing | Invariant Testing | Testnet testing | Audited |
| :-------------------------: | :----------: | :----------: | :---------------: | :-------------: | :-----: |
|             ICI             |      🔵      |      🔴      |        🔴         |       🔴        |   🔴    |
|             ICC             |      🔵      |      🔵      |        🔴         |       🔴        |   🔴    |
|             ICP             |      🟢      |      🟢      |        🟡         |       🔴        |   🔴    |

---

## Last Changes 📰

- 🔄 All code has been **refactored**: Admin based (centralized) or non-admin based (decentralized public infrastructure) versions.
- ✅ New updated **foundry tests** created.

---

## **FUTURE IMPROVEMENTS** 🎉

- Write tests for hash with `bytes32(0)` value. Whether for inputs or permission ids.
- **Test in testnet**.
- Protect against **DoS attacks** by abusing the contract's storage in the public version.
- **Self-audit** with automated tools.
- **Third-party Audit/s**.
- Old hardhat tests might be updated to the refactored code.
- Add new **feature**. Now, if granted new input permissions, old ones get overwritten. Design it so users can modify existing ones without overwriting.

---

## Contact 📨

Carlos Alegre Urquizú - [calegreu@gmail.com](mailto:calegreu@gmail.com)

---

## **Buy me a CryptoCoffee** ☕

Buy me a crypto coffee in ETH, MATIC, or BNB ☕🧐☕ (or any token if you fancy)
`0x2365bf29236757bcfD141Fdb5C9318183716d866`

---

## **License** 📜

Distributed under the MIT License. See [LICENSE](https://github.com/CarlosAlegreUr/InputControl-SmartContract-DesignPattern/blob/main/LICENSE) in the repository for more details.
