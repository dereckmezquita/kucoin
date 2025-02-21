# File: ./R/impl_spottrading_orders_cancel_stop.R

box::use(
    ./helpers_api[process_kucoin_response, build_headers],
    ./utils[build_query, get_base_url, verify_symbol, get_api_keys],
    coro[async, await],
    data.table[data.table, rbindlist],
    httr[DELETE, timeout],
    rlang[abort]
)

#' Cancel Stop Order By ClientOid (Implementation)
#'
#' Cancels a stop order on the KuCoin Spot trading system using its client order ID (`clientOid`) asynchronously.
#' This function sends a cancellation request and returns a `data.table` with the cancelled order's details.
#' Note that this endpoint only initiates cancellation; the actual status must be verified via order status checks or WebSocket subscription.
#'
#' ## Description
#' This endpoint allows users to cancel a stop order identified by its `clientOid`, a user-assigned unique identifier.
#' Stop orders are conditional orders that trigger when the market price reaches a specified `stopPrice`. The function
#' sends a DELETE request to the KuCoin API and returns confirmation details upon successful initiation of the cancellation.
#' The maximum number of untriggered stop orders per trading pair is 20, and this endpoint helps manage that limit by
#' removing specific orders.
#'
#' ## Workflow
#' 1. **Parameter Validation**: Ensures `clientOid` is a non-empty string and, if provided, `symbol` is a valid trading pair.
#' 2. **Request Construction**: Builds the endpoint URL with query parameters `symbol` (optional) and `clientOid` (required).
#' 3. **Authentication**: Generates private API headers using `build_headers()` with the DELETE method and endpoint.
#' 4. **API Request**: Sends a DELETE request to the KuCoin API with a 3-second timeout.
#' 5. **Response Processing**: Parses the response, validates success, and returns a `data.table` with `cancelledOrderId` and `clientOid`.
#'
#' ## API Details
#' - **Endpoint**: `DELETE https://api.kucoin.com/api/v1/stop-order/cancelOrderByClientOid`
#' - **Domain**: Spot
#' - **API Channel**: Private
#' - **API Permission**: Spot
#' - **Rate Limit Pool**: Spot
#' - **Rate Limit Weight**: 5
#' - **SDK Service**: Spot
#' - **SDK Sub-Service**: Order
#' - **SDK Method Name**: cancelStopOrderByClientOid
#' - **Official Documentation**: [KuCoin Cancel Stop Order By ClientOid](https://www.kucoin.com/docs-new/rest/spot-trading/orders/cancel-stop-order-by-clientoid)
#'
#' ## Request
#' ### Query Parameters
#' - `symbol`: String (optional) - The trading pair symbol (e.g., "BTC-USDT").
#' - `clientOid`: String (required) - Unique client order ID created by the user (e.g., "689ff597f4414061aa819cc414836abd").
#'
#' ### Example Request
#' ```bash
#' curl --location --request DELETE 'https://api.kucoin.com/api/v1/stop-order/cancelOrderByClientOid?symbol=BTC-USDT&clientOid=689ff597f4414061aa819cc414836abd'
#' ```
#'
#' ## Response
#' ### HTTP Code: 200
#' - **Content Type**: `application/json`
#'
#' ### Data Schema
#' - `code`: String (required) - Response code ("200000" indicates success).
#' - `data`: Object (required) - Contains:
#'   - `clientOid`: String (required) - Client-assigned order ID from the request.
#'   - `cancelledOrderId`: String (required) - Unique ID of the cancelled order assigned by the system.
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
#'
#' @param keys List; API configuration parameters from `get_api_keys()`. Defaults to `get_api_keys()`.
#' @param base_url Character string; base URL for the KuCoin API. Defaults to `get_base_url()`.
#' @param symbol Character string; the trading pair symbol (e.g., "BTC-USDT"). Optional.
#' @param clientOid Character string; the unique client order ID to cancel (e.g., "689ff597f4414061aa819cc414836abd"). Required.
#' @return Promise resolving to a `data.table` with one row containing:
#'   - `cancelledOrderId` (character): Unique ID of the cancelled order.
#'   - `clientOid` (character): Client-assigned order ID.
#' @examples
#' \dontrun{
#' library(coro)
#' library(data.table)
#'
#' main_async <- coro::async(function() {
#'   # Cancel a stop order by clientOid
#'   cancellation <- await(cancel_stop_order_by_client_oid_impl(
#'     symbol = "BTC-USDT",
#'     clientOid = "689ff597f4414061aa819cc414836abd"
#'   ))
#'   print(cancellation)
#' })
#'
#' # Run the async function
#' main_async()
#' while (!later::loop_empty()) later::run_now()
#'
#' # Expected Output:
#' #    cancelledOrderId         clientOid
#' # 1: vs8hoo8ksc8mario0035a74n 689ff597f4414061aa819cc414836abd
#' }
#' @importFrom coro async await
#' @importFrom data.table data.table rbindlist
#' @importFrom httr DELETE timeout
#' @importFrom rlang abort
#' @export
cancel_stop_order_by_client_oid_impl <- coro::async(function(
    keys = get_api_keys(),
    base_url = get_base_url(),
    symbol = NULL,
    clientOid
) {
    tryCatch({
        # Validate parameters
        if (is.null(clientOid) || !is.character(clientOid) || nchar(clientOid) == 0) {
            rlang::abort("Parameter 'clientOid' must be a non-empty string.")
        }
        if (!is.null(symbol) && !verify_symbol(symbol)) {
            rlang::abort("Parameter 'symbol', if provided, must be a valid ticker (e.g., 'BTC-USDT').")
        }

        # Construct endpoint and query string
        endpoint <- "/api/v1/stop-order/cancelOrderByClientOid"
        query_params <- list(clientOid = clientOid)
        if (!is.null(symbol)) query_params$symbol <- symbol
        query_string <- build_query(query_params)
        endpoint_with_query <- paste0(endpoint, query_string)
        full_url <- paste0(base_url, endpoint_with_query)

        # Generate authentication headers
        headers <- await(build_headers("DELETE", endpoint_with_query, NULL, keys))

        # Send DELETE request
        response <- httr::DELETE(
            url = full_url,
            headers,
            httr::timeout(3)
        )

        # Process response
        parsed_response <- process_kucoin_response(response, full_url)
        if (parsed_response$code != "200000") {
            rlang::abort(sprintf("API error: %s - %s", parsed_response$code, parsed_response$msg))
        }

        # Convert response data to data.table
        result_dt <- data.table::data.table(
            cancelledOrderId = parsed_response$data$cancelledOrderId,
            clientOid = parsed_response$data$clientOid
        )

        return(result_dt)
    }, error = function(e) {
        rlang::abort(sprintf("Error in cancel_stop_order_by_client_oid_impl: %s", conditionMessage(e)))
    })
})

#' Cancel Stop Order By OrderId (Implementation)
#'
#' Cancels a stop order on the KuCoin Spot trading system using its system-generated order ID (`orderId`) asynchronously.
#' This function sends a cancellation request and returns a `data.table` with the cancelled order's details.
#' Note that this endpoint only initiates cancellation; the actual status must be verified via order status checks or WebSocket subscription.
#'
#' ## Description
#' This endpoint allows users to cancel a previously placed stop order identified by its `orderId`, which is the unique identifier assigned by the KuCoin system upon order creation. Stop orders are conditional orders that trigger when the market price reaches a specified `stopPrice`. The function sends a DELETE request to the KuCoin API and returns confirmation details upon successful initiation of the cancellation. The maximum number of untriggered stop orders per trading pair is 20, and this endpoint helps manage that limit by removing specific orders.
#'
#' ## Workflow
#' 1. **Parameter Validation**: Ensures `orderId` is a non-empty string.
#' 2. **Request Construction**: Builds the endpoint URL with `orderId` as a path parameter.
#' 3. **Authentication**: Generates private API headers using `build_headers()` with the DELETE method and endpoint.
#' 4. **API Request**: Sends a DELETE request to the KuCoin API with a 3-second timeout.
#' 5. **Response Processing**: Parses the response, validates success, and returns a `data.table` with `cancelledOrderIds`.
#'
#' ## API Details
#' - **Endpoint**: `DELETE https://api.kucoin.com/api/v1/stop-order/{orderId}`
#' - **Domain**: Spot
#' - **API Channel**: Private
#' - **API Permission**: Spot
#' - **Rate Limit Pool**: Spot
#' - **Rate Limit Weight**: 3
#' - **SDK Service**: Spot
#' - **SDK Sub-Service**: Order
#' - **SDK Method Name**: cancelStopOrderByOrderId
#' - **Official Documentation**: [KuCoin Cancel Stop Order By OrderId](https://www.kucoin.com/docs-new/rest/spot-trading/orders/cancel-stop-order-by-orderld)
#'
#' ## Request
#' ### Path Parameters
#' - `orderId`: String (required) - The unique order ID generated by the trading system (e.g., "671124f9365ccb00073debd4").
#'
#' ### Example Request
#' ```bash
#' curl --location --request DELETE 'https://api.kucoin.com/api/v1/stop-order/671124f9365ccb00073debd4'
#' ```
#'
#' ## Response
#' ### HTTP Code: 200
#' - **Content Type**: `application/json`
#'
#' ### Data Schema
#' - `code`: String (required) - Response code ("200000" indicates success).
#' - `data`: Object (required) - Contains:
#'   - `cancelledOrderIds`: Array[String] (required) - Array of order IDs that were cancelled (typically a single ID for this endpoint).
#'
#' ### JSON Response Example
#' ```json
#' {
#'   "code": "200000",
#'   "data": {
#'     "cancelledOrderIds": [
#'       "671124f9365ccb00073debd4"
#'     ]
#'   }
#' }
#' ```
#'
#' @param keys List; API configuration parameters from `get_api_keys()`. Defaults to `get_api_keys()`.
#' @param base_url Character string; base URL for the KuCoin API. Defaults to `get_base_url()`.
#' @param orderId Character string; the unique order ID to cancel (e.g., "671124f9365ccb00073debd4"). Required.
#' @return Promise resolving to a `data.table` with one row containing:
#'   - `cancelledOrderIds` (character): The ID of the cancelled order.
#' @examples
#' \dontrun{
#' library(coro)
#' library(data.table)
#'
#' main_async <- coro::async(function() {
#'   # Cancel a stop order by orderId
#'   cancellation <- await(cancel_stop_order_by_order_id_impl(
#'     orderId = "671124f9365ccb00073debd4"
#'   ))
#'   print(cancellation)
#' })
#'
#' # Run the async function
#' main_async()
#' while (!later::loop_empty()) later::run_now()
#'
#' # Expected Output:
#' #    cancelledOrderIds
#' # 1: 671124f9365ccb00073debd4
#' }
#' @importFrom coro async await
#' @importFrom data.table data.table
#' @importFrom httr DELETE timeout
#' @importFrom rlang abort
#' @export
cancel_stop_order_by_order_id_impl <- coro::async(function(
    keys = get_api_keys(),
    base_url = get_base_url(),
    orderId
) {
    tryCatch({
        # Validate parameters
        if (is.null(orderId) || !is.character(orderId) || nchar(orderId) == 0) {
            rlang::abort("Parameter 'orderId' must be a non-empty string.")
        }

        # Construct endpoint
        endpoint <- paste0("/api/v1/stop-order/", orderId)
        full_url <- paste0(base_url, endpoint)

        # Generate authentication headers
        headers <- await(build_headers("DELETE", endpoint, NULL, keys))

        # Send DELETE request
        response <- httr::DELETE(
            url = full_url,
            headers,
            httr::timeout(3)
        )

        # Process response
        parsed_response <- process_kucoin_response(response, full_url)
        if (parsed_response$code != "200000") {
            rlang::abort(sprintf("API error: %s - %s", parsed_response$code, parsed_response$msg))
        }

        # Convert response data to data.table
        result_dt <- data.table::data.table(
            cancelledOrderIds = parsed_response$data$cancelledOrderIds
        )

        return(result_dt)
    }, error = function(e) {
        rlang::abort(sprintf("Error in cancel_stop_order_by_order_id_impl: %s", conditionMessage(e)))
    })
})
