# 10101.art Smart Contracts

A blockchain platform for fractional ownership of valuable physical artworks, making art investment transparent, secure, and accessible to a wider audience on BNB Smart Chain (BSC) and other EVM-compatible networks.

## Technology Stack

- **Blockchain**: BNB Smart Chain + EVM-compatible chains
- **Smart Contracts**: Solidity ^0.8.9
- **Frontend**: React + wagmi
- **Backend**: Node.js + web3.js
- **Development**: Hardhat, OpenZeppelin libraries

## Supported Networks

- **BNB Smart Chain Mainnet** (Chain ID: 56)
- **BNB Smart Chain Testnet** (Chain ID: 97)
- **Ethereum Mainnet** (Chain ID: 1)

## Contract Addresses

| Network  | Core Contract                              | Token Contract |
|----------|--------------------------------------------|----------------|
| BNB Mainnet | -                                          | 0x3626b74E1d3D5EB0c362c77B915a8718bD1D05E3 |
| BNB Testnet | -                                          | 0x131e44193f59feeE1635e3624CCeBe939B5521E2 |
| Ethereum    | 0xc7CcB2FF8b44aa249F5c8459372f8CFd77384108 | 0xd003945c9003b96Ea8d50862EA4bB7ec70051c31 |

## Features

- Whitelists for transfers and sales
- Collection can be sold through proxy-contracts for different currencies or directly from the core contract and backend
- Most of the errors based on codes instead of strings to save gas and contract size
- Mint can be paused and unpaused by the owner or admin
- Additional features for RWA assets (e.g., physical artwork) management

## Licensing
- This project is licensed under the MIT License. This means you are free to use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of the code, provided that the original copyright notice and permission notice are included in all copies or substantial portions of the code.
- This project uses OpenZeppelin Contracts which are licensed under the MIT License and remain subject to their respective terms.

This code is provided "as is", without warranty of any kind — express or implied — including but not limited to the warranties of merchantability, fitness for a particular purpose, and non-infringement. Use at your own risk. We take no responsibility for any damages, loss of funds, bugs, exploits, or misuse that may result from the use, deployment, or interaction with these smart contracts.
These smart contracts have not undergone a formal third-party security audit. They are published for transparency, educational purposes, and community review. Before using in production or deploying on mainnet, we highly recommend conducting your own thorough audit and legal due diligence.
