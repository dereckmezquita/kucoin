# File: ./R/KucoinSpotGet.ROrder

# box::use(
#     ./impl_spottrading_orders_get_order_by[
#         get_order_by_order_id_impl,
#         get_order_by_client_oid_impl
#     ],
#     ./impl_spottrading_orders_get_trade_history[
#         get_trade_history_impl
#     ],
#     ./impl_spottrading_orders_get_x[
#         get_symbols_with_open_order_impl,
#         get_open_orders_impl,
#         get_closed_orders_impl
#     ],
#     ./utils[get_api_keys, get_base_url]
# )

#' KucoinSpotGetOrder Class for KuCoin Spot Trading Order Retrieval
#'
#' The `KucoinSpotGetOrder` class provides an asynchronous interface for retrieving spot trading order information from KuCoin.
#' It leverages the `coro` package for non-blocking HTTP requests, returning promises that resolve to `data.table` objects.
#' This class focuses on querying order details, trade history, open and closed orders, and symbols with active orders.
#'
#' ### Purpose and Scope
#' This class is designed for retrieving and monitoring order-related data in the KuCoin Spot trading system, including:
#' - **Order Details**: Fetching specific order information by `orderId` or `clientOid`.
#' - **Trade History**: Retrieving fill details for orders or symbols.
#' - **Order States**: Listing open and closed orders for a symbol.
#' - **Portfolio Overview**: Identifying symbols with active orders.
#'
#' ### Workflow Overview
#' Not applicable (class definition overview).
#'
#' ### API Endpoint
#' Not applicable (class-level documentation; see individual methods for specific endpoints).
#'
#' ### Usage
#' Utilised by traders and developers to programmatically query and monitor Spot trading orders on KuCoin. The class is initialized with API credentials,
#' automatically loaded via `get_api_keys()` if not provided, and a base URL from `get_base_url()`. For detailed endpoint information,
#' parameters, and response schemas, refer to the official [KuCoin API Documentation](https://www.kucoin.com/docs-new).
#'
#' ### Official Documentation
#' [KuCoin API Documentation - Spot Trading Orders](https://www.kucoin.com/docs-new/rest/spot-trading/orders/introduction)
#'
#' @section Methods:
#' - **initialize(keys, base_url):** Initialises the object with API credentials and base URL.
#' - **get_order_by_order_id(orderId, symbol):** Retrieves detailed order info by `orderId`.
#' - **get_order_by_client_oid(clientOid, symbol):** Retrieves detailed order info by `clientOid`.
#' - **get_trade_history(symbol, orderId, side, type, lastId, limit, startAt, endAt):** Fetches trade history (fills) for a symbol or order.
#' - **get_symbols_with_open_orders():** Lists symbols with active orders.
#' - **get_open_orders(symbol):** Retrieves all active orders for a symbol.
#' - **get_closed_orders(symbol, side, type, startAt, endAt, limit, max_pages):** Retrieves all closed orders for a symbol with pagination.
#'
#' @return Not applicable (class definition; see individual methods for return values).
#'
#' @examples
#' \dontrun{
#' # Comprehensive example demonstrating key methods
#' main_async <- coro::async(function() {
#'   # Initialise the class
#'   queries <- KucoinSpotGetOrder$new()
#'
#'   # Retrieve order details by orderId
#'   order <- await(queries$get_order_by_order_id("6717422bd51c29000775ea03", "BTC-USDT"))
#'   print("Order Details by OrderId:"); print(order)
#'
#'   # Retrieve order details by clientOid
#'   order_by_client <- await(queries$get_order_by_client_oid("5c52e11203aa677f33e493fb", "BTC-USDT"))
#'   print("Order Details by ClientOid:"); print(order_by_client)
#'
#'   # Get trade history
#'   trades <- await(queries$get_trade_history(symbol = "BTC-USDT", limit = 50))
#'   print("Trade History:"); print(trades)
#'
#'   # Get symbols with open orders
#'   active_symbols <- await(queries$get_symbols_with_open_orders())
#'   print("Symbols with Open Orders:"); print(active_symbols)
#'
#'   # Get open orders
#'   open_orders <- await(queries$get_open_orders("BTC-USDT"))
#'   print("Open Orders:"); print(open_orders)
#'
#'   # Get closed orders
#'   closed_orders <- await(queries$get_closed_orders(
#'     symbol = "BTC-USDT", limit = 50, max_pages = 2
#'   ))
#'   print("Closed Orders:"); print(closed_orders)
#' })
#' main_async()
#' while (!later::loop_empty()) later::run_now()
#' }
#'
#' @importFrom R6 R6Class
#' @export
KucoinSpotGetOrder <- R6::R6Class(
    "KucoinSpotGetOrder",
    public = list(
        #' @field keys List containing KuCoin API keys (`api_key`, `api_secret`, `api_passphrase`, `key_version`).
        keys = NULL,
        #' @field base_url Character string representing the base URL for KuCoin API endpoints.
        base_url = NULL,

        #' Initialise a New KucoinSpotGetOrder Object
        #'
        #' ### Description
        #' Initialises a `KucoinSpotGetOrder` object with API credentials and a base URL for retrieving Spot trading order data asynchronously.
        #' If not provided, credentials are sourced from `get_api_keys()` and the base URL from `get_base_url()`.
        #'
        #' ### Workflow Overview
        #' 1. **Credential Assignment**: Sets `self$keys` to the provided or default API keys.
        #' 2. **URL Assignment**: Sets `self$base_url` to the provided or default base URL.
        #'
        #' ### API Endpoint
        #' Not applicable (initialisation method).
        #'
        #' ### Usage
        #' Utilised to create an instance for querying Spot trading orders and related data.
        #'
        #' ### Official Documentation
        #' [KuCoin API Authentication](https://www.kucoin.com/docs-new/rest/introduction#authentication)
        #'
        #' ### Automated Trading Usage
        #' - **Monitoring Hub**: Use this as a dedicated instance for order querying in your trading system, integrating with real-time feeds for timely updates.
        #' - **Secure Setup**: Load credentials via `get_api_keys()` from a secure source (e.g., environment variables), ensuring safe deployment.
        #' - **Scalability**: Reuse this instance across your bot’s lifecycle, pairing with other classes (e.g., `KucoinSpotOCO`) for full order management.
        #'
        #' @param keys List containing API configuration parameters from `get_api_keys()`, including:
        #'   - `api_key`: Character string; your KuCoin API key.
        #'   - `api_secret`: Character string; your KuCoin API secret.
        #'   - `api_passphrase`: Character string; your KuCoin API passphrase.
        #'   - `key_version`: Character string; API key version (e.g., `"2"`).
        #'   Defaults to `get_api_keys()`.
        #' @param base_url Character string representing the base URL for the API. Defaults to `get_base_url()`.
        #'
        #' @return A new instance of the `KucoinSpotGetOrder` class.
        initialize = function(keys = get_api_keys(), base_url = get_base_url()) {
            self$keys <- keys
            self$base_url <- base_url
        },

        #' Get Order By OrderId
        #'
        #' ### Description
        #' Retrieves detailed info for a spot order by its system-generated `orderId` via a GET request to `/api/v1/hf/orders/{orderId}`.
        #' Calls `get_order_by_order_id_impl`.
        #'
        #' ### Workflow Overview
        #' 1. **Validation**: Ensures `orderId` and `symbol` are valid.
        #' 2. **URL**: Constructs endpoint with `orderId` and `symbol`.
        #' 3. **Authentication**: Generates headers.
        #' 4. **API Call**: Sends GET request.
        #' 5. **Response**: Returns detailed order info with datetime columns.
        #'
        #' ### API Endpoint
        #' `GET https://api.kucoin.com/api/v1/hf/orders/{orderId}?symbol={symbol}`
        #'
        #' ### Usage
        #' Utilised to fetch comprehensive details of a specific order by its system ID.
        #'
        #' ### Official Documentation
        #' [KuCoin Get Order By OrderId](https://www.kucoin.com/docs-new/rest/spot-trading/orders/get-order-by-orderld)
        #'
        #' ### Automated Trading Usage
        #' - **Order Tracking**: Monitor `active` and `inOrderBook` to confirm order status post-placement (e.g., still open or recently filled).
        #' - **Execution Verification**: Check `dealSize` and `dealFunds` against expected fills, triggering alerts if discrepancies arise.
        #' - **Time Analysis**: Use `createdAtDatetime` and `lastUpdatedAtDatetime` to assess order lifecycle, adjusting strategies if delays occur.
        #'
        #' @param orderId Character string; system-generated order ID (e.g., "6717422bd51c29000775ea03"). Required.
        #' @param symbol Character string; trading pair (e.g., "BTC-USDT"). Required.
        #' @return Promise resolving to a `data.table` with columns including:
        #'   - `id` (character), `clientOid` (character), `symbol` (character), `type` (character), `side` (character),
        #'   - `price` (character), `size` (character), `dealSize` (character), `active` (logical), `createdAtDatetime` (POSIXct)
        #'   - Full schema in implementation docs.
        #' ### JSON Response Example
        #' ```json
        #' {"code": "200000", "data": {"id": "6717422bd51c29000775ea03", "symbol": "BTC-USDT", "type": "limit", "side": "buy", "price": "70000", "size": "0.00001", "dealSize": "0.00001", "active": false, "createdAt": 1729577515444}}
        #' ```
        get_order_by_order_id = function(orderId, symbol) {
            return(get_order_by_order_id_impl(keys = self$keys, base_url = self$base_url, orderId = orderId, symbol = symbol))
        },

        #' Get Order By ClientOid
        #'
        #' ### Description
        #' Retrieves detailed info for a spot order by its client-assigned `clientOid` via a GET request to `/api/v1/hf/orders/client-order/{clientOid}`.
        #' Calls `get_order_by_client_oid_impl`.
        #'
        #' ### Workflow Overview
        #' 1. **Validation**: Ensures `clientOid` and `symbol` are valid.
        #' 2. **URL**: Constructs endpoint with `clientOid` and `symbol`.
        #' 3. **Authentication**: Generates headers.
        #' 4. **API Call**: Sends GET request.
        #' 5. **Response**: Returns detailed order info with datetime columns.
        #'
        #' ### API Endpoint
        #' `GET https://api.kucoin.com/api/v1/hf/orders/client-order/{clientOid}?symbol={symbol}`
        #'
        #' ### Usage
        #' Utilised to fetch comprehensive order details using a custom client ID.
        #'
        #' ### Official Documentation
        #' [KuCoin Get Order By ClientOid](https://www.kucoin.com/docs-new/rest/spot-trading/orders/get-order-by-clientoid)
        #'
        #' ### Automated Trading Usage
        #' - **Custom Sync**: Use `clientOid` to align KuCoin data with your system’s order records, especially after network issues.
        #' - **Status Checks**: Monitor `active` to react to order completion, updating position trackers accordingly.
        #' - **Audit Trail**: Log `dealFunds` and `fee` for cost analysis, ensuring profitability calculations are accurate.
        #'
        #' @param clientOid Character string; client-assigned order ID (e.g., "5c52e11203aa677f33e493fb"). Required.
        #' @param symbol Character string; trading pair (e.g., "BTC-USDT"). Required.
        #' @return Promise resolving to a `data.table` with columns including:
        #'   - `id` (character), `clientOid` (character), `symbol` (character), `type` (character), `side` (character),
        #'   - `price` (character), `size` (character), `dealSize` (character), `active` (logical), `createdAtDatetime` (POSIXct)
        #'   - Full schema in implementation docs.
        #' ### JSON Response Example
        #' ```json
        #' {"code": "200000", "data": {"id": "6717422bd51c29000775ea03", "clientOid": "5c52e11203aa677f33e493fb", "symbol": "BTC-USDT", "type": "limit", "side": "buy", "price": "70000", "size": "0.00001", "dealSize": "0.00001", "active": false, "createdAt": 1729577515444}}
        #' ```
        get_order_by_client_oid = function(clientOid, symbol) {
            return(get_order_by_client_oid_impl(keys = self$keys, base_url = self$base_url, clientOid = clientOid, symbol = symbol))
        },

        #' Get Trade History
        #'
        #' ### Description
        #' Retrieves latest spot transaction details (fills) for a symbol or order via a GET request to `/api/v1/hf/fills`.
        #' Calls `get_trade_history_impl`.
        #'
        #' ### Workflow Overview
        #' 1. **Validation**: Ensures `symbol` or `orderId` is valid.
        #' 2. **URL**: Builds endpoint with query parameters.
        #' 3. **Authentication**: Generates headers.
        #' 4. **API Call**: Sends GET request.
        #' 5. **Response**: Returns fill details with datetime column.
        #'
        #' ### API Endpoint
        #' `GET https://api.kucoin.com/api/v1/hf/fills`
        #'
        #' ### Usage
        #' Utilised to fetch fill history for analysis or verification.
        #'
        #' ### Official Documentation
        #' [KuCoin Get Trade History](https://www.kucoin.com/docs-new/rest/spot-trading/orders/get-trade-history)
        #'
        #' ### Automated Trading Usage
        #' - **Performance Tracking**: Analyze `price`, `size`, and `fee` to assess trade execution quality, adjusting strategies if costs are high.
        #' - **Fill Confirmation**: Use `orderId` to verify fills post-order placement, ensuring expected trades occurred.
        #' - **Pagination**: Leverage `lastId` and `limit` for incremental updates, syncing with a trade log database efficiently.
        #'
        #' @param symbol Character string; trading pair (e.g., "BTC-USDT"). Required if `orderId` not provided.
        #' @param orderId Character string; order ID. Optional, overrides other filters if provided.
        #' @param side Character string; "buy" or "sell". Optional.
        #' @param type Character string; "limit" or "market". Optional.
        #' @param lastId Integer; last fill ID for pagination. Optional.
        #' @param limit Integer; fills per request (1-100, default 20). Optional.
        #' @param startAt Integer; start time (ms). Optional.
        #' @param endAt Integer; end time (ms). Optional.
        #' @return Promise resolving to a `data.table` with columns including:
        #'   - `id` (integer), `orderId` (character), `symbol` (character), `price` (character), `size` (character),
        #'   - `funds` (character), `fee` (character), `createdAtDatetime` (POSIXct)
        #'   - Full schema in implementation docs.
        #' ### JSON Response Example
        #' ```json
        #' {"code": "200000", "data": {"items": [{"id": 19814995255305, "orderId": "6717422bd51c29000775ea03", "symbol": "BTC-USDT", "price": "67717.6", "size": "0.00001", "funds": "0.677176", "fee": "0.000677176", "createdAt": 1729577515473}], "lastId": 19814995255305}}
        #' ```
        get_trade_history = function(
            symbol = NULL,
            orderId = NULL,
            side = NULL,
            type = NULL,
            lastId = NULL,
            limit = 20,
            startAt = NULL,
            endAt = NULL
        ) {
            return(get_trade_history_impl(
                keys = self$keys,
                base_url = self$base_url,
                symbol = symbol,
                orderId = orderId,
                side = side,
                type = type,
                lastId = lastId, 
                limit = limit,
                startAt = startAt
                endAt = endAt
            ))
        },

        #' Get Symbols With Open Orders
        #'
        #' ### Description
        #' Retrieves a list of symbols with active orders via a GET request to `/api/v1/hf/orders/active/symbols`.
        #' Calls `get_symbols_with_open_order_impl`.
        #'
        #' ### Workflow Overview
        #' 1. **URL**: Constructs endpoint with no parameters.
        #' 2. **Authentication**: Generates headers.
        #' 3. **API Call**: Sends GET request.
        #' 4. **Response**: Returns a `data.table` of symbols.
        #'
        #' ### API Endpoint
        #' `GET https://api.kucoin.com/api/v1/hf/orders/active/symbols`
        #'
        #' ### Usage
        #' Utilised to identify markets with ongoing order activity.
        #'
        #' ### Official Documentation
        #' [KuCoin Get Symbols With Open Order](https://www.kucoin.com/docs-new/rest/spot-trading/orders/get-symbols-with-open-order)
        #'
        #' ### Automated Trading Usage
        #' - **Portfolio Snapshot**: Poll periodically to detect active markets, triggering detailed queries (e.g., `get_open_orders`) for each symbol.
        #' - **Resource Allocation**: Prioritize trading logic or risk checks on returned symbols, optimizing bot performance.
        #' - **Idle Detection**: If empty, signal your system to place new orders or adjust strategies for inactive markets.
        #'
        #' @return Promise resolving to a `data.table` with:
        #'   - `symbols` (character): Vector of trading pair symbols with active orders.
        #' ### JSON Response Example
        #' ```json
        #' {"code": "200000", "data": {"symbols": ["ETH-USDT", "BTC-USDT"]}}
        #' ```
        get_symbols_with_open_orders = function() {
            return(get_symbols_with_open_order_impl(keys = self$keys, base_url = self$base_url))
        },

        #' Get Open Orders
        #'
        #' ### Description
        #' Retrieves all active spot orders for a symbol via a GET request to `/api/v1/hf/orders/active`.
        #' Calls `get_open_orders_impl`.
        #'
        #' ### Workflow Overview
        #' 1. **Validation**: Ensures `symbol` is valid.
        #' 2. **URL**: Constructs endpoint with `symbol`.
        #' 3. **Authentication**: Generates headers.
        #' 4. **API Call**: Sends GET request.
        #' 5. **Response**: Returns active orders with datetime columns.
        #'
        #' ### API Endpoint
        #' `GET https://api.kucoin.com/api/v1/hf/orders/active?symbol={symbol}`
        #'
        #' ### Usage
        #' Utilised to list all active orders for a specific trading pair.
        #'
        #' ### Official Documentation
        #' [KuCoin Get Open Orders](https://www.kucoin.com/docs-new/rest/spot-trading/orders/get-open-orders)
        #'
        #' ### Automated Trading Usage
        #' - **Order Management**: Monitor `remainSize` to adjust or cancel orders nearing fill limits, maintaining strategy alignment.
        #' - **Risk Exposure**: Aggregate `funds` across orders to assess total exposure per symbol, triggering risk mitigations if over thresholds.
        #' - **Stale Orders**: Cancel orders with old `createdAtDatetime` (e.g., >24 hours) using a paired cancel class method.
        #'
        #' @param symbol Character string; trading pair (e.g., "BTC-USDT"). Required.
        #' @return Promise resolving to a `data.table` with columns including:
        #'   - `id` (character), `clientOid` (character), `symbol` (character), `type` (character), `side` (character),
        #'   - `price` (character), `size` (character), `remainSize` (character), `active` (logical), `createdAtDatetime` (POSIXct)
        #'   - Full schema in implementation docs.
        #' ### JSON Response Example
        #' ```json
        #' {"code": "200000", "data": [{"id": "67120bbef094e200070976f6", "symbol": "BTC-USDT", "type": "limit", "side": "buy", "price": "50000", "size": "0.00001", "remainSize": "0.00001", "active": true, "createdAt": 1729235902748}]}
        #' ```
        get_open_orders = function(symbol) {
            return(get_open_orders_impl(keys = self$keys, base_url = self$base_url, symbol = symbol))
        },

        #' Get Closed Orders
        #'
        #' ### Description
        #' Retrieves all closed spot orders for a symbol via a GET request to `/api/v1/hf/orders/done`, with pagination.
        #' Calls `get_closed_orders_impl`.
        #'
        #' ### Workflow Overview
        #' 1. **Validation**: Ensures `symbol` and `limit` are valid.
        #' 2. **URL**: Builds endpoint with query parameters.
        #' 3. **Authentication**: Generates headers.
        #' 4. **API Call**: Fetches pages until complete or `max_pages` reached.
        #' 5. **Response**: Returns closed orders with datetime columns.
        #'
        #' ### API Endpoint
        #' `GET https://api.kucoin.com/api/v1/hf/orders/done`
        #'
        #' ### Usage
        #' Utilised to fetch historical closed orders for analysis.
        #'
        #' ### Official Documentation
        #' [KuCoin Get Closed Orders](https://www.kucoin.com/docs-new/rest/spot-trading/orders/get-closed-orders)
        #'
        #' ### Automated Trading Usage
        #' - **Performance Review**: Analyze `dealFunds` and `fee` to evaluate past trades, refining entry/exit points.
        #' - **Time Filters**: Use `startAt` and `endAt` to fetch specific periods (e.g., last 24 hours) for daily reconciliations.
        #' - **Pagination Control**: Set `max_pages` to limit data volume in high-frequency systems, balancing detail with performance.
        #'
        #' @param symbol Character string; trading pair (e.g., "BTC-USDT"). Required.
        #' @param side Character string; "buy" or "sell". Optional.
        #' @param type Character string; "limit" or "market". Optional.
        #' @param startAt Numeric; start time (ms). Optional.
        #' @param endAt Numeric; end time (ms). Optional.
        #' @param limit Integer; orders per page (1-100, default 20). Optional.
        #' @param max_pages Numeric; max pages to fetch (default `Inf`). Optional.
        #' @return Promise resolving to a `data.table` with columns including:
        #'   - `id` (character), `clientOid` (character), `symbol` (character), `type` (character), `side` (character),
        #'   - `price` (character), `size` (character), `dealSize` (character), `active` (logical), `createdAtDatetime` (POSIXct)
        #'   - Full schema in implementation docs.
        #' ### JSON Response Example
        #' ```json
        #' {"code": "200000", "data": {"lastId": 19814995255305, "items": [{"id": "6717422bd51c29000775ea03", "symbol": "BTC-USDT", "type": "limit", "side": "buy", "price": "70000", "size": "0.00001", "dealSize": "0.00001", "active": false, "createdAt": 1729577515444}]}}
        #' ```
        get_closed_orders = function(
            symbol,
            side = NULL,
            type = NULL,
            startAt = NULL,
            endAt = NULL,
            limit = 20,
            max_pages = Inf
        ) {
            return(get_closed_orders_impl(
                keys = self$keys,
                base_url = self$base_url,
                symbol = symbol,
                side = side,
                type = type,
                startAt = startAt,
                endAt = endAt,
                limit = limit,
                max_pages = max_pages
            ))
        }
    )
)
