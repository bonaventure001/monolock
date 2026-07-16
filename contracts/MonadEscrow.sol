// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/utils/ReentrancyGuard.sol";

/// @title MonadEscrow
/// @notice Time-based escrow. Buyer deposits MON (native) or an ERC20 token for a seller.
///         Funds auto-release to the seller once `releaseTime` passes, UNLESS either party
///         raises a dispute first — in which case funds are only released once both parties
///         agree on a split.
/// @dev    THIS IS AN MVP TEMPLATE FOR TESTNET USE. Get it professionally audited before
///         holding real client funds on mainnet.
contract MonadEscrow is ReentrancyGuard {
    using SafeERC20 for IERC20;

    enum Status { Active, Disputed, Resolved }

    struct Escrow {
        address buyer;
        address seller;
        address token;         // address(0) = native MON
        uint256 amount;
        uint256 releaseTime;   // timestamp after which funds auto-release to seller
        Status status;
        uint16 proposedBuyerBps; // last proposed buyer share, in basis points (0-10000)
        address proposer;        // who made the last proposal
    }

    uint256 public escrowCount;
    mapping(uint256 => Escrow) public escrows;

    event EscrowCreated(uint256 indexed id, address indexed buyer, address indexed seller, address token, uint256 amount, uint256 releaseTime);
    event Released(uint256 indexed id, address to, uint256 amount);
    event DisputeRaised(uint256 indexed id, address by);
    event SplitProposed(uint256 indexed id, address by, uint16 buyerBps);
    event SplitAccepted(uint256 indexed id, uint16 buyerBps, uint256 buyerAmount, uint256 sellerAmount);

    modifier onlyParty(uint256 id) {
        require(msg.sender == escrows[id].buyer || msg.sender == escrows[id].seller, "not a party to this escrow");
        _;
    }

    /// @notice Create and fund a new escrow.
    /// @param seller Who receives the funds if all goes normally.
    /// @param token  address(0) for native MON, otherwise an ERC20 token address (e.g. USDC).
    /// @param amount Amount to escrow. For native MON, msg.value must equal this.
    /// @param releaseTime Unix timestamp after which anyone can trigger release() to the seller.
    function createEscrow(
        address seller,
        address token,
        uint256 amount,
        uint256 releaseTime
    ) external payable nonReentrant returns (uint256 id) {
        require(seller != address(0) && seller != msg.sender, "invalid seller");
        require(releaseTime > block.timestamp, "release time must be in the future");
        require(amount > 0, "amount required");

        if (token == address(0)) {
            require(msg.value == amount, "MON sent must match amount");
        } else {
            require(msg.value == 0, "do not send MON for token escrows");
            IERC20(token).safeTransferFrom(msg.sender, address(this), amount);
        }

        id = escrowCount++;
        escrows[id] = Escrow({
            buyer: msg.sender,
            seller: seller,
            token: token,
            amount: amount,
            releaseTime: releaseTime,
            status: Status.Active,
            proposedBuyerBps: 0,
            proposer: address(0)
        });

        emit EscrowCreated(id, msg.sender, seller, token, amount, releaseTime);
    }

    /// @notice Anyone can call this once releaseTime has passed, if no dispute was raised.
    function release(uint256 id) external nonReentrant {
        Escrow storage e = escrows[id];
        require(e.status == Status.Active, "escrow not active");
        require(block.timestamp >= e.releaseTime, "too early");

        e.status = Status.Resolved;
        _payout(e.token, e.seller, e.amount);
        emit Released(id, e.seller, e.amount);
    }

    /// @notice Either party can freeze auto-release before releaseTime if something's wrong.
    function raiseDispute(uint256 id) external onlyParty(id) {
        Escrow storage e = escrows[id];
        require(e.status == Status.Active, "escrow not active");
        require(block.timestamp < e.releaseTime, "already past release time, call release()");

        e.status = Status.Disputed;
        emit DisputeRaised(id, msg.sender);
    }

    /// @notice Either party proposes how to split the funds (in basis points to the buyer).
    ///         e.g. buyerBps = 5000 means 50% back to buyer, 50% to seller.
    function proposeSplit(uint256 id, uint16 buyerBps) external onlyParty(id) {
        Escrow storage e = escrows[id];
        require(e.status == Status.Disputed, "escrow not disputed");
        require(buyerBps <= 10000, "invalid bps");

        e.proposedBuyerBps = buyerBps;
        e.proposer = msg.sender;
        emit SplitProposed(id, msg.sender, buyerBps);
    }

    /// @notice The OTHER party accepts the pending proposal, executing the split immediately.
    function acceptSplit(uint256 id) external onlyParty(id) nonReentrant {
        Escrow storage e = escrows[id];
        require(e.status == Status.Disputed, "escrow not disputed");
        require(e.proposer != address(0), "no proposal pending");
        require(e.proposer != msg.sender, "cannot accept your own proposal");

        uint256 buyerAmount = (e.amount * e.proposedBuyerBps) / 10000;
        uint256 sellerAmount = e.amount - buyerAmount;

        e.status = Status.Resolved;

        if (buyerAmount > 0) _payout(e.token, e.buyer, buyerAmount);
        if (sellerAmount > 0) _payout(e.token, e.seller, sellerAmount);

        emit SplitAccepted(id, e.proposedBuyerBps, buyerAmount, sellerAmount);
    }

    function getEscrow(uint256 id) external view returns (Escrow memory) {
        return escrows[id];
    }

    function _payout(address token, address to, uint256 amount) internal {
        if (token == address(0)) {
            (bool ok, ) = to.call{value: amount}("");
            require(ok, "native transfer failed");
        } else {
            IERC20(token).safeTransfer(to, amount);
        }
    }
}
