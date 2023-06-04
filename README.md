<hr/>
<hr/>

<a name="readme-top"></a>

# [Input Control Contract](https://github.com/CarlosAlegreUr/InputControl-SmartContract-DesignPattern)

<hr/>

# Tests and simple implementation for InputControl contract.

Check the contract code here => [(click)](https://github.com/CarlosAlegreUr/InputControl-SmartContract-DesignPattern)

Check the npm repository => [(click)](https://www.npmjs.com/package/input-control-contract)

I asked ChatGPT about it, this was it's answer:

`Overall, the InputControl smart contract looks well-structured and easy to understand. However, there are some areas where improvements could be made to enhance its functionality and usability.`

After showing ChatGPT the UseCaseContract, it answered:

`Based on the presented code, it seems that the previous improvement recommendations are not relevant anymore as they have been addressed in this version of the contract. However, it is always good practice to keep reviewing and improving the code to ensure it is secure and efficient. `

If further elaboration, development or testing please mention me in your work.

😉 https://github.com/CarlosAlegreUr 😉

<hr/>

## 📰 Last Changes 📰

- Fixed bug, inputToTimesToUse mapping now is overwritten correctly. In previous version it could overflow and/or lead to unexpected behaviours.

- Added getIsSequence() function.
- Deleted argument \_isSequence ins getAllowedInputs().
- New tests in tests' repository.

## 🎉 FUTURE IMPROVEMENTS 🎉

- Improve and review code and tests. (static analysis, audit...)

- Test in testnet.
- Create modifier locker. Make it more flexible and be able to activate or deactivate InputControl in your functions.
- Check if worth it to create better option: adding more allowed inputs to client who hasn't used all of them. Now it overwrites.
- Check gas implications of changing 4 bytes function selector to 32 bytes hashed function signatures.

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
