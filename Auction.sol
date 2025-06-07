// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.7.0 <0.9.0;

/**
 * @title Auction
 * @author Federico S.
 * @notice A feature-rich and secure auction smart contract that fulfills the homework requirements.
 * It includes a 5% minimum bid increment, dynamic auction time extension, and a safe withdrawal
 * mechanism for outbid participants (fulfilling the partial refund requirement).
 */
contract Auction {
    //===========
    // State Variables
    //===========

    /// @notice The address that will receive the final auction proceeds (the contract deployer).
    address public immutable beneficiary;

    /// @notice The timestamp when the auction is scheduled to end.
    uint256 public auctionEndTime;

    /// @notice The address of the current highest bidder.
    address public highestBidder;

    /// @notice The amount of the current highest bid.
    uint256 public highestBid;

    /// @notice A mapping that stores the amounts available for withdrawal for each address.
    /// When a bidder is outbid, their previous bid is added to this mapping.
    mapping(address => uint256) public pendingReturns;

    /// @notice A boolean flag to indicate if the auction has been officially ended.
    bool public auctionEnded;

    //============
    // Constants
    //============

    uint256 public constant BID_INCREMENT_PERCENTAGE = 5;
    uint256 public constant TIME_EXTENSION_MINUTES = 10 minutes;
    uint256 public constant COMMISSION_PERCENTAGE = 2;

    //===========
    // Events
    //===========

    /// @notice Emitted when a new valid bid is placed.
    event NewBid(address indexed bidder, uint256 amount);

    /// @notice Emitted when the auction is successfully finalized.
    event AuctionEnded(address winner, uint256 amount);

    /// @notice Emitted when a user withdraws their pending funds.
    event Withdrawal(address indexed withdrawer, uint256 amount);

    //===========
    // Modifiers
    //===========

    /// @notice Checks if the auction is still ongoing.
    modifier auctionIsActive() {
        require(block.timestamp < auctionEndTime, "Auction is not active.");
        _;
    }

    /// @notice Checks if the scheduled auction time has passed.
    modifier auctionTimeHasPassed() {
        require(
            block.timestamp >= auctionEndTime,
            "Auction has not ended yet."
        );
        _;
    }

    /// @notice Checks if the auction has not already been finalized.
    modifier auctionNotEnded() {
        require(!auctionEnded, "The auction has already been finalized.");
        _;
    }

    /// @notice Checks if the caller is the beneficiary of the auction.
    modifier onlyBeneficiary() {
        require(
            msg.sender == beneficiary,
            "Only the beneficiary can call this function."
        );
        _;
    }

    //================
    // Core Functions
    //================

    /**
     * @notice Initializes the auction with a beneficiary (the contract deployer) and a duration.
     * @param _biddingTimeMinutes The duration of the auction in minutes.
     */
    constructor(uint256 _biddingTimeMinutes) {
        beneficiary = msg.sender;
        auctionEndTime = block.timestamp + (_biddingTimeMinutes * 1 minutes);
    }

    /**
     * @notice Allows a user to place a bid by sending Ether to the contract.
     * It enforces the 5% minimum increment and the time extension rule.
     */
    function bid() external payable auctionIsActive auctionNotEnded {
        // --- Checks ---
        // Calculate the minimum required bid. For the first bid, any amount is valid.
        uint256 minBid = (highestBid == 0)
            ? 1
            : highestBid + ((highestBid * BID_INCREMENT_PERCENTAGE) / 100);

        require(msg.value >= minBid, "Bid is not high enough.");

        // --- Effects ---
        // If there was a previous bidder, their bid becomes available for withdrawal.
        if (highestBidder != address(0)) {
            pendingReturns[highestBidder] += highestBid;
        }

        // Update the state with the new highest bidder and bid.
        highestBidder = msg.sender;
        highestBid = msg.value;

        // If the bid was placed in the last 10 minutes, extend the auction time.
        if (auctionEndTime - block.timestamp < TIME_EXTENSION_MINUTES) {
            auctionEndTime += TIME_EXTENSION_MINUTES;
        }

        // --- Interaction ---
        emit NewBid(highestBidder, highestBid);
    }

    /**
     * @notice Finalizes the auction after the end time has passed.
     * It calculates the commission and transfers the final amount to the beneficiary.
     * This function can be called by anyone.
     */
    function endAuction()
        external
        auctionTimeHasPassed
        auctionNotEnded
        onlyBeneficiary
    {
        // --- Effects ---
        auctionEnded = true;

        // --- Interaction ---
        if (highestBidder != address(0)) {
            // Calculate the 2% commission.
            uint256 commission = (highestBid * COMMISSION_PERCENTAGE) / 100;
            uint256 amountToBeneficiary = highestBid - commission;

            // Transfer the funds to the beneficiary.
            (bool success, ) = beneficiary.call{value: amountToBeneficiary}("");
            require(success, "Transfer to beneficiary failed.");
        }

        emit AuctionEnded(highestBidder, highestBid);
    }

    /**
     * @notice Allows users (both losing bidders and bidders who re-bid) to withdraw their funds.
     * This function fulfills the "partial refund" requirement in a secure way.
     */
    function withdraw() external {
        // --- Checks ---
        uint256 amount = pendingReturns[msg.sender];
        require(amount > 0, "You have no funds to withdraw.");

        // --- Effects ---
        // Set the pending return to 0 BEFORE the transfer to prevent reentrancy attacks.
        pendingReturns[msg.sender] = 0;

        // --- Interaction ---
        // Send the funds back to the user.
        (bool success, ) = payable(msg.sender).call{value: amount}("");
        require(success, "Withdrawal failed.");

        emit Withdrawal(msg.sender, amount);
    }

    //================
    // View Functions
    //================

    /**
     * @return winner The address of the highest bidder.
     * @return amount The value of the highest bid.
     */
    function getWinner()
        external
        view
        returns (address winner, uint256 amount)
    {
        return (highestBidder, highestBid);
    }

    /**
     * @notice Returns the address of the bidders and their offers values.
     * @dev To avoid high gas costs, this contract does not store a dynamic array of all bidders.
     * A frontend application should build the list of bidders by listening to the `NewBid` events.
     * The `pendingReturns` mapping can be queried to see funds available for withdrawal for any address.
     */
    function getAuctionDetails()
        external
        view
        returns (
            address _beneficiary,
            uint256 _auctionEndTime,
            address _highestBidder,
            uint256 _highestBid,
            bool _auctionEnded
        )
    {
        return (
            beneficiary,
            auctionEndTime,
            highestBidder,
            highestBid,
            auctionEnded
        );
    }
}
