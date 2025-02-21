# File: ./R/impl_spottrading_orders_get_trade_history.R

# box::use(
#     ./helpers_api[process_kucoin_response, build_headers],
#     ./utils[build_query, get_base_url, verify_symbol, get_api_keys],
#     ./utils_time_convert_kucoin[time_convert_from_kucoin],
#     coro[async, await],
#     data.table[rbindlist, data.table],
#     httr[GET, timeout],
#     rlang[abort],
#     purrr[map_dfr]
# )

#' Get Trade History (Implementation)
#'
#' Retrieves a list of the latest spot transaction details (fills) for a specified symbol or orderId from the KuCoin Spot trading system asynchronously.
#' This function returns a `data.table` with detailed information about each fill, sorted by the latest update time in descending order.
#'
#' ## Description
#' This endpoint fetches the latest transaction details (fills) for a given trading pair or specific order. The data is sorted in descending order based on the update time of the order.
#' If `orderId` is provided, it overrides other query parameters except for `lastId`, `limit`, `startAt`, and `endAt`.
#'
#' ## Workflow
#' 1. **Parameter Validation**: Ensures `symbol` is a valid trading pair if `orderId` is not provided. Validates optional parameters.
#' 2. **Request Construction**: Builds the endpoint URL with query parameters.
#' 3. **Authentication**: Generates private API headers using `build_headers()` with the GET method and endpoint.
#' 4. **API Request**: Sends a GET request to the KuCoin API with a 3-second timeout.
#' 5. **Response Processing**: Parses the response, converts the `items` array to a `data.table`, and adds a `createdAtDatetime` column.
#'
#' ## API Details
#' - **Endpoint**: `GET https://api.kucoin.com/api/v1/hf/fills`
#' - **Domain**: Spot
#' - **API Channel**: Private
#' - **API Permission**: General
#' - **Rate Limit Pool**: Spot
#' - **Rate Limit Weight**: 2
#' - **SDK Service**: Spot
#' - **SDK Sub-Service**: Order
#' - **SDK Method Name**: getTradeHistory
#' - **Official Documentation**: [KuCoin Get Trade History](https://www.kucoin.com/docs-new/rest/spot-trading/orders/get-trade-history)
#'
#' ## Request
#' ### Query Parameters
#' - `symbol`: String (required if `orderId` is not provided) - The trading pair symbol (e.g., "BTC-USDT").
#' - `orderId`: String (optional) - The unique order ID. If provided, other parameters (except `lastId`, `limit`, `startAt`, `endAt`) are ignored.
#' - `side`: Enum<String> (optional) - Order side: "buy" or "sell".
#' - `type`: Enum<String> (optional) - Order type: "limit" or "market".
#' - `lastId`: Integer<int64> (optional) - The ID of the last fill from the previous batch for pagination.
#' - `limit`: Integer (optional) - Number of fills per page (1 to 100, default 20).
#' - `startAt`: Integer<int64> (optional) - Start time in milliseconds.
#' - `endAt`: Integer<int64> (optional) - End time in milliseconds.
#'
#' ### Example Request
#' ```bash
#' curl --location --request GET 'https://api.kucoin.com/api/v1/hf/fills?symbol=BTC-USDT&limit=100&startAt=1728663338000&endAt=1728692138000'
#' ```
#'
#' ## Response
#' ### HTTP Code: 200
#' - **Content Type**: `application/json`
#'
#' ### Data Schema
#' - `code`: String (required) - Response code ("200000" indicates success).
#' - `data`: Object (required) - Contains:
#'   - `lastId`: Integer<int64> (required) - The ID of the last fill in the current batch.
#'   - `items`: Array of objects (required) - List of fill details, each with:
#'     - `id`: Integer<int64> - Fill ID.
#'     - `orderId`: String - Order ID.
#'     - `counterOrderId`: String - Counterparty order ID.
#'     - `tradeId`: Integer<int64> - Trade ID.
#'     - `symbol`: String - Trading pair.
#'     - `side`: Enum<String> - "buy" or "sell".
#'     - `liquidity`: Enum<String> - "taker" or "maker".
#'     - `type`: Enum<String> - "limit" or "market".
#'     - `forceTaker`: Boolean - Whether the order was forced to take liquidity.
#'     - `price`: String - Fill price.
#'     - `size`: String - Fill size.
#'     - `funds`: String - Funds involved in the fill.
#'     - `fee`: String - Handling fees.
#'     - `feeRate`: String - Fee rate.
#'     - `feeCurrency`: String - Fee currency.
#'     - `stop`: String - Stop type (currently empty for HFT).
#'     - `tradeType`: String - Trade type.
#'     - `taxRate`: String - Tax rate.
#'     - `tax`: String - Tax amount.
#'     - `createdAt`: Integer<int64> - Fill timestamp in milliseconds.
#'
#' ### JSON Response Example
#' ```json
#' {
#'   "code": "200000",
#'   "data": {
#'     "items": [
#'       {
#'         "id": 19814995255305,
#'         "orderId": "6717422bd51c29000775ea03",
#'         "counterOrderId": "67174228135f9e000709da8c",
#'         "tradeId": 11029373945659392,
#'         "symbol": "BTC-USDT",
#'         "side": "buy",
#'         "liquidity": "taker",
#'         "type": "limit",
#'         "forceTaker": false,
#'         "price": "67717.6",
#'         "size": "0.00001",
#'         "funds": "0.677176",
#'         "fee": "0.000677176",
#'         "feeRate": "0.001",
#'         "feeCurrency": "USDT",
#'         "stop": "",
#'         "tradeType": "TRADE",
#'         "taxRate": "0",
#'         "tax": "0",
#'         "createdAt": 1729577515473
#'       }
#'     ],
#'     "lastId": 19814995255305
#'   }
#' }
#' ```
#'
#' @param keys List; API configuration parameters from `get_api_keys()`. Defaults to `get_api_keys()`.
#' @param base_url Character string; base URL for the KuCoin API. Defaults to `get_base_url()`.
#' @param symbol Character string; the trading pair symbol (e.g., "BTC-USDT"). Required if `orderId` is not provided.
#' @param orderId Character string; the unique order ID. If provided, other parameters are ignored except for pagination and time filters.
#' @param side Character string; optional filter for order side: "buy" or "sell".
#' @param type Character string; optional filter for order type: "limit" or "market".
#' @param lastId Integer; optional ID of the last fill for pagination.
#' @param limit Integer; number of fills to return per request (1–100, default 20).
#' @param startAt Integer; optional start time in milliseconds.
#' @param endAt Integer; optional end time in milliseconds.
#' @return Promise resolving to a `data.table` with columns corresponding to the fill fields, including:
#'   - `id` (integer): Fill ID.
#'   - `orderId` (character): Order ID.
#'   - `counterOrderId` (character): Counterparty order ID.
#'   - `tradeId` (integer): Trade ID.
#'   - `symbol` (character): Trading pair.
#'   - `side` (character): "buy" or "sell".
#'   - `liquidity` (character): "taker" or "maker".
#'   - `type` (character): "limit" or "market".
#'   - `forceTaker` (logical): Whether forced to take liquidity.
#'   - `price` (character): Fill price.
#'   - `size` (character): Fill size.
#'   - `funds` (character): Funds involved.
#'   - `fee` (character): Handling fees.
#'   - `feeRate` (character): Fee rate.
#'   - `feeCurrency` (character): Fee currency.
#'   - `stop` (character): Stop type.
#'   - `tradeType` (character): Trade type.
#'   - `taxRate` (character): Tax rate.
#'   - `tax` (character): Tax amount.
#'   - `createdAt` (integer): Fill timestamp (milliseconds).
#'   - `createdAtDatetime` (POSIXct): Fill time in UTC.
#' @examples
#' \dontrun{
#' library(coro)
#' library(data.table)
#'
#' main_async <- coro::async(function() {
#'   # Retrieve trade history for BTC-USDT
#'   trade_history <- await(get_trade_history_impl(
#'     symbol = "BTC-USDT",
#'     limit = 50
#'   ))
#'   print(trade_history)
#' })
#'
#' # Run the async function
#' main_async()
#' while (!later::loop_empty()) later::run_now()
#' }
#' @importFrom coro async await
#' @importFrom data.table rbindlist data.table
#' @importFrom httr GET timeout
#' @importFrom rlang abort
#' @export
get_trade_history_impl <- coro::async(function(
    keys = get_api_keys(),
    base_url = get_base_url(),
    symbol = NULL,
    orderId = NULL,
    side = NULL,
    type = NULL,
    lastId = NULL,
    limit = 20,
    startAt = NULL,
    endAt = NULL
) {
    tryCatch({
        # Validate parameters
        if (is.null(orderId)) {
            if (is.null(symbol) || !verify_symbol(symbol)) {
                rlang::abort("Parameter 'symbol' must be a valid ticker (e.g., 'BTC-USDT') when 'orderId' is not provided.")
            }
        }
        if (!is.null(limit) && (!is.integer(limit) || limit < 1 || limit > 100)) {
            rlang::abort("Parameter 'limit' must be an integer between 1 and 100.")
        }

        # Construct query parameters
        query_params <- list()
        if (!is.null(orderId)) {
            query_params$orderId <- orderId
        } else {
            query_params$symbol <- symbol
            if (!is.null(side)) query_params$side <- side
            if (!is.null(type)) query_params$type <- type
        }
        if (!is.null(lastId)) query_params$lastId <- lastId
        if (!is.null(limit)) query_params$limit <- limit
        if (!is.null(startAt)) query_params$startAt <- startAt
        if (!is.null(endAt)) query_params$endAt <- endAt

        # Build query string
        query_string <- build_query(query_params)
        endpoint <- "/api/v1/hf/fills"
        full_url <- paste0(base_url, endpoint, query_string)

        # Generate authentication headers
        headers <- await(build_headers("GET", endpoint, query_string, keys))

        # Send GET request
        response <- httr::GET(
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
        if (length(parsed_response$data$items) == 0) {
            fills_dt <- data.table::data.table(
                id = integer(),
                orderId = character(),
                counterOrderId = character(),
                tradeId = integer(),
                symbol = character(),
                side = character(),
                liquidity = character(),
                type = character(),
                forceTaker = logical(),
                price = character(),
                size = character(),
                funds = character(),
                fee = character(),
                feeRate = character(),
                feeCurrency = character(),
                stop = character(),
                tradeType = character(),
                taxRate = character(),
                tax = character(),
                createdAt = integer(),
                createdAtDatetime = as.POSIXct(character())
            )
        } else {
            fills_dt <- data.table::rbindlist(parsed_response$data$items, fill = TRUE)
            fills_dt[, createdAtDatetime := time_convert_from_kucoin(createdAt, unit = "ms")]
        }

        return(fills_dt)
    }, error = function(e) {
        rlang::abort(sprintf("Error in get_trade_history_impl: %s", conditionMessage(e)))
    })
})
