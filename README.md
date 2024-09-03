# Bettoken Smart Contract

## Overview

**Bettoken** is a decentralized ERC20 token built on the Ethereum blockchain. It leverages the OpenZeppelin library for security, access control, and standard token functionality. Bettoken is designed to support private sales, pre-sales, and vesting schedules, ensuring a structured and secure token distribution. The contract includes functions for token burning and pausing operations in case of emergencies.

## Features

- **Total Supply:** A fixed total supply of 200,000,000 BETT tokens.
- **Private Sale:** A stage where a limited number of tokens are available at a discounted price.
- **Pre-Sale:** A subsequent stage where more tokens are available, typically at a higher price than the private sale.
- **Vesting:** Tokens allocated to users can be released gradually over a specified period.
- **Burning:** Tokens can be permanently removed from circulation.
- **Pausing:** The contract can be paused during emergencies to prevent critical operations.

## Contract Details

### Prerequisites

To deploy and interact with this contract, you will need:

- **Solidity Version:** `^0.8.6`
- **OpenZeppelin Contracts:** Import the standard library from OpenZeppelin.
- **Chainlink Price Feeds:** For fetching the latest prices during token sales.

### Contract Inheritance

The `Bettoken` contract inherits from the following OpenZeppelin contracts:

1. **ERC20:** Provides the standard ERC20 token functionality.
2. **Ownable:** Ensures that only the owner of the contract can execute certain functions.
3. **ReentrancyGuard:** Prevents reentrancy attacks by ensuring that certain functions cannot be re-entered while they are executing.
4. **Pausable:** Allows the contract to be paused, stopping all operations temporarily.

### Contract Variables

- `TOTAL_SUPPLY`: The total supply of BETT tokens.
- `BURN_ADDRESS`: A predefined address (`0x000000000000000000000000000000000000dEaD`) used for burning tokens.
- `privateSaleTarget`: The target amount of tokens to be sold during the private sale.
- `preSaleTarget`: The target amount of tokens to be sold during the pre-sale.
- `stage`: Tracks the current stage of the sale (Private Sale, Pre-Sale, or None).
- `vestingSchedules`: A mapping to manage vesting schedules for different addresses.
- `priceFeeds`: An array of Chainlink price feed interfaces used to get the latest token prices.

### Functions

#### 1. `constructor(address[] memory _priceFeeds)`

Initializes the Bettoken contract, mints the total supply, and sets up price feeds.

- **_priceFeeds:** An array of addresses for Chainlink price feeds.

#### 2. `getLatestPrice() public view returns (uint256)`

Fetches and calculates the average price from multiple Chainlink oracles.

- **Returns:** The average price from the oracles.

#### 3. `getTotalSupply() external pure returns (uint256)`

Returns the total supply of BETT tokens.

- **Returns:** The total supply of tokens.

#### 4. `startPrivateSale() external onlyOwner`

Initiates the private sale phase. This function can only be called by the contract owner.

#### 5. `startPreSale() external onlyOwner`

Initiates the pre-sale phase after the private sale is completed. This function can only be called by the contract owner.

#### 6. `buyTokens(uint256 usdAmount) external payable nonReentrant whenNotPaused`

Allows users to purchase tokens during the private sale or pre-sale phases.

- **usdAmount:** The amount of USD to be converted into BETT tokens.

#### 7. `calculateTokens(uint256 usdAmount, uint256 startPrice, uint256 endPrice, uint256 soldTokens, uint256 totalTokens) internal pure returns (uint256)`

Calculates the number of tokens a user can purchase based on the amount of USD provided.

- **usdAmount:** The amount of USD used for purchase.
- **startPrice:** The starting price of the token.
- **endPrice:** The ending price of the token.
- **soldTokens:** The number of tokens already sold.
- **totalTokens:** The total number of tokens available for sale.
- **Returns:** The number of tokens that can be purchased.

#### 8. `createVestingSchedule(address beneficiary, uint256 amount, uint256 startTime, uint256 duration, uint256 interval) internal`

Creates a vesting schedule for a beneficiary.

- **beneficiary:** The address receiving the vested tokens.
- **amount:** The total amount of tokens to be vested.
- **startTime:** The time when vesting starts.
- **duration:** The total duration of the vesting.
- **interval:** The interval at which tokens are released.

#### 9. `releaseVestedTokens() external nonReentrant`

Releases vested tokens for the caller based on their vesting schedule.

#### 10. `haltSales() external onlyOwner`

Stops all token sales and pauses the contract.

#### 11. `emergencyWithdraw(address tokenAddress, uint256 amount) external onlyOwner nonReentrant`

Withdraws tokens from the contract in case of an emergency.

- **tokenAddress:** The address of the token to be withdrawn.
- **amount:** The amount of tokens to withdraw.

#### 12. `withdrawFunds() external onlyOwner nonReentrant`

Withdraws the contract's Ether balance to the owner's address.

#### 13. `burn(uint256 amount) external onlyOwner`

Burns a specific amount of tokens from the contract's balance.

- **amount:** The amount of tokens to burn.

#### 14. `burnFrom(address account, uint256 amount) external onlyOwner`

Burns a specific amount of tokens from a specified address.

- **account:** The address from which the tokens will be burned.
- **amount:** The amount of tokens to burn.

#### 15. `burnTokens(uint256 amount) external onlyOwner`

Transfers a specific amount of tokens to the `BURN_ADDRESS`, effectively burning them.

- **amount:** The amount of tokens to transfer to the burn address.

#### 16. `pause() external onlyOwner`

Pauses the contract, disabling critical functions.

#### 17. `unpause() external onlyOwner`

Unpauses the contract, re-enabling critical functions.

#### 18. `fallback() external payable`

Prevents direct Ether transfers to the contract.

#### 19. `receive() external payable`

Prevents direct Ether transfers to the contract.

## Usage

### Deployment

To deploy the contract, you can use a script like `deploy_with_ethers.ts` or manually deploy it using Remix, Truffle, or Hardhat. Ensure that you provide the necessary Chainlink price feed addresses during deployment.

### Minting Tokens

During deployment, the total supply of tokens is minted to the contract itself. No additional minting is allowed after the deployment.

### Token Sales

1. **Private Sale:** Use `startPrivateSale()` to begin the private sale phase.
2. **Pre-Sale:** Use `startPreSale()` after completing the private sale.

Users can purchase tokens during these phases by calling the `buyTokens()` function with the appropriate amount of USD.

### Vesting

Vesting schedules are created automatically when tokens are sold during the private sale. The vesting schedule dictates when and how many tokens the user can claim.

### Burning Tokens

To burn tokens, the owner can call either `burn()` or `burnFrom()` functions. Alternatively, tokens can be transferred to the `BURN_ADDRESS` using `burnTokens()`.

### Emergency Functions

In case of an emergency, the owner can withdraw tokens or Ether from the contract using `emergencyWithdraw()` or `withdrawFunds()`. The contract can also be paused or unpaused using `pause()` and `unpause()`.

## Security Considerations

- **Reentrancy:** The contract uses the `ReentrancyGuard` to protect against reentrancy attacks.
- **Access Control:** The `Ownable` contract ensures that only the owner can execute critical functions.
- **Pausing:** The contract can be paused to prevent operations during emergencies.
- **Price Feeds:** The contract relies on Chainlink oracles for accurate price data during token sales.

## License

This project is licensed under the MIT License. See the [LICENSE](LICENSE) file for details.
