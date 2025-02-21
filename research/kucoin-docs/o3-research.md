Understood. I will conduct deep research on the KuCoin API, covering all available endpoints, authentication details, request structures, response formats, rate limits, error codes, WebSocket API, and any specific implementation details such as clock synchronization and data precision recommendations. The final deliverable will be a single, comprehensive document formatted to serve as developer documentation, suitable for building a wrapper package for programmatic access. 

I'll update you once the research is complete and the document is ready.

# KuCoin API – Developer Guide

## Complete List of Endpoints

**Spot (Exchange) REST API** – KuCoin’s Spot API includes public market data endpoints and private endpoints for accounts and trading operations. Key endpoint categories include: 

- **Accounts & Wallet** – Manage accounts and funds. Endpoints exist to get account balances, account details, and ledgers (transaction history) for main, trading, margin, and high-frequency (HF) accounts ([Get Account List - Spot/Margin/trade_hf | KuCoin API Documentation](https://www.kucoin.com/docs/rest/account/basic-info/get-account-list-spot-margin-trade_hf#:~:text=Param%20Type%20Mandatory%20Description%20currency,String%20No%20Account%20type%20main%E3%80%81trade%E3%80%81margin%E3%80%81trade_hf)) ([Get Account List - Spot/Margin/trade_hf | KuCoin API Documentation](https://www.kucoin.com/docs/rest/account/basic-info/get-account-list-spot-margin-trade_hf#:~:text=balance%20Total%20funds%20in%20the,not%20available%20for%20use)). There are endpoints to create and retrieve deposit addresses, query deposit history, and manage withdrawals (get withdrawal quotas, list withdrawals, apply or cancel withdrawal) ([Spot Trading | KuCoin API Documentation](https://www.kucoin.com/docs/websocket/spot-trading/public-channels/ticker#:~:text=,%5BImage%2021%5D%20Withdrawals)) ([Spot Trading | KuCoin API Documentation](https://www.kucoin.com/docs/websocket/spot-trading/public-channels/ticker#:~:text=,%5BImage%2022%5D%20Transfer)). Transfers between accounts (e.g. main to trading) or to sub-accounts are also supported ([Spot Trading | KuCoin API Documentation](https://www.kucoin.com/docs/websocket/spot-trading/public-channels/ticker#:~:text=)).  
- **Market Data (Public)** – Retrieve market information without authentication. Endpoints provide currency info and symbol details, price tickers, order books, trade history, klines (candlesticks), 24-hour stats, fiat prices, server time, etc. ([Spot Trading | KuCoin API Documentation](https://www.kucoin.com/docs/websocket/spot-trading/public-channels/ticker#:~:text=)) ([Spot Trading | KuCoin API Documentation](https://www.kucoin.com/docs/websocket/spot-trading/public-channels/ticker#:~:text=,Get%20Service%20Status)). For example, you can list all trading pairs (`GET /api/v1/symbols`), get the order book (`GET /api/v1/market/orderbook/level2`), or fetch all market tickers (`GET /api/v1/market/allTickers`) ([Spot Trading | KuCoin API Documentation](https://www.kucoin.com/docs/websocket/spot-trading/public-channels/ticker#:~:text=)) ([Get All Tickers | KuCoin API Documentation](https://www.kucoin.com/docs/rest/spot-trading/market-data/get-all-tickers#:~:text=)). These endpoints do not require an API key.  
- **Trading (Private)** – Place and manage orders on the spot (and margin) market. Endpoints exist to **place orders** (regular or test mode), **cancel orders** (by order ID or client order ID), **batch cancel** all or multiple orders, and query order status or list orders ([Spot Trading | KuCoin API Documentation](https://www.kucoin.com/docs/websocket/spot-trading/public-channels/ticker#:~:text=,Get%20Order%20Details%20by%20orderId)) ([Spot Trading | KuCoin API Documentation](https://www.kucoin.com/docs/websocket/spot-trading/public-channels/ticker#:~:text=,%5BImage%2028%5D%20Fills)). High-frequency trading (HF) accounts have specialized order endpoints for extremely low-latency order placement and cancellation ([Spot Trading | KuCoin API Documentation](https://www.kucoin.com/docs/websocket/spot-trading/public-channels/ticker#:~:text=,Cancel%20HF%20order%20by%20orderId)) ([Spot Trading | KuCoin API Documentation](https://www.kucoin.com/docs/websocket/spot-trading/public-channels/ticker#:~:text=,HF%20order%20details%20by%20clientOid)). Separate sets of endpoints handle **stop orders** and **OCO (one-cancels-other) orders** for conditional trading ([Spot Trading | KuCoin API Documentation](https://www.kucoin.com/docs/websocket/spot-trading/public-channels/ticker#:~:text=)) ([Spot Trading | KuCoin API Documentation](https://www.kucoin.com/docs/websocket/spot-trading/public-channels/ticker#:~:text=)). Trade fills (executions) can be retrieved with endpoints for fill history ([Spot Trading | KuCoin API Documentation](https://www.kucoin.com/docs/websocket/spot-trading/public-channels/ticker#:~:text=)). (All these require authentication with Spot Trading permissions.)  
- **Margin Trading** – Similar to spot trading, with additional endpoints for margin-specific actions. You can borrow and repay funds, query interest rates, and get margin account info ([Spot Trading | KuCoin API Documentation](https://www.kucoin.com/docs/websocket/spot-trading/public-channels/ticker#:~:text=)). Endpoints cover both cross and isolated margin configuration and interest records ([Spot Trading | KuCoin API Documentation](https://www.kucoin.com/docs/websocket/spot-trading/public-channels/ticker#:~:text=,Image%2035%5D%20Isolated%20Margin)) ([Spot Trading | KuCoin API Documentation](https://www.kucoin.com/docs/websocket/spot-trading/public-channels/ticker#:~:text=,Image%2037%5D%20Lending%20Market%28V3)). (Margin endpoints generally require the Margin Trading permission.)  
- **Futures REST API** – KuCoin’s Futures API (separate base URL) provides analogous endpoints for futures trading:  
  - **Futures Market Data** (Public) – Endpoints to list futures contracts, get contract details, fetch the ticker for a contract, or get aggregated market data. For example: list all symbols (`GET /api/v1/contracts/active`), get a contract’s ticker, Level-2 order book (full depth or top 20/100 entries), recent trades, klines, 24h volume, index price, mark price, and funding rate history ([Spot Trading | KuCoin API Documentation](https://www.kucoin.com/docs/websocket/spot-trading/public-channels/ticker#:~:text=)) ([Spot Trading | KuCoin API Documentation](https://www.kucoin.com/docs/websocket/spot-trading/public-channels/ticker#:~:text=,%5BImage%2040%5D%20Orders)). These require no auth and are IP rate-limited similar to spot public endpoints.  
  - **Futures Trading** (Private) – Endpoints to place futures orders (limit or market), including test orders, and place or cancel stop (take-profit/stop-loss) orders ([Spot Trading | KuCoin API Documentation](https://www.kucoin.com/docs/websocket/spot-trading/public-channels/ticker#:~:text=,213)) ([Spot Trading | KuCoin API Documentation](https://www.kucoin.com/docs/websocket/spot-trading/public-channels/ticker#:~:text=,%5BImage%2041%5D%20Fills)). You can batch cancel orders, list open orders, query order details (by ID or client ID), and list fills ([Spot Trading | KuCoin API Documentation](https://www.kucoin.com/docs/websocket/spot-trading/public-channels/ticker#:~:text=,%5BImage%2041%5D%20Fills)) ([Spot Trading | KuCoin API Documentation](https://www.kucoin.com/docs/websocket/spot-trading/public-channels/ticker#:~:text=,%5BImage%2042%5D%20Positions)). There are also endpoints to query and modify positions (e.g. get current positions, add/remove margin, set auto-deposit margin, adjust leverage) ([Spot Trading | KuCoin API Documentation](https://www.kucoin.com/docs/websocket/spot-trading/public-channels/ticker#:~:text=)) ([Spot Trading | KuCoin API Documentation](https://www.kucoin.com/docs/websocket/spot-trading/public-channels/ticker#:~:text=,Image%2043%5D%20Risk%20Limit)), as well as to get the account’s overall futures account balance and transaction history ([Spot Trading | KuCoin API Documentation](https://www.kucoin.com/docs/websocket/spot-trading/public-channels/ticker#:~:text=)). (These require Futures Trading permissions on your API key.)  
  - **Futures Account & Risk** – Additional endpoints allow querying the futures account overview, transferring funds to/from the futures account (via the main account endpoints), and checking **risk limits** and setting the risk limit level for contracts ([Spot Trading | KuCoin API Documentation](https://www.kucoin.com/docs/websocket/spot-trading/public-channels/ticker#:~:text=)) ([Spot Trading | KuCoin API Documentation](https://www.kucoin.com/docs/websocket/spot-trading/public-channels/ticker#:~:text=,Image%2044%5D%20Funding%20Fees)). Funding fee history and the current funding rate can also be retrieved ([Spot Trading | KuCoin API Documentation](https://www.kucoin.com/docs/websocket/spot-trading/public-channels/ticker#:~:text=)).  

**WebSocket API** – KuCoin offers WebSocket feeds for real-time updates, with separate channels for spot, margin, and futures data: 

- **Spot WebSocket (Public)** – Public **market data streams** include: ticker updates for individual symbols, a combined feed of all tickers, snapshot data for a symbol or the entire market, best bid/ask (Level 1) updates, full order book depth (Level 2) updates, L2 incremental feeds (e.g. top 50 orders), recent trade executions, and candlestick updates ([Spot Trading | KuCoin API Documentation](https://www.kucoin.com/docs/websocket/spot-trading/public-channels/ticker#:~:text=,Klines)) ([Spot Trading | KuCoin API Documentation](https://www.kucoin.com/docs/websocket/spot-trading/public-channels/ticker#:~:text=%2A%20Level2%20,Image%2059%5D%20Private%20Channels)). For example, subscribing to the `/market/ticker` topic for `BTC-USDT` delivers live price updates.  
- **Spot WebSocket (Private)** – Private authenticated channels deliver user-specific updates. You can subscribe to receive **order updates** (execution reports) for your trades – for instance, order confirmations, fills, cancellations (on either the original “v1” or an enhanced “v2” order event feed) ([Spot Trading | KuCoin API Documentation](https://www.kucoin.com/docs/websocket/spot-trading/public-channels/ticker#:~:text=,Stop%20Order%20Event)) ([Spot Trading | KuCoin API Documentation](https://www.kucoin.com/docs/websocket/spot-trading/public-channels/ticker#:~:text=,285)). There are also channels for **account balance changes** (e.g. deposits/withdrawals or funds held for orders) and **stop order triggers** ([Spot Trading | KuCoin API Documentation](https://www.kucoin.com/docs/websocket/spot-trading/public-channels/ticker#:~:text=,Stop%20Order%20Event)) ([Spot Trading | KuCoin API Documentation](https://www.kucoin.com/docs/websocket/spot-trading/public-channels/ticker#:~:text=,Stop%20Order%20Event)). These require an authorized WebSocket connection (with your API key credentials).  
- **Futures WebSocket (Public)** – Real-time futures market data channels include: ticker feeds (there are v2 and v1 versions of the ticker channel) ([Spot Trading | KuCoin API Documentation](https://www.kucoin.com/docs/websocket/spot-trading/public-channels/ticker#:~:text=)) ([Spot Trading | KuCoin API Documentation](https://www.kucoin.com/docs/websocket/spot-trading/public-channels/ticker#:~:text=,299)), Level 2 order book updates (full order book and top 5/50 depth), trade feeds (match execution data), candlesticks, and contract market statistics (like 24h volume) ([Spot Trading | KuCoin API Documentation](https://www.kucoin.com/docs/websocket/spot-trading/public-channels/ticker#:~:text=,299)) ([Spot Trading | KuCoin API Documentation](https://www.kucoin.com/docs/websocket/spot-trading/public-channels/ticker#:~:text=%2A%20Level2%20,Image%2065%5D%20Private%20Channels)). There are also periodic event streams, such as the funding rate settlement updates and 24h turnover statistics ([Spot Trading | KuCoin API Documentation](https://www.kucoin.com/docs/websocket/spot-trading/public-channels/ticker#:~:text=%2A%20Level2%20,Image%2065%5D%20Private%20Channels)) ([Spot Trading | KuCoin API Documentation](https://www.kucoin.com/docs/websocket/spot-trading/public-channels/ticker#:~:text=,Image%2065%5D%20Private%20Channels)).  
- **Futures WebSocket (Private)** – Authenticated futures channels provide your **order updates** (separate channels for different order types or market vs stop orders) ([Spot Trading | KuCoin API Documentation](https://www.kucoin.com/docs/websocket/spot-trading/public-channels/ticker#:~:text=)) ([Spot Trading | KuCoin API Documentation](https://www.kucoin.com/docs/websocket/spot-trading/public-channels/ticker#:~:text=,Account%20Balance%20Events)), **account balance changes**, and **position changes** in real-time ([Spot Trading | KuCoin API Documentation](https://www.kucoin.com/docs/websocket/spot-trading/public-channels/ticker#:~:text=)). These let a trading application track fill events, position updates, liquidation warnings, etc., instantly. (As with spot, you must connect with a token obtained using your API credentials to subscribe to private topics.)

All REST endpoints are documented with their HTTP method and path (e.g. `GET /api/v1/..., POST /api/v1/...`), and WebSocket channels are identified by topic strings. The above is a high-level overview; for a **complete detailed list**, refer to KuCoin’s official API reference which enumerates every endpoint in each category ([Spot Trading | KuCoin API Documentation](https://www.kucoin.com/docs/websocket/spot-trading/public-channels/ticker#:~:text=)) ([Spot Trading | KuCoin API Documentation](https://www.kucoin.com/docs/websocket/spot-trading/public-channels/ticker#:~:text=)).

## Request Details (Methods, Headers, Auth, Body)

All REST API calls are made via HTTPS requests. Each endpoint specifies an HTTP method (`GET`, `POST`, `DELETE`, etc.), the request path, and what headers or body data are required. For example, a typical order placement uses `POST /api/v1/orders` ([Orders | KuCoin API Documentation](https://www.kucoin.com/docs/rest/spot-trading/orders/place-order#:~:text=)), whereas fetching market data like tickers might use `GET` requests. 

**Base URLs** – The base URL for Spot (including margin and spot HF) REST endpoints is `https://api.kucoin.com`, while Futures REST endpoints use `https://api-futures.kucoin.com` ([Base URL | KuCoin API Documentation](https://www.kucoin.com/docs/basic-info/base-url#:~:text=,com)). The path shown in documentation (e.g. `/api/v1/orders`) should be appended to the appropriate base URL. (KuCoin also offers a sandbox base URL for testing ([Base URL | KuCoin API Documentation](https://www.kucoin.com/docs/basic-info/base-url#:~:text=)), and a separate base for broker API, not covered here.)

**HTTP Headers** – For **authenticated requests** (those that require an API key, i.e. most private endpoints like account info or order placement), you must include the following headers: 

- `KC-API-KEY`: Your API key.  
- `KC-API-SIGN`: The request signature (a HMAC SHA256 digest, base64-encoded – see **Authentication** below for how to generate).  
- `KC-API-TIMESTAMP`: A Unix timestamp (in milliseconds) of the request moment ([Types | KuCoin API Documentation](https://www.kucoin.com/docs/basic-info/connection-method/types/timestamps#:~:text=The%20KC,1547015186532)).  
- `KC-API-PASSPHRASE`: The API passphrase (encrypted if using API key version 2.0 or above).  
- `KC-API-KEY-VERSION`: The version of your API key (e.g. `"2"` for the current version) ([Signing a Message | KuCoin API Documentation](https://www.kucoin.com/docs/basic-info/connection-method/authentication/signing-a-message#:~:text=passphrase%20%3D%20base64.b64encode%28hmac.new%28api_secret.encode%28%27utf,VERSION%22%3A%20%222)).  
- `Content-Type`: Must be `application/json` for endpoints that have a JSON request body (e.g. POST calls) ([Spot Errors Code | KuCoin API Documentation](https://www.kucoin.com/docs/errors-code/spot-errors-code#:~:text=400800%20Leverage%20order%20failed%20411100,is%20not%20enabled%20for%20trading)). 

Public endpoints (like market data GET calls) do **not** require the API key or signature headers. However, even for public POST endpoints (if any) you should set `Content-Type: application/json`. Omitting the correct content type or using an unsupported format will result in a `415 Unsupported Media Type` error ([Errors Code | KuCoin API Documentation](https://www.kucoin.com/docs/errors-code/http-errors-code#:~:text=405%20Method%20Not%20Allowed%20,Try%20again%20later)) ([Spot Errors Code | KuCoin API Documentation](https://www.kucoin.com/docs/errors-code/spot-errors-code#:~:text=400800%20Leverage%20order%20failed%20411100,is%20not%20enabled%20for%20trading)).

**Request Body and Parameters** – GET requests encode parameters in the query string (e.g. `?symbol=BTC-USDT`). POST/PUT requests expect a JSON body. The KuCoin API documentation specifies the fields and types for each endpoint’s parameters. For instance, placing a limit order (`POST /api/v1/orders`) requires a JSON body with fields like `clientOid` (a unique client order ID), `side` (`buy` or `sell`), `symbol`, `type`, and price/size for limit orders ([Orders | KuCoin API Documentation](https://www.kucoin.com/docs/rest/spot-trading/orders/place-order#:~:text=Param%20Type%20Mandatory%20Description%20clientOid,trading%20%3A%20TRADE%EF%BC%88Spot%20Trade%EF%BC%89%2C%20MARGIN_TRADE)) ([Orders | KuCoin API Documentation](https://www.kucoin.com/docs/rest/spot-trading/orders/place-order#:~:text=,Orders)). Optional fields can be included as needed (e.g. `remark`, `timeInForce`). When sending numeric values, **use strings for numbers to preserve precision** (see **Data Formatting** below) – this is recommended by KuCoin ([Numbers | KuCoin API Documentation](https://www.kucoin.com/docs/basic-info/connection-method/types/numbers#:~:text=Decimal%20numbers%20are%20returned%20as,avoid%20truncation%20and%20precision%20errors)). 

**Authentication requirements** – Each private endpoint also defines which API key permission is needed. For example, order placement requires the “Trade” permission on the key (Spot or Futures as appropriate) ([Orders | KuCoin API Documentation](https://www.kucoin.com/docs/rest/spot-trading/orders/place-order#:~:text=)), while accessing account balances may require the “General” (read) permission ([Get Account List - Spot/Margin/trade_hf | KuCoin API Documentation](https://www.kucoin.com/docs/rest/account/basic-info/get-account-list-spot-margin-trade_hf#:~:text=)). Ensure your API key is created with the proper permissions for the endpoints you plan to use.

## Response Details (Format and Fields)

KuCoin’s REST API responses are returned in JSON with a consistent envelope structure. A successful HTTP 200 response will contain a JSON object with: 

- **`code`** – A string code `"200000"` indicating success ([Success response | KuCoin API Documentation](https://www.kucoin.com/docs/basic-info/connection-method/request/success-response#:~:text=A%20successful%20response%20is%20indicated,success%20response%20is%20as%20follows)).  
- **`data`** – The result payload, which can be an object, array, or value depending on the endpoint. For example, a successful response for getting server time looks like: 

```json
{
  "code": "200000",
  "data": 1546837113087
}
``` 

Here, `data` is a timestamp in milliseconds ([Get Server Time | KuCoin API Documentation](https://www.kucoin.com/docs/rest/spot-trading/market-data/get-server-time#:~:text=)). If the endpoint returns more complex data (e.g. a list of objects), the `data` field will usually contain an object or array. For instance, fetching account list returns `data` as an array of account objects ([Get Account List - Spot/Margin/trade_hf | KuCoin API Documentation](https://www.kucoin.com/docs/rest/account/basic-info/get-account-list-spot-margin-trade_hf#:~:text=%5B%20%7B%20,assets%20of%20a%20currency)) ([Get Account List - Spot/Margin/trade_hf | KuCoin API Documentation](https://www.kucoin.com/docs/rest/account/basic-info/get-account-list-spot-margin-trade_hf#:~:text=,%7D)), and getting all tickers returns `data` with a time and a `ticker` array of symbols ([Get All Tickers | KuCoin API Documentation](https://www.kucoin.com/docs/rest/spot-trading/market-data/get-all-tickers#:~:text=%7B%20,%2F%2F%20bestBid)) ([Get All Tickers | KuCoin API Documentation](https://www.kucoin.com/docs/rest/spot-trading/market-data/get-all-tickers#:~:text=,currency%20of%20last%2024%20hours)).

In case of an error or failed request, the API will typically return a non-200 HTTP status and a JSON body with: 

- **`code`** – An error code (not `"200000"`). KuCoin defines both HTTP-level error codes and application-specific error codes. For example, a missing parameter might return HTTP 400 with code `"400100"`, and a message explaining the error ([Error response | KuCoin API Documentation](https://www.kucoin.com/docs/basic-info/connection-method/request/error-response#:~:text=When%20errors%20occur%2C%20the%20HTTP,message%20parameter%20indicating%20the%20cause)).  
- **`msg`** – A text message describing the error ([Error response | KuCoin API Documentation](https://www.kucoin.com/docs/basic-info/connection-method/request/error-response#:~:text=When%20errors%20occur%2C%20the%20HTTP,message%20parameter%20indicating%20the%20cause)). For instance, an invalid request might yield: 

```json
{
  "code": "400100",
  "msg": "Invalid Parameter."
}
``` 

Some error responses (especially for trading requests) might include additional fields, but generally `code` and `msg` are present to interpret the error.

**Common response fields** – Many data responses share common field names. For example, most market data objects have a `symbol`, and account balances have `balance`, `available`, and `holds` fields to indicate total, available, and held funds ([Get Account List - Spot/Margin/trade_hf | KuCoin API Documentation](https://www.kucoin.com/docs/rest/account/basic-info/get-account-list-spot-margin-trade_hf#:~:text=,)) ([Get Account List - Spot/Margin/trade_hf | KuCoin API Documentation](https://www.kucoin.com/docs/rest/account/basic-info/get-account-list-spot-margin-trade_hf#:~:text=,%7D)). Order-related responses often return an `orderId` (KuCoin’s order identifier) when an order is successfully placed ([Orders | KuCoin API Documentation](https://www.kucoin.com/docs/rest/spot-trading/orders/place-order#:~:text=)). The documentation for each endpoint describes the response JSON structure in detail. 

**Pagination** – When an endpoint returns a potentially large list (e.g. trade history or ledgers), the response may include pagination info such as `currentPage`, `pageSize`, and `totalNum`, or a `hasMore` flag ([Base URL | KuCoin API Documentation](https://www.kucoin.com/docs/basic-info/base-url#:~:text=,Image%209%5D%20Pager)). Follow the documentation’s guidance on how to request subsequent pages (often via query params like `currentPage` or by using the `currentPage` value from the response). KuCoin’s API also sometimes uses a `next` cursor or `hasMore` boolean for pagination on certain endpoints ([Base URL | KuCoin API Documentation](https://www.kucoin.com/docs/basic-info/base-url#:~:text=)).

## Authentication and Security

KuCoin uses API keys to authenticate requests. You need to create an API key on KuCoin’s website, which will provide: an **API Key**, an **API Secret**, and an **API Passphrase** (the passphrase is defined by you when creating the key). The API Secret is used for signing requests and should **never** be shared. The passphrase is required as an extra security measure.

**API Key Permissions** – When creating a key, you can assign permissions (e.g. General, Trade, Withdraw) and optionally bind IP addresses. **IP whitelisting** is highly recommended – if an API request comes from a non-whitelisted IP, it will be rejected (`400006` error code for IP not in whitelist) ([Spot Errors Code | KuCoin API Documentation](https://www.kucoin.com/docs/errors-code/spot-errors-code#:~:text=400002%20KC,Denied%20404000%20Url%20Not%20Found)). Ensure your key has the proper permissions: for example, a trading bot needs the “Trade” permission to place orders, and a read-only dashboard might only need “General” (for account info). KuCoin also supports separate keys for Spot and Futures; some keys can have combined permissions, but often you may create distinct keys for each platform (the API will reject a Spot-only key on a Futures endpoint and vice versa).

**Signature Generation** – For each private REST request, you must generate a signature and include it in the `KC-API-SIGN` header. The signature is a HMAC SHA256 of a **prehash string** composed of:  

```
timestamp + HTTP_METHOD + requestPath + requestBody
``` 

concatenated in that order ([Signing a Message | KuCoin API Documentation](https://www.kucoin.com/docs/basic-info/connection-method/authentication/signing-a-message#:~:text=%2A%20Use%20API,result%20in%20step%201%20again)) ([Signing a Message | KuCoin API Documentation](https://www.kucoin.com/docs/basic-info/connection-method/authentication/signing-a-message#:~:text=%24what%20%3D%20%24timestamp%20,%24body)). 

- The `timestamp` is the same value you put in `KC-API-TIMESTAMP` (in milliseconds).  
- `HTTP_METHOD` is the uppercase method (`GET`, `POST`, etc.).  
- `requestPath` is the endpoint path (include the query string for GET/DELETE requests if any) ([Signing a Message | KuCoin API Documentation](https://www.kucoin.com/docs/basic-info/connection-method/authentication/signing-a-message#:~:text=,typically%20for%20GET%20requests)). Example: `/api/v1/deposit-addresses?currency=BTC`.  
- `requestBody` is the exact JSON string being sent (for GET requests with no body, this is an empty string).  

Using your API Secret as the HMAC key, compute HMAC SHA256 on the prehash string, then Base64-encode the result ([Signing a Message | KuCoin API Documentation](https://www.kucoin.com/docs/basic-info/connection-method/authentication/signing-a-message#:~:text=For%20the%20header%20of%20KC)). The output is your `KC-API-SIGN`. **Important:** The timestamp must be in sync with KuCoin’s server time (within a few seconds) – see **Clock Synchronization** below – or you may get an invalid signature or timestamp error (`400002` or `400005`) ([Spot Errors Code | KuCoin API Documentation](https://www.kucoin.com/docs/errors-code/spot-errors-code#:~:text=400001%20Any%20of%20KC,api%20whitelist%20400007%20Access%20Denied)).

**Passphrase** – The `KC-API-PASSPHRASE` header is the API passphrase you set. For API Key version 2.0 and above, KuCoin requires this passphrase to be encrypted with your API Secret as well ([Signing a Message | KuCoin API Documentation](https://www.kucoin.com/docs/basic-info/connection-method/authentication/signing-a-message#:~:text=%2A%20For%20API%20key,before%20you%20pass%20the%20request)). The encryption method is the same HMAC SHA256 + Base64 process (using the API Secret to HMAC the passphrase) ([Signing a Message | KuCoin API Documentation](https://www.kucoin.com/docs/basic-info/connection-method/authentication/signing-a-message#:~:text=%2A%20For%20API%20key,before%20you%20pass%20the%20request)). The header should contain the Base64-encoded result. (If your key is older version 1.0, the passphrase can be sent plaintext, but most keys are version 2 or 3 now – specify the version via `KC-API-KEY-VERSION` header accordingly ([Signing a Message | KuCoin API Documentation](https://www.kucoin.com/docs/basic-info/connection-method/authentication/signing-a-message#:~:text=%2A%20For%20API%20key,Encrypt)) ([Signing a Message | KuCoin API Documentation](https://www.kucoin.com/docs/basic-info/connection-method/authentication/signing-a-message#:~:text=%22KC,specifying%20content%20type%20or)).)

**Secure Practices** – Treat your API Secret like a password: store it securely (not in code repositories) and do not transmit it except to sign requests. Use the IP whitelist feature to restrict where the key can be used ([Spot Errors Code | KuCoin API Documentation](https://www.kucoin.com/docs/errors-code/spot-errors-code#:~:text=400002%20KC,api%20whitelist%20400007%20Access%20Denied)). Never expose your key or secret in client-side code. If possible, assign keys with the minimum required permissions (e.g. a key for market data that doesn’t need trading permission). KuCoin also allows setting a **passphrase** separate from your login, which adds security – keep this passphrase safe as it’s required for API calls. If an unauthorized request is made with your key (e.g. wrong passphrase or bad signature), KuCoin will respond with errors like `KC-API-PASSPHRASE error` (`400004`) or `Signature error` (`400005`) ([Spot Errors Code | KuCoin API Documentation](https://www.kucoin.com/docs/errors-code/spot-errors-code#:~:text=400001%20Any%20of%20KC,Denied%20404000%20Url%20Not%20Found)). These are indicators to check your signing logic and credentials. 

## Rate Limits and Throttling

KuCoin enforces rate limits on API requests to ensure fair use of resources. The limits are defined in terms of **“requests per unit time”** or a weight system, and they vary based on the API endpoint and the user’s account tier (VIP level). Developers should design their API wrapper to respect these limits to avoid HTTP 429 **Too Many Requests** errors or temporary bans.

**Weight and Tier System** – Each API request has a weight (cost). Users are allowed a certain total weight in a rolling time window (usually per 30 seconds) ([Basic Info | KuCoin API Documentation](https://www.kucoin.com/docs/basic-info/request-rate-limit/rest-api#:~:text=If%20the%20quota%20of%20any,reset%20before%20continuing%20to%20access)). For a regular user (VIP0), the limit for Spot API is 4000 points per 30 seconds, and for Futures API 2000 points/30s ([Basic Info | KuCoin API Documentation](https://www.kucoin.com/docs/basic-info/request-rate-limit/rest-api#:~:text=Level%20Spot%20Futures%20Management%20Public,23000%2F30s%2010000%2F30s%2010000%2F30s%202000%2F30s%202000%2F30s)). Higher VIP levels have higher quotas. For example, VIP1 allows 6000/30s for Spot, VIP2 8000/30s, etc., up to VIP12 with 40000/30s ([Basic Info | KuCoin API Documentation](https://www.kucoin.com/docs/basic-info/request-rate-limit/rest-api#:~:text=Level%20Spot%20Futures%20Management%20Public,23000%2F30s%2010000%2F30s%2010000%2F30s%202000%2F30s%202000%2F30s)). Some endpoint calls have higher weight than 1. For instance, placing an order might cost 2 points of the Spot quota ([Basic Info | KuCoin API Documentation](https://www.kucoin.com/docs/basic-info/request-rate-limit/rest-api#:~:text=When%20the%20user%27s%20VIP%20is,of%2016000%2F30s)). The KuCoin documentation typically notes the “Request rate limit (weight)” for each endpoint. For example, fetching server time has a public weight of 3 ([Get Server Time | KuCoin API Documentation](https://www.kucoin.com/docs/rest/spot-trading/market-data/get-server-time#:~:text=)), and placing a standard order might have a weight of 2 for Spot ([Orders | KuCoin API Documentation](https://www.kucoin.com/docs/rest/spot-trading/orders/place-order#:~:text=)).

**429 Responses** – If you exceed the allowed request quota in the time window, the API will respond with HTTP 429. The JSON error will have an error code `429000` indicating rate limit exceeded ([Basic Info | KuCoin API Documentation](https://www.kucoin.com/docs/basic-info/request-rate-limit/rest-api#:~:text=If%20the%20quota%20of%20any,reset%20before%20continuing%20to%20access)). The response headers will include `Retry-After` or reset information. In fact, KuCoin’s API provides specific headers in **every response** to help you track your usage: 

- `gw-ratelimit-limit` – The total allowed requests (weight) in the current window ([Basic Info | KuCoin API Documentation](https://www.kucoin.com/docs/basic-info/request-rate-limit/rest-api#:~:text=,milliseconds)).  
- `gw-ratelimit-remaining` – How many points remain in your quota for this window ([Basic Info | KuCoin API Documentation](https://www.kucoin.com/docs/basic-info/request-rate-limit/rest-api#:~:text=%22gw)).  
- `gw-ratelimit-reset` – Milliseconds until the quota resets (new window starts) ([Basic Info | KuCoin API Documentation](https://www.kucoin.com/docs/basic-info/request-rate-limit/rest-api#:~:text=%22gw)).  

Your wrapper should read these headers. When `remaining` goes low or zero, you should back off until after the `reset` time. If a 429 error is received, inspect the headers to know when it’s safe to retry ([Basic Info | KuCoin API Documentation](https://www.kucoin.com/docs/basic-info/request-rate-limit/rest-api#:~:text=If%20the%20quota%20of%20any,reset%20before%20continuing%20to%20access)) (the API might also include a `Retry-After` header in seconds).

**Public vs Private Limits** – KuCoin has separate rate limiting for public (unauthenticated) requests and private (authenticated) requests. Public endpoints are limited per IP address. The **“Public weight”** quota is smaller (e.g. 50 or 60 requests per 10 seconds for some public endpoints) and is shared across all public calls from that IP ([Basic Info | KuCoin API Documentation](https://www.kucoin.com/docs/basic-info/request-rate-limit/rest-api#:~:text=,avoid%20IP%20rate%20limit%20issues)). If your application needs high-frequency market data, KuCoin **recommends using WebSocket** streams rather than repeatedly polling REST endpoints ([Basic Info | KuCoin API Documentation](https://www.kucoin.com/docs/basic-info/request-rate-limit/rest-api#:~:text=,avoid%20IP%20rate%20limit%20issues)). You can also distribute requests across multiple IPs or use a server with multiple network interfaces if you approach the public IP limit ([Basic Info | KuCoin API Documentation](https://www.kucoin.com/docs/basic-info/request-rate-limit/rest-api#:~:text=,avoid%20IP%20rate%20limit%20issues)). Private endpoint limits are tied to your account and API key, and are categorized by Spot, Futures, etc., as described above.

**Throttling Strategy** – To handle rate limits gracefully: 

- **Use WebSockets for real-time data**: Instead of REST polling for price updates or order book changes, subscribe to WebSocket feeds (which do not consume the REST rate limit). This is especially useful for high-frequency or low-latency data needs ([Basic Info | KuCoin API Documentation](https://www.kucoin.com/docs/basic-info/request-rate-limit/rest-api#:~:text=,avoid%20IP%20rate%20limit%20issues)).  
- **Batch requests when possible**: KuCoin provides batch endpoints (e.g. place multiple orders in one call ([Spot Trading | KuCoin API Documentation](https://www.kucoin.com/docs/websocket/spot-trading/public-channels/ticker#:~:text=,all%20HF%20orders%20by%20symbol)), cancel multiple orders). Using these can be more efficient than many single calls.  
- **Monitor headers**: As mentioned, check `gw-ratelimit-remaining`. Your wrapper can dynamically slow down requests if the remaining quota is low, instead of continuing until a hard failure.  
- **Backoff on 429**: If you do hit a 429 error, implement an exponential backoff or wait until the reset time indicated by `gw-ratelimit-reset` before retrying. Do not spam retries as that could extend the ban.  
- **Optimize usage**: Avoid unnecessary calls. For example, instead of polling an order status every second, consider waiting for a WebSocket order update or using a reasonable interval. Use specific endpoints rather than general ones if possible (for instance, there’s an endpoint to get a single order by ID – use it rather than pulling your entire order list). 

By adhering to these practices, you can stay within KuCoin’s limits and maintain smooth API interactions.

## Error Codes and Troubleshooting

KuCoin’s API returns error codes to indicate what went wrong with a request. There are two layers of error codes: **HTTP status codes** and KuCoin-specific **business error codes** (returned in the JSON response `code` field). The HTTP code gives a broad indication (e.g. 400 for bad request, 401 for unauthorized, 403 for forbidden, etc.), while the `code` in the JSON provides a specific error number and the `msg` provides details.

**HTTP-Level Errors:** Common HTTP responses include: 

- `400 Bad Request` – The request is malformed or invalid ([Errors Code | KuCoin API Documentation](https://www.kucoin.com/docs/errors-code/http-errors-code#:~:text=Code%20Meaning%20400%20Bad%20Request,24)) (e.g. missing required parameters, invalid JSON format).  
- `401 Unauthorized` – API key is missing or incorrect ([Errors Code | KuCoin API Documentation](https://www.kucoin.com/docs/errors-code/http-errors-code#:~:text=Code%20Meaning%20400%20Bad%20Request,24)). You’ll get this if you forgot to send authentication headers or if they are wrong.  
- `403 Forbidden` – The request was understood but refused. This can happen if your API key doesn’t have permission for that endpoint, or if you hit rate limits (“Too Many Requests”) ([Errors Code | KuCoin API Documentation](https://www.kucoin.com/docs/errors-code/http-errors-code#:~:text=400%20Bad%20Request%20,24)). KuCoin uses 403 for both permission issues and for exceeding rate limits ([Errors Code | KuCoin API Documentation](https://www.kucoin.com/docs/errors-code/http-errors-code#:~:text=400%20Bad%20Request%20,24)). The response body and code will clarify which it is (e.g. `400007 Access Denied` vs. a 429000 code).  
- `404 Not Found` – The endpoint URL is incorrect ([Errors Code | KuCoin API Documentation](https://www.kucoin.com/docs/errors-code/http-errors-code#:~:text=403%20Forbidden%20or%20Too%20Many,Try%20again%20later)) (check if you spelled the path right or used the correct base URL).  
- `405 Method Not Allowed` – You tried to use the wrong HTTP method (e.g. POST on an endpoint that expects GET) ([Errors Code | KuCoin API Documentation](https://www.kucoin.com/docs/errors-code/http-errors-code#:~:text=limit%20breached%20,Try%20again%20later)).  
- `415 Unsupported Media Type` – Content-Type is not `application/json` for a request with a body ([Errors Code | KuCoin API Documentation](https://www.kucoin.com/docs/errors-code/http-errors-code#:~:text=405%20Method%20Not%20Allowed%20,Try%20again%20later)). Ensure you set the header and format the JSON correctly.  
- `500 Internal Server Error` – A server-side problem at KuCoin ([Errors Code | KuCoin API Documentation](https://www.kucoin.com/docs/errors-code/http-errors-code#:~:text=method,Try%20again%20later)). Rare, but you should retry after a brief wait.  
- `503 Service Unavailable` – The system is down or in maintenance ([Errors Code | KuCoin API Documentation](https://www.kucoin.com/docs/errors-code/http-errors-code#:~:text=500%20Internal%20Server%20Error%20,Try%20again%20later)). You should try again later if you see this.

**KuCoin API Error Codes:** In the JSON response, the `code` field (when not 200000) provides a specific error identifier. Some common codes and their meanings: 

- `400001` – Required header missing (one of `KC-API-KEY`, `KC-API-SIGN`, `KC-API-TIMESTAMP`, or `KC-API-PASSPHRASE` was not sent) ([Spot Errors Code | KuCoin API Documentation](https://www.kucoin.com/docs/errors-code/spot-errors-code#:~:text=260210%20withdraw.disabled%20,not%20in%20the%20api%20whitelist)).  
- `400002` – Invalid `KC-API-TIMESTAMP` (likely your timestamp is outside the allowed range or not in milliseconds) ([Spot Errors Code | KuCoin API Documentation](https://www.kucoin.com/docs/errors-code/spot-errors-code#:~:text=400001%20Any%20of%20KC,not%20in%20the%20api%20whitelist)). This often means your system clock is too far from KuCoin’s time – see **Clock Synchronization**.  
- `400003` – `KC-API-KEY` not exists (the API key is wrong, maybe a typo or you’re using the wrong environment) ([Spot Errors Code | KuCoin API Documentation](https://www.kucoin.com/docs/errors-code/spot-errors-code#:~:text=400001%20Any%20of%20KC,not%20in%20the%20api%20whitelist)). Ensure you’re using the correct key for the domain (sandbox vs production, spot vs futures).  
- `400004` – API passphrase error (passphrase is incorrect or not properly encrypted) ([Spot Errors Code | KuCoin API Documentation](https://www.kucoin.com/docs/errors-code/spot-errors-code#:~:text=400002%20KC,not%20in%20the%20api%20whitelist)). Double-check your passphrase and encryption method.  
- `400005` – Signature error (the `KC-API-SIGN` does not match) ([Spot Errors Code | KuCoin API Documentation](https://www.kucoin.com/docs/errors-code/spot-errors-code#:~:text=400002%20KC,not%20in%20the%20api%20whitelist)). This means the signature you generated is wrong – likely an error in constructing the prehash string or using the wrong secret. Recompute and compare.  
- `400006` – The IP address is not in the API whitelist ([Spot Errors Code | KuCoin API Documentation](https://www.kucoin.com/docs/errors-code/spot-errors-code#:~:text=400002%20KC,api%20whitelist%20400007%20Access%20Denied)). Your key is IP-restricted and your request came from a non-approved IP. Use an allowed IP or update the key’s whitelist (not via API, but in the web UI).  
- `400007` – Access Denied (perhaps your API key status is suspended or your account is banned) ([Spot Errors Code | KuCoin API Documentation](https://www.kucoin.com/docs/errors-code/spot-errors-code#:~:text=400004%20KC,api%20whitelist%20400007%20Access%20Denied)). Contact KuCoin support if you believe your key should be active.  
- `400100` – Parameter error ([Spot Errors Code | KuCoin API Documentation](https://www.kucoin.com/docs/errors-code/spot-errors-code#:~:text=404000%20Url%20Not%20Found%20400100,risk%20problem%20in%20your%20account)). The `msg` will usually specify which parameter is wrong. For example, you might see a message about an insufficient balance (`account.available.amount -- Insufficient balance` is sometimes returned with code 400100 as well ([Spot Errors Code | KuCoin API Documentation](https://www.kucoin.com/docs/errors-code/spot-errors-code#:~:text=404000%20Url%20Not%20Found%20400100,risk%20problem%20in%20your%20account))). This code is a generic bad-input error for request params.  
- `404000` – URL not found ([Spot Errors Code | KuCoin API Documentation](https://www.kucoin.com/docs/errors-code/spot-errors-code#:~:text=400006%20The%20requested%20ip%20address,Insufficient%20balance)). Similar to HTTP 404, indicates the endpoint path is wrong.  
- `411100` – User frozen ([Spot Errors Code | KuCoin API Documentation](https://www.kucoin.com/docs/errors-code/spot-errors-code#:~:text=400700%20Transaction%20restricted%2C%20there%27s%20a,the%20request%20header%20needs%20to)). This implies the user/account is frozen (perhaps for security reasons). API access might be blocked.  
- `500000` – Internal server error on KuCoin’s side ([Spot Errors Code | KuCoin API Documentation](https://www.kucoin.com/docs/errors-code/spot-errors-code#:~:text=400800%20Leverage%20order%20failed%20411100,application%2Fjson%20500000%20Internal%20Server%20Error)). This corresponds to a 500 status. Usually transient.  
- `200000` – (Not an error) Success code ([Success response | KuCoin API Documentation](https://www.kucoin.com/docs/basic-info/connection-method/request/success-response#:~:text=A%20successful%20response%20is%20indicated,success%20response%20is%20as%20follows)). Included here for completeness: any code other than 200000 should be treated as an error.

KuCoin’s documentation provides separate lists for spot, margin, futures, etc. errors ([Orders | KuCoin API Documentation](https://www.kucoin.com/docs/rest/spot-trading/orders/place-order#:~:text=)) ([Spot Errors Code | KuCoin API Documentation](https://www.kucoin.com/docs/errors-code/spot-errors-code#:~:text=Spot%20Errors%20Code)). In general, the codes above cover many common cases. When troubleshooting, pay attention to both the `code` and `msg`. The `msg` is often very descriptive (e.g. “Order size exceeded” or “Symbol not exist”). 

**Debug Tips:** If you encounter errors: 

- For auth issues (`40000X` codes), log the exact string you signed and the headers you sent (except the secret). Compare your signature generation step with KuCoin’s example ([Signing a Message | KuCoin API Documentation](https://www.kucoin.com/docs/basic-info/connection-method/authentication/signing-a-message#:~:text=api_key%20%3D%20,8)) ([Signing a Message | KuCoin API Documentation](https://www.kucoin.com/docs/basic-info/connection-method/authentication/signing-a-message#:~:text=passphrase%20%3D%20base64.b64encode%28hmac.new%28api_secret.encode%28%27utf,VERSION%22%3A%20%222)). Small details like including query params or using the correct timestamp format matter.  
- For request formatting errors (`400100`), verify that your JSON keys match the documentation exactly, and that you’re sending the correct data types (strings for numbers, etc.). Also ensure no trailing commas or improper JSON syntax (KuCoin notes to avoid extra spaces in JSON strings ([Orders | KuCoin API Documentation](https://www.kucoin.com/docs/rest/spot-trading/orders/place-order#:~:text=requirements%20for%20the%20quantity%20parameters,for%20each%20trading%20pair))).  
- If you get a response code you don’t understand, refer to the official “Errors Code” section of KuCoin’s docs which enumerates many error codes and their meanings ([Spot Errors Code | KuCoin API Documentation](https://www.kucoin.com/docs/errors-code/spot-errors-code#:~:text=Spot%20Errors%20Code)) ([Spot Errors Code | KuCoin API Documentation](https://www.kucoin.com/docs/errors-code/spot-errors-code#:~:text=260210%20withdraw.disabled%20,not%20in%20the%20api%20whitelist)). This can provide insight into what went wrong.  
- Utilize the KuCoin API Telegram or support channels if an error code is unclear or if you suspect an issue on KuCoin’s side (after verifying your implementation) ([Spot Errors Code | KuCoin API Documentation](https://www.kucoin.com/docs/errors-code/spot-errors-code#:~:text=If%20the%20returned%20HTTP%20status,the%20error%20code%20for%20details)).

By handling errors systematically and logging the responses, your wrapper can provide clear error messages or exceptions to the end developer using it.

## Clock Synchronization

**Time synchronization** is crucial when authenticating with KuCoin’s API. Every private request uses a timestamp (`KC-API-TIMESTAMP`) that must be within a small tolerance of KuCoin’s server time. If the timestamp is too far off, you will get `KC-API-TIMESTAMP Invalid` errors (code `400002`) ([Spot Errors Code | KuCoin API Documentation](https://www.kucoin.com/docs/errors-code/spot-errors-code#:~:text=400001%20Any%20of%20KC,not%20in%20the%20api%20whitelist)). 

KuCoin expects the timestamp in milliseconds since Unix epoch (UTC) ([Types | KuCoin API Documentation](https://www.kucoin.com/docs/basic-info/connection-method/types/timestamps#:~:text=The%20KC,1547015186532)). For example, `1547015186532` represents Tue, 09 Jan 2019 03:39:46.532 GMT. You can use integer or decimal milliseconds (the API will accept a decimal like `1547015186532.123`, but it’s safest to use an integer) ([Types | KuCoin API Documentation](https://www.kucoin.com/docs/basic-info/connection-method/types/timestamps#:~:text=The%20KC,1547015186532)). The important part is accuracy.

**Accepted time window:** KuCoin does not explicitly document the exact allowed drift, but in practice your timestamp should be within a few seconds of the server’s time. Many developers use a tolerance of 5 seconds. If your system clock is more than 5 seconds out of sync, your requests may be rejected (hence the `400002` error). 

**Server Time Endpoint:** KuCoin provides an endpoint to fetch the server time: `GET /api/v1/timestamp` ([Get Server Time | KuCoin API Documentation](https://www.kucoin.com/docs/rest/spot-trading/market-data/get-server-time#:~:text=)). This is a public endpoint that returns the server’s current time in milliseconds. For example: 

```json
GET /api/v1/timestamp

{
  "code": "200000",
  "msg": "success",
  "data": 1546837113087
}
``` 

 ([Get Server Time | KuCoin API Documentation](https://www.kucoin.com/docs/rest/spot-trading/market-data/get-server-time#:~:text=)). Your wrapper can call this periodically to check the difference between local time and KuCoin time. 

**Best Practices for Sync:** 

- **Initial sync:** On startup, hit the server time endpoint and calculate the difference (server_time - local_time). Use this offset to adjust your timestamps if needed.  
- **Ongoing sync:** Repeat the above at intervals or before sending bursts of requests. The server time is cheap to query (weight 3) ([Get Server Time | KuCoin API Documentation](https://www.kucoin.com/docs/rest/spot-trading/market-data/get-server-time#:~:text=)). You might sync every few minutes or if you start seeing `400002` errors. 
- **System clock:** It’s advisable to run an NTP service on your machine to keep its clock accurate. This reduces the chance of drift.  
- **Use server time directly:** Some developers choose to always call the server time endpoint just before sending any signed request. This guarantees accuracy but adds latency and load. A balanced approach is to cache an offset. For example, if KuCoin time is 120ms ahead of your PC, add 120ms to each timestamp you send. Remember that network latency can be a factor (the server time you receive has some small delay). 

By ensuring your timestamp is in sync, you avoid the hassle of nonce errors. A synchronized clock is essential for the signature to be considered valid ([Signing a Message | KuCoin API Documentation](https://www.kucoin.com/docs/basic-info/connection-method/authentication/signing-a-message#:~:text=Notice%3A)).

## Data Formatting Guidelines

Consistent data formatting is important for using the KuCoin API correctly. Notably, KuCoin has specific recommendations for handling numeric values to preserve precision, as well as general JSON formatting rules:

- **Decimals as Strings:** KuCoin **returns decimal numbers as strings** in JSON, and they recommend that you **also send decimals as strings** in requests ([Numbers | KuCoin API Documentation](https://www.kucoin.com/docs/basic-info/connection-method/types/numbers#:~:text=Decimal%20numbers%20are%20returned%20as,avoid%20truncation%20and%20precision%20errors)). This is to avoid precision loss that can occur if using floating-point types. For example, an account balance might be returned as `"237582.04299"` (with quotes) ([Get Account List - Spot/Margin/trade_hf | KuCoin API Documentation](https://www.kucoin.com/docs/rest/account/basic-info/get-account-list-spot-margin-trade_hf#:~:text=,)). When placing an order, you should send the price and size as strings: e.g. `"price": "11328.9", "size": "0.001"` rather than numeric literals ([Get All Tickers | KuCoin API Documentation](https://www.kucoin.com/docs/rest/spot-trading/market-data/get-all-tickers#:~:text=%22symbol%22%3A%20%22BTC,%2F%2F%2024h%20change%20rate)) ([Get All Tickers | KuCoin API Documentation](https://www.kucoin.com/docs/rest/spot-trading/market-data/get-all-tickers#:~:text=%22changePrice%22%3A%20%22,24h%20average%20transaction%20price)). This ensures that very large or very precise numbers are transmitted exactly without floating-point rounding. In your wrapper, you might convert decimal or float types to string before sending the JSON payload. 

- **Integer sizes:** Timestamps are integer values (in ms) but often provided as numbers in JSON (without quotes). That is fine, but ensure you use 64-bit integers. If using JavaScript, for instance, the numbers might be too large to represent accurately – treat them carefully or as strings if needed. KuCoin’s examples show the timestamp as a number in the JSON response (e.g. `"data": 1546837113087` with no quotes) ([Get Server Time | KuCoin API Documentation](https://www.kucoin.com/docs/rest/spot-trading/market-data/get-server-time#:~:text=)). Most JSON libraries handle this, but just be mindful of the size.

- **Case sensitivity and naming:** JSON keys in requests should exactly match what the API expects. They use lower-case with words separated by camelCase or underscores. For instance, use `"clientOid"` exactly as documented. The same goes for values that are strings but essentially enumerations (e.g. `"timeInForce": "GTC"`). The API is case-sensitive for these fields.

- **No extra spaces or escapes:** The KuCoin docs explicitly advise **not to include extra spaces or line breaks in JSON strings** ([Orders | KuCoin API Documentation](https://www.kucoin.com/docs/rest/spot-trading/orders/place-order#:~:text=requirements%20for%20the%20quantity%20parameters,for%20each%20trading%20pair)). While JSON allows insignificant whitespace, the signature is computed on the exact string. If your JSON serialization adds whitespace in different places when you compute the signature vs when the HTTP library sends it, you could get a signature mismatch. It’s safest to **use the exact same JSON string for signing and for the request body**. In practice, this means constructing the JSON as a string (or ensuring your JSON library produces a consistent output) before signing. 

- **Precision and Rounding:** Do not round values unless required. If an endpoint expects, say, a price with up to 8 decimal places, sending more decimal places than the market supports is usually okay (the API might truncate or reject with an error if too precise). It’s better to let KuCoin handle rounding rules. Just format your number as a string with the necessary precision. When reading responses, remember they are strings – convert to a decimal type in your programming language to avoid float issues, especially for monetary values.

- **Units and Formats:** Pay attention to units. For example, `size` or `funds` in an order might be amounts of cryptocurrency, whereas `price` is typically in quote currency per unit of base currency. `interestRate` might be per hour (as a decimal), etc. KuCoin usually documents units (e.g. in comments next to response fields like 24h volume) ([Get All Tickers | KuCoin API Documentation](https://www.kucoin.com/docs/rest/spot-trading/market-data/get-all-tickers#:~:text=%22changePrice%22%3A%20%22,24h%20average%20transaction%20price)) ([Get All Tickers | KuCoin API Documentation](https://www.kucoin.com/docs/rest/spot-trading/market-data/get-all-tickers#:~:text=,%2F%2F%20Basic%20Maker%20Fee)). Ensure your wrapper’s documentation clarifies these to the end-user to prevent confusion.

By following these formatting guidelines – especially treating numbers as strings – you ensure compatibility across different languages and avoid subtle bugs (like a floating point rounding turning `0.1` into `0.10000000149`). KuCoin’s choice to use strings for decimals is specifically to **preserve full precision across platforms** ([Numbers | KuCoin API Documentation](https://www.kucoin.com/docs/basic-info/connection-method/types/numbers#:~:text=Decimal%20numbers%20are%20returned%20as,avoid%20truncation%20and%20precision%20errors)).

## WebSocket API (Usage, Messages, Subscriptions)

KuCoin’s WebSocket API provides real-time data through persistent connections. To use it, your application (or wrapper) must handle the connection flow: obtaining a token, connecting to the WebSocket server, subscribing to topics, and maintaining the connection (ping/pong). Below is a breakdown of the process and message formats:

**1. Getting a WebSocket Token:** Unlike some exchanges with fixed WebSocket URLs, KuCoin requires you to fetch a **token and server address** via REST before connecting. There are two endpoints: 

- **Public Token:** `POST /api/v1/bullet-public` for public channels (no auth required) ([Public token (No authentication required): | KuCoin API Documentation](https://www.kucoin.com/docs/websocket/basic-info/apply-connect-token/public-token-no-authentication-required-#:~:text=)). Use this if you only need public data (market feeds). 
- **Private Token:** `POST /api/v1/bullet-private` for private channels (requires your API key authentication). Use this to subscribe to your private topics (orders, balances). You can also use it for public topics if you plan to use the same connection for both. 

Both return a JSON with a `token` and a list of `instanceServers`. For example, a response for the public token might look like (abbreviated):

```json
{
  "code":"200000",
  "data": {
    "instanceServers": [
      {
        "endpoint": "wss://ws-api-spot.kucoin.com/", 
        "protocol": "websocket",
        "encrypt": true,
        "pingInterval": 18000,
        "pingTimeout": 10000
      }
    ],
    "token": "xxx"
  }
}
``` 

 ([Public token (No authentication required) - KuCoin](https://www.kucoin.com/docs/websocket/basic-info/apply-connect-token/public-token-no-authentication-required-#:~:text=Public%20token%20,If%20you%20only%20use)) ([Kucoin API with Rust how to get symbol ticker data](https://tms-dev-blog.com/kucoin-api-with-rust-how-to-get-symbol-ticker-data/#:~:text=Kucoin%20API%20with%20Rust%20how,)). The `endpoint` is the WebSocket server URL base, and `pingInterval`/`pingTimeout` are in milliseconds. (The above values are examples; refer to the actual response. `encrypt:true` indicates data is by default not raw text – but in KuCoin’s case, public feeds are not encrypted, so this may refer to an older mechanism. You will receive JSON messages normally over the WebSocket.)

**2. Connecting to WebSocket:** Take the `endpoint` URL and append query parameters `?token=<your-token>` (and optionally `&[connectId=<custom-id>]`). The **connectId** is an ID you can generate (alphanumeric) to identify the connection – if not provided, KuCoin might use the token or assign one. For example ([Create connection | KuCoin API Documentation](https://www.kucoin.com/docs/websocket/basic-info/create-connection#:~:text=var%20socket%20%3D%20new%20WebSocket,spot.kucoin.com%2F%3Ftoken%3Dxxx%26%5BconnectId%3Dxxxxx%5D%27%2C)):

```js
const ws = new WebSocket("wss://ws-api-spot.kucoin.com/?token=<your-token>&connectId=myconn001");
``` 

Upon successful connection, the server will send a **welcome message**:

```json
{
  "id": "<connectionId>",
  "type": "welcome"
}
``` 

 ([Create connection | KuCoin API Documentation](https://www.kucoin.com/docs/websocket/basic-info/create-connection#:~:text=When%20the%20connection%20is%20successfully,will%20send%20a%20welcome%20message)). You must wait for this `"type": "welcome"` message before sending subscriptions. (If you attempt to subscribe too early, the messages might be ignored or result in an error.)

**3. Subscribing to Channels:** To subscribe to a topic (channel), send a JSON message over the WebSocket with the following format:

```json
{
  "id": "<unique-message-id>",
  "type": "subscribe",
  "topic": "<topic-string>",
  "privateChannel": false,
  "response": true
}
``` 

 ([Subscribe | KuCoin API Documentation](https://www.kucoin.com/docs/websocket/basic-info/subscribe/introduction#:~:text=%2F%2FSpot%20Demo%20%7B%20,Set%20as%20false%20by%20default)). Here:
 - `id` is a unique ID for your message (you can use a timestamp or a simple counter). The server will reply referencing this id.
 - `type` is `"subscribe"` (for unsubscribing, use `"unsubscribe"`).
 - `topic` is the channel topic you want. For example: `"/market/ticker:BTC-USDT"` for the BTC-USDT ticker ([Subscribe | KuCoin API Documentation](https://www.kucoin.com/docs/websocket/basic-info/subscribe/introduction#:~:text=,Set%20as%20false%20by%20default)). You can subscribe to multiple symbols in one request by comma-separating them (e.g. `"/market/ticker:BTC-USDT,ETH-USDT"` to get both ([Subscribe | KuCoin API Documentation](https://www.kucoin.com/docs/websocket/basic-info/subscribe/introduction#:~:text=,Set%20as%20false%20by%20default))). KuCoin topics usually start with a forward slash. Some common topics:  
   - Spot market ticker: `"/market/ticker:{symbol}"`  
   - All spot tickers: `"/market/ticker:all"`  
   - Spot Level2 market data: `"/market/level2:{symbol}"` (or specific depths like level2_5, level2_50).  
   - Trade executions: `"/market/match:{symbol}"`.  
   - Candles: `"/market/candles:{symbol}_{interval}"`.  
   - For futures, topics are similar but might be slightly different (e.g. `"/contractMarket/ticker:{symbol}"` for ticker). KuCoin’s docs list all topic strings for each category.  
 - `privateChannel`: `false` for public topics, `true` for private topics. If you are subscribing to your own order updates, set this to true. (Public token connections may not allow private topics at all – you’d use a private token connection for that.) ([KucoinWebsocketClient does not handle batch (un)subscribe correctly · Issue #109 · Kucoin/kucoin-python-sdk · GitHub](https://github.com/Kucoin/kucoin-python-sdk/issues/109#:~:text=%7B%20,))  
 - `response`: if `true`, the server will send an acknowledgment (ack) when subscription is successful. It’s good practice to set this true so you know the subscription status.

If the subscription succeeds, and `response:true` was requested, the server replies with an **acknowledgment** message:

```json
{
  "id": "<same-id-you-sent>",
  "type": "ack"
}
``` 

 ([Subscribe | KuCoin API Documentation](https://www.kucoin.com/docs/websocket/basic-info/subscribe/introduction#:~:text=If%20the%20subscription%20succeeds%2C%20the,response%20is%20set%20as%20true)). This indicates the server registered your subscription. If you don’t receive an ack (and you requested one), something might be wrong (e.g. topic string typo).

Once subscribed, you will start receiving messages for that topic. **Message structure:** Typically, each message has: 
- a `type`: often `"message"` for data updates, or `"error"` for errors, etc. 
- a `topic`: the topic of the message (e.g. `"/market/ticker:BTC-USDT"`), 
- a `subject` (for private channels, e.g. `"orderChange"`), 
- a `data` object containing the details (e.g. for ticker, it will have fields like `price`, `sequence`, etc.). For example, a ticker update might look like:

```json
{
  "type": "message",
  "topic": "/market/ticker:BTC-USDT",
  "subject": "trade.ticker", 
  "data": {
    "bestAsk": "11329", "bestBid": "11328.9", ... "price": "11328.9", "sequence": "1545912741843", "time": 1602832092060
  }
}
``` 

(This is illustrative; refer to official docs for exact fields ([Get All Tickers | KuCoin API Documentation](https://www.kucoin.com/docs/rest/spot-trading/market-data/get-all-tickers#:~:text=%22ticker%22%3A%20%5B%20%7B%20%22symbol%22%3A%20%22BTC,%2F%2F%2024h%20change%20rate)) ([Get All Tickers | KuCoin API Documentation](https://www.kucoin.com/docs/rest/spot-trading/market-data/get-all-tickers#:~:text=%22changePrice%22%3A%20%22,24h%20average%20transaction%20price)).)

For private order updates, the `data` will include order details (orderId, status, filled size, etc.). 

**4. Unsubscribing:** To unsubscribe, send a similar message with `"type": "unsubscribe"` and the same topic string. Example:

```json
{
  "id": "<unique-id-2>",
  "type": "unsubscribe",
  "topic": "/market/ticker:BTC-USDT,ETH-USDT",
  "privateChannel": false,
  "response": true
}
``` 

 ([KucoinWebsocketClient does not handle batch (un)subscribe correctly · Issue #109 · Kucoin/kucoin-python-sdk · GitHub](https://github.com/Kucoin/kucoin-python-sdk/issues/109#:~:text=%7B%20,)). The server will ack with `"type": "ack"` for the unsubscribe as well (if requested).

**5. Ping/Pong (Connection Keep-alive):** KuCoin requires periodic ping messages to keep the connection alive. The `instanceServers` info includes `pingInterval` (e.g. 18000 ms = 18s). Your client should send a ping message within that interval. KuCoin’s ping is a **text frame with a JSON** content:

```json
{
  "id": "<unique-id-3>",
  "type": "ping"
}
``` 

 ([Ping | KuCoin API Documentation](https://www.kucoin.com/docs/websocket/basic-info/ping#:~:text=%7B%20,)).

After sending a ping, the server responds with a **pong** message:

```json
{
  "id": "<same-id-3>",
  "type": "pong"
}
``` 

 ([Ping | KuCoin API Documentation](https://www.kucoin.com/docs/websocket/basic-info/ping#:~:text=After%20the%20ping%20message%20is,message%20to%20the%20client%20side)). If the server doesn’t receive pings or any messages from you for a long time (longer than `pingTimeout`), it will disconnect ([Ping | KuCoin API Documentation](https://www.kucoin.com/docs/websocket/basic-info/ping#:~:text=To%20prevent%20the%20TCP%20link,to%20keep%20alive%20the%20link)). In practice, you should send pings at the interval they specify (usually slightly less to be safe, e.g. every 15 seconds for an 18 second interval). Many WebSocket libraries can automate pings, but since KuCoin’s protocol uses a JSON ping, you may need to handle it at the application level. 

**Reconnecting:** WebSocket connections can drop due to network issues or if you exceed certain message limits. If disconnected, you should fetch a new token (tokens expire after a short time, around 30 seconds if not used, or a few minutes of connection), then reconnect and resubscribe to needed topics. KuCoin’s WebSocket does not guarantee to replay missed messages, so treat a disconnect as a point after which you may need to resync data (e.g. re-fetch the order book snapshot after reconnecting, if doing order book management).

**Multiplexing:** You can subscribe to multiple topics on one connection (KuCoin encourages using one connection for many subscriptions). However, there are limits (the docs mention a limit of topics per connection – e.g. 100 topics). If you need many subscriptions, you can open multiple connections (just be mindful of rate limits on the token requests and overall system load). KuCoin documentation has a section on *Multiplexing* which describes handling multiple topics on one socket ([Spot Trading | KuCoin API Documentation](https://www.kucoin.com/docs/websocket/spot-trading/public-channels/ticker#:~:text=)).

In summary, your wrapper should provide an easy way to: obtain the token, connect, send subscribe/unsubscribe messages, parse incoming messages, and handle ping/pong. It’s important to abstract these details for users of the wrapper, but internally ensure you follow KuCoin’s protocol. With proper handling, the WebSocket API provides low-latency updates that are crucial for trading applications.

## Practical Examples

Below are some practical examples of using the KuCoin API, demonstrating the request and response formats for common operations. These examples assume the use of JSON and the inclusion of necessary headers for authenticated endpoints.

### Example 1: Get Market Ticker (Spot, Public REST)

Suppose we want to retrieve the current price ticker for all trading pairs on the spot market. We use the **Get All Tickers** endpoint.

**Request:** `GET /api/v1/market/allTickers` (to be made on the Spot base URL, no auth needed).

**Response:** (partial JSON example)

```json
{
  "code": "200000",
  "data": {
    "time": 1602832092060,
    "ticker": [
      {
        "symbol": "BTC-USDT",
        "symbolName": "BTC-USDT",
        "buy": "11328.9",      // best bid price
        "sell": "11329",       // best ask price
        "bestBidSize": "0.1",
        "bestAskSize": "1",
        "changeRate": "-0.0055",   // 24h change rate
        "changePrice": "-63.6",    // 24h change amount
        "high": "11610",           // 24h high price
        "low": "11200",            // 24h low price
        "vol": "2282.70993217",    // 24h volume (in base currency) ([Get All Tickers | KuCoin API Documentation](https://www.kucoin.com/docs/rest/spot-trading/market-data/get-all-tickers#:~:text=%22changePrice%22%3A%20%22,24h%20average%20transaction%20price))
        "volValue": "25984946.157790431", // 24h volume (in quote currency) ([Get All Tickers | KuCoin API Documentation](https://www.kucoin.com/docs/rest/spot-trading/market-data/get-all-tickers#:~:text=,%2F%2F%20Basic%20Maker%20Fee))
        "last": "11328.9",        // last traded price
        "averagePrice": "11360.66065903", // 24h average price
        "takerFeeRate": "0.001",  // basic taker fee rate
        "makerFeeRate": "0.001",  // basic maker fee rate
        "nextPage": null         // (if there were pagination, not in this endpoint)
      },
      {
        "symbol": "ETH-USDT",
        "symbolName": "ETH-USDT",
        "buy": "371.5",
        "sell": "371.6",
        "...": "..."
      }
      // ... more tickers
    ]
  }
}
``` 

In this output, `data.ticker` is an array of objects for each trading pair. We’ve shown two examples (BTC-USDT and ETH-USDT). The fields are documented in KuCoin’s API reference. Notably, all numeric values are strings (e.g. `"11328.9"` for prices) ([Get All Tickers | KuCoin API Documentation](https://www.kucoin.com/docs/rest/spot-trading/market-data/get-all-tickers#:~:text=%22symbol%22%3A%20%22BTC,%2F%2F%2024h%20change%20rate)). The wrapper should parse these into appropriate numeric types if needed by the application.

### Example 2: Place a Limit Order (Spot, Private REST)

This example demonstrates placing a buy limit order on the spot market for BTC-USDT.

**Request:** `POST /api/v1/orders` (Spot base URL). This is a private endpoint, so include the authentication headers (`KC-API-KEY`, etc.). The request body (JSON) might look like:

```json
{
  "clientOid": "abc123-e0b8-46d4",   // client-provided unique ID for the order
  "side": "buy",
  "symbol": "BTC-USDT",
  "type": "limit",
  "price": "11000.0",
  "size": "0.001",
  "remark": "buy 0.001 BTC",        // optional tag
  "timeInForce": "GTC"             // good-till-cancel (default if omitted)
}
``` 

Headers (example): 

```
KC-API-KEY: <your_key>
KC-API-SIGN: <signature>
KC-API-TIMESTAMP: 1603000000000
KC-API-PASSPHRASE: <your_passphrase (encrypted if v2)>
KC-API-KEY-VERSION: 2
Content-Type: application/json
```

After sending, if the order is successfully accepted, you’ll get:

**Response:** 

```json
{
  "code": "200000",
  "data": {
    "orderId": "5f8d40127e41d3000ab3d123"
  }
}
``` 

 ([Orders | KuCoin API Documentation](https://www.kucoin.com/docs/rest/spot-trading/orders/place-order#:~:text=)). The `orderId` is KuCoin’s unique identifier for your order. You can use this to query order status or cancel the order if needed.

If something was wrong with the request, for example an insufficient balance, you might instead receive an error like:

```json
{
  "code": "400100",
  "msg": "account.available.amount -- Insufficient balance"
}
``` 

indicating you didn’t have enough funds to place this order (the error message points to the available amount) ([Spot Errors Code | KuCoin API Documentation](https://www.kucoin.com/docs/errors-code/spot-errors-code#:~:text=404000%20Url%20Not%20Found%20400100,risk%20problem%20in%20your%20account)).

### Example 3: Check Account Balance (Spot, Private REST)

This example fetches a list of your accounts and their balances.

**Request:** `GET /api/v1/accounts` (Spot base URL, with auth headers).

You can optionally specify query params like `?type=trade` to filter by account type, but here we get all.

**Response:** 

```json
{
  "code": "200000",
  "data": [
    {
      "id": "5bd6e9286d99522a52e458de",
      "currency": "BTC",
      "type": "main",
      "balance": "237582.04299",
      "available": "237582.03200",
      "holds": "0.01099"
    },
    {
      "id": "5bd6e9216d99522a52e458d6",
      "currency": "BTC",
      "type": "trade",
      "balance": "1234356",
      "available": "1234356",
      "holds": "0"
    },
    {
      "id": "5f8d4bf76d7934000a066de8",
      "currency": "USDT",
      "type": "margin",
      "balance": "100.25",
      "available": "50.25",
      "holds": "50.0"
    }
    // ... potentially more accounts (one per currency per account type)
  ]
}
``` 

 ([Get Account List - Spot/Margin/trade_hf | KuCoin API Documentation](https://www.kucoin.com/docs/rest/account/basic-info/get-account-list-spot-margin-trade_hf#:~:text=%5B%20%7B%20,assets%20of%20a%20currency)) ([Get Account List - Spot/Margin/trade_hf | KuCoin API Documentation](https://www.kucoin.com/docs/rest/account/basic-info/get-account-list-spot-margin-trade_hf#:~:text=,%7D))Each object in the array is one of your accounts. In this example, we see a main BTC account, a trading BTC account, and a margin USDT account. `holds` indicates funds locked (e.g. by open orders or loans). If you only care about certain accounts, you could filter by the `type` parameter in the request.

### Example 4: WebSocket Subscribe to Ticker (Public WS)

Finally, an example of using the WebSocket API to subscribe to a ticker feed for BTC-USDT.

**Step 1:** Get public token:

```
POST /api/v1/bullet-public
```

Response (excerpt):

```json
{
  "code": "200000",
  "data": {
    "instanceServers": [
      {
        "endpoint": "wss://ws-api-spot.kucoin.com/",
        "protocol": "websocket",
        "pingInterval": 18000,
        "pingTimeout": 10000
      }
    ],
    "token": "t5e8e10f-xxxxx-xxxxx-xxxxx"
  }
}
``` 

Use the `endpoint` and `token` to connect.

**Step 2:** Connect via WebSocket to `wss://ws-api-spot.kucoin.com/?token=t5e8e10f-...`.

**Step 3:** Subscribe to topic:

Send this message over the WebSocket after receiving the welcome:

```json
{
  "id": "1603052503568", 
  "type": "subscribe",
  "topic": "/market/ticker:BTC-USDT",
  "privateChannel": false,
  "response": true
}
``` 

The server should reply with:

```json
{
  "id": "1603052503568",
  "type": "ack"
}
``` 

indicating subscription success ([Subscribe | KuCoin API Documentation](https://www.kucoin.com/docs/websocket/basic-info/subscribe/introduction#:~:text=If%20the%20subscription%20succeeds%2C%20the,response%20is%20set%20as%20true)).

**Step 4:** Receive ticker updates:

The client will start receiving messages like:

```json
{
  "type": "message",
  "topic": "/market/ticker:BTC-USDT",
  "subject": "trade.ticker",
  "data": {
    "sequence": "1545896661840",
    "bestAsk": "11330", 
    "bestAskSize": "0.5",
    "bestBid": "11329.8",
    "bestBidSize": "0.0084",
    "price": "11330",          // last trade price
    "size": "0.005",           // last trade size
    "tradeId": "5f8d9b826d…",  // last trade ID
    "ts": 1602833347135        // timestamp of the tick
  }
}
```

Each such message is a snapshot of the current best bids/asks and last trade. They arrive in real-time (typically whenever a trade happens or order book changes). The `price` here is the last traded price, and `bestBid`/`bestAsk` reflect the current order book top. The wrapper would parse these and perhaps emit an event or callback to the user with the updated ticker info.

**Step 5:** Periodically ping:

Every 18 seconds (as given by pingInterval), send:

```json
{ "id": "1603052520000", "type": "ping" }
```

and expect a `{ "id": "1603052520000", "type": "pong" }` in return ([Ping | KuCoin API Documentation](https://www.kucoin.com/docs/websocket/basic-info/ping#:~:text=To%20prevent%20the%20TCP%20link,to%20keep%20alive%20the%20link)) ([Ping | KuCoin API Documentation](https://www.kucoin.com/docs/websocket/basic-info/ping#:~:text=After%20the%20ping%20message%20is,message%20to%20the%20client%20side)). This keeps the connection alive.

This example demonstrates an end-to-end flow for WebSocket. For private channels, the steps are similar but using `bullet-private` and including your API key signature in that request, then subscribing with `"privateChannel": true` to something like `"/spot/orderBook:{symbol}"` or `"/account/balance"` channels. The wrapper can abstract token management and provide high-level subscribe functions.

## Developer Best Practices

Building a robust API wrapper for KuCoin involves more than just calling endpoints. Here are some best practices to ensure efficiency, reliability, and ease of use:

- **Abstract and Simplify**: Provide clear methods/functions in your wrapper for each major action (e.g. `get_ticker(symbol)`, `place_order(params)`, `on_order_update(callback)`). The wrapper should handle the low-level details (like constructing URLs, adding headers, signing requests, parsing JSON) so that developers using it can work at a higher level.

- **Handle Authentication Gracefully**: Incorporate the API key, secret, passphrase in a configuration object. Perhaps allow initialization like `KucoinClient(api_key, api_secret, passphrase, sandbox=False)` so switching between environments is easy. Internally, handle the signing as per KuCoin’s requirements ([Signing a Message | KuCoin API Documentation](https://www.kucoin.com/docs/basic-info/connection-method/authentication/signing-a-message#:~:text=passphrase%20%3D%20base64.b64encode%28hmac.new%28api_secret.encode%28%27utf,VERSION%22%3A%20%222)). Security-wise, never log the secret or passphrase. If providing logging options, ensure sensitive info is masked.

- **Respect Rate Limits**: Implement a rate limiter within the wrapper. This could be as simple as tracking the last request timestamps and weights, or as advanced as a token bucket algorithm. Since KuCoin gives remaining request counts in headers ([Basic Info | KuCoin API Documentation](https://www.kucoin.com/docs/basic-info/request-rate-limit/rest-api#:~:text=,milliseconds)), your HTTP client code can read those and perhaps sleep or delay if the remaining quota is low. Also consider queueing requests if the user of the wrapper issues a burst of calls that exceed limits – the wrapper can serialize them with slight delays to stay just under the threshold. Document these behaviors for the user.

- **Use WebSockets for High-Frequency Data**: As a best practice, guide users to use the provided WebSocket methods for real-time needs (order books, trades, etc.) ([Basic Info | KuCoin API Documentation](https://www.kucoin.com/docs/basic-info/request-rate-limit/rest-api#:~:text=,avoid%20IP%20rate%20limit%20issues)). Your wrapper might include a WebSocket sub-module that manages connections and subscriptions. Ensure it can automatically reconnect on disconnections and resubscribe to topics. Perhaps expose an interface like `client.subscribe_ticker("BTC-USDT", callback)`.

- **Error Handling and Retries**: Catch errors (HTTP errors, JSON parse errors, etc.) and convert them into meaningful exceptions or error codes in your wrapper. For example, if KuCoin returns `400005 Signature error`, your wrapper could raise a `KucoinAPIError("Invalid API signature")` pointing to a likely misconfiguration. For network issues or rate limit errors, implement retries with backoff. But be careful: do not retry non-idempotent requests blindly (placing an order twice could create duplicate orders if the first actually went through). For order placement, if a timeout or network error occurs, it’s safer to query the order status by clientOid to see if it succeeded before retrying.

- **Precision and Data Types**: Since KuCoin expects numbers as strings, your wrapper should handle conversions. For instance, if a user calls `client.place_order(symbol="BTC-USDT", price=11000.0, size=0.001)`, the wrapper should format those to `"11000.0"` and `"0.001"` in the JSON. Likewise, when returning data, you might convert strings to `Decimal` types for precision. Clearly document this behavior. Using Python’s `decimal.Decimal` or Java’s `BigDecimal` can help avoid floating point issues. The wrapper could also provide raw access to the data if users prefer to handle precision themselves.

- **Time Synchronization**: It’s good practice for the wrapper to check system time vs KuCoin time (perhaps on initialization). If a large discrepancy is found, log a warning or automatically adjust timestamps for signing. You could provide a method like `client.sync_time()` that fetches server time and stores an offset. Use this offset in your signature timestamp calculation to avoid `400002` errors. Many official client libraries do this under the hood.

- **Pagination Helpers**: For endpoints that paginate, the wrapper can provide a helper to fetch all pages. E.g., `client.get_trade_history(symbol, start_time, end_time)` could internally loop through pages until all data is retrieved (honoring rate limits). Or provide a generator/iterator that fetches page by page as needed. This makes it easier for developers to get complete datasets without writing pagination logic.

- **Testing in Sandbox**: Encourage testing on KuCoin’s Sandbox (if available) by making it a simple flag or separate environment in the wrapper. This allows users to simulate trading without real funds. (KuCoin’s documentation references a sandbox base URL in the introduction.)

- **Concurrency and Threads**: If the wrapper will be used in high-performance scenarios, ensure that it’s thread-safe (if applicable) or that you document how to use it in asynchronous contexts. For example, provide async methods (or a separate async class) if using languages that support async/await, so that the user can integrate the API calls without blocking their event loop. The official API allows concurrent use, but the wrapper should manage shared resources like the rate limit counter or WebSocket connections carefully.

- **Logging and Debugging**: Build in optional logging. For instance, the wrapper could log all requests (method, endpoint, params) and responses (status code, maybe truncated data) at a debug log level. This is invaluable for debugging issues. Just ensure sensitive data (API secret, user personal data) is not logged. Provide a way for the developer to turn on verbose logging when needed.

- **Up-to-date and Extensible**: Design the wrapper to accommodate new endpoints easily. KuCoin periodically updates their API (for instance, the introduction of new account types like `trade_hf`). If your wrapper is well-structured, adding a new endpoint is just adding a new method that hits the appropriate path. Try to avoid hardcoding too many things that might change (like error code lists), instead allow pass-through of unknown codes with messages, so the wrapper doesn’t break if KuCoin adds new features.

- **Graceful Shutdown**: Particularly for WebSocket usage, provide a way to gracefully disconnect (sending unsubscribe and/or close the socket). This helps avoid leaving connections open or dangling threads.

- **Examples and Documentation**: Finally, accompany your wrapper with documentation and examples (many developers will look for how to place an order, how to get balances, etc., as we’ve illustrated above). Possibly include some of the sample outputs from KuCoin’s docs ([Get Account List - Spot/Margin/trade_hf | KuCoin API Documentation](https://www.kucoin.com/docs/rest/account/basic-info/get-account-list-spot-margin-trade_hf#:~:text=%5B%20%7B%20,assets%20of%20a%20currency)) ([Orders | KuCoin API Documentation](https://www.kucoin.com/docs/rest/spot-trading/orders/place-order#:~:text=)) to show what to expect. Clear documentation reduces misuse and error.

By following these best practices, your KuCoin API wrapper will be developer-friendly, efficient, and reliable. It will abstract the complexities of the KuCoin API (signature generation, rate limits, data formats) and let users focus on building their trading logic or data analysis on top of it. Always test thoroughly against the real API (and sandbox) to ensure correctness. And keep an eye on KuCoin’s official API changelog or announcements – when new endpoints or changes come, update the wrapper so developers using it can seamlessly access new features or adapt to changes.


