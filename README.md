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

- abi.encodePacked() was fatal error! Same inputs might have the same encoded value. Now using abi.encode().
- Now you can decide wheter a function allows inputs in ordered or unordered manner even after deployment.
- Handle collision with 0 value not needed: now map to bool indicates if input has already been used.
- Better memory management when unordered inputs used.
- Function selectors now are bytes4 instead of strings, like actual func selectors in ETH.
- Shortened variable names in code.
- Tests improved.

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
