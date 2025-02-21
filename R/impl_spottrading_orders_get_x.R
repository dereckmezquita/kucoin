# File: ./R/impl_spottrading_orders_get_x.R

# box::use(
#     ./helpers_api[process_kucoin_response, build_headers],
#     ./utils[get_base_url, verify_symbol, get_api_keys],
#     coro[async, await],
#     data.table[rbindlist, data.table],
#     httr[GET, timeout],
#     rlang[abort]
# )

#' Get Symbols With Open Order (Implementation)
#'
#' Retrieves a list of spot trading symbols with active orders from the KuCoin Spot trading system asynchronously.
#' This function returns a `data.table` containing the symbols that currently have open orders.
#'
#' ## Description
#' This endpoint queries all trading pair symbols (e.g., "BTC-USDT", "ETH-USDT") that have active orders for the authenticated account.
#' An active order is one that is currently in the order book and has not been fully filled or canceled.
#' This is useful for monitoring which markets have ongoing trading activity for the user.
#'
#' ## Workflow
#' 1. **Request Construction**: Builds the endpoint URL with no additional parameters since none are required.
#' 2. **Authentication**: Generates private API headers using `build_headers()` with the GET method and endpoint.
#' 3. **API Request**: Sends a GET request to the KuCoin API with a 3-second timeout.
#' 4. **Response Processing**: Parses the response and converts the `symbols` array within the `data` object to a `data.table`.
#'
#' ## API Details
#' - **Endpoint**: `GET https://api.kucoin.com/api/v1/hf/orders/active/symbols`
#' - **Domain**: Spot
#' - **API Channel**: Private
#' - **API Permission**: Spot
#' - **Rate Limit Pool**: Spot
#' - **Rate Limit Weight**: 2
#' - **SDK Service**: Spot
#' - **SDK Sub-Service**: Order
#' - **SDK Method Name**: getSymbolsWithOpenOrder
#' - **Official Documentation**: [KuCoin Get Symbols With Open Order](https://www.kucoin.com/docs-new/rest/spot-trading/orders/get-symbols-with-open-order)
#'
#' ## Request
#' ### Path Parameters
#' - None
#'
#' ### Query Parameters
#' - None
#'
#' ### Example Request
#' ```bash
#' curl --location --request GET 'https://api.kucoin.com/api/v1/hf/orders/active/symbols'
#' ```
#'
#' ## Response
#' ### HTTP Code: 200
#' - **Content Type**: `application/json`
#'
#' ### Data Schema
#' - `code`: String (required) - Response code ("200000" indicates success).
#' - `data`: Object (required) - Contains the following field:
#'   - `symbols`: Array[String] (required) - List of trading pair symbols with active orders (e.g., "ETH-USDT", "BTC-USDT").
#'
#' ### JSON Response Example
#' ```json
#' {
#'   "code": "200000",
#'   "data": {
#'     "symbols": [
#'       "ETH-USDT",
#'       "BTC-USDT"
#'     ]
#'   }
#' }
#' ```
#'
#' @param keys List; API configuration parameters from `get_api_keys()`. Defaults to `get_api_keys()`.
#' @param base_url Character string; base URL for the KuCoin API. Defaults to `get_base_url()`.
#' @return Promise resolving to a `data.table` with one column:
#'   - `symbols` (character): Vector of trading pair symbols with active orders.
#' @examples
#' \dontrun{
#' library(coro)
#' library(data.table)
#'
#' main_async <- coro::async(function() {
#'   # Retrieve symbols with open orders
#'   active_symbols <- await(get_symbols_with_open_order_impl())
#'   print(active_symbols)
#' })
#'
#' # Run the async function
#' main_async()
#' while (!later::loop_empty()) later::run_now()
#' }
#'
#' # Expected Output (example):
#' #    symbols
#' # 1: ETH-USDT
#' # 2: BTC-USDT
#' @importFrom coro async await
#' @importFrom data.table data.table
#' @importFrom httr GET timeout
#' @importFrom rlang abort
#' @export
get_symbols_with_open_order_impl <- coro::async(function(
    keys = get_api_keys(),
    base_url = get_base_url()
) {
    tryCatch({
        # Construct endpoint
        endpoint <- "/api/v1/hf/orders/active/symbols"
        full_url <- paste0(base_url, endpoint)

        # Generate authentication headers
        headers <- await(build_headers("GET", endpoint, NULL, keys))

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
        # If no symbols, return an empty data.table with the correct column
        if (length(parsed_response$data$symbols) == 0) {
            result_dt <- data.table::data.table(symbols = character())
        } else {
            result_dt <- data.table::data.table(symbols = parsed_response$data$symbols)
        }

        return(result_dt)
    }, error = function(e) {
        rlang::abort(sprintf("Error in get_symbols_with_open_order_impl: %s", conditionMessage(e)))
    })
})

#' Get Open Orders (Implementation)
#'
#' Retrieves all active spot orders for a specified symbol from the KuCoin Spot trading system asynchronously.
#' This function returns a `data.table` with detailed information about each active order, sorted by the latest update time in descending order.
#'
#' ## Description
#' This endpoint fetches all active orders for a given trading pair (e.g., "BTC-USDT"). Active orders are those currently in the order book and not fully filled or canceled.
#' The orders are returned in descending order based on their last update time.
#'
#' ## Workflow
#' 1. **Parameter Validation**: Ensures `symbol` is a non-empty string and a valid trading pair.
#' 2. **Request Construction**: Builds the endpoint URL with `symbol` as a query parameter.
#' 3. **Authentication**: Generates private API headers using `build_headers()` with the GET method and endpoint.
#' 4. **API Request**: Sends a GET request to the KuCoin API with a 3-second timeout.
#' 5. **Response Processing**: Parses the response, converts the array of orders to a `data.table`, and adds `createdAtDatetime` and `lastUpdatedAtDatetime` columns.
#'
#' ## API Details
#' - **Endpoint**: `GET https://api.kucoin.com/api/v1/hf/orders/active?symbol={symbol}`
#' - **Domain**: Spot
#' - **API Channel**: Private
#' - **API Permission**: General
#' - **Rate Limit Pool**: Spot
#' - **Rate Limit Weight**: 2
#' - **SDK Service**: Spot
#' - **SDK Sub-Service**: Order
#' - **SDK Method Name**: getOpenOrders
#' - **Official Documentation**: [KuCoin Get Open Orders](https://www.kucoin.com/docs-new/rest/spot-trading/orders/get-open-orders)
#'
#' ## Request
#' ### Query Parameters
#' - `symbol`: String (required) - The trading pair symbol (e.g., "BTC-USDT").
#'
#' ### Example Request
#' ```bash
#' curl --location --request GET 'https://api.kucoin.com/api/v1/hf/orders/active?symbol=BTC-USDT'
#' ```
#'
#' ## Response
#' ### HTTP Code: 200
#' - **Content Type**: `application/json`
#'
#' ### Data Schema
#' - `code`: String (required) - Response code ("200000" indicates success).
#' - `data`: Array of objects (required) - List of active orders, each with fields such as:
#'   - `id`: String - Unique order ID.
#'   - `clientOid`: String - Client-assigned order ID.
#'   - `symbol`: String - Trading pair.
#'   - `opType`: String - Operation type.
#'   - `type`: Enum<String> - Order type: "limit" or "market".
#'   - `side`: Enum<String> - Order side: "buy" or "sell".
#'   - `price`: String - Order price.
#'   - `size`: String - Order size.
#'   - `funds`: String - Order funds.
#'   - `dealSize`: String - Filled quantity.
#'   - `dealFunds`: String - Filled funds.
#'   - `cancelledSize`: String - Canceled quantity.
#'   - `cancelledFunds`: String - Canceled funds.
#'   - `remainSize`: String - Remaining quantity.
#'   - `remainFunds`: String - Remaining funds.
#'   - `fee`: String - Handling fees.
#'   - `feeCurrency`: String - Fee currency.
#'   - `stp`: Enum<String> - Self Trade Prevention: "DC", "CO", "CN", "CB" or null.
#'   - `timeInForce`: Enum<String> - Time in force: "GTC", "GTT", "IOC", "FOK".
#'   - `postOnly`: Boolean - Post-only flag.
#'   - `hidden`: Boolean - Hidden order flag.
#'   - `iceberg`: Boolean - Iceberg order flag.
#'   - `visibleSize`: String - Visible size for iceberg orders.
#'   - `cancelAfter`: Integer - Seconds until cancellation for GTT.
#'   - `channel`: String - Order channel.
#'   - `remark`: String or null - Order remarks.
#'   - `tags`: String or null - Order tags.
#'   - `cancelExist`: Boolean - Indicates a cancellation record.
#'   - `tradeType`: String - Trade type.
#'   - `inOrderBook`: Boolean - Whether in the order book.
#'   - `tax`: String - Tax information.
#'   - `active`: Boolean - Order status (true = active).
#'   - `createdAt`: Integer<int64> - Creation timestamp in milliseconds.
#'   - `lastUpdatedAt`: Integer<int64> - Last update timestamp in milliseconds.
#'
#' ### JSON Response Example
#' ```json
#' {
#'   "code": "200000",
#'   "data": [
#'     {
#'       "id": "67120bbef094e200070976f6",
#'       "clientOid": "5c52e11203aa677f33e493fb",
#'       "symbol": "BTC-USDT",
#'       "opType": "DEAL",
#'       "type": "limit",
#'       "side": "buy",
#'       "price": "50000",
#'       "size": "0.00001",
#'       "funds": "0.5",
#'       "dealSize": "0",
#'       "dealFunds": "0",
#'       "fee": "0",
#'       "feeCurrency": "USDT",
#'       "stp": null,
#'       "timeInForce": "GTC",
#'       "postOnly": false,
#'       "hidden": false,
#'       "iceberg": false,
#'       "visibleSize": "0",
#'       "cancelAfter": 0,
#'       "channel": "API",
#'       "remark": "order remarks",
#'       "tags": "order tags",
#'       "cancelExist": false,
#'       "tradeType": "TRADE",
#'       "inOrderBook": true,
#'       "cancelledSize": "0",
#'       "cancelledFunds": "0",
#'       "remainSize": "0.00001",
#'       "remainFunds": "0.5",
#'       "tax": "0",
#'       "active": true,
#'       "createdAt": 1729235902748,
#'       "lastUpdatedAt": 1729235909862
#'     }
#'   ]
#' }
#' ```
#'
#' @param keys List; API configuration parameters from `get_api_keys()`. Defaults to `get_api_keys()`.
#' @param base_url Character string; base URL for the KuCoin API. Defaults to `get_base_url()`.
#' @param symbol Character string; the trading pair symbol (e.g., "BTC-USDT"). Required.
#' @return Promise resolving to a `data.table` with columns corresponding to the order fields, including:
#'   - `id` (character): Unique order ID.
#'   - `clientOid` (character): Client-assigned order ID.
#'   - `symbol` (character): Trading pair.
#'   - `opType` (character): Operation type.
#'   - `type` (character): Order type ("limit" or "market").
#'   - `side` (character): Order side ("buy" or "sell").
#'   - `price` (character): Order price.
#'   - `size` (character): Order size.
#'   - `funds` (character): Order funds.
#'   - `dealSize` (character): Filled quantity.
#'   - `dealFunds` (character): Filled funds.
#'   - `cancelledSize` (character): Canceled quantity.
#'   - `cancelledFunds` (character): Canceled funds.
#'   - `remainSize` (character): Remaining quantity.
#'   - `remainFunds` (character): Remaining funds.
#'   - `fee` (character): Handling fees.
#'   - `feeCurrency` (character): Fee currency.
#'   - `stp` (character or NA): Self Trade Prevention strategy.
#'   - `timeInForce` (character): Time in force.
#'   - `postOnly` (logical): Post-only flag.
#'   - `hidden` (logical): Hidden order flag.
#'   - `iceberg` (logical): Iceberg order flag.
#'   - `visibleSize` (character): Visible size for iceberg orders.
#'   - `cancelAfter` (integer): Seconds until cancellation for GTT.
#'   - `channel` (character): Order channel.
#'   - `remark` (character or NA): Order remarks.
#'   - `tags` (character or NA): Order tags.
#'   - `cancelExist` (logical): Indicates a cancellation record.
#'   - `tradeType` (character): Trade type.
#'   - `inOrderBook` (logical): Whether in the order book.
#'   - `tax` (character): Tax information.
#'   - `active` (logical): Order status (true = active).
#'   - `createdAt` (integer): Creation timestamp (milliseconds).
#'   - `lastUpdatedAt` (integer): Last update timestamp (milliseconds).
#'   - `createdAtDatetime` (POSIXct): Creation time in UTC.
#'   - `lastUpdatedAtDatetime` (POSIXct): Last update time in UTC.
#' @examples
#' \dontrun{
#' library(coro)
#' library(data.table)
#'
#' main_async <- coro::async(function() {
#'   # Retrieve open orders for BTC-USDT
#'   open_orders <- await(get_open_orders_impl(symbol = "BTC-USDT"))
#'   print(open_orders)
#' })
#'
#' # Run the async function
#' main_async()
#' while (!later::loop_empty()) later::run_now()
#' }
#' @importFrom coro async await
#' @importFrom data.table data.table rbindlist
#' @importFrom httr GET timeout
#' @importFrom rlang abort
#' @export
get_open_orders_impl <- coro::async(function(
    keys = get_api_keys(),
    base_url = get_base_url(),
    symbol
) {
    tryCatch({
        # Validate parameters
        if (is.null(symbol) || !is.character(symbol) || nchar(symbol) == 0) {
            rlang::abort("Parameter 'symbol' must be a non-empty string (e.g., 'BTC-USDT').")
        }
        if (!verify_symbol(symbol)) {
            rlang::abort("Parameter 'symbol' must be a valid trading pair (e.g., 'BTC-USDT').")
        }

        # Construct endpoint and query string
        endpoint <- "/api/v1/hf/orders/active"
        query_params <- list(symbol = symbol)
        query_string <- build_query(query_params)
        endpoint_with_query <- paste0(endpoint, query_string)
        full_url <- paste0(base_url, endpoint_with_query)

        # Generate authentication headers
        headers <- await(build_headers("GET", endpoint_with_query, NULL, keys))

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
        if (length(parsed_response$data) == 0) {
            # Define empty data.table with expected columns
            order_details <- data.table::data.table(
                id = character(),
                clientOid = character(),
                symbol = character(),
                opType = character(),
                type = character(),
                side = character(),
                price = character(),
                size = character(),
                funds = character(),
                dealSize = character(),
                dealFunds = character(),
                cancelledSize = character(),
                cancelledFunds = character(),
                remainSize = character(),
                remainFunds = character(),
                fee = character(),
                feeCurrency = character(),
                stp = character(),
                timeInForce = character(),
                postOnly = logical(),
                hidden = logical(),
                iceberg = logical(),
                visibleSize = character(),
                cancelAfter = integer(),
                channel = character(),
                remark = character(),
                tags = character(),
                cancelExist = logical(),
                tradeType = character(),
                inOrderBook = logical(),
                tax = character(),
                active = logical(),
                createdAt = integer(),
                lastUpdatedAt = integer(),
                createdAtDatetime = as.POSIXct(character()),
                lastUpdatedAtDatetime = as.POSIXct(character())
            )
        } else {
            order_details <- data.table::rbindlist(parsed_response$data, fill = TRUE)
            # Add datetime columns
            order_details[, createdAtDatetime := time_convert_from_kucoin(createdAt, unit = "ms")]
            order_details[, lastUpdatedAtDatetime := time_convert_from_kucoin(lastUpdatedAt, unit = "ms")]
        }

        return(order_details)
    }, error = function(e) {
        rlang::abort(sprintf("Error in get_open_orders_impl: %s", conditionMessage(e)))
    })
})

#' Get Closed Orders (Implementation)
#'
#' Retrieves all closed spot orders for a specified symbol from the KuCoin Spot trading system asynchronously.
#' This function supports pagination and returns a `data.table` with detailed information about each closed order,
#' sorted by the latest update time in descending order.
#'
#' ## Description
#' This endpoint fetches all closed orders (canceled or fully filled) for a given trading pair (e.g., "BTC-USDT").
#' The orders are returned in descending order based on their last update time. The function handles pagination
#' using the `lastId` parameter to fetch multiple pages of results, with data availability limited to the last
#' 72 hours by default if no time range is specified beyond that period.
#'
#' ## Workflow
#' 1. **Parameter Validation**: Ensures `symbol` is a valid trading pair and `limit` is an integer between 1 and 100.
#' 2. **Request Construction**: Builds the API endpoint with query parameters including `symbol`, `side`, `type`, `startAt`, `endAt`, and `limit`.
#' 3. **Authentication**: Generates private API headers using `build_headers()` with the GET method and endpoint.
#' 4. **API Request**: Sends asynchronous GET requests to fetch pages of closed orders until no more orders are returned or `max_pages` is reached.
#' 5. **Response Processing**: Combines the fetched orders into a single `data.table` and adds `createdAtDatetime` and `lastUpdatedAtDatetime` columns using `time_convert_from_kucoin()`.
#'
#' ## API Details
#' - **Endpoint**: `GET https://api.kucoin.com/api/v1/hf/orders/done`
#' - **Domain**: Spot
#' - **API Channel**: Private
#' - **API Permission**: General
#' - **Rate Limit Pool**: Spot
#' - **Rate Limit Weight**: 2
#' - **SDK Service**: Spot
#' - **SDK Sub-Service**: Order
#' - **SDK Method Name**: getClosedOrders
#' - **Official Documentation**: [KuCoin Get Closed Orders](https://www.kucoin.com/docs-new/rest/spot-trading/orders/get-closed-orders)
#'
#' ## Request
#' ### Query Parameters
#' - `symbol`: String (required) - The trading pair symbol (e.g., "BTC-USDT").
#' - `side`: Enum<String> (optional) - Order side: "buy" or "sell".
#' - `type`: Enum<String> (optional) - Order type: "limit" or "market".
#' - `lastId`: Integer<int64> (optional) - The ID of the last order from the previous batch for pagination.
#' - `limit`: Integer (optional) - Number of orders per page (default 20, max 100).
#' - `startAt`: Integer<int64> (optional) - Start time in milliseconds.
#' - `endAt`: Integer<int64> (optional) - End time in milliseconds.
#'
#' ### Example Request
#' ```bash
#' curl --location --request GET 'https://api.kucoin.com/api/v1/hf/orders/done?symbol=BTC-USDT&side=buy&type=limit&lastId=254062248624417&limit=20&startAt=1728663338000&endAt=1728692138000'
#' ```
#'
#' ## Response
#' ### HTTP Code: 200
#' - **Content Type**: `application/json`
#'
#' ### Data Schema
#' - `code`: String (required) - Response code ("200000" indicates success).
#' - `data`: Object (required) - Contains:
#'   - `lastId`: Integer<int64> (required) - The ID for the next page of data.
#'   - `items`: Array of objects (required) - List of closed orders, each with fields:
#'     - `id`: String - Unique order ID.
#'     - `clientOid`: String - Client-assigned order ID.
#'     - `symbol`: String - Trading pair.
#'     - `opType`: String - Operation type.
#'     - `type`: Enum<String> - Order type: "limit" or "market".
#'     - `side`: Enum<String> - Order side: "buy" or "sell".
#'     - `price`: String - Order price.
#'     - `size`: String - Order size.
#'     - `funds`: String - Order funds.
#'     - `dealSize`: String - Filled quantity.
#'     - `dealFunds`: String - Filled funds.
#'     - `remainSize`: String - Remaining quantity.
#'     - `remainFunds`: String - Remaining funds.
#'     - `cancelledSize`: String - Canceled quantity.
#'     - `cancelledFunds`: String - Canceled funds.
#'     - `fee`: String - Handling fees.
#'     - `feeCurrency`: String - Fee currency.
#'     - `stp`: Enum<String> - Self Trade Prevention: "DC", "CO", "CN", "CB" or NA.
#'     - `timeInForce`: Enum<String> - Time in force: "GTC", "GTT", "IOC", "FOK".
#'     - `postOnly`: Boolean - Post-only flag.
#'     - `hidden`: Boolean - Hidden order flag.
#'     - `iceberg`: Boolean - Iceberg order flag.
#'     - `visibleSize`: String - Visible size for iceberg orders.
#'     - `cancelAfter`: Integer - Seconds until cancellation for GTT.
#'     - `channel`: String - Order channel.
#'     - `remark`: String or NA - Order remarks.
#'     - `tags`: String or NA - Order tags.
#'     - `cancelExist`: Boolean - Indicates a cancellation record.
#'     - `tradeType`: String - Trade type.
#'     - `inOrderBook`: Boolean - Whether in the order book.
#'     - `tax`: String - Tax information.
#'     - `active`: Boolean - Order status (false for closed orders).
#'     - `createdAt`: Integer<int64> - Creation timestamp in milliseconds.
#'     - `lastUpdatedAt`: Integer<int64> - Last update timestamp in milliseconds.
#'
#' ### JSON Response Example
#' ```json
#' {
#'   "code": "200000",
#'   "data": {
#'     "lastId": 19814995255305,
#'     "items": [
#'       {
#'         "id": "6717422bd51c29000775ea03",
#'         "clientOid": "5c52e11203aa677f33e493fb",
#'         "symbol": "BTC-USDT",
#'         "opType": "DEAL",
#'         "type": "limit",
#'         "side": "buy",
#'         "price": "70000",
#'         "size": "0.00001",
#'         "funds": "0.7",
#'         "dealSize": "0.00001",
#'         "dealFunds": "0.677176",
#'         "remainSize": "0",
#'         "remainFunds": "0.022824",
#'         "cancelledSize": "0",
#'         "cancelledFunds": "0",
#'         "fee": "0.000677176",
#'         "feeCurrency": "USDT",
#'         "stp": null,
#'         "timeInForce": "GTC",
#'         "postOnly": false,
#'         "hidden": false,
#'         "iceberg": false,
#'         "visibleSize": "0",
#'         "cancelAfter": 0,
#'         "channel": "API",
#'         "remark": "order remarks",
#'         "tags": null,
#'         "cancelExist": false,
#'         "tradeType": "TRADE",
#'         "inOrderBook": false,
#'         "active": false,
#'         "tax": "0",
#'         "createdAt": 1729577515444,
#'         "lastUpdatedAt": 1729577515481
#'       }
#'     ]
#'   }
#' }
#' ```
#'
#' @param keys List; API configuration parameters from `get_api_keys()`. Defaults to `get_api_keys()`.
#' @param base_url Character string; base URL for the KuCoin API. Defaults to `get_base_url()`.
#' @param symbol Character string; the trading pair symbol (e.g., "BTC-USDT"). Required.
#' @param side Character string; optional filter for order side: "buy" or "sell".
#' @param type Character string; optional filter for order type: "limit" or "market".
#' @param startAt Numeric; optional start time in milliseconds.
#' @param endAt Numeric; optional end time in milliseconds.
#' @param limit Integer; number of orders per page (1 to 100, default 20).
#' @param max_pages Numeric; maximum number of pages to fetch (default `Inf`).
#' @return Promise resolving to a `data.table` with columns:
#'   - `id` (character): Unique order ID.
#'   - `clientOid` (character): Client-assigned order ID.
#'   - `symbol` (character): Trading pair.
#'   - `opType` (character): Operation type.
#'   - `type` (character): Order type ("limit" or "market").
#'   - `side` (character): Order side ("buy" or "sell").
#'   - `price` (character): Order price.
#'   - `size` (character): Order size.
#'   - `funds` (character): Order funds.
#'   - `dealSize` (character): Filled quantity.
#'   - `dealFunds` (character): Filled funds.
#'   - `remainSize` (character): Remaining quantity.
#'   - `remainFunds` (character): Remaining funds.
#'   - `cancelledSize` (character): Canceled quantity.
#'   - `cancelledFunds` (character): Canceled funds.
#'   - `fee` (character): Handling fees.
#'   - `feeCurrency` (character): Fee currency.
#'   - `stp` (character or NA): Self Trade Prevention strategy.
#'   - `timeInForce` (character): Time in force.
#'   - `postOnly` (logical): Post-only flag.
#'   - `hidden` (logical): Hidden order flag.
#'   - `iceberg` (logical): Iceberg order flag.
#'   - `visibleSize` (character): Visible size for iceberg orders.
#'   - `cancelAfter` (integer): Seconds until cancellation for GTT.
#'   - `channel` (character): Order channel.
#'   - `remark` (character or NA): Order remarks.
#'   - `tags` (character or NA): Order tags.
#'   - `cancelExist` (logical): Indicates a cancellation record.
#'   - `tradeType` (character): Trade type.
#'   - `inOrderBook` (logical): Whether in the order book.
#'   - `tax` (character): Tax information.
#'   - `active` (logical): Order status (false for closed orders).
#'   - `createdAt` (numeric): Creation timestamp (milliseconds).
#'   - `lastUpdatedAt` (numeric): Last update timestamp (milliseconds).
#'   - `createdAtDatetime` (POSIXct): Creation time in UTC.
#'   - `lastUpdatedAtDatetime` (POSIXct): Last update time in UTC.
#' @examples
#' \dontrun{
#' library(coro)
#' library(data.table)
#'
#' main_async <- coro::async(function() {
#'   # Retrieve closed orders for BTC-USDT
#'   closed_orders <- await(get_closed_orders_impl(
#'     symbol = "BTC-USDT",
#'     side = "buy",
#'     type = "limit",
#'     startAt = 1728663338000,
#'     endAt = 1728692138000,
#'     limit = 50,
#'     max_pages = 2
#'   ))
#'   print(closed_orders)
#' })
#'
#' # Run the async function
#' main_async()
#' while (!later::loop_empty()) later::run_now()
#' }
#' @importFrom coro async await
#' @importFrom data.table data.table rbindlist
#' @importFrom httr GET timeout
#' @importFrom rlang abort
#' @export
get_closed_orders_impl <- coro::async(function(
    keys = get_api_keys(),
    base_url = get_base_url(),
    symbol,
    side = NULL,
    type = NULL,
    startAt = NULL,
    endAt = NULL,
    limit = 20,
    max_pages = Inf
) {
    tryCatch({
        # Validate parameters
        if (is.null(symbol) || !is.character(symbol) || nchar(symbol) == 0) {
            rlang::abort("Parameter 'symbol' must be a non-empty string (e.g., 'BTC-USDT').")
        }
        if (!verify_symbol(symbol)) {
            rlang::abort("Parameter 'symbol' must be a valid trading pair (e.g., 'BTC-USDT').")
        }
        if (!is.numeric(limit) || limit < 1 || limit > 100 || limit %% 1 != 0) {
            rlang::abort("Parameter 'limit' must be an integer between 1 and 100.")
        }

        # Construct base query
        query <- list(symbol = symbol, limit = as.integer(limit))
        if (!is.null(side)) query$side <- side
        if (!is.null(type)) query$type <- type
        if (!is.null(startAt)) query$startAt <- as.numeric(startAt)
        if (!is.null(endAt)) query$endAt <- as.numeric(endAt)

        # Inner function to fetch a single page
        fetch_page <- coro::async(function(lastId = NULL) {
            if (!is.null(lastId)) query$lastId <- lastId
            query_string <- build_query(query)
            endpoint <- "/api/v1/hf/orders/done"
            full_url <- paste0(base_url, endpoint, query_string)
            headers <- await(build_headers("GET", paste0(endpoint, query_string), NULL, keys))
            response <- httr::GET(full_url, headers, httr::timeout(3))
            parsed <- process_kucoin_response(response, full_url)
            if (parsed$code != "200000") {
                rlang::abort(sprintf("API error: %s - %s", parsed$code, parsed$msg))
            }
            return(parsed$data)
        })

        # Collect pages
        orders_list <- list()
        page <- 1
        lastId <- NULL
        while (TRUE) {
            data <- await(fetch_page(lastId))
            if (length(data$items) == 0 || page >= max_pages) {
                break
            }
            orders_list[[page]] <- data$items
            lastId <- data$lastId
            page <- page + 1
        }

        # Combine results and add datetime columns
        if (length(orders_list) == 0) {
            orders_dt <- data.table::data.table(
                id = character(),
                clientOid = character(),
                symbol = character(),
                opType = character(),
                type = character(),
                side = character(),
                price = character(),
                size = character(),
                funds = character(),
                dealSize = character(),
                dealFunds = character(),
                remainSize = character(),
                remainFunds = character(),
                cancelledSize = character(),
                cancelledFunds = character(),
                fee = character(),
                feeCurrency = character(),
                stp = character(),
                timeInForce = character(),
                postOnly = logical(),
                hidden = logical(),
                iceberg = logical(),
                visibleSize = character(),
                cancelAfter = integer(),
                channel = character(),
                remark = character(),
                tags = character(),
                cancelExist = logical(),
                tradeType = character(),
                inOrderBook = logical(),
                tax = character(),
                active = logical(),
                createdAt = numeric(),
                lastUpdatedAt = numeric(),
                createdAtDatetime = as.POSIXct(character()),
                lastUpdatedAtDatetime = as.POSIXct(character())
            )
        } else {
            orders_dt <- data.table::rbindlist(orders_list, fill = TRUE)
            orders_dt[, createdAtDatetime := time_convert_from_kucoin(createdAt, unit = "ms")]
            orders_dt[, lastUpdatedAtDatetime := time_convert_from_kucoin(lastUpdatedAt, unit = "ms")]
        }

        return(orders_dt)
    }, error = function(e) {
        rlang::abort(sprintf("Error in get_closed_orders_impl: %s", conditionMessage(e)))
    })
})
