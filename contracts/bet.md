# Bettoken Smart Contract

This smart contract implements a token-based **Private Sale** system with **affiliate rewards**, **vesting**, and **staking** mechanisms.

## Table of Contents

- [Overview](#overview)
- [Functions](#functions)
  - [addToWhitelist](#addtowhitelist)
  - [addAffiliate](#addaffiliate)
  - [startPrivateSale](#startprivatesale)
  - [buyTokens](#buytokens)
  - [getPrivateSaleSoldTokens](#getprivatesalesoldtokens)
  - [calculateTokens](#calculatetokens)
  - [createVestingSchedule](#createvestingschedule)
  - [releaseVestedTokens](#releasevestedtokens)
  - [endPrivateSale](#endprivatesale)
  - [setAffiliateRewardPercentage](#setaffiliaterewardpercentage)

---

## Overview

The **Bettoken Smart Contract** is designed to manage a **Private Sale** of tokens, including:
- Whitelisting users to participate in the sale.
- Assigning affiliate codes to users for earning rewards.
- Handling vesting and staking for purchased tokens.
- Dynamic management of affiliate rewards and token distribution.

---

## Functions

### `addToWhitelist`

- **Description**: Adds an address to the whitelist, allowing it to participate in the Private Sale.
- **Input**:
  - `address _address`: The address to be added to the whitelist.
- **Output**: 
  - None. This function executes successfully if the address is added.
- **Security**: Only the contract owner can call this function (`onlyOwner`).

### `addAffiliate`

- **Description**: Assigns an affiliate code to a specified user. The affiliate code must be unique and can only be assigned once per user.
- **Input**:
  - `address user`: The address of the user to whom the affiliate code is assigned.
  - `string calldata code`: The affiliate code to assign (must be unique and not already in use).
- **Output**: 
  - None. The affiliate code is assigned, and the function emits an event.
- **Security**: Only the contract owner can call this function (`onlyOwner`).

### `startPrivateSale`

- **Description**: Starts the Private Sale and sets the affiliate reward percentage.
- **Input**:
  - `uint256 _affiliateRewardPercentage`: The percentage of tokens that affiliates will earn as a reward.
- **Output**: 
  - None. The Private Sale is initiated, and an event is emitted.
- **Security**: Only the contract owner can call this function (`onlyOwner`).

### `buyTokens`

- **Description**: Allows a user to purchase tokens during the Private Sale. Optionally, an affiliate code can be provided to earn affiliate rewards. Purchased tokens are staked for 1 year and vested over 6 months.
- **Input**:
  - `uint256 usdAmount`: The amount in USD to spend on purchasing tokens.
  - `string calldata affiliateCode`: (Optional) The affiliate code, if available.
- **Output**: 
  - None. Tokens are purchased and staked, and events are emitted for the purchase and staking.
- **Security**:
  - The user must be whitelisted.
  - If an affiliate code is provided, it must be valid.

### `getPrivateSaleSoldTokens`

- **Description**: Returns the total number of tokens sold during the Private Sale.
- **Input**:
  - None.
- **Output**:
  - `uint256`: The total number of tokens sold.

### `calculateTokens`

- **Description**: Calculates how many tokens can be purchased with a specified USD amount, based on the token price.
- **Input**:
  - `uint256 usdAmount`: The amount in USD to calculate the token equivalent.
- **Output**:
  - `uint256`: The number of tokens that can be purchased.

### `createVestingSchedule`

- **Description**: Creates a vesting schedule for a user, specifying the total token amount, start time, duration, and interval for release.
- **Input**:
  - `address beneficiary`: The address of the user whose tokens will be vested.
  - `uint256 amount`: The total number of tokens to be vested.
  - `uint256 startTime`: The start time (timestamp) when the vesting begins.
  - `uint256 duration`: The total vesting duration (e.g., 6 months).
  - `uint256 interval`: The interval (e.g., 30 days) for token release.
- **Output**:
  - None. A vesting schedule is created for the user.

### `releaseVestedTokens`

- **Description**: Allows users to claim their vested tokens after the vesting period has started. The tokens are released based on the vesting schedule.
- **Input**:
  - None. The caller's address is used to determine the vested tokens.
- **Output**:
  - None. Vested tokens are released to the caller, and an event is emitted.

### `endPrivateSale`

- **Description**: Ends the Private Sale, preventing further token purchases.
- **Input**:
  - None.
- **Output**:
  - None. The Private Sale is ended, and an event is emitted.
- **Security**: Only the contract owner can call this function (`onlyOwner`).

### `setAffiliateRewardPercentage`

- **Description**: Dynamically sets the affiliate reward percentage for future purchases.
- **Input**:
  - `uint256 _percentage`: The new affiliate reward percentage (between 0 and 100).
- **Output**:
  - None. The affiliate reward percentage is updated.
- **Security**: Only the contract owner can call this function (`onlyOwner`).

---

## Events

- **PrivateSaleStarted(uint256 affiliateRewardPercentage)**: Emitted when the Private Sale is started.
- **PrivateSale(address buyer, uint256 amount)**: Emitted when a user purchases tokens during the Private Sale.
- **AffiliateRewardPaid(address affiliate, uint256 reward)**: Emitted when an affiliate earns a reward for referring a buyer.
- **TokensStaked(address staker, uint256 amount, uint256 releaseTime)**: Emitted when tokens are staked for 1 year.
- **VestedTokensReleased(address beneficiary, uint256 amount)**: Emitted when vested tokens are released to the user.

---

## Security Notes

- **Whitelisting**: Only addresses added by the owner can participate in the Private Sale.
- **Affiliate Codes**: Each affiliate code must be unique and is assigned to only one user.
- **Owner-Only Functions**: Functions related to sale management and affiliate code assignment are restricted to the contract owner.

