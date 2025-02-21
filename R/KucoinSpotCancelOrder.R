# File: ./R/KucoinSpotCancelOrder.R

# box::use(
#     ./impl_spottrading_orders_cancel_order[
#         cancel_order_by_order_id_impl,
#         cancel_order_by_client_oid_impl,
#         cancel_partial_order_impl,
#         cancel_all_orders_by_symbol_impl,
#         cancel_all_orders_impl
#     ],
#     ./utils[get_api_keys, get_base_url]
# )

#' KucoinSpotCancelOrder Class for KuCoin Spot Trading Order Cancellation
#'
#' The `KucoinSpotCancelOrder` class provides an asynchronous interface for canceling spot trading orders on KuCoin.
#' It leverages the `coro` package for non-blocking HTTP requests, returning promises that resolve to `data.table` objects.
#' This class supports canceling individual orders by `orderId` or `clientOid`, partially canceling an order, canceling all orders
#' for a specific symbol, and canceling all orders across all symbols.
#'
#' ### Purpose and Scope
#' This class focuses exclusively on order cancellation operations in the KuCoin Spot trading system, including:
#' - **Individual Cancellation**: Cancel a single order by `orderId` or `clientOid`.
#' - **Partial Cancellation**: Reduce the quantity of a specific order.
#' - **Bulk Cancellation**: Cancel all orders for a symbol or across all symbols.
#'
#' ### Workflow Overview
#' Not applicable (class definition overview).
#'
#' ### API Endpoint
#' Not applicable (class-level documentation; see individual methods for specific endpoints).
#'
#' ### Usage
#' Utilised by traders and developers to programmatically cancel Spot trading orders on KuCoin. The class is initialized with API credentials,
#' automatically loaded via `get_api_keys()` if not provided, and a base URL from `get_base_url()`. For detailed endpoint information,
#' parameters, and response schemas, refer to the official [KuCoin API Documentation](https://www.kucoin.com/docs-new).
#'
#' ### Official Documentation
#' [KuCoin API Documentation - Spot Trading Orders](https://www.kucoin.com/docs-new/rest/spot-trading/orders/introduction)
#'
#' @section Methods:
#' - **initialize(keys, base_url):** Initialises the object with API credentials and base URL.
#' - **cancel_order_by_order_id(orderId, symbol):** Cancels an order by its system-generated `orderId`.
#' - **cancel_order_by_client_oid(clientOid, symbol):** Cancels an order by its client-assigned `clientOid`.
#' - **cancel_partial_order(orderId, symbol, cancelSize):** Partially cancels an order by `orderId` with a specified quantity.
#' - **cancel_all_orders_by_symbol(symbol):** Cancels all orders for a specific symbol.
#' - **cancel_all_orders():** Cancels all spot orders across all symbols.
#'
#' @return Not applicable (class definition; see individual methods for return values).
#'
#' @examples
#' \dontrun{
#' # Comprehensive example demonstrating key methods
#' main_async <- coro::async(function() {
#'   # Initialise the class
#'   cancellations <- KucoinSpotCancelOrder$new()
#'
#'   # Cancel an order by orderId
#'   canceled_order <- await(cancellations$cancel_order_by_order_id("671124f9365ccb00073debd4", "BTC-USDT"))
#'   print("Canceled by OrderId:"); print(canceled_order)
#'
#'   # Cancel an order by clientOid
#'   canceled_client <- await(cancellations$cancel_order_by_client_oid("5c52e11203aa677f33e493fb", "BTC-USDT"))
#'   print("Canceled by ClientOid:"); print(canceled_client)
#'
#'   # Partially cancel an order
#'   partial_cancel <- await(cancellations$cancel_partial_order("6711f73c1ef16c000717bb31", "BTC-USDT", "0.00001"))
#'   print("Partial Cancellation:"); print(partial_cancel)
#'
#'   # Cancel all orders for a symbol
#'   symbol_cancel <- await(cancellations$cancel_all_orders_by_symbol("BTC-USDT"))
#'   print("All Orders for Symbol Canceled:"); print(symbol_cancel)
#'
#'   # Cancel all orders across all symbols
#'   all_cancel <- await(cancellations$cancel_all_orders())
#'   print("All Orders Canceled:"); print(all_cancel)
#' })
#' main_async()
#' while (!later::loop_empty()) later::run_now()
#' }
#'
#' @importFrom R6 R6Class
#' @export
KucoinSpotCancelOrder <- R6::R6Class(
    "KucoinSpotCancelOrder",
    public = list(
        #' @field keys List containing KuCoin API keys (`api_key`, `api_secret`, `api_passphrase`, `key_version`).
        keys = NULL,
        #' @field base_url Character string representing the base URL for KuCoin API endpoints.
        base_url = NULL,

        #' Initialise a New KucoinSpotCancelOrder Object
        #'
        #' ### Description
        #' Initialises a `KucoinSpotCancelOrder` object with API credentials and a base URL for canceling Spot trading orders asynchronously.
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
        #' Utilised to create an instance for managing order cancellations in Spot trading.
        #'
        #' ### Official Documentation
        #' [KuCoin API Authentication](https://www.kucoin.com/docs-new/rest/introduction#authentication)
        #'
        #' ### Automated Trading Usage
        #' - **Cancellation Hub**: Use this as the central object for all cancellation operations in your trading bot, streamlining order termination logic.
        #' - **Secure Setup**: Load credentials via `get_api_keys()` from a secure source (e.g., environment variables or a vault), ensuring safe deployment.
        #' - **Integration**: Pair with querying classes (e.g., `KucoinSpotOrderQueries`) to verify cancellations and maintain order state consistency.
        #'
        #' @param keys List containing API configuration parameters from `get_api_keys()`, including:
        #'   - `api_key`: Character string; your KuCoin API key.
        #'   - `api_secret`: Character string; your KuCoin API secret.
        #'   - `api_passphrase`: Character string; your KuCoin API passphrase.
        #'   - `key_version`: Character string; API key version (e.g., `"2"`).
        #'   Defaults to `get_api_keys()`.
        #' @param base_url Character string representing the base URL for the API. Defaults to `get_base_url()`.
        #'
        #' @return A new instance of the `KucoinSpotCancelOrder` class.
        initialize = function(keys = get_api_keys(), base_url = get_base_url()) {
            self$keys <- keys
            self$base_url <- base_url
        },

        #' Cancel Order By OrderId
        #'
        #' ### Description
        #' Cancels a spot order by its system-generated `orderId` via a DELETE request to `/api/v1/hf/orders/{orderId}`.
        #' Calls `cancel_order_by_order_id_impl`.
        #'
        #' ### Workflow Overview
        #' 1. **Validation**: Ensures `orderId` and `symbol` are valid.
        #' 2. **URL**: Constructs endpoint with `orderId` and `symbol`.
        #' 3. **Authentication**: Generates headers.
        #' 4. **API Call**: Sends DELETE request.
        #' 5. **Response**: Returns the canceled `orderId`.
        #'
        #' ### API Endpoint
        #' `DELETE https://api.kucoin.com/api/v1/hf/orders/{orderId}?symbol={symbol}`
        #'
        #' ### Usage
        #' Utilised to cancel a specific order using its KuCoin-assigned ID.
        #'
        #' ### Official Documentation
        #' [KuCoin Cancel Order By OrderId](https://www.kucoin.com/docs-new/rest/spot-trading/orders/cancel-order-by-orderld)
        #'
        #' ### Automated Trading Usage
        #' - **Targeted Cancellation**: Cancel specific orders when market conditions shift (e.g., cancel a buy order if price spikes), using `orderId` from placement logs.
        #' - **Status Verification**: Post-cancellation, confirm with a query class (e.g., `get_order_by_order_id`) to ensure completion before re-ordering.
        #' - **Error Handling**: If cancellation fails (e.g., already filled), log the `orderId` and retry or adjust strategy based on status.
        #'
        #' @param orderId Character string; system-generated order ID (e.g., "671124f9365ccb00073debd4"). Required.
        #' @param symbol Character string; trading pair (e.g., "BTC-USDT"). Required.
        #' @return Promise resolving to a `data.table` with:
        #'   - `orderId` (character): The canceled order ID.
        #' ### JSON Response Example
        #' ```json
        #' {"code": "200000", "data": {"orderId": "671124f9365ccb00073debd4"}}
        #' ```
        cancel_order_by_order_id = function(orderId, symbol) {
            return(cancel_order_by_order_id_impl(keys = self$keys, base_url = self$base_url, orderId = orderId, symbol = symbol))
        },

        #' Cancel Order By ClientOid
        #'
        #' ### Description
        #' Cancels a spot order by its client-assigned `clientOid` via a DELETE request to `/api/v1/hf/orders/client-order/{clientOid}`.
        #' Calls `cancel_order_by_client_oid_impl`.
        #'
        #' ### Workflow Overview
        #' 1. **Validation**: Ensures `clientOid` and `symbol` are valid.
        #' 2. **URL**: Constructs endpoint with `clientOid` and `symbol`.
        #' 3. **Authentication**: Generates headers.
        #' 4. **API Call**: Sends DELETE request.
        #' 5. **Response**: Returns the canceled `clientOid`.
        #'
        #' ### API Endpoint
        #' `DELETE https://api.kucoin.com/api/v1/hf/orders/client-order/{clientOid}?symbol={symbol}`
        #'
        #' ### Usage
        #' Utilised to cancel a specific order using a custom client ID.
        #'
        #' ### Official Documentation
        #' [KuCoin Cancel Order By ClientOid](https://www.kucoin.com/docs-new/rest/spot-trading/orders/cancel-order-by-clientoid)
        #'
        #' ### Automated Trading Usage
        #' - **Custom Tracking**: Cancel orders by `clientOid` tied to your system’s identifiers (e.g., "STRAT1_001"), avoiding `orderId` mapping.
        #' - **Event-Driven**: Trigger cancellation based on signals (e.g., volatility spike), using stored `clientOid` values from your database.
        #' - **Confirmation**: Verify with a query class (e.g., `get_order_by_client_oid`) to update order status in real-time.
        #'
        #' @param clientOid Character string; client-assigned order ID (e.g., "5c52e11203aa677f33e493fb"). Required.
        #' @param symbol Character string; trading pair (e.g., "BTC-USDT"). Required.
        #' @return Promise resolving to a `data.table` with:
        #'   - `clientOid` (character): The canceled client order ID.
        #' ### JSON Response Example
        #' ```json
        #' {"code": "200000", "data": {"clientOid": "5c52e11203aa677f33e493fb"}}
        #' ```
        cancel_order_by_client_oid = function(clientOid, symbol) {
            return(cancel_order_by_client_oid_impl(
                keys = self$keys,
                base_url = self$base_url,
                clientOid = clientOid,
                symbol = symbol
            ))
        },

        #' Cancel Partial Order
        #'
        #' ### Description
        #' Partially cancels a spot order by its `orderId` with a specified quantity via a DELETE request to `/api/v1/hf/orders/cancel/{orderId}`.
        #' Calls `cancel_partial_order_impl`.
        #'
        #' ### Workflow Overview
        #' 1. **Validation**: Ensures `orderId`, `symbol`, and `cancelSize` are valid.
        #' 2. **URL**: Constructs endpoint with `orderId`, `symbol`, and `cancelSize`.
        #' 3. **Authentication**: Generates headers.
        #' 4. **API Call**: Sends DELETE request.
        #' 5. **Response**: Returns the `orderId` and `cancelSize`.
        #'
        #' ### API Endpoint
        #' `DELETE https://api.kucoin.com/api/v1/hf/orders/cancel/{orderId}?symbol={symbol}&cancelSize={cancelSize}`
        #'
        #' ### Usage
        #' Utilised to reduce the quantity of an existing order without fully canceling it.
        #'
        #' ### Official Documentation
        #' [KuCoin Cancel Partial Order](https://www.kucoin.com/docs-new/rest/spot-trading/orders/cancel-partial-order)
        #'
        #' ### Automated Trading Usage
        #' - **Position Adjustment**: Reduce exposure (e.g., cancel 0.01 BTC of a 0.05 BTC order) when risk thresholds are approached, using dynamic `cancelSize` calculations.
        #' - **Liquidity Management**: Partially cancel large orders to free capital based on market depth updates, maintaining some market presence.
        #' - **Post-Cancel Check**: Use a query class to confirm remaining `size` via `get_order_by_order_id`, ensuring the adjustment took effect.
        #'
        #' @param orderId Character string; system-generated order ID (e.g., "6711f73c1ef16c000717bb31"). Required.
        #' @param symbol Character string; trading pair (e.g., "BTC-USDT"). Required.
        #' @param cancelSize Character string; quantity to cancel (e.g., "0.00001"). Required.
        #' @return Promise resolving to a `data.table` with:
        #'   - `orderId` (character): The partially canceled order ID.
        #'   - `cancelSize` (character): The canceled quantity.
        #' ### JSON Response Example
        #' ```json
        #' {"code": "200000", "data": {"orderId": "6711f73c1ef16c000717bb31", "cancelSize": "0.00001"}}
        #' ```
        cancel_partial_order = function(orderId, symbol, cancelSize) {
            return(cancel_partial_order_impl(
                keys = self$keys,
                base_url = self$base_url,
                orderId = orderId,
                symbol = symbol,
                cancelSize = cancelSize
            ))
        },

        #' Cancel All Orders By Symbol
        #'
        #' ### Description
        #' Cancels all spot orders for a specified symbol via a DELETE request to `/api/v1/hf/orders`.
        #' Calls `cancel_all_orders_by_symbol_impl`.
        #'
        #' ### Workflow Overview
        #' 1. **Validation**: Ensures `symbol` is valid.
        #' 2. **URL**: Constructs endpoint with `symbol`.
        #' 3. **Authentication**: Generates headers.
        #' 4. **API Call**: Sends DELETE request.
        #' 5. **Response**: Returns a success indicator.
        #'
        #' ### API Endpoint
        #' `DELETE https://api.kucoin.com/api/v1/hf/orders?symbol={symbol}`
        #'
        #' ### Usage
        #' Utilised to cancel all orders associated with a specific trading pair.
        #'
        #' ### Official Documentation
        #' [KuCoin Cancel All Orders By Symbol](https://www.kucoin.com/docs-new/rest/spot-trading/orders/cancel-all-orders-by-symbol)
        #'
        #' ### Automated Trading Usage
        #' - **Market Exit**: Clear all orders for a symbol (e.g., "BTC-USDT") during strategy shifts or market closeouts, triggered by price thresholds.
        #' - **Risk Mitigation**: Cancel all orders for a volatile symbol if risk metrics (e.g., VaR) exceed limits, using real-time data.
        #' - **Post-Cancel Audit**: Verify with `get_open_orders` from a query class to ensure no orders remain, logging any discrepancies.
        #'
        #' @param symbol Character string; trading pair (e.g., "BTC-USDT"). Required.
        #' @return Promise resolving to a `data.table` with:
        #'   - `result` (character): "success" if the request is accepted.
        #' ### JSON Response Example
        #' ```json
        #' {"code": "200000", "data": "success"}
        #' ```
        cancel_all_orders_by_symbol = function(symbol) {
            return(cancel_all_orders_by_symbol_impl(
                keys = self$keys,
                base_url = self$base_url,
                symbol = symbol
            ))
        },

        #' Cancel All Orders
        #'
        #' ### Description
        #' Cancels all spot orders across all symbols via a DELETE request to `/api/v1/hf/orders/cancelAll`.
        #' Calls `cancel_all_orders_impl`.
        #'
        #' ### Workflow Overview
        #' 1. **URL**: Constructs endpoint with no parameters.
        #' 2. **Authentication**: Generates headers.
        #' 3. **API Call**: Sends DELETE request.
        #' 4. **Response**: Returns successful and failed symbols.
        #'
        #' ### API Endpoint
        #' `DELETE https://api.kucoin.com/api/v1/hf/orders/cancelAll`
        #'
        #' ### Usage
        #' Utilised to terminate all spot trading activity across all markets.
        #'
        #' ### Official Documentation
        #' [KuCoin Cancel All Orders](https://www.kucoin.com/docs-new/rest/spot-trading/orders/cancel-all-orders)
        #'
        #' ### Automated Trading Usage
        #' - **Emergency Stop**: Execute during critical events (e.g., account breaches, market crashes) to halt all trading, triggered by risk alerts.
        #' - **Portfolio Reset**: Clear all orders before a major strategy overhaul, ensuring a clean slate for new setups.
        #' - **Failure Analysis**: Inspect `failedSymbols` to identify cancellation issues (e.g., already filled orders), logging errors for debugging.
        #'
        #' @return Promise resolving to a `data.table` with:
        #'   - `succeedSymbols` (character): Vector of symbols successfully canceled.
        #'   - `failedSymbols` (list): List of objects with `symbol` and `error` for failed cancellations.
        #' ### JSON Response Example
        #' ```json
        #' {"code": "200000", "data": {"succeedSymbols": ["ETH-USDT", "BTC-USDT"], "failedSymbols": []}}
        #' ```
        cancel_all_orders = function() {
            return(cancel_all_orders_impl(keys = self$keys, base_url = self$base_url))
        }
    )
)
