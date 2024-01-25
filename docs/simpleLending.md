# SimpleSwap

This is a simple lending contract for testing the functionality of Mantle Sepolia testnet.

## Introduction

Firstly, we need to prepare two accounts. The first account will be used as the lending depositor. The second account
will be used as the lending borrower.

In this contract, we only support same token lending and borrowing, which means the deposit token and borrow token
should be the same. And we don't set the interest rate and repay period.

The depositor will deposit the deposit token to the lending contract. The borrower will borrow the borrow token from the
lending contract, and whenever the borrower wants to repay the borrow token, he will repay the borrow token from the
lending contract.

## How to run it

1. Install dependencies

```bash
bun install
```

2. Complete the configuration of the script

```bash
cp .env.example .env
```

Then fill your config with your own values.

3. Run the script

```bash
./script/simpleSwap.sh
```
