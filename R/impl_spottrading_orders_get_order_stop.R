# File: ./R/impl_spottrading_orders_get_order_stop.R

box::use(
    ./helpers_api[process_kucoin_response, build_headers],
    ./utils[build_query, get_base_url, verify_symbol, get_api_keys],
    ./utils_time_convert_kucoin[time_convert_from_kucoin],
    coro[async, await],
    data.table[data.table, rbindlist],
    httr[GET, timeout],
    rlang[abort]
)

#' Get Stop Orders List (Implementation)
#'
#' Retrieves a paginated list of untriggered stop orders from the KuCoin Spot trading system asynchronously.
#' This function constructs a GET request to the KuCoin API and returns a promise that resolves to a `data.table`
#' containing details of stop orders, sorted by the latest update time in descending order.
#'
#' ## Description
#' This endpoint fetches a list of stop orders that have not yet been triggered. Stop orders are conditional orders
#' that become active when the market price reaches a specified `stopPrice`. The list is paginated and sorted to show
#' the most recent orders first. Users can filter the results using various query parameters such as `symbol`, `side`,
#' `type`, and time range.
#'
#' ## Workflow
#' 1. **Parameter Validation**: Ensures that provided parameters are valid, such as `symbol`, `side`, `type`, and pagination settings.
#' 2. **Request Construction**: Builds the endpoint URL with query parameters for filtering and pagination.
#' 3. **Authentication**: Generates private API headers using `build_headers()` with the GET method and endpoint.
#' 4. **API Request**: Sends a GET request to the KuCoin API with a 3-second timeout.
#' 5. **Response Processing**: Parses the response, converts the `items` array to a `data.table`, and adds datetime columns for `createdAt` and `orderTime`.
#'
#' ## API Details
#' - **Endpoint**: `GET https://api.kucoin.com/api/v1/stop-order`
#' - **Domain**: Spot
#' - **API Channel**: Private
#' - **API Permission**: General
#' - **Rate Limit Pool**: Spot
#' - **Rate Limit Weight**: 8
#' - **SDK Service**: Spot
#' - **SDK Sub-Service**: Order
#' - **SDK Method Name**: getStopOrdersList
#' - **Official Documentation**: [KuCoin Get Stop Orders List](https://www.kucoin.com/docs-new/rest/spot-trading/orders/get-stop-orders-list)
#'
#' ## Request
#' ### Query Parameters
#' - `symbol`: String (optional) - Filter by trading pair (e.g., "BTC-USDT").
#' - `side`: Enum<String> (optional) - Filter by order side: "buy" or "sell".
#' - `type`: Enum<String> (optional) - Filter by order type: "limit", "market", "limit_stop", "market_stop".
#' - `tradeType`: Enum<String> (optional) - Filter by trade type: "TRADE", "MARGIN_TRADE", "MARGIN_ISOLATED_TRADE".
#' - `startAt`: Integer<int64> (optional) - Start time in milliseconds.
#' - `endAt`: Integer<int64> (optional) - End time in milliseconds.
#' - `currentPage`: Integer (optional) - Current page number.
#' - `orderIds`: String (optional) - Comma-separated list of order IDs.
#' - `pageSize`: Integer (optional) - Number of orders per page.
#' - `stop`: String (optional) - Filter by stop order type: "stop" or "oco".
#'
#' ### Example Request
#' ```bash
#' curl --location --request GET 'https://api.kucoin.com/api/v1/stop-order?symbol=BTC-USDT&side=buy&pageSize=10'
#' ```
#'
#' ## Response
#' ### HTTP Code: 200
#' - **Content Type**: `application/json`
#'
#' ### Data Schema
#' - `code`: String (required) - Response code ("200000" indicates success).
#' - `data`: Object (required) - Contains:
#'   - `currentPage`: Integer - Current page number.
#'   - `pageSize`: Integer - Number of orders per page.
#'   - `totalNum`: Integer - Total number of stop orders.
#'   - `totalPage`: Integer - Total number of pages.
#'   - `items`: Array of objects - List of stop orders, each with fields such as:
#'     - `id`: String - Order ID.
#'     - `symbol`: String - Trading pair.
#'     - `userId`: String - User ID.
#'     - `status`: String - Order status.
#'     - `type`: String - Order type.
#'     - `side`: String - Order side.
#'     - `price`: String - Order price.
#'     - `size`: String - Order size.
#'     - `funds`: String - Order funds.
#'     - `stp`: String - Self Trade Prevention.
#'     - `timeInForce`: String - Time in force.
#'     - `cancelAfter`: Integer - Cancel after n seconds.
#'     - `postOnly`: Boolean - Post-only flag.
#'     - `hidden`: Boolean - Hidden order flag.
#'     - `iceberg`: Boolean - Iceberg order flag.
#'     - `visibleSize`: String - Visible size for iceberg orders.
#'     - `channel`: String - Order channel.
#'     - `clientOid`: String - Client order ID.
#'     - `remark`: String - Order remarks.
#'     - `tags`: String - Order tags.
#'     - `orderTime`: Integer - Order time in nanoseconds.
#'     - `domainId`: String - Domain ID.
#'     - `tradeSource`: String - Trade source.
#'     - `tradeType`: String - Trade type.
#'     - `feeCurrency`: String - Fee currency.
#'     - `takerFeeRate`: String - Taker fee rate.
#'     - `makerFeeRate`: String - Maker fee rate.
#'     - `createdAt`: Integer - Creation timestamp in milliseconds.
#'     - `stop`: String - Stop order type.
#'     - `stopTriggerTime`: Integer - Stop trigger time.
#'     - `stopPrice`: String - Stop price.
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
#'       {
#'         "id": "vs8hoo8kqjnklv4m0038lrfq",
#'         "symbol": "KCS-USDT",
#'         "userId": "60fe4956c43cbc0006562c2c",
#'         "status": "NEW",
#'         "type": "limit",
#'         "side": "buy",
#'         "price": "0.01000000000000000000",
#'         "size": "0.01000000000000000000",
#'         "funds": null,
#'         "stp": null,
#'         "timeInForce": "GTC",
#'         "cancelAfter": -1,
#'         "postOnly": false,
#'         "hidden": false,
#'         "iceberg": false,
#'         "visibleSize": null,
#'         "channel": "API",
#'         "clientOid": "404814a0fb4311eb9098acde48001122",
#'         "remark": null,
#'         "tags": null,
#'         "orderTime": 1628755183702150167,
#'         "domainId": "kucoin",
#'         "tradeSource": "USER",
#'         "tradeType": "TRADE",
#'         "feeCurrency": "USDT",
#'         "takerFeeRate": "0.00200000000000000000",
#'         "makerFeeRate": "0.00200000000000000000",
#'         "createdAt": 1628755183704,
#'         "stop": "loss",
#'         "stopTriggerTime": null,
#'         "stopPrice": "10.00000000000000000000"
#'       }
#'     ]
#'   }
#' }
#' ```
#'
#' @param keys List; API configuration parameters from `get_api_keys()`. Defaults to `get_api_keys()`.
#' @param base_url Character string; base URL for the KuCoin API. Defaults to `get_base_url()`.
#' @param query Named list; query parameters for filtering and pagination (e.g., `list(symbol = "BTC-USDT", side = "buy", pageSize = 10)`). Optional.
#' @return Promise resolving to a `data.table` containing stop order details, with the following columns:
#'   - `id` (character): Unique order ID assigned by KuCoin.
#'   - `symbol` (character): Trading pair (e.g., "KCS-USDT").
#'   - `userId` (character): User ID associated with the order.
#'   - `status` (character): Order status (e.g., "NEW", "TRIGGERED").
#'   - `type` (character): Order type (e.g., "limit", "market").
#'   - `side` (character): Order side ("buy" or "sell").
#'   - `price` (character): Order price.
#'   - `size` (character): Order size.
#'   - `funds` (character or NA): Order funds (NULL for untriggered orders).
#'   - `stp` (character or NA): Self Trade Prevention strategy (e.g., "DC", "CO", "CN", "CB").
#'   - `timeInForce` (character): Time in force (e.g., "GTC", "GTT", "IOC", "FOK").
#'   - `cancelAfter` (integer): Seconds until cancellation for GTT (-1 if not applicable).
#'   - `postOnly` (logical): Whether the order is post-only.
#'   - `hidden` (logical): Whether the order is hidden.
#'   - `iceberg` (logical): Whether the order is an iceberg order.
#'   - `visibleSize` (character or NA): Visible size for iceberg orders.
#'   - `channel` (character): Order source (e.g., "API").
#'   - `clientOid` (character): Client-assigned order ID.
#'   - `remark` (character or NA): Order remarks.
#'   - `tags` (character or NA): Order tags.
#'   - `orderTime` (numeric): Order creation time in nanoseconds.
#'   - `domainId` (character): Domain ID (e.g., "kucoin").
#'   - `tradeSource` (character): Trade source (e.g., "USER").
#'   - `tradeType` (character): Trade type (e.g., "TRADE").
#'   - `feeCurrency` (character): Currency used for fees.
#'   - `takerFeeRate` (character): Taker fee rate.
#'   - `makerFeeRate` (character): Maker fee rate.
#'   - `createdAt` (integer): Creation timestamp in milliseconds.
#'   - `stop` (character): Stop order type (e.g., "loss", "entry").
#'   - `stopTriggerTime` (integer or NA): Trigger time in milliseconds (NULL if untriggered).
#'   - `stopPrice` (character): Stop price.
#'   - `createdAtDatetime` (POSIXct): Creation time in UTC (derived from `createdAt`).
#'   - `orderTimeDatetime` (POSIXct): Order placement time in UTC (derived from `orderTime`).
#' @examples
#' \dontrun{
#' library(coro)
#' library(data.table)
#'
#' main_async <- coro::async(function() {
#'   # Retrieve stop orders list for BTC-USDT
#'   stop_orders <- await(get_stop_orders_list_impl(
#'     query = list(symbol = "BTC-USDT", side = "buy", pageSize = 10)
#'   ))
#'   print(stop_orders)
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
get_stop_orders_list_impl <- coro::async(function(
    keys = get_api_keys(),
    base_url = get_base_url(),
    query = list()
) {
    tryCatch({
        # Validate parameters
        if (!is.list(query)) {
            rlang::abort("Parameter 'query' must be a named list.")
        }
        if ("symbol" %in% names(query) && !is.null(query$symbol) && !verify_symbol(query$symbol)) {
            rlang::abort("Parameter 'query$symbol', if provided, must be a valid trading pair (e.g., 'BTC-USDT').")
        }

        # Construct endpoint and query string
        endpoint <- "/api/v1/stop-order"
        query_string <- build_query(query)
        full_url <- paste0(base_url, endpoint, query_string)

        # Generate authentication headers
        headers <- await(build_headers("GET", paste0(endpoint, query_string), NULL, keys))

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
            stop_orders_dt <- data.table::data.table(
                id = character(),
                symbol = character(),
                userId = character(),
                status = character(),
                type = character(),
                side = character(),
                price = character(),
                size = character(),
                funds = character(),
                stp = character(),
                timeInForce = character(),
                cancelAfter = integer(),
                postOnly = logical(),
                hidden = logical(),
                iceberg = logical(),
                visibleSize = character(),
                channel = character(),
                clientOid = character(),
                remark = character(),
                tags = character(),
                orderTime = numeric(),
                domainId = character(),
                tradeSource = character(),
                tradeType = character(),
                feeCurrency = character(),
                takerFeeRate = character(),
                makerFeeRate = character(),
                createdAt = integer(),
                stop = character(),
                stopTriggerTime = integer(),
                stopPrice = character(),
                createdAtDatetime = as.POSIXct(character()),
                orderTimeDatetime = as.POSIXct(character())
            )
        } else {
            stop_orders_dt <- data.table::rbindlist(parsed_response$data$items, fill = TRUE)
            stop_orders_dt[, createdAtDatetime := time_convert_from_kucoin(createdAt, unit = "ms")]
            stop_orders_dt[, orderTimeDatetime := time_convert_from_kucoin(orderTime, unit = "ns")]
        }

        return(stop_orders_dt)
    }, error = function(e) {
        rlang::abort(sprintf("Error in get_stop_orders_list_impl: %s", conditionMessage(e)))
    })
})

#' Get Stop Order By OrderId (Implementation)
#'
#' Retrieves detailed information for a single stop order using its order ID from the KuCoin Spot trading system asynchronously.
#' This function constructs a GET request to the KuCoin API and returns a promise that resolves to a `data.table`
#' with comprehensive stop order details, including additional UTC datetime columns derived from timestamps.
#'
#' ## Description
#' This endpoint fetches data for a specific stop order identified by its `orderId`, which is the unique identifier
#' assigned by the KuCoin system when the order is created. The stop order can be in various states, such as "NEW"
#' (untriggered) or "TRIGGERED" (activated).
#'
#' ## Workflow
#' 1. **Parameter Validation**: Ensures `orderId` is a non-empty string.
#' 2. **Request Construction**: Builds the endpoint URL with `orderId` as a path parameter.
#' 3. **Authentication**: Generates private API headers using `build_headers()` with the GET method and endpoint.
#' 4. **API Request**: Sends a GET request to the KuCoin API with a 3-second timeout.
#' 5. **Response Processing**: Parses the response, converts the `data` object to a `data.table`, and adds `createdAtDatetime` and `orderTimeDatetime` columns.
#'
#' ## API Details
#' - **Endpoint**: `GET https://api.kucoin.com/api/v1/stop-order/{orderId}`
#' - **Domain**: Spot
#' - **API Channel**: Private
#' - **API Permission**: General
#' - **Rate Limit Pool**: Spot
#' - **Rate Limit Weight**: 3
#' - **SDK Service**: Spot
#' - **SDK Sub-Service**: Order
#' - **SDK Method Name**: getStopOrderByOrderId
#' - **Official Documentation**: [KuCoin Get Stop Order By OrderId](https://www.kucoin.com/docs-new/rest/spot-trading/orders/get-stop-order-by-orderld)
#'
#' ## Request
#' ### Path Parameters
#' - `orderId`: String (required) - The unique order ID generated by the trading system (e.g., "vs8hoo8q2ceshiue003b67c0").
#'
#' ### Example Request
#' ```bash
#' curl --location --request GET 'https://api.kucoin.com/api/v1/stop-order/vs8hoo8q2ceshiue003b67c0'
#' ```
#'
#' ## Response
#' ### HTTP Code: 200
#' - **Content Type**: `application/json`
#'
#' ### Data Schema
#' - `code`: String (required) - Response code ("200000" indicates success).
#' - `data`: Object (required) - Stop order details with fields such as:
#'   - `id`: String - Order ID.
#'   - `symbol`: String - Trading pair.
#'   - `userId`: String - User ID.
#'   - `status`: String - Order status.
#'   - `type`: String - Order type.
#'   - `side`: String - Order side.
#'   - `price`: String - Order price.
#'   - `size`: String - Order size.
#'   - `funds`: String - Order funds.
#'   - `stp`: String - Self Trade Prevention.
#'   - `timeInForce`: String - Time in force.
#'   - `cancelAfter`: Integer - Cancel after n seconds.
#'   - `postOnly`: Boolean - Post-only flag.
#'   - `hidden`: Boolean - Hidden order flag.
#'   - `iceberg`: Boolean - Iceberg order flag.
#'   - `visibleSize`: String - Visible size for iceberg orders.
#'   - `channel`: String - Order channel.
#'   - `clientOid`: String - Client order ID.
#'   - `remark`: String - Order remarks.
#'   - `tags`: String - Order tags.
#'   - `orderTime`: Integer - Order time in nanoseconds.
#'   - `domainId`: String - Domain ID.
#'   - `tradeSource`: String - Trade source.
#'   - `tradeType`: String - Trade type.
#'   - `feeCurrency`: String - Fee currency.
#'   - `takerFeeRate`: String - Taker fee rate.
#'   - `makerFeeRate`: String - Maker fee rate.
#'   - `createdAt`: Integer - Creation timestamp in milliseconds.
#'   - `stop`: String - Stop order type.
#'   - `stopTriggerTime`: Integer - Stop trigger time.
#'   - `stopPrice`: String - Stop price.
#'
#' ### JSON Response Example
#' ```json
#' {
#'   "code": "200000",
#'   "data": {
#'     "id": "vs8hoo8q2ceshiue003b67c0",
#'     "symbol": "KCS-USDT",
#'     "userId": "60fe4956c43cbc0006562c2c",
#'     "status": "NEW",
#'     "type": "limit",
#'     "side": "buy",
#'     "price": "0.01000000000000000000",
#'     "size": "0.01000000000000000000",
#'     "funds": null,
#'     "stp": null,
#'     "timeInForce": "GTC",
#'     "cancelAfter": -1,
#'     "postOnly": false,
#'     "hidden": false,
#'     "iceberg": false,
#'     "visibleSize": null,
#'     "channel": "API",
#'     "clientOid": "40e0eb9efe6311eb8e58acde48001122",
#'     "remark": null,
#'     "tags": null,
#'     "orderTime": 1629098781127530345,
#'     "domainId": "kucoin",
#'     "tradeSource": "USER",
#'     "tradeType": "TRADE",
#'     "feeCurrency": "USDT",
#'     "takerFeeRate": "0.00200000000000000000",
#'     "makerFeeRate": "0.00200000000000000000",
#'     "createdAt": 1629098781128,
#'     "stop": "loss",
#'     "stopTriggerTime": null,
#'     "stopPrice": "10.00000000000000000000"
#'   }
#' }
#' ```
#'
#' @param keys List; API configuration parameters from `get_api_keys()`. Defaults to `get_api_keys()`.
#' @param base_url Character string; base URL for the KuCoin API. Defaults to `get_base_url()`.
#' @param orderId Character string; the unique order ID to retrieve (e.g., "vs8hoo8q2ceshiue003b67c0"). Required.
#' @return Promise resolving to a `data.table` with one row containing stop order details, with the following columns:
#'   - `id` (character): Unique order ID assigned by KuCoin.
#'   - `symbol` (character): Trading pair (e.g., "KCS-USDT").
#'   - `userId` (character): User ID associated with the order.
#'   - `status` (character): Order status (e.g., "NEW", "TRIGGERED").
#'   - `type` (character): Order type (e.g., "limit", "market").
#'   - `side` (character): Order side ("buy" or "sell").
#'   - `price` (character): Order price.
#'   - `size` (character): Order size.
#'   - `funds` (character or NA): Order funds (NULL for untriggered orders).
#'   - `stp` (character or NA): Self Trade Prevention strategy (e.g., "DC", "CO", "CN", "CB").
#'   - `timeInForce` (character): Time in force (e.g., "GTC", "GTT", "IOC", "FOK").
#'   - `cancelAfter` (integer): Seconds until cancellation for GTT (-1 if not applicable).
#'   - `postOnly` (logical): Whether the order is post-only.
#'   - `hidden` (logical): Whether the order is hidden.
#'   - `iceberg` (logical): Whether the order is an iceberg order.
#'   - `visibleSize` (character or NA): Visible size for iceberg orders.
#'   - `channel` (character): Order source (e.g., "API").
#'   - `clientOid` (character): Client-assigned order ID.
#'   - `remark` (character or NA): Order remarks.
#'   - `tags` (character or NA): Order tags.
#'   - `orderTime` (numeric): Order creation time in nanoseconds.
#'   - `domainId` (character): Domain ID (e.g., "kucoin").
#'   - `tradeSource` (character): Trade source (e.g., "USER").
#'   - `tradeType` (character): Trade type (e.g., "TRADE").
#'   - `feeCurrency` (character): Currency used for fees.
#'   - `takerFeeRate` (character): Taker fee rate.
#'   - `makerFeeRate` (character): Maker fee rate.
#'   - `createdAt` (integer): Creation timestamp in milliseconds.
#'   - `stop` (character): Stop order type (e.g., "loss", "entry").
#'   - `stopTriggerTime` (integer or NA): Trigger time in milliseconds (NULL if untriggered).
#'   - `stopPrice` (character): Stop price.
#'   - `createdAtDatetime` (POSIXct): Creation time in UTC (derived from `createdAt`).
#'   - `orderTimeDatetime` (POSIXct): Order placement time in UTC (derived from `orderTime`).
#' @examples
#' \dontrun{
#' library(coro)
#' library(data.table)
#'
#' main_async <- coro::async(function() {
#'   # Retrieve stop order details by orderId
#'   stop_order_details <- await(get_stop_order_by_order_id_impl(
#'     orderId = "vs8hoo8q2ceshiue003b67c0"
#'   ))
#'   print(stop_order_details)
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
get_stop_order_by_order_id_impl <- coro::async(function(
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
        stop_order_details <- data.table::rbindlist(list(parsed_response$data), fill = TRUE)

        # Add datetime columns from millisecond and nanosecond timestamps
        stop_order_details[, createdAtDatetime := time_convert_from_kucoin(createdAt, unit = "ms")]
        stop_order_details[, orderTimeDatetime := time_convert_from_kucoin(orderTime, unit = "ns")]

        return(stop_order_details)
    }, error = function(e) {
        rlang::abort(sprintf("Error in get_stop_order_by_order_id_impl: %s", conditionMessage(e)))
    })
})

#' Get Stop Order By ClientOid (Implementation)
#'
#' Retrieves detailed information for a single stop order using its client order ID (`clientOid`) from the KuCoin Spot trading system asynchronously.
#' This function constructs a GET request to the KuCoin API and returns a promise that resolves to a `data.table`
#' with comprehensive stop order details, including additional UTC datetime columns derived from timestamps.
#'
#' ## Description
#' This endpoint fetches data for a specific stop order identified by its `clientOid`, a unique identifier assigned
#' by the user when placing the order. The stop order can be in various states, such as "NEW" (untriggered) or
#' "TRIGGERED" (activated).
#'
#' ## Workflow
#' 1. **Parameter Validation**: Ensures `clientOid` is a non-empty string and `symbol` (if provided) is a valid trading pair.
#' 2. **Request Construction**: Builds the endpoint URL with query parameters `clientOid` and optionally `symbol`.
#' 3. **Authentication**: Generates private API headers using `build_headers()` with the GET method and endpoint.
#' 4. **API Request**: Sends a GET request to the KuCoin API with a 3-second timeout.
#' 5. **Response Processing**: Parses the response, converts the `data` array to a `data.table`, and adds `createdAtDatetime` and `orderTimeDatetime` columns.
#'
#' ## API Details
#' - **Endpoint**: `GET https://api.kucoin.com/api/v1/stop-order/queryOrderByClientOid`
#' - **Domain**: Spot
#' - **API Channel**: Private
#' - **API Permission**: General
#' - **Rate Limit Pool**: Spot
#' - **Rate Limit Weight**: 3
#' - **SDK Service**: Spot
#' - **SDK Sub-Service**: Order
#' - **SDK Method Name**: getStopOrderByClientOid
#' - **Official Documentation**: [KuCoin Get Stop Order By ClientOid](https://www.kucoin.com/docs-new/rest/spot-trading/get-stop-order-by-clientoid)
#'
#' ## Request
#' ### Query Parameters
#' - `clientOid`: String (required) - The unique client order ID (e.g., "2b700942b5db41cebe578cff48960e09").
#' - `symbol`: String (optional) - The trading pair symbol (e.g., "KCS-USDT").
#'
#' ### Example Request
#' ```bash
#' curl --location --request GET 'https://api.kucoin.com/api/v1/stop-order/queryOrderByClientOid?clientOid=404814a0fb4311eb9098acde48001122&symbol=KCS-USDT'
#' ```
#'
#' ## Response
#' ### HTTP Code: 200
#' - **Content Type**: `application/json`
#'
#' ### Data Schema
#' - `code`: String (required) - Response code ("200000" indicates success).
#' - `data`: Array of objects (required) - List of stop order details (typically one item), each with fields such as:
#'   - `id`: String - Order ID.
#'   - `symbol`: String - Trading pair.
#'   - `userId`: String - User ID.
#'   - `status`: String - Order status.
#'   - `type`: String - Order type.
#'   - `side`: String - Order side.
#'   - `price`: String - Order price.
#'   - `size`: String - Order size.
#'   - `funds`: String - Order funds.
#'   - `stp`: String - Self Trade Prevention.
#'   - `timeInForce`: String - Time in force.
#'   - `cancelAfter`: Integer - Cancel after n seconds.
#'   - `postOnly`: Boolean - Post-only flag.
#'   - `hidden`: Boolean - Hidden order flag.
#'   - `iceberg`: Boolean - Iceberg order flag.
#'   - `visibleSize`: String - Visible size for iceberg orders.
#'   - `channel`: String - Order channel.
#'   - `clientOid`: String - Client order ID.
#'   - `remark`: String - Order remarks.
#'   - `tags`: String - Order tags.
#'   - `orderTime`: Integer - Order time in nanoseconds.
#'   - `domainId`: String - Domain ID.
#'   - `tradeSource`: String - Trade source.
#'   - `tradeType`: String - Trade type.
#'   - `feeCurrency`: String - Fee currency.
#'   - `takerFeeRate`: String - Taker fee rate.
#'   - `makerFeeRate`: String - Maker fee rate.
#'   - `createdAt`: Integer - Creation timestamp in milliseconds.
#'   - `stop`: String - Stop order type.
#'   - `stopTriggerTime`: Integer - Stop trigger time.
#'   - `stopPrice`: String - Stop price.
#'
#' ### JSON Response Example
#' ```json
#' {
#'   "code": "200000",
#'   "data": [
#'     {
#'       "id": "vs8hoo8os561f5np0032vngj",
#'       "symbol": "KCS-USDT",
#'       "userId": "60fe4956c43cbc0006562c2c",
#'       "status": "NEW",
#'       "type": "limit",
#'       "side": "buy",
#'       "price": "0.01000000000000000000",
#'       "size": "0.01000000000000000000",
#'       "funds": null,
#'       "stp": null,
#'       "timeInForce": "GTC",
#'       "cancelAfter": -1,
#'       "postOnly": false,
#'       "hidden": false,
#'       "iceberg": false,
#'       "visibleSize": null,
#'       "channel": "API",
#'       "clientOid": "2b700942b5db41cebe578cff48960e09",
#'       "remark": null,
#'       "tags": null,
#'       "orderTime": 1629020492834532600,
#'       "domainId": "kucoin",
#'       "tradeSource": "USER",
#'       "tradeType": "TRADE",
#'       "feeCurrency": "USDT",
#'       "takerFeeRate": "0.00200000000000000000",
#'       "makerFeeRate": "0.00200000000000000000",
#'       "createdAt": 1629020492837,
#'       "stop": "loss",
#'       "stopTriggerTime": null,
#'       "stopPrice": "1.00000000000000000000"
#'     }
#'   ]
#' }
#' ```
#'
#' @param keys List; API configuration parameters from `get_api_keys()`. Defaults to `get_api_keys()`.
#' @param base_url Character string; base URL for the KuCoin API. Defaults to `get_base_url()`.
#' @param clientOid Character string; the unique client order ID to retrieve (e.g., "2b700942b5db41cebe578cff48960e09"). Required.
#' @param symbol Character string; the trading pair symbol (e.g., "KCS-USDT"). Optional.
#' @return Promise resolving to a `data.table` with typically one row containing stop order details, with the following columns:
#'   - `id` (character): Unique order ID assigned by KuCoin.
#'   - `symbol` (character): Trading pair (e.g., "KCS-USDT").
#'   - `userId` (character): User ID associated with the order.
#'   - `status` (character): Order status (e.g., "NEW", "TRIGGERED").
#'   - `type` (character): Order type (e.g., "limit", "market").
#'   - `side` (character): Order side ("buy" or "sell").
#'   - `price` (character): Order price.
#'   - `size` (character): Order size.
#'   - `funds` (character or NA): Order funds (NULL for untriggered orders).
#'   - `stp` (character or NA): Self Trade Prevention strategy (e.g., "DC", "CO", "CN", "CB").
#'   - `timeInForce` (character): Time in force (e.g., "GTC", "GTT", "IOC", "FOK").
#'   - `cancelAfter` (integer): Seconds until cancellation for GTT (-1 if not applicable).
#'   - `postOnly` (logical): Whether the order is post-only.
#'   - `hidden` (logical): Whether the order is hidden.
#'   - `iceberg` (logical): Whether the order is an iceberg order.
#'   - `visibleSize` (character or NA): Visible size for iceberg orders.
#'   - `channel` (character): Order source (e.g., "API").
#'   - `clientOid` (character): Client-assigned order ID.
#'   - `remark` (character or NA): Order remarks.
#'   - `tags` (character or NA): Order tags.
#'   - `orderTime` (numeric): Order creation time in nanoseconds.
#'   - `domainId` (character): Domain ID (e.g., "kucoin").
#'   - `tradeSource` (character): Trade source (e.g., "USER").
#'   - `tradeType` (character): Trade type (e.g., "TRADE").
#'   - `feeCurrency` (character): Currency used for fees.
#'   - `takerFeeRate` (character): Taker fee rate.
#'   - `makerFeeRate` (character): Maker fee rate.
#'   - `createdAt` (integer): Creation timestamp in milliseconds.
#'   - `stop` (character): Stop order type (e.g., "loss", "entry").
#'   - `stopTriggerTime` (integer or NA): Trigger time in milliseconds (NULL if untriggered).
#'   - `stopPrice` (character): Stop price.
#'   - `createdAtDatetime` (POSIXct): Creation time in UTC (derived from `createdAt`).
#'   - `orderTimeDatetime` (POSIXct): Order placement time in UTC (derived from `orderTime`).
#' @examples
#' \dontrun{
#' library(coro)
#' library(data.table)
#'
#' main_async <- coro::async(function() {
#'   # Retrieve stop order details by clientOid
#'   stop_order_details <- await(get_stop_order_by_client_oid_impl(
#'     clientOid = "2b700942b5db41cebe578cff48960e09",
#'     symbol = "KCS-USDT"
#'   ))
#'   print(stop_order_details)
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
get_stop_order_by_client_oid_impl <- coro::async(function(
    keys = get_api_keys(),
    base_url = get_base_url(),
    clientOid,
    symbol = NULL
) {
    tryCatch({
        # Validate parameters
        if (is.null(clientOid) || !is.character(clientOid) || nchar(clientOid) == 0) {
            rlang::abort("Parameter 'clientOid' must be a non-empty string.")
        }
        if (!is.null(symbol) && !verify_symbol(symbol)) {
            rlang::abort("Parameter 'symbol', if provided, must be a valid trading pair (e.g., 'KCS-USDT').")
        }

        # Construct endpoint and query string
        endpoint <- "/api/v1/stop-order/queryOrderByClientOid"
        query_params <- list(clientOid = clientOid)
        if (!is.null(symbol)) {
            query_params$symbol <- symbol
        }
        query_string <- build_query(query_params)
        full_url <- paste0(base_url, endpoint, query_string)

        # Generate authentication headers
        headers <- await(build_headers("GET", paste0(endpoint, query_string), NULL, keys))

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
            stop_order_details <- data.table::data.table(
                id = character(),
                symbol = character(),
                userId = character(),
                status = character(),
                type = character(),
                side = character(),
                price = character(),
                size = character(),
                funds = character(),
                stp = character(),
                timeInForce = character(),
                cancelAfter = integer(),
                postOnly = logical(),
                hidden = logical(),
                iceberg = logical(),
                visibleSize = character(),
                channel = character(),
                clientOid = character(),
                remark = character(),
                tags = character(),
                orderTime = numeric(),
                domainId = character(),
                tradeSource = character(),
                tradeType = character(),
                feeCurrency = character(),
                takerFeeRate = character(),
                makerFeeRate = character(),
                createdAt = integer(),
                stop = character(),
                stopTriggerTime = integer(),
                stopPrice = character(),
                createdAtDatetime = as.POSIXct(character()),
                orderTimeDatetime = as.POSIXct(character())
            )
        } else {
            stop_order_details <- data.table::rbindlist(parsed_response$data, fill = TRUE)
            stop_order_details[, createdAtDatetime := time_convert_from_kucoin(createdAt, unit = "ms")]
            stop_order_details[, orderTimeDatetime := time_convert_from_kucoin(orderTime, unit = "ns")]
        }

        return(stop_order_details)
    }, error = function(e) {
        rlang::abort(sprintf("Error in get_stop_order_by_client_oid_impl: %s", conditionMessage(e)))
    })
})
