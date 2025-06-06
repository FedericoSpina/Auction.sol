# 🧾 Dynamic Auction Smart Contract (with Partial Refunds & Time Extension)

This smart contract implements an advanced **auction system** on Ethereum, featuring:

- Dynamic time extension on late bids
- Minimum 5% bid increment
- Partial refunds of previous bids
- 2% commission to contract owner
- Full bid history tracking and transparency

> Developed and maintained by **Federico S.**

---

## 📌 Key Features

✅ Time auto-extends when a bid is made in the last 10 minutes  
✅ Minimum 5% increment required over the current highest bid  
✅ Bid history is saved and partially refundable  
✅ Auction owner earns 2% commission from the final bid  
✅ Events emitted for frontend integration or logs  

---

## 🔧 Environment

This contract is intended to be used with:

- [Remix IDE](https://remix.ethereum.org)
- [MetaMask](https://metamask.io)
- Ethereum testnet: **Sepolia**
- Solidity version: `^0.8.2`

---

## 📄 Contract Overview

```solidity
constructor(uint256 _durationMinutes)
```

Initializes the auction with a custom duration (in minutes).

```solidity
function bid() external payable
```

Submit a bid. Must be at least 5% higher than the current highest bid.

```solidity
function refundPartial() external
```

Refunds all previous bids (except the latest) for the sender.

```solidity
function endAuction() external
```

Ends the auction, emits the winner, and pays 2% commission to the owner.

```solidity
function withdraw() external
```

Allows non-winning bidders to reclaim their funds **after the auction ends**.

---

## 🧪 Example: Step-by-Step Auction on Sepolia using Remix & MetaMask

### ✅ 1. Compile

- Open [Remix](https://remix.ethereum.org)
- Paste the contract into a new file: `Auction.sol`
- Use **Solidity compiler version 0.8.2 or higher**
- Compile the contract

### 🚀 2. Deploy

- Go to the **Deploy & Run Transactions** tab
- Select **Injected Provider - MetaMask** (make sure you're connected to **Sepolia**)
- Set value for `_durationMinutes`: e.g. `30` (for a 30-minute auction)
- Click **Deploy**

📌 **Example:**

| Field             | Value                       |
|------------------|-----------------------------|
| Network          | Sepolia Testnet             |
| Owner Address    | `0xAbC123...7890`           |
| Duration         | `30` minutes                |
| Contract Address | `0xD3F456...Ef98`           |

---

### 💰 3. Bidding

Call the `bid()` function and send Ether (ETH):

#### Example:

- **User A** (address `0xA111...`) bids `0.5 ETH`
- **User B** must bid at least `0.525 ETH` (5% higher)

Steps:
1. Select address A in MetaMask
2. Enter `0.5` ETH in Remix value field
3. Click `bid`

Next bidder:
1. Select address B
2. Enter `0.525` ETH or more
3. Click `bid`

⏱️ If someone bids within the **last 10 minutes**, the auction auto-extends by 10 minutes.

---

### 🔁 4. Refund Previous Bids

If a bidder places multiple bids, only their last one remains. They can recover earlier bids by calling:

```solidity
refundPartial()
```

👉 Example:  
If you bid `0.5`, then `0.6`, the contract stores `0.5` in your bid history. You can get it back using this function.

---

### 🏁 5. End the Auction

Once time has passed:

```solidity
endAuction()
```

- Only callable after the deadline
- Transfers 2% of the final bid to the owner
- Emits `AuctionEnded` event

---

### 💸 6. Withdraw Funds (non-winners only)

```solidity
withdraw()
```

- Allowed only **after** the auction ends
- **Highest bidder cannot call this**

Other participants can reclaim their current bid using this function.

---

## 📢 Events

| Event Name     | Parameters                             | When Triggered                          |
|----------------|-----------------------------------------|------------------------------------------|
| `NewBid`       | `address bidder, uint256 amount`       | Every time a valid new bid is placed     |
| `AuctionEnded` | `address winner, uint256 amount`       | When `endAuction()` is called            |

---

## 🔐 Security Notes

- Uses `.call{value: amount}("")` for safe ETH transfers
- Re-entrancy safe: state changes happen before transfers
- The highest bidder cannot withdraw to avoid self-refund abuse

---

## 🧾 License

This project is licensed under the [GNU General Public License v3.0](https://www.gnu.org/licenses/gpl-3.0.html)

---

## 🙋 About the Author

**Federico S.**  
Smart Contract Developer & Ethereum Enthusiast  

