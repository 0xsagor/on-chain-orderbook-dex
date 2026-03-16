// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/utils/ReentrancyGuard.sol";

/**
 * @title OrderbookDEX
 * @dev On-chain matching engine for peer-to-peer ERC20 trading.
 */
contract OrderbookDEX is ReentrancyGuard {
    enum Side { Buy, Sell }

    struct Order {
        uint256 id;
        address trader;
        Side side;
        address tokenAddress;
        uint256 amount;
        uint256 price; // Price in quote token units
        bool isCancelled;
        bool isFilled;
    }

    uint256 public nextOrderId;
    mapping(uint256 => Order) public orders;

    event OrderCreated(uint256 id, address indexed trader, Side side, uint256 amount, uint256 price);
    event OrderMatched(uint256 buyOrderId, uint256 sellOrderId, uint256 amount, uint256 price);
    event OrderCancelled(uint256 id);

    /**
     * @notice Creates a new limit order on the book.
     */
    function createOrder(Side _side, address _token, uint256 _amount, uint256 _price) external {
        require(_amount > 0, "Amount must be > 0");
        require(_price > 0, "Price must be > 0");

        orders[nextOrderId] = Order({
            id: nextOrderId,
            trader: msg.sender,
            side: _side,
            tokenAddress: _token,
            amount: _amount,
            price: _price,
            isCancelled: false,
            isFilled: false
        });

        emit OrderCreated(nextOrderId, msg.sender, _side, _amount, _price);
        nextOrderId++;
    }

    /**
     * @notice Cancels an existing order if not already filled.
     */
    function cancelOrder(uint256 _orderId) external {
        Order storage order = orders[_orderId];
        require(order.trader == msg.sender, "Not your order");
        require(!order.isFilled, "Already filled");
        
        order.isCancelled = true;
        emit OrderCancelled(_orderId);
    }

    /**
     * @notice Matches a buy and sell order.
     * @dev In a production environment, this would be optimized or triggered by off-chain keepers.
     */
    function matchOrders(uint256 _buyOrderId, uint256 _sellOrderId, address _quoteToken) external nonReentrant {
        Order storage buyOrder = orders[_buyOrderId];
        Order storage sellOrder = orders[_sellOrderId];

        require(buyOrder.side == Side.Buy && sellOrder.side == Side.Sell, "Invalid sides");
        require(buyOrder.tokenAddress == sellOrder.tokenAddress, "Token mismatch");
        require(buyOrder.price >= sellOrder.price, "Price mismatch");
        require(!buyOrder.isFilled && !sellOrder.isFilled, "Order already filled");
        require(!buyOrder.isCancelled && !sellOrder.isCancelled, "Order cancelled");

        uint256 matchAmount = buyOrder.amount < sellOrder.amount ? buyOrder.amount : sellOrder.amount;
        uint256 totalQuote = matchAmount * sellOrder.price;

        buyOrder.isFilled = true;
        sellOrder.isFilled = true;

        // Perform settlements
        IERC20 baseToken = IERC20(buyOrder.tokenAddress);
        IERC20 quoteToken = IERC20(_quoteToken);

        // Seller gives Base to Buyer
        require(baseToken.transferFrom(sellOrder.trader, buyOrder.trader, matchAmount), "Base transfer failed");
        // Buyer gives Quote to Seller
        require(quoteToken.transferFrom(buyOrder.trader, sellOrder.trader, totalQuote), "Quote transfer failed");

        emit OrderMatched(_buyOrderId, _sellOrderId, matchAmount, sellOrder.price);
    }
}
