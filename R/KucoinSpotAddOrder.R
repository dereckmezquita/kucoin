# File: ./R/KucoinSpotAddOrder.R

# box::use(
#     ./impl_spottrading_orders_add_order[
#         add_order_impl,
#         add_order_test_impl,
#         add_order_batch_impl
#     ],
#     ./utils[get_api_keys, get_base_url]
# )

#' KucoinSpotAddOrder Class for KuCoin Spot Trading Order Placement
#'
#' The `KucoinSpotAddOrder` class provides an asynchronous interface for placing spot trading orders on KuCoin.
#' It leverages the `coro` package for non-blocking HTTP requests, returning promises that resolve to `data.table` objects.
#' This class supports placing single orders (limit or market), testing order placement, and batch order placement (up to 20 orders).
#'
#' ### Purpose and Scope
#' This class focuses exclusively on order creation operations in the KuCoin Spot trading system, including:
#' - **Single Order Placement**: Place limit or market orders with detailed parameters.
#' - **Order Testing**: Simulate order placement for validation without execution.
#' - **Batch Order Placement**: Place multiple orders in a single request for efficiency.
#'
#' ### Workflow Overview
#' Not applicable (class definition overview).
#'
#' ### API Endpoint
#' Not applicable (class-level documentation; see individual methods for specific endpoints).
#'
#' ### Usage
#' Utilised by traders and developers to programmatically place Spot trading orders on KuCoin. The class is initialized with API credentials,
#' automatically loaded via `get_api_keys()` if not provided, and a base URL from `get_base_url()`. For detailed endpoint information,
#' parameters, and response schemas, refer to the official [KuCoin API Documentation](https://www.kucoin.com/docs-new).
#'
#' ### Official Documentation
#' [KuCoin API Documentation - Spot Trading Orders](https://www.kucoin.com/docs-new/rest/spot-trading/orders/introduction)
#'
#' @section Methods:
#' - **initialize(keys, base_url):** Initialises the object with API credentials and base URL.
#' - **add_order(type, symbol, side, ...):** Places a single limit or market order.
#' - **add_order_test(type, symbol, side, ...):** Simulates placing a single order for testing.
#' - **add_order_batch(order_list):** Places multiple orders (up to 20) in a batch.
#'
#' @return Not applicable (class definition; see individual methods for return values).
#'
#' @examples
#' \dontrun{
#' # Comprehensive example demonstrating key methods
#' main_async <- coro::async(function() {
#'   # Initialise the class
#'   additions <- KucoinSpotAddOrder$new()
#'
#'   # Place a limit buy order
#'   order <- await(additions$add_order(
#'     type = "limit",
#'     symbol = "BTC-USDT",
#'     side = "buy",
#'     price = "50000",
#'     size = "0.0001",
#'     clientOid = uuid::UUIDgenerate(),
#'     remark = "Test limit order"
#'   ))
#'   print("New Order:"); print(order)
#'
#'   # Test a market buy order
#'   test_order <- await(additions$add_order_test(
#'     type = "market",
#'     symbol = "BTC-USDT",
#'     side = "buy",
#'     funds = "10",
#'     clientOid = uuid::UUIDgenerate()
#'   ))
#'   print("Test Order:"); print(test_order)
#'
#'   # Place batch orders
#'   order_list <- list(
#'     list(
#'       clientOid = uuid::UUIDgenerate(),
#'       symbol = "BTC-USDT",
#'       type = "limit",
#'       side = "buy",
#'       price = "30000",
#'       size = "0.00001",
#'       remark = "Batch buy"
#'     ),
#'     list(
#'       clientOid = uuid::UUIDgenerate(),
#'       symbol = "ETH-USDT",
#'       type = "market",
#'       side = "sell",
#'       size = "0.01"
#'     )
#'   )
#'   batch_result <- await(additions$add_order_batch(order_list))
#'   print("Batch Orders:"); print(batch_result)
#' })
#' main_async()
#' while (!later::loop_empty()) later::run_now()
#' }
#'
#' @importFrom R6 R6Class
#' @export
KucoinSpotAddOrder <- R6::R6Class(
    "KucoinSpotAddOrder",
    public = list(
        #' @field keys List containing KuCoin API keys (`api_key`, `api_secret`, `api_passphrase`, `key_version`).
        keys = NULL,
        #' @field base_url Character string representing the base URL for KuCoin API endpoints.
        base_url = NULL,

        #' Initialise a New KucoinSpotAddOrder Object
        #'
        #' ### Description
        #' Initialises a `KucoinSpotAddOrder` object with API credentials and a base URL for placing Spot trading orders asynchronously.
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
        #' Utilised to create an instance for managing order placements in Spot trading.
        #'
        #' ### Official Documentation
        #' [KuCoin API Authentication](https://www.kucoin.com/docs-new/rest/introduction#authentication)
        #'
        #' ### Automated Trading Usage
        #' - **Order Placement Hub**: Use this as the central object for all order creation in your trading bot, streamlining trade execution logic.
        #' - **Secure Setup**: Load credentials via `get_api_keys()` from a secure source (e.g., environment variables or a vault), ensuring safe deployment.
        #' - **Integration**: Pair with querying (`KucoinSpotOrderQueries`) and cancellation (`KucoinSpotOrderCancellations`) classes for full trade lifecycle management.
        #'
        #' @param keys List containing API configuration parameters from `get_api_keys()`, including:
        #'   - `api_key`: Character string; your KuCoin API key.
        #'   - `api_secret`: Character string; your KuCoin API secret.
        #'   - `api_passphrase`: Character string; your KuCoin API passphrase.
        #'   - `key_version`: Character string; API key version (e.g., `"2"`).
        #'   Defaults to `get_api_keys()`.
        #' @param base_url Character string representing the base URL for the API. Defaults to `get_base_url()`.
        #'
        #' @return A new instance of the `KucoinSpotAddOrder` class.
        initialize = function(keys = get_api_keys(), base_url = get_base_url()) {
            self$keys <- keys
            self$base_url <- base_url
        },

        #' Add Order
        #'
        #' ### Description
        #' Places a new limit or market order on KuCoin Spot trading asynchronously via a POST request to `/api/v1/hf/orders`.
        #' Calls `add_order_impl`.
        #'
        #' ### Workflow Overview
        #' 1. **Validation**: Ensures parameters match order type (limit/market).
        #' 2. **Request Body**: Constructs JSON with order details.
        #' 3. **Authentication**: Generates headers.
        #' 4. **API Call**: Sends POST request.
        #' 5. **Response**: Returns `orderId` and `clientOid`.
        #'
        #' ### API Endpoint
        #' `POST https://api.kucoin.com/api/v1/hf/orders`
        #'
        #' ### Usage
        #' Utilised to place individual spot trading orders with detailed customization.
        #'
        #' ### Official Documentation
        #' [KuCoin Add Order](https://www.kucoin.com/docs-new/rest/spot-trading/orders/add-order)
        #'
        #' ### Automated Trading Usage
        #' - **Dynamic Trading**: Place limit orders with `price` based on technical indicators (e.g., moving averages) or market orders with `funds` for precise capital allocation.
        #' - **Order Tagging**: Use `clientOid` (e.g., UUID with strategy prefix) to track orders back to specific trading rules or sessions in your logs.
        #' - **Risk Control**: Set `timeInForce` to "IOC" or "FOK" for immediate execution checks, canceling via a paired class if unfilled.
        #'
        #' @param type Character string; "limit" or "market". Required.
        #' @param symbol Character string; trading pair (e.g., "BTC-USDT"). Required.
        #' @param side Character string; "buy" or "sell". Required.
        #' @param clientOid Character string; unique client ID (max 40 chars). Optional.
        #' @param price Character string; price for limit orders (e.g., "50000"). Required for limit.
        #' @param size Character string; quantity (e.g., "0.0001"). Required for limit, optional for market.
        #' @param funds Character string; funds for market orders (e.g., "10"). Optional for market.
        #' @param stp Character string; self-trade prevention: "CN", "CO", "CB", "DC". Optional.
        #' @param tags Character string; tag (max 20 chars). Optional.
        #' @param remark Character string; remarks (max 20 chars). Optional.
        #' @param timeInForce Character string; "GTC", "GTT", "IOC", "FOK". Optional.
        #' @param cancelAfter Integer; seconds until cancellation for GTT. Optional.
        #' @param postOnly Logical; post-only flag. Optional.
        #' @param hidden Logical; hidden order flag. Optional.
        #' @param iceberg Logical; iceberg order flag. Optional.
        #' @param visibleSize Character string; visible size for iceberg orders. Optional.
        #' @return Promise resolving to a `data.table` with:
        #'   - `orderId` (character): KuCoin-generated order ID.
        #'   - `clientOid` (character): Client-assigned order ID.
        #' ### JSON Response Example
        #' ```json
        #' {"code": "200000", "data": {"orderId": "6717422bd51c29000775ea03", "clientOid": "5c52e11203aa677f33e493fb"}}
        #' ```
        add_order = function(type, symbol, side, clientOid = NULL, price = NULL, size = NULL, funds = NULL,
                             stp = NULL, tags = NULL, remark = NULL, timeInForce = NULL, cancelAfter = NULL,
                             postOnly = NULL, hidden = NULL, iceberg = NULL, visibleSize = NULL) {
            return(add_order_impl(
                keys = self$keys, base_url = self$base_url, type = type, symbol = symbol, side = side,
                clientOid = clientOid, price = price, size = size, funds = funds, stp = stp, tags = tags,
                remark = remark, timeInForce = timeInForce, cancelAfter = cancelAfter, postOnly = postOnly,
                hidden = hidden, iceberg = iceberg, visibleSize = visibleSize
            ))
        },

        #' Add Order Test
        #'
        #' ### Description
        #' Simulates placing a new limit or market order via a POST request to `/api/v1/hf/orders/test`.
        #' Calls `add_order_test_impl`.
        #'
        #' ### Workflow Overview
        #' 1. **Validation**: Ensures parameters match order type.
        #' 2. **Request Body**: Constructs JSON with order details.
        #' 3. **Authentication**: Generates headers.
        #' 4. **API Call**: Sends POST request to test endpoint.
        #' 5. **Response**: Returns simulated `orderId` and `clientOid`.
        #'
        #' ### API Endpoint
        #' `POST https://api.kucoin.com/api/v1/hf/orders/test`
        #'
        #' ### Usage
        #' Utilised to test order placement logic without executing trades.
        #'
        #' ### Official Documentation
        #' [KuCoin Add Order Test](https://www.kucoin.com/docs-new/rest/spot-trading/orders/add-order-test)
        #'
        #' ### Automated Trading Usage
        #' - **Strategy Validation**: Test order parameters (e.g., `price`, `size`) against KuCoin’s rules before live execution, ensuring compliance.
        #' - **Signature Testing**: Verify authentication setup by simulating requests, catching errors in a sandbox environment.
        #' - **Dry Run**: Use in development to simulate trading strategies, logging results for analysis without financial impact.
        #'
        #' @param type Character string; "limit" or "market". Required.
        #' @param symbol Character string; trading pair (e.g., "BTC-USDT"). Required.
        #' @param side Character string; "buy" or "sell". Required.
        #' @param clientOid Character string; unique client ID (max 40 chars). Optional.
        #' @param price Character string; price for limit orders (e.g., "50000"). Required for limit.
        #' @param size Character string; quantity (e.g., "0.0001"). Required for limit, optional for market.
        #' @param funds Character string; funds for market orders (e.g., "10"). Optional for market.
        #' @param stp Character string; self-trade prevention: "CN", "CO", "CB", "DC". Optional.
        #' @param tags Character string; tag (max 20 chars). Optional.
        #' @param remark Character string; remarks (max 20 chars). Optional.
        #' @param timeInForce Character string; "GTC", "GTT", "IOC", "FOK". Optional.
        #' @param cancelAfter Integer; seconds until cancellation for GTT. Optional.
        #' @param postOnly Logical; post-only flag. Optional.
        #' @param hidden Logical; hidden order flag. Optional.
        #' @param iceberg Logical; iceberg order flag. Optional.
        #' @param visibleSize Character string; visible size for iceberg orders. Optional.
        #' @return Promise resolving to a `data.table` with:
        #'   - `orderId` (character): Simulated KuCoin-generated order ID.
        #'   - `clientOid` (character): Client-assigned order ID.
        #' ### JSON Response Example
        #' ```json
        #' {"code": "200000", "data": {"orderId": "simulated-6717422bd51c29000775ea03", "clientOid": "5c52e11203aa677f33e493fb"}}
        #' ```
        add_order_test = function(type, symbol, side, clientOid = NULL, price = NULL, size = NULL, funds = NULL,
                                  stp = NULL, tags = NULL, remark = NULL, timeInForce = NULL, cancelAfter = NULL,
                                  postOnly = NULL, hidden = NULL, iceberg = NULL, visibleSize = NULL) {
            return(add_order_test_impl(
                keys = self$keys, base_url = self$base_url, type = type, symbol = symbol, side = side,
                clientOid = clientOid, price = price, size = size, funds = funds, stp = stp, tags = tags,
                remark = remark, timeInForce = timeInForce, cancelAfter = cancelAfter, postOnly = postOnly,
                hidden = hidden, iceberg = iceberg, visibleSize = visibleSize
            ))
        },

        #' Add Order Batch
        #'
        #' ### Description
        #' Places multiple orders (up to 20) in a batch via a POST request to `/api/v1/hf/orders/multi`.
        #' Calls `add_order_batch_impl`.
        #'
        #' ### Workflow Overview
        #' 1. **Validation**: Ensures `order_list` has 1–20 valid orders.
        #' 2. **Request Body**: Constructs JSON with order list.
        #' 3. **Authentication**: Generates headers.
        #' 4. **API Call**: Sends POST request.
        #' 5. **Response**: Returns results for each order.
        #'
        #' ### API Endpoint
        #' `POST https://api.kucoin.com/api/v1/hf/orders/multi`
        #'
        #' ### Usage
        #' Utilised to efficiently place multiple spot trading orders in a single request.
        #'
        #' ### Official Documentation
        #' [KuCoin Batch Add Orders](https://www.kucoin.com/docs-new/rest/spot-trading/orders/batch-add-orders)
        #'
        #' ### Automated Trading Usage
        #' - **Multi-Market Execution**: Place orders across symbols (e.g., BTC-USDT, ETH-USDT) simultaneously based on portfolio signals, reducing latency.
        #' - **Error Handling**: Check `success` and `failMsg` per order to retry failed placements or adjust strategy dynamically.
        #' - **Batch Optimization**: Use with market data to set `price` or `funds` for each order, ensuring alignment with current conditions.
        #'
        #' @param order_list List; list of orders, each a list with:
        #'   - `symbol` (character): Trading pair (e.g., "BTC-USDT"). Required.
        #'   - `type` (character): "limit" or "market". Required.
        #'   - `side` (character): "buy" or "sell". Required.
        #'   - `clientOid` (character): Unique client ID (max 40 chars). Optional.
        #'   - `price` (character): Price for limit orders. Required for limit.
        #'   - `size` (character): Quantity. Required for limit, optional for market.
        #'   - `funds` (character): Funds for market orders. Optional for market.
        #'   - `stp` (character): Self-trade prevention: "CN", "CO", "CB", "DC". Optional.
        #'   - `tags` (character): Tag (max 20 chars). Optional.
        #'   - `remark` (character): Remarks (max 20 chars). Optional.
        #'   - `timeInForce` (character): "GTC", "GTT", "IOC", "FOK". Optional.
        #'   - `cancelAfter` (integer): Seconds until cancellation for GTT. Optional.
        #'   - `postOnly` (logical): Post-only flag. Optional.
        #'   - `hidden` (logical): Hidden order flag. Optional.
        #'   - `iceberg` (logical): Iceberg order flag. Optional.
        #'   - `visibleSize` (character): Visible size for iceberg orders. Optional.
        #' @return Promise resolving to a `data.table` with columns:
        #'   - `success` (logical): Whether placement succeededAIza

        #'   - `orderId` (character): KuCoin-generated order ID (if successful).
        #'   - `clientOid` (character): Client-assigned order ID (if provided).
        #'   - `failMsg` (character): Error message (if failed).
        #' ### JSON Response Example
        #' ```json
        #' {"code": "200000", "data": [{"success": true, "orderId": "6717422bd51c29000775ea03", "clientOid": "batch1", "failMsg": null}, {"success": true, "orderId": "6717422bd51c29000775ea04", "clientOid": "batch2", "failMsg": null}]}
        #' ```
        add_order_batch = function(order_list) {
            return(add_order_batch_impl(keys = self$keys, base_url = self$base_url, order_list = order_list))
        }
    )
)
