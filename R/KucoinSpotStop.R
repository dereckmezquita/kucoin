# File: ./R/KucoinSpotStop.R

# box::use(
#     ./impl_spottrading_orders_stop[
#         add_stop_order_impl,
#         cancel_stop_order_by_client_oid_impl,
#         cancel_stop_order_by_order_id_impl,
#         get_stop_order_list_impl,
#         get_stop_order_by_order_id_impl,
#         get_stop_order_by_client_oid_impl,
#         cancel_stop_order_batch_impl
#     ],
#     ./utils[get_api_keys, get_base_url]
# )

#' KucoinSpotStop Class for KuCoin Spot Trading Stop Orders
#'
#' The `KucoinSpotStop` class provides an asynchronous interface for managing stop orders on KuCoin's Spot trading platform.
#' It leverages the `coro` package for non-blocking HTTP requests, returning promises that resolve to `data.table` objects.
#' This class supports placing stop orders (limit or market), canceling them by various identifiers, retrieving individual order details,
#' listing untriggered stop orders, and batch canceling orders.
#'
#' ### What is a Stop Order?
#' A stop order is a conditional order that triggers a market or limit order when the market price reaches a specified `stopPrice`. Key uses include:
#' - **Loss Limiting**: Sell an asset if its price drops to a threshold (e.g., sell BTC at $48,000 if it falls from $50,000).
#' - **Breakout Trading**: Buy an asset if its price rises past a resistance level (e.g., buy BTC at $52,000 if it breaks $51,000).
#' - **Risk Management**: Automate exits or entries without constant monitoring.
#' KuCoin supports two types: **limit stop orders** (specifying a price and size) and **market stop orders** (executing at market price with size or funds).
#'
#' ### Workflow Overview
#' Not applicable (class definition overview).
#'
#' ### API Endpoint
#' Not applicable (class-level documentation; see individual methods for specific endpoints).
#'
#' ### Usage
#' Utilised by traders to programmatically manage stop orders on KuCoin Spot markets. The class is initialized with API credentials,
#' automatically loaded via `get_api_keys()` if not provided, and a base URL from `get_base_url()`. For detailed endpoint
#' information, parameters, and response schemas, refer to the official [KuCoin API Documentation](https://www.kucoin.com/docs-new).
#'
#' ### Official Documentation
#' [KuCoin API Documentation - Spot Trading Orders](https://www.kucoin.com/docs-new/rest/spot-trading/orders/introduction)
#'
#' @section Methods:
#' - **initialize(keys, base_url):** Initialises the object with API credentials and the base URL.
#' - **add_stop_order(type, symbol, side, stopPrice, ...):** Places a new stop order (limit or market).
#' - **cancel_stop_order_by_order_id(orderId):** Cancels a stop order by its system-generated `orderId`.
#' - **cancel_stop_order_by_client_oid(clientOid, symbol):** Cancels a stop order by its client-assigned `clientOid`.
#' - **cancel_stop_order_batch(query):** Batch cancels stop orders with optional filters.
#' - **get_stop_order_by_order_id(orderId):** Retrieves detailed stop order info by `orderId`.
#' - **get_stop_order_by_client_oid(clientOid, symbol):** Retrieves detailed stop order info by `clientOid`.
#' - **get_stop_order_list(query):** Retrieves a paginated list of untriggered stop orders.
#'
#' @return Not applicable (class definition; see individual methods for return values).
#'
#' @examples
#' \dontrun{
#' # Comprehensive example demonstrating key methods
#' main_async <- coro::async(function() {
#'   # Initialise the class
#'   stop <- KucoinSpotStop$new()
#'
#'   # Place a limit stop order
#'   order <- await(stop$add_stop_order(
#'     type = "limit",
#'     symbol = "BTC-USDT",
#'     side = "buy",
#'     stopPrice = "49000",
#'     price = "50000",
#'     size = "0.00001",
#'     clientOid = "stop_test_001",
#'     remark = "Test Stop"
#'   ))
#'   print("New Stop Order:")
#'   print(order)
#'
#'   # Retrieve order details by orderId
#'   details <- await(stop$get_stop_order_by_order_id(order$orderId))
#'   print("Stop Order Details:")
#'   print(details)
#'
#'   # Cancel the order by orderId
#'   canceled <- await(stop$cancel_stop_order_by_order_id(order$orderId))
#'   print("Canceled Order IDs:")
#'   print(canceled)
#'
#'   # List all stop orders
#'   order_list <- await(stop$get_stop_order_list(
#'     query = list(symbol = "BTC-USDT", pageSize = 10)
#'   ))
#'   print("Stop Order List:")
#'   print(order_list)
#' })
#' main_async()
#' while (!later::loop_empty()) later::run_now()
#' }
#'
#' @importFrom R6 R6Class
#' @export
KucoinSpotStop <- R6::R6Class(
    "KucoinSpotStop",
    public = list(
        #' @field keys List containing KuCoin API keys (`api_key`, `api_secret`, `api_passphrase`, `key_version`).
        keys = NULL,
        #' @field base_url Character string representing the base URL for KuCoin API endpoints.
        base_url = NULL,

        #' Initialise a New KucoinSpotStop Object
        #'
        #' ### Description
        #' Initialises a `KucoinSpotStop` object with API credentials and a base URL for managing stop orders on KuCoin Spot markets asynchronously.
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
        #' Utilised to create an instance of the class with authentication details for stop order management.
        #'
        #' ### Official Documentation
        #' [KuCoin API Authentication](https://www.kucoin.com/docs-new/rest/introduction#authentication)
        #'
        #' ### Automated Trading Usage
        #' - **Setup**: Use this method to initialise a dedicated instance for stop order management within your trading bot. Store the instance in a global environment or session to reuse across trading cycles.
        #' - **Credentials**: Rely on `get_api_keys()` to load credentials securely from an environment file or vault, ensuring your bot remains portable and secure across different deployment environments.
        #'
        #' @param keys List containing API configuration parameters from `get_api_keys()`, including:
        #'   - `api_key`: Character string; your KuCoin API key.
        #'   - `api_secret`: Character string; your KuCoin API secret.
        #'   - `api_passphrase`: Character string; your KuCoin API passphrase.
        #'   - `key_version`: Character string; API key version (e.g., `"2"`).
        #'   Defaults to `get_api_keys()`.
        #' @param base_url Character string representing the base URL for the API. Defaults to `get_base_url()`.
        #'
        #' @return A new instance of the `KucoinSpotStop` class.
        initialize = function(keys = get_api_keys(), base_url = get_base_url()) {
            self$keys <- keys
            self$base_url <- base_url
        },

        #' Add Stop Order
        #'
        #' ### Description
        #' Places a new stop order (limit or market) on KuCoin Spot trading asynchronously via a POST request to `/api/v1/stop-order`.
        #' Triggers when the market price hits `stopPrice`. Calls `add_stop_order_impl`.
        #'
        #' ### Workflow Overview
        #' 1. **Validation**: Ensures required parameters and type-specific fields (e.g., `price` for limit).
        #' 2. **Request Body**: Constructs JSON with order details.
        #' 3. **Authentication**: Generates headers asynchronously.
        #' 4. **API Call**: Sends POST request with 3-second timeout.
        #' 5. **Response**: Returns a `data.table` with `orderId` and `clientOid`.
        #'
        #' ### API Endpoint
        #' `POST https://api.kucoin.com/api/v1/stop-order`
        #'
        #' ### Usage
        #' Utilised to set conditional orders for risk management or breakout trading.
        #'
        #' ### Official Documentation
        #' [KuCoin Add Stop Order](https://www.kucoin.com/docs-new/rest/spot-trading/orders/add-stop-order)
        #'
        #' ### Automated Trading Usage
        #' - **Risk Control**: Use limit stop orders to exit positions at predefined loss levels (e.g., sell BTC at $48,000 if it drops below $49,000). Pair with market data feeds to set `stopPrice` dynamically based on volatility or support levels.
        #' - **Breakout Strategy**: Place market stop orders to enter positions on price breakouts (e.g., buy ETH at $3,000 if it exceeds $2,950). Combine with technical indicators like moving averages or Bollinger Bands to determine `stopPrice`.
        #' - **Position Sizing**: For market orders, use `funds` to control exact capital allocation dynamically (e.g., allocate $100 to buy BTC when triggered), adjusting based on account balance or risk percentage.
        #' - **Tracking**: Assign unique `clientOid` values (e.g., UUIDs with strategy tags) to trace orders back to specific trading rules or sessions in your system logs.
        #'
        #' @param type Character string; "limit" or "market". Required.
        #' @param symbol Character string; trading pair (e.g., "BTC-USDT"). Required.
        #' @param side Character string; "buy" or "sell". Required.
        #' @param stopPrice Character string; trigger price (e.g., "49000"). Required.
        #' @param clientOid Character string; unique client ID (max 40 chars). Optional.
        #' @param price Character string; limit order price (e.g., "50000"). Required for limit orders.
        #' @param size Character string; order quantity (e.g., "0.00001"). Required for limit, optional for market.
        #' @param funds Character string; funds for market orders (e.g., "1"). Optional for market.
        #' @param stp Character string; self-trade prevention: "DC", "CO", "CN", "CB". Optional.
        #' @param remark Character string; remarks (max 20 chars). Optional.
        #' @param timeInForce Character string; "GTC", "GTT", "IOC", "FOK". Optional.
        #' @param cancelAfter Integer; seconds until cancellation for GTT. Optional.
        #' @param postOnly Logical; post-only flag. Optional.
        #' @param hidden Logical; hidden order flag. Optional.
        #' @param iceberg Logical; iceberg order flag. Optional.
        #' @param visibleSize Character string; visible size for iceberg orders. Optional.
        #' @param tradeType Character string; "TRADE" (default). Optional.
        #'
        #' @return Promise resolving to a `data.table` with:
        #'   - `orderId` (character): System-generated order ID.
        #'   - `clientOid` (character): Client-assigned order ID.
        #'
        #' ### JSON Response Example
        #' ```json
        #' {
        #'   "code": "200000",
        #'   "data": {
        #'     "orderId": "670fd33bf9406e0007ab3945",
        #'     "clientOid": "5c52e11203aa677f33e493fb"
        #'   }
        #' }
        #' ```
        add_stop_order = function(
            type,
            symbol,
            side,
            stopPrice,
            clientOid = NULL,
            price = NULL,
            size = NULL,
            funds = NULL,
            stp = NULL,
            remark = NULL,
            timeInForce = NULL,
            cancelAfter = NULL,
            postOnly = NULL,
            hidden = NULL,
            iceberg = NULL,
            visibleSize = NULL,
            tradeType = "TRADE"
        ) {
            return(add_stop_order_impl(
                keys = self$keys,
                base_url = self$base_url,
                type = type,
                symbol = symbol,
                side = side,
                stopPrice = stopPrice,
                clientOid = clientOid,
                price = price,
                size = size,
                funds = funds,
                stp = stp,
                remark = remark,
                timeInForce = timeInForce,
                cancelAfter = cancelAfter,
                postOnly = postOnly,
                hidden = hidden,
                iceberg = iceberg,
                visibleSize = visibleSize,
                tradeType = tradeType
            ))
        },

        #' Cancel Stop Order By OrderId
        #'
        #' ### Description
        #' Cancels a stop order by its system-generated `orderId` asynchronously via a DELETE request to `/api/v1/stop-order/{orderId}`.
        #' Calls `cancel_stop_order_by_order_id_impl`.
        #'
        #' ### Workflow Overview
        #' 1. **Validation**: Ensures `orderId` is valid.
        #' 2. **URL**: Constructs endpoint with `orderId`.
        #' 3. **Authentication**: Generates headers.
        #' 4. **API Call**: Sends DELETE request.
        #' 5. **Response**: Returns canceled order IDs.
        #'
        #' ### API Endpoint
        #' `DELETE https://api.kucoin.com/api/v1/stop-order/{orderId}`
        #'
        #' ### Usage
        #' Utilised to remove a stop order by its system ID, e.g., when adjusting strategies.
        #'
        #' ### Official Documentation
        #' [KuCoin Cancel Stop Order By OrderId](https://www.kucoin.com/docs-new/rest/spot-trading/orders/cancel-stop-order-by-orderld)
        #'
        #' ### Automated Trading Usage
        #' - **Dynamic Adjustment**: Cancel stop orders when market conditions invalidate your initial setup (e.g., cancel a $48,000 BTC sell stop if a bullish signal emerges). Use with real-time price feeds to trigger cancellation.
        #' - **Order Cleanup**: Periodically cancel stale stop orders (e.g., older than 24 hours) by tracking `orderId` and `createdAt` from `get_stop_order_by_order_id`, maintaining the 20-order limit per pair.
        #' - **Confirmation**: After cancellation, verify status via `get_stop_order_by_order_id` or WebSocket to ensure the order is removed before placing new ones.
        #'
        #' @param orderId Character string; system-generated order ID (e.g., "671124f9365ccb00073debd4"). Required.
        #'
        #' @return Promise resolving to a `data.table` with:
        #'   - `cancelledOrderIds` (character): ID of the canceled order.
        #'
        #' ### JSON Response Example
        #' ```json
        #' {
        #'   "code": "200000",
        #'   "data": {
        #'     "cancelledOrderIds": ["671124f9365ccb00073debd4"]
        #'   }
        #' }
        #' ```
        cancel_stop_order_by_order_id = function(orderId) {
            return(cancel_stop_order_by_order_id_impl(
                keys = self$keys,
                base_url = self$base_url,
                orderId = orderId
            ))
        },

        #' Cancel Stop Order By ClientOid
        #'
        #' ### Description
        #' Cancels a stop order by its client-assigned `clientOid` asynchronously via a DELETE request to `/api/v1/stop-order/cancelOrderByClientOid`.
        #' Calls `cancel_stop_order_by_client_oid_impl`.
        #'
        #' ### Workflow Overview
        #' 1. **Validation**: Ensures `clientOid` is valid, `symbol` optional.
        #' 2. **URL**: Constructs endpoint with query parameters.
        #' 3. **Authentication**: Generates headers.
        #' 4. **API Call**: Sends DELETE request.
        #' 5. **Response**: Returns canceled order details.
        #'
        #' ### API Endpoint
        #' `DELETE https://api.kucoin.com/api/v1/stop-order/cancelOrderByClientOid`
        #'
        #' ### Usage
        #' Utilised to cancel a stop order using a custom client ID, ideal for local tracking.
        #'
        #' ### Official Documentation
        #' [KuCoin Cancel Stop Order By ClientOid](https://www.kucoin.com/docs-new/rest/spot-trading/orders/cancel-stop-order-by-clientoid)
        #'
        #' ### Automated Trading Usage
        #' - **Custom Management**: Use `clientOid` to cancel specific orders tracked in your system (e.g., tagged by strategy ID). This avoids needing to map system `orderId` values.
        #' - **Symbol Filtering**: Include `symbol` to ensure cancellation targets the correct trading pair in multi-pair strategies, reducing errors in high-frequency bots.
        #' - **Event-Driven**: Trigger cancellation based on external signals (e.g., news events or volatility spikes) by referencing `clientOid` stored in your order database.
        #'
        #' @param clientOid Character string; client-assigned order ID (e.g., "689ff597f4414061aa819cc414836abd"). Required.
        #' @param symbol Character string; trading pair (e.g., "BTC-USDT"). Optional.
        #'
        #' @return Promise resolving to a `data.table` with:
        #'   - `cancelledOrderId` (character): System-assigned ID of the canceled order.
        #'   - `clientOid` (character): Client-assigned order ID.
        #'
        #' ### JSON Response Example
        #' ```json
        #' {
        #'   "code": "200000",
        #'   "data": {
        #'     "cancelledOrderId": "vs8hoo8ksc8mario0035a74n",
        #'     "clientOid": "689ff597f4414061aa819cc414836abd"
        #'   }
        #' }
        #' ```
        cancel_stop_order_by_client_oid = function(clientOid, symbol = NULL) {
            return(cancel_stop_order_by_client_oid_impl(
                keys = self$keys,
                base_url = self$base_url,
                symbol = symbol,
                clientOid = clientOid
            ))
        },

        #' Batch Cancel Stop Orders
        #'
        #' ### Description
        #' Cancels multiple stop orders asynchronously via a DELETE request to `/api/v1/stop-order/cancel`.
        #' Calls `cancel_stop_order_batch_impl`.
        #'
        #' ### Workflow Overview
        #' 1. **Validation**: Checks `query` parameters.
        #' 2. **URL**: Builds endpoint with query string.
        #' 3. **Authentication**: Generates headers.
        #' 4. **API Call**: Sends DELETE request.
        #' 5. **Response**: Returns all canceled order IDs.
        #'
        #' ### API Endpoint
        #' `DELETE https://api.kucoin.com/api/v1/stop-order/cancel`
        #'
        #' ### Usage
        #' Utilised to remove multiple stop orders, optionally filtered by `symbol`, `tradeType`, or `orderIds`.
        #'
        #' ### Official Documentation
        #' [KuCoin Batch Cancel Stop Orders](https://www.kucoin.com/docs-new/rest/spot-trading/orders/batch-cancel-stop-orders)
        #'
        #' ### Automated Trading Usage
        #' - **Portfolio Reset**: Cancel all stop orders for a `symbol` (e.g., "BTC-USDT") when exiting a market or during a strategy overhaul. Use with `symbol` filter to target specific pairs.
        #' - **Bulk Cleanup**: Periodically clear outdated orders by supplying a list of `orderIds` from your tracking system, ensuring compliance with the 20-order limit per pair.
        #' - **Volatility Response**: Batch cancel during sudden market moves (e.g., flash crashes) to prevent unwanted triggers, using real-time volatility indicators to initiate the call.
        #'
        #' @param query Named list; optional filters (e.g., `list(symbol = "ETH-BTC", orderIds = "id1,id2")`).
        #'
        #' @return Promise resolving to a `data.table` with:
        #'   - `cancelledOrderIds` (list): List of canceled order IDs.
        #'
        #' ### JSON Response Example
        #' ```json
        #' {
        #'   "code": "200000",
        #'   "data": {
        #'     "cancelledOrderIds": ["671124f9365ccb00073debd4"]
        #'   }
        #' }
        #' ```
        cancel_stop_order_batch = function(query = list()) {
            return(cancel_stop_order_batch_impl(
                keys = self$keys,
                base_url = self$base_url,
                query = query
            ))
        },

        #' Get Stop Order By OrderId
        #'
        #' ### Description
        #' Retrieves detailed stop order info by `orderId` asynchronously via a GET request to `/api/v1/stop-order/{orderId}`.
        #' Calls `get_stop_order_by_order_id_impl`.
        #'
        #' ### Workflow Overview
        #' 1. **Validation**: Ensures `orderId` is valid.
        #' 2. **URL**: Constructs endpoint with `orderId`.
        #' 3. **Authentication**: Generates headers.
        #' 4. **API Call**: Sends GET request.
        #' 5. **Response**: Returns detailed order info with datetime columns.
        #'
        #' ### API Endpoint
        #' `GET https://api.kucoin.com/api/v1/stop-order/{orderId}`
        #'
        #' ### Usage
        #' Utilised to inspect a stop order’s full details, including status and parameters.
        #'
        #' ### Official Documentation
        #' [KuCoin Get Stop Order By OrderId](https://www.kucoin.com/docs-new/rest/spot-trading/orders/get-stop-order-by-orderld)
        #'
        #' ### Automated Trading Usage
        #' - **Status Monitoring**: Check `status` (e.g., "NEW" or "TRIGGERED") to confirm order state before acting (e.g., placing replacements). Use in a polling loop or post-event check.
        #' - **Audit Trail**: Log detailed order info (`price`, `stopPrice`, `createdAtDatetime`) to analyze strategy performance or debug execution issues.
        #' - **Conditional Logic**: Adjust strategies if `stopTriggerTime` indicates recent activation, triggering follow-up orders or alerts in your system.
        #'
        #' @param orderId Character string; system-generated order ID (e.g., "vs8hoo8q2ceshiue003b67c0"). Required.
        #'
        #' @return Promise resolving to a `data.table` with columns including:
        #'   - `id` (character)
        #'   - `symbol` (character)
        #'   - `status` (character)
        #'   - `type` (character)
        #'   - `side` (character)
        #'   - `price` (character)
        #'   - `size` (character)
        #'   - `stopPrice` (character)
        #'   - `createdAtDatetime` (POSIXct)
        #'   - Full schema in implementation docs.
        #'
        #' ### JSON Response Example
        #' ```json
        #' {
        #'   "code": "200000",
        #'   "data": {
        #'     "id": "vs8hoo8q2ceshiue003b67c0",
        #'     "symbol": "KCS-USDT",
        #'     "status": "NEW",
        #'     "type": "limit",
        #'     "side": "buy",
        #'     "price": "0.01",
        #'     "size": "0.01",
        #'     "stopPrice": "10",
        #'     "createdAt": 1629098781128
        #'   }
        #' }
        #' ```
        get_stop_order_by_order_id = function(orderId) {
            return(get_stop_order_by_order_id_impl(
                keys = self$keys,
                base_url = self$base_url,
                orderId = orderId
            ))
        },

        #' Get Stop Order By ClientOid
        #'
        #' ### Description
        #' Retrieves detailed stop order info by `clientOid` asynchronously via a GET request to `/api/v1/stop-order/queryOrderByClientOid`.
        #' Calls `get_stop_order_by_client_oid_impl`.
        #'
        #' ### Workflow Overview
        #' 1. **Validation**: Ensures `clientOid` is valid, `symbol` optional.
        #' 2. **URL**: Constructs endpoint with query parameters.
        #' 3. **Authentication**: Generates headers.
        #' 4. **API Call**: Sends GET request.
        #' 5. **Response**: Returns detailed order info with datetime columns.
        #'
        #' ### API Endpoint
        #' `GET https://api.kucoin.com/api/v1/stop-order/queryOrderByClientOid`
        #'
        #' ### Usage
        #' Utilised to fetch order details using a custom client ID, ideal for tracking.
        #'
        #' ### Official Documentation
        #' [KuCoin Get Stop Order By ClientOid](https://www.kucoin.com/docs-new/rest/spot-trading/get-stop-order-by-clientoid)
        #'
        #' ### Automated Trading Usage
        #' - **Order Sync**: Verify order details against your system’s records using `clientOid`, ensuring alignment post-placement or after network disruptions.
        #' - **Multi-Pair**: Use `symbol` to disambiguate orders in multi-pair strategies, fetching precise details for targeted actions (e.g., canceling or adjusting).
        #' - **Event Handling**: Check `status` and `stopTriggerTime` to react to order triggers, updating position trackers or risk calculators in real time.
        #'
        #' @param clientOid Character string; client-assigned order ID (e.g., "2b700942b5db41cebe578cff48960e09"). Required.
        #' @param symbol Character string; trading pair (e.g., "KCS-USDT"). Optional.
        #'
        #' @return Promise resolving to a `data.table` with columns including:
        #'   - `id` (character)
        #'   - `symbol` (character)
        #'   - `status` (character)
        #'   - `type` (character)
        #'   - `side` (character)
        #'   - `price` (character)
        #'   - `size` (character)
        #'   - `stopPrice` (character)
        #'   - `createdAtDatetime` (POSIXct)
        #'   - Full schema in implementation docs.
        #'
        #' ### JSON Response Example
        #' ```json
        #' {
        #'   "code": "200000",
        #'   "data": [{
        #'     "id": "vs8hoo8os561f5np0032vngj",
        #'     "symbol": "KCS-USDT",
        #'     "status": "NEW",
        #'     "type": "limit",
        #'     "side": "buy",
        #'     "price": "0.01",
        #'     "size": "0.01",
        #'     "stopPrice": "1",
        #'     "clientOid": "2b700942b5db41cebe578cff48960e09",
        #'     "createdAt": 1629020492837
        #'   }]
        #' }
        #' ```
        get_stop_order_by_client_oid = function(clientOid, symbol = NULL) {
            return(get_stop_order_by_client_oid_impl(
                keys = self$keys,
                base_url = self$base_url,
                clientOid = clientOid,
                symbol = symbol
            ))
        },

        #' Get Stop Order List
        #'
        #' ### Description
        #' Retrieves a paginated list of untriggered stop orders asynchronously via a GET request to `/api/v1/stop-order`.
        #' Calls `get_stop_order_list_impl`.
        #'
        #' ### Workflow Overview
        #' 1. **Validation**: Checks `query` parameters.
        #' 2. **URL**: Builds endpoint with query string.
        #' 3. **Authentication**: Generates headers.
        #' 4. **API Call**: Sends GET request.
        #' 5. **Response**: Returns a list of stop orders with datetime columns.
        #'
        #' ### API Endpoint
        #' `GET https://api.kucoin.com/api/v1/stop-order`
        #'
        #' ### Usage
        #' Utilised to review all untriggered stop orders, with optional filtering.
        #'
        #' ### Official Documentation
        #' [KuCoin Get Stop Orders List](https://www.kucoin.com/docs-new/rest/spot-trading/orders/get-stop-orders-list)
        #'
        #' ### Automated Trading Usage
        #' - **Portfolio Oversight**: Regularly fetch the list (e.g., hourly) to monitor active stop orders, ensuring they align with current market conditions and strategy goals.
        #' - **Limit Management**: Use `pageSize` and filter by `symbol` to track order counts per pair, canceling excess orders via `cancel_stop_order_batch` to stay under the 20-order cap.
        #' - **Time-Based Actions**: Filter by `startAt` and `endAt` to identify orders nearing trigger points or overdue for review, automating adjustments or cancellations.
        #'
        #' @param query Named list; optional filters (e.g., `list(symbol = "BTC-USDT", pageSize = 10)`).
        #'
        #' @return Promise resolving to a `data.table` with columns including:
        #'   - `id` (character)
        #'   - `symbol` (character)
        #'   - `status` (character)
        #'   - `type` (character)
        #'   - `side` (character)
        #'   - `price` (character)
        #'   - `size` (character)
        #'   - `stopPrice` (character)
        #'   - `createdAtDatetime` (POSIXct)
        #'   - Full schema in implementation docs.
        #'
        #' ### JSON Response Example
        #' ```json
        #' {
        #'   "code": "200000",
        #'   "data": {
        #'     "currentPage": 1,
        #'     "pageSize": 50,
        #'     "totalNum": 1,
        #'     "totalPage": 1,
        #'     "items": [{
        #'       "id": "vs8hoo8kqjnklv4m0038lrfq",
        #'       "symbol": "KCS-USDT",
        #'       "status": "NEW",
        #'       "type": "limit",
        #'       "side": "buy",
        #'       "price": "0.01",
        #'       "size": "0.01",
        #'       "stopPrice": "10",
        #'       "createdAt": 1628755183704
        #'     }]
        #'   }
        #' }
        #' ```
        get_stop_order_list = function(query = list()) {
            return(get_stop_order_list_impl(
                keys = self$keys,
                base_url = self$base_url,
                query = query
            ))
        }
    )
)
