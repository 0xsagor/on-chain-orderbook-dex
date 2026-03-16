# On-Chain Orderbook DEX

A professional-grade Decentralized Exchange (DEX) using an orderbook model. Unlike AMMs, this repository implements a limit-order system directly on-chain, allowing for precise price discovery and professional trading features.

### Features
* **Limit Orders**: Users can specify exact prices for buy and sell orders.
* **Order Management**: Robust functions to cancel active orders before they are filled.
* **Partial Fills**: Logic to handle orders that are only partially matched by the engine.
* **Atomic Settlement**: Instant swapping of assets once a match is found, ensuring no counterparty risk.

### How to Use
1. Deploy `OrderbookDEX.sol`.
2. Traders must `approve` the DEX to spend their Base and Quote tokens.
3. Call `createOrder` with the desired side (Buy/Sell), amount, and price.
4. Use `matchOrders` to execute trades between compatible buy and sell requests.
