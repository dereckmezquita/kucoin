# File: ./R/KucoinSpotOco.R

# box::use(
#     ./impl_spottrading_orders_oco[
#         add_oco_order_impl,
#         cancel_oco_order_by_order_id_impl,
#         cancel_oco_order_by_client_oid_impl,
#         cancel_oco_order_batch_impl,
#         get_oco_order_by_order_id_impl,
#         get_oco_order_by_client_oid_impl,
#         get_oco_order_detail_by_order_id_impl,
#         get_oco_order_list_impl
#     ],
#     ./utils[get_api_keys, get_base_url]
# )

#' KucoinSpotOco Class for KuCoin Spot Trading OCO Orders
#'
#' The `KucoinSpotOco` class provides an asynchronous interface for managing One-Cancels-the-Other (OCO) orders on KuCoin's Spot trading platform.
#' It leverages the `coro` package for non-blocking HTTP requests, returning promises that typically resolve to `data.table` objects.
#' This class supports placing OCO orders, canceling them by various identifiers, retrieving order details, and listing existing OCO orders.
#'
#' ### What is an OCO Order?
#' An OCO order is a paired trading strategy combining a limit order (e.g., to take profits) with a stop-limit order (e.g., to limit losses).
#' When one order executes, the other is automatically canceled. This is ideal for:
#' - **Risk Management**: Set a stop-loss to cap losses (e.g., sell BTC at $48,000 if bought at $50,000).
#' - **Profit Taking**: Secure gains at a target price (e.g., sell BTC at $55,000).
#' - **Automation**: Manage trades in volatile markets without constant monitoring.
#'
#' ### Workflow Overview
#' Not applicable (class definition overview).
#'
#' ### API Endpoint
#' Not applicable (class-level documentation; see individual methods for specific endpoints).
#'
#' ### Usage
#' Utilised by traders to programmatically manage OCO orders on KuCoin Spot markets. The class is initialized with API credentials,
#' automatically loaded via `get_api_keys()` if not provided, and a base URL from `get_base_url()`. For detailed endpoint
#' information, parameters, and response schemas, refer to the official [KuCoin API Documentation](https://www.kucoin.com/docs-new).
#'
#' ### Official Documentation
#' [KuCoin API Documentation](https://www.kucoin.com/docs-new/introduction)
#' 
#' - [Add OCO Order](https://www.kucoin.com/docs-new/rest/spot-trading/orders/add-oco-order)
#' - [Cancel OCO Order By OrderId](https://www.kucoin.com/docs-new/rest/spot-trading/orders/cancel-oco-order-by-orderld)
#' - [Cancel OCO Order By ClientOid](https://www.kucoin.com/docs-new/rest/spot-trading/orders/cancel-oco-order-by-clientoid)
#' - [Batch Cancel OCO Orders](https://www.kucoin.com/docs-new/rest/spot-trading/orders/batch-cancel-oco-order)
#' - [Get OCO Order By OrderId](https://www.kucoin.com/docs-new/rest/spot-trading/orders/get-oco-order-by-orderld)
#' - [Get OCO Order By ClientOid](https://www.kucoin.com/docs-new/rest/spot-trading/orders/get-oco-order-by-clientoid)
#' - [Get OCO Order Detail By OrderId](https://www.kucoin.com/docs-new/rest/spot-trading/orders/get-oco-order-detail-by-orderld)
#' - [Get OCO Order List](https://www.kucoin.com/docs-new/rest/spot-trading/orders/get-oco-order-list)
#'
#' @section Methods:
#' - **initialize(keys, base_url):** Initialises the object with API credentials and the base URL.
#' - **add_oco_order(symbol, side, price, size, clientOid, stopPrice, limitPrice, remark, tradeType):** Places a new OCO order.
#' - **cancel_oco_order_by_order_id(orderId):** Cancels an OCO order by its system-generated `orderId`.
#' - **cancel_oco_order_by_client_oid(clientOid):** Cancels an OCO order by its client-assigned `clientOid`.
#' - **cancel_oco_order_batch(query):** Batch cancels OCO orders with optional filters.
#' - **get_oco_order_by_order_id(orderId):** Retrieves basic OCO order info by `orderId`.
#' - **get_oco_order_by_client_oid(clientOid):** Retrieves basic OCO order info by `clientOid`.
#' - **get_oco_order_detail_by_order_id(orderId):** Retrieves detailed OCO order info by `orderId`.
#' - **get_oco_order_list(query):** Retrieves a paginated list of current OCO orders.
#'
#' @return Not applicable (class definition; see individual methods for return values).
#'
#' @examples
#' \dontrun{
#' # Comprehensive example demonstrating key methods
#' main_async <- coro::async(function() {
#'   # Initialise the class
#'   oco <- KucoinSpotOco$new()
#'
#'   # Place a new OCO order
#'   order <- await(oco$add_oco_order(
#'     symbol = "BTC-USDT",
#'     side = "buy",
#'     price = "94000",
#'     size = "0.1",
#'     clientOid = "oco_test_001",
#'     stopPrice = "98000",
#'     limitPrice = "96000",
#'     remark = "Test OCO"
#'   ))
#'   print("New OCO Order:")
#'   print(order)
#'
#'   # Retrieve order details
#'   details <- await(oco$get_oco_order_detail_by_order_id(order$orderId))
#'   print("OCO Order Details:")
#'   print(details)
#'
#'   # Cancel the order by orderId
#'   canceled <- await(oco$cancel_oco_order_by_order_id(order$orderId))
#'   print("Canceled Order IDs:")
#'   print(canceled)
#'
#'   # List all OCO orders
#'   order_list <- await(oco$get_oco_order_list(
#'     query = list(symbol = "BTC-USDT", pageSize = 10)
#'   ))
#'   print("OCO Order List:")
#'   print(order_list)
#' })
#' main_async()
#' while (!later::loop_empty()) later::run_now()
#' }
#'
#' @importFrom R6 R6Class
#' @export
KucoinSpotOco <- R6::R6Class(
    "KucoinSpotOco",
    public = list(
        #' @field keys List containing KuCoin API keys (`api_key`, `api_secret`, `api_passphrase`, `key_version`).
        keys = NULL,
        #' @field base_url Character string representing the base URL for KuCoin API endpoints.
        base_url = NULL,

        #' Initialise a New KucoinSpotOco Object
        #'
        #' ### Description
        #' Initialises a `KucoinSpotOco` object with API credentials and a base URL for managing OCO orders on KuCoin Spot markets asynchronously.
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
        #' Utilised to create an instance of the class with authentication details for OCO order management.
        #'
        #' ### Official Documentation
        #' [KuCoin API Authentication](https://www.kucoin.com/docs-new/rest/introduction#authentication)
        #'
        #' @param keys List containing API configuration parameters from `get_api_keys()`, including:
        #'   - `api_key`: Character string; your KuCoin API key.
        #'   - `api_secret`: Character string; your KuCoin API secret.
        #'   - `api_passphrase`: Character string; your KuCoin API passphrase.
        #'   - `key_version`: Character string; API key version (e.g., `"2"`).
        #'   Defaults to `get_api_keys()`.
        #' @param base_url Character string representing the base URL for the API. Defaults to `get_base_url()`.
        #'
        #' @return A new instance of the `KucoinSpotOco` class.
        initialize = function(keys = get_api_keys(), base_url = get_base_url()) {
            self$keys <- keys
            self$base_url <- base_url
        },

        #' Add OCO Order
        #'
        #' ### Description
        #' Places a new OCO order on KuCoin Spot trading asynchronously by sending a POST request to `/api/v3/oco/order`.
        #' Combines a limit order and a stop-limit order, where executing one cancels the other. Calls `add_oco_order_impl`.
        #'
        #' ### Workflow Overview
        #' 1. **Validation**: Checks required parameters and enums (e.g., `side`).
        #' 2. **Request Body**: Constructs JSON with order details.
        #' 3. **Authentication**: Generates headers asynchronously.
        #' 4. **API Call**: Sends POST request with 3-second timeout.
        #' 5. **Response**: Processes into a `data.table` with the order ID.
        #'
        #' ### API Endpoint
        #' `POST https://api.kucoin.com/api/v3/oco/order`
        #'
        #' ### Usage
        #' Utilised to automate trading strategies with paired profit-taking and loss-limiting orders.
        #'
        #' ### Official Documentation
        #' [KuCoin Add OCO Order](https://www.kucoin.com/docs-new/rest/spot-trading/orders/add-oco-order)
        #'
        #' @param symbol Character string; trading pair (e.g., "BTC-USDT"). Required.
        #' @param side Character string; "buy" or "sell". Required.
        #' @param price Character string; limit order price (e.g., "94000"). Required.
        #' @param size Character string; order quantity (e.g., "0.1"). Required.
        #' @param clientOid Character string; unique client ID (max 40 chars). Required.
        #' @param stopPrice Character string; stop-limit trigger price (e.g., "98000"). Required.
        #' @param limitPrice Character string; stop-limit price (e.g., "96000"). Required.
        #' @param remark Character string; optional remarks (max 20 chars).
        #' @param tradeType Character string; "TRADE" (default).
        #'
        #' @return Promise resolving to a `data.table` with:
        #'   - `orderId` (character): System-generated OCO order ID.
        #'
        #' ### JSON Response Example
        #' ```json
        #' {
        #'   "code": "200000",
        #'   "data": {
        #'     "orderId": "674c316e688dea0007c7b986"
        #'   }
        #' }
        #' ```
        add_oco_order = function(symbol, side, price, size, clientOid, stopPrice, limitPrice, remark = NULL, tradeType = "TRADE") {
            return(add_oco_order_impl(
                keys = self$keys,
                base_url = self$base_url,
                symbol = symbol,
                side = side,
                price = price,
                size = size,
                clientOid = clientOid,
                stopPrice = stopPrice,
                limitPrice = limitPrice,
                remark = remark,
                tradeType = tradeType
            ))
        },

        #' Cancel OCO Order By OrderId
        #'
        #' ### Description
        #' Cancels an OCO order using its system-generated `orderId` asynchronously via a DELETE request to `/api/v3/oco/order/{orderId}`.
        #' Calls `cancel_oco_order_by_order_id_impl`.
        #'
        #' ### Workflow Overview
        #' 1. **Validation**: Ensures `orderId` is valid.
        #' 2. **URL**: Constructs endpoint with `orderId`.
        #' 3. **Authentication**: Generates headers.
        #' 4. **API Call**: Sends DELETE request.
        #' 5. **Response**: Returns canceled order IDs.
        #'
        #' ### API Endpoint
        #' `DELETE https://api.kucoin.com/api/v3/oco/order/{orderId}`
        #'
        #' ### Usage
        #' Utilised to remove an OCO order by its system ID, e.g., for strategy adjustments.
        #'
        #' ### Official Documentation
        #' [KuCoin Cancel OCO Order By OrderId](https://www.kucoin.com/docs-new/rest/spot-trading/orders/cancel-oco-order-by-orderld)
        #'
        #' @param orderId Character string; system-generated order ID. Required.
        #'
        #' @return Promise resolving to a `data.table` with:
        #'   - `cancelledOrderIds` (list): List of canceled limit and stop-limit order IDs.
        #'
        #' ### JSON Response Example
        #' ```json
        #' {
        #'   "code": "200000",
        #'   "data": {
        #'     "cancelledOrderIds": ["vs93gpqc6kkmkk57003gok16", "vs93gpqc6kkmkk57003gok17"]
        #'   }
        #' }
        #' ```
        cancel_oco_order_by_order_id = function(orderId) {
            return(cancel_oco_order_by_order_id_impl(
                keys = self$keys,
                base_url = self$base_url,
                orderId = orderId
            ))
        },

        #' Cancel OCO Order By ClientOid
        #'
        #' ### Description
        #' Cancels an OCO order using its client-assigned `clientOid` asynchronously via a DELETE request to `/api/v3/oco/client-order/{clientOid}`.
        #' Calls `cancel_oco_order_by_client_oid_impl`.
        #'
        #' ### Workflow Overview
        #' 1. **Validation**: Ensures `clientOid` is valid.
        #' 2. **URL**: Constructs endpoint with `clientOid`.
        #' 3. **Authentication**: Generates headers.
        #' 4. **API Call**: Sends DELETE request.
        #' 5. **Response**: Returns canceled order IDs.
        #'
        #' ### API Endpoint
        #' `DELETE https://api.kucoin.com/api/v3/oco/client-order/{clientOid}`
        #'
        #' ### Usage
        #' Utilised to cancel an OCO order using a custom client ID, ideal for local tracking.
        #'
        #' ### Official Documentation
        #' [KuCoin Cancel OCO Order By ClientOid](https://www.kucoin.com/docs-new/rest/spot-trading/orders/cancel-oco-order-by-clientoid)
        #'
        #' @param clientOid Character string; client-assigned order ID. Required.
        #'
        #' @return Promise resolving to a `data.table` with:
        #'   - `cancelledOrderIds` (list): List of canceled limit and stop-limit order IDs.
        #'
        #' ### JSON Response Example
        #' ```json
        #' {
        #'   "code": "200000",
        #'   "data": {
        #'     "cancelledOrderIds": ["vs93gpqc6r0mkk57003gok3h", "vs93gpqc6r0mkk57003gok3i"]
        #'   }
        #' }
        #' ```
        cancel_oco_order_by_client_oid = function(clientOid) {
            return(cancel_oco_order_by_client_oid_impl(
                keys = self$keys,
                base_url = self$base_url,
                clientOid = clientOid
            ))
        },

        #' Batch Cancel OCO Orders
        #'
        #' ### Description
        #' Cancels multiple OCO orders asynchronously via a DELETE request to `/api/v3/oco/orders`. Calls `cancel_oco_order_batch_impl`.
        #'
        #' ### Workflow Overview
        #' 1. **Validation**: Checks `query` parameters.
        #' 2. **URL**: Builds endpoint with query string.
        #' 3. **Authentication**: Generates headers.
        #' 4. **API Call**: Sends DELETE request.
        #' 5. **Response**: Returns all canceled order IDs.
        #'
        #' ### API Endpoint
        #' `DELETE https://api.kucoin.com/api/v3/oco/orders`
        #'
        #' ### Usage
        #' Utilised to remove multiple OCO orders, optionally filtered by `orderIds` or `symbol`.
        #'
        #' ### Official Documentation
        #' [KuCoin Batch Cancel OCO Order](https://www.kucoin.com/docs-new/rest/spot-trading/orders/batch-cancel-oco-order)
        #'
        #' @param query Named list; optional filters (e.g., `list(orderIds = "id1,id2", symbol = "BTC-USDT")`).
        #'
        #' @return Promise resolving to a `data.table` with:
        #'   - `cancelledOrderIds` (list): List of all canceled order IDs.
        #'
        #' ### JSON Response Example
        #' ```json
        #' {
        #'   "code": "200000",
        #'   "data": {
        #'     "cancelledOrderIds": ["vs93gpqc750mkk57003gok6i", "vs93gpqc750mkk57003gok6j"]
        #'   }
        #' }
        #' ```
        cancel_oco_order_batch = function(query = list()) {
            return(cancel_oco_order_batch_impl(
                keys = self$keys,
                base_url = self$base_url,
                query = query
            ))
        },

        #' Get OCO Order By OrderId
        #'
        #' ### Description
        #' Retrieves basic OCO order info by `orderId` asynchronously via a GET request to `/api/v3/oco/order/{orderId}`.
        #' Calls `get_oco_order_by_order_id_impl`.
        #'
        #' ### Workflow Overview
        #' 1. **Validation**: Ensures `orderId` is valid.
        #' 2. **URL**: Constructs endpoint with `orderId`.
        #' 3. **Authentication**: Generates headers.
        #' 4. **API Call**: Sends GET request.
        #' 5. **Response**: Returns basic order details.
        #'
        #' ### API Endpoint
        #' `GET https://api.kucoin.com/api/v3/oco/order/{orderId}`
        #'
        #' ### Usage
        #' Utilised to monitor an OCO order’s status and basic details.
        #'
        #' ### Official Documentation
        #' [KuCoin Get OCO Order By OrderId](https://www.kucoin.com/docs-new/rest/spot-trading/orders/get-oco-order-by-orderld)
        #'
        #' @param orderId Character string; system-generated order ID. Required.
        #'
        #' @return Promise resolving to a `data.table` with:
        #'   - `orderId` (character)
        #'   - `symbol` (character)
        #'   - `clientOid` (character)
        #'   - `orderTime` (integer)
        #'   - `status` (character)
        #'
        #' ### JSON Response Example
        #' ```json
        #' {
        #'   "code": "200000",
        #'   "data": {
        #'     "orderId": "674c3b6e688dea0007c7bab2",
        #'     "symbol": "BTC-USDT",
        #'     "clientOid": "5c52e1203aa6f37f1e493fb",
        #'     "orderTime": 1733049198863,
        #'     "status": "NEW"
        #'   }
        #' }
        #' ```
        get_oco_order_by_order_id = function(orderId) {
            return(get_oco_order_by_order_id_impl(
                keys = self$keys,
                base_url = self$base_url,
                orderId = orderId
            ))
        },

        #' Get OCO Order By ClientOid
        #'
        #' ### Description
        #' Retrieves basic OCO order info by `clientOid` asynchronously via a GET request to `/api/v3/oco/client-order/{clientOid}`.
        #' Calls `get_oco_order_by_client_oid_impl`.
        #'
        #' ### Workflow Overview
        #' 1. **Validation**: Ensures `clientOid` is valid.
        #' 2. **URL**: Constructs endpoint with `clientOid`.
        #' 3. **Authentication**: Generates headers.
        #' 4. **API Call**: Sends GET request.
        #' 5. **Response**: Returns basic order details.
        #'
        #' ### API Endpoint
        #' `GET https://api.kucoin.com/api/v3/oco/client-order/{clientOid}`
        #'
        #' ### Usage
        #' Utilised to fetch order details using a custom client ID.
        #'
        #' ### Official Documentation
        #' [KuCoin Get OCO Order By ClientOid](https://www.kucoin.com/docs-new/rest/spot-trading/orders/get-oco-order-by-clientoid)
        #'
        #' @param clientOid Character string; client-assigned order ID. Required.
        #'
        #' @return Promise resolving to a `data.table` with:
        #'   - `orderId` (character)
        #'   - `symbol` (character)
        #'   - `clientOid` (character)
        #'   - `orderTime` (integer)
        #'   - `status` (character)
        #'
        #' ### JSON Response Example
        #' ```json
        #' {
        #'   "code": "200000",
        #'   "data": {
        #'     "orderId": "674c3cfa72cf2800072ee7ce",
        #'     "symbol": "BTC-USDT",
        #'     "clientOid": "5c52e1203aa6f3g7f1e493fb",
        #'     "orderTime": 1733049594803,
        #'     "status": "NEW"
        #'   }
        #' }
        #' ```
        get_oco_order_by_client_oid = function(clientOid) {
            return(get_oco_order_by_client_oid_impl(
                keys = self$keys,
                base_url = self$base_url,
                clientOid = clientOid
            ))
        },

        #' Get OCO Order Detail By OrderId
        #'
        #' ### Description
        #' Retrieves detailed OCO order info by `orderId` asynchronously via a GET request to `/api/v3/oco/order/details/{orderId}`.
        #' Calls `get_oco_order_detail_by_order_id_impl`.
        #'
        #' ### Workflow Overview
        #' 1. **Validation**: Ensures `orderId` is valid.
        #' 2. **URL**: Constructs endpoint with `orderId`.
        #' 3. **Authentication**: Generates headers.
        #' 4. **API Call**: Sends GET request.
        #' 5. **Response**: Returns detailed order info with nested orders.
        #'
        #' ### API Endpoint
        #' `GET https://api.kucoin.com/api/v3/oco/order/details/{orderId}`
        #'
        #' ### Usage
        #' Utilised to inspect the full details of an OCO order, including its limit and stop-limit components.
        #'
        #' ### Official Documentation
        #' [KuCoin Get OCO Order Detail By OrderId](https://www.kucoin.com/docs-new/rest/spot-trading/orders/get-oco-order-detail-by-orderld)
        #'
        #' @param orderId Character string; system-generated order ID. Required.
        #'
        #' @return Promise resolving to a `data.table` with:
        #'   - `orderId` (character)
        #'   - `symbol` (character)
        #'   - `clientOid` (character)
        #'   - `orderTime` (integer)
        #'   - `status` (character)
        #'   - `orders` (list): Nested list of limit and stop-limit order details.
        #'
        #' ### JSON Response Example
        #' ```json
        #' {
        #'   "code": "200000",
        #'   "data": {
        #'     "orderId": "674c3b6e688dea0007c7bab2",
        #'     "symbol": "BTC-USDT",
        #'     "clientOid": "5c52e1203aa6f37f1e493fb",
        #'     "orderTime": 1733049198863,
        #'     "status": "NEW",
        #'     "orders": [
        #'       {"id": "vs93gpqc7dn6h3fa003sfelj", "symbol": "BTC-USDT", "side": "buy", "price": "94000", "stopPrice": "94000", "size": "0.1", "status": "NEW"},
        #'       {"id": "vs93gpqc7dn6h3fa003sfelk", "symbol": "BTC-USDT", "side": "buy", "price": "96000", "stopPrice": "98000", "size": "0.1", "status": "NEW"}
        #'     ]
        #'   }
        #' }
        #' ```
        get_oco_order_detail_by_order_id = function(orderId) {
            return(get_oco_order_detail_by_order_id_impl(
                keys = self$keys,
                base_url = self$base_url,
                orderId = orderId
            ))
        },

        #' Get OCO Order List
        #'
        #' ### Description
        #' Retrieves a paginated list of OCO orders asynchronously via a GET request to `/api/v3/oco/orders`.
        #' Calls `get_oco_order_list_impl`.
        #'
        #' ### Workflow Overview
        #' 1. **Validation**: Checks `query` parameters.
        #' 2. **URL**: Builds endpoint with query string.
        #' 3. **Authentication**: Generates headers.
        #' 4. **API Call**: Sends GET request.
        #' 5. **Response**: Returns a list of OCO orders.
        #'
        #' ### API Endpoint
        #' `GET https://api.kucoin.com/api/v3/oco/orders`
        #'
        #' ### Usage
        #' Utilised to review all current OCO orders, with optional filtering.
        #'
        #' ### Official Documentation
        #' [KuCoin Get OCO Order List](https://www.kucoin.com/docs-new/rest/spot-trading/orders/get-oco-order-list)
        #'
        #' @param query Named list; optional filters (e.g., `list(symbol = "BTC-USDT", pageSize = 10)`).
        #'
        #' @return Promise resolving to a `data.table` with:
        #'   - `orderId` (character)
        #'   - `symbol` (character)
        #'   - `clientOid` (character)
        #'   - `orderTime` (integer)
        #'   - `status` (character)
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
        #'     "items": [
        #'       {"orderId": "674c3cfa72cf2800072ee7ce", "symbol": "BTC-USDT", "clientOid": "5c52e1203aa6f3g7f1e493fb", "orderTime": 1733049594803, "status": "NEW"}
        #'     ]
        #'   }
        #' }
        #' ```
        get_oco_order_list = function(query = list()) {
            return(get_oco_order_list_impl(
                keys = self$keys,
                base_url = self$base_url,
                query = query
            ))
        }
    )
)
