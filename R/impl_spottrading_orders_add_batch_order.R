# File: ./R/impl_spottrading_orders_add_batch_order.R

box::use(
    ./helpers_api[process_kucoin_response, build_headers],
    ./utils[build_query, get_base_url, verify_symbol],
    ./utils_time_convert_kucoin[time_convert_to_kucoin],
    coro[async, await],
    data.table[as.data.table],
    httr[POST, timeout, content_type_json],
    jsonlite[toJSON],
    rlang[abort, arg_match0]
)

#' Validate a Single Order for Batch Placement
#'
#' Validates the parameters of a single order within a batch, ensuring all required fields are present
#' and optional fields meet KuCoin's specifications. Sets default values where applicable.
#'
#' @param order List; a list containing order parameters such as `symbol`, `type`, `side`, etc.
#' @return List; the validated order with defaults applied.
validate_order <- function(order) {
    if (!is.list(order)) {
        rlang::abort("Each order must be a list.")
    }

    # Check required fields
    required_fields <- c("symbol", "type", "side")
    for (field in required_fields) {
        if (is.null(order[[field]])) {
            rlang::abort(sprintf("Missing required field '%s' in order.", field))
        }
    }

    # Validate core parameters
    type <- rlang::arg_match0(order$type, c("limit", "market"), arg_name = "type")
    side <- rlang::arg_match0(order$side, c("buy", "sell"), arg_name = "side")
    if (!verify_symbol(order$symbol)) {
        rlang::abort(sprintf("Invalid symbol '%s' in order.", order$symbol))
    }

    # Initialize validated order with required fields
    validated_order <- list(
        symbol = order$symbol,
        type = type,
        side = side
    )

    # Type-specific validation
    if (type == "limit") {
        if (is.null(order$price) || !is.character(order$price)) {
            rlang::abort("Parameter 'price' is required for limit orders and must be a character string.")
        }
        if (is.null(order$size) || !is.character(order$size)) {
            rlang::abort("Parameter 'size' is required for limit orders and must be a character string.")
        }
        if (!is.null(order$funds)) {
            rlang::abort("Parameter 'funds' is not applicable for limit orders.")
        }
        validated_order$price <- order$price
        validated_order$size <- order$size
    } else if (type == "market") {
        if (!is.null(order$price)) {
            rlang::abort("Parameter 'price' is not applicable for market orders.")
        }
        if (is.null(order$size) && is.null(order$funds)) {
            rlang::abort("Either 'size' or 'funds' must be specified for market orders.")
        }
        if (!is.null(order$size) && !is.null(order$funds)) {
            rlang::abort("Parameters 'size' and 'funds' are mutually exclusive for market orders.")
        }
        if (!is.null(order$size)) {
            if (!is.character(order$size)) {
                rlang::abort("Parameter 'size' must be a character string for market orders.")
            }
            validated_order$size <- order$size
        }
        if (!is.null(order$funds)) {
            if (!is.character(order$funds)) {
                rlang::abort("Parameter 'funds' must be a character string for market orders.")
            }
            validated_order$funds <- order$funds
        }
    }

    # Validate optional parameters
    if (!is.null(order$clientOid)) {
        if (!is.character(order$clientOid) || nchar(order$clientOid) > 40 || !grepl("^[a-zA-Z0-9_-]+$", order$clientOid)) {
            rlang::abort("Parameter 'clientOid' must be a string with maximum 40 characters, containing only letters, numbers, underscores, or hyphens.")
        }
        validated_order$clientOid <- order$clientOid
    }
    if (!is.null(order$stp)) {
        validated_order$stp <- rlang::arg_match0(order$stp, c("CN", "CO", "CB", "DC"), arg_name = "stp")
    }
    if (!is.null(order$tags)) {
        if (!is.character(order$tags) || nchar(order$tags) > 20 || !grepl("^[[:ascii:]]+$", order$tags)) {
            rlang::abort("Parameter 'tags' must be ASCII and maximum 20 characters.")
        }
        validated_order$tags <- order$tags
    }
    if (!is.null(order$remark)) {
        if (!is.character(order$remark) || nchar(order$remark) > 20 || !grepl("^[[:ascii:]]+$", order$remark)) {
            rlang::abort("Parameter 'remark' must be ASCII and maximum 20 characters.")
        }
        validated_order$remark <- order$remark
    }
    if (!is.null(order$timeInForce)) {
        validated_order$timeInForce <- rlang::arg_match0(order$timeInForce, c("GTC", "GTT", "IOC", "FOK"), arg_name = "timeInForce")
    } else {
        validated_order$timeInForce <- "GTC"  # Default as per API documentation
    }
    if (!is.null(order$cancelAfter)) {
        if (!is.numeric(order$cancelAfter) || order$cancelAfter <= 0) {
            rlang::abort("Parameter 'cancelAfter' must be a positive number.")
        }
        validated_order$cancelAfter <- as.integer(order$cancelAfter)
    }
    if (!is.null(order$postOnly)) {
        if (!is.logical(order$postOnly)) {
            rlang::abort("Parameter 'postOnly' must be a logical value.")
        }
        validated_order$postOnly <- order$postOnly
    } else {
        validated_order$postOnly <- FALSE  # Default as per API documentation
    }
    if (!is.null(order$hidden)) {
        if (!is.logical(order$hidden)) {
            rlang::abort("Parameter 'hidden' must be a logical value.")
        }
        validated_order$hidden <- order$hidden
    } else {
        validated_order$hidden <- FALSE  # Default as per API documentation
    }
    if (!is.null(order$iceberg)) {
        if (!is.logical(order$iceberg)) {
            rlang::abort("Parameter 'iceberg' must be a logical value.")
        }
        validated_order$iceberg <- order$iceberg
    } else {
        validated_order$iceberg <- FALSE  # Default as per API documentation
    }
    if (!is.null(order$visibleSize)) {
        if (!is.character(order$visibleSize)) {
            rlang::abort("Parameter 'visibleSize' must be a character string.")
        }
        if (!validated_order$iceberg) {
            rlang::abort("Parameter 'visibleSize' is only applicable when 'iceberg' is TRUE.")
        }
        validated_order$visibleSize <- order$visibleSize
    }

    # Additional validation for timeInForce constraints
    if (validated_order$timeInForce == "GTT" && is.null(validated_order$cancelAfter)) {
        rlang::abort("Parameter 'cancelAfter' is required when 'timeInForce' is 'GTT'.")
    }
    if (validated_order$postOnly && validated_order$timeInForce %in% c("IOC", "FOK")) {
        rlang::abort("Parameter 'postOnly' cannot be TRUE when 'timeInForce' is 'IOC' or 'FOK'.")
    }
    if (validated_order$iceberg && validated_order$hidden) {
        rlang::abort("Parameters 'iceberg' and 'hidden' cannot both be TRUE.")
    }

    return(validated_order)
}

#' Batch Add Orders (Implementation)
#'
#' Places multiple new orders (up to 20) to the KuCoin Spot trading system asynchronously.
#' This function validates a list of orders, constructs a batch request, and returns the placement results for each order.
#'
#' ### Workflow Overview
#' 1. **Parameter Validation**: Ensures the `order_list` contains 1–20 valid orders, each validated via `validate_order()`.
#' 2. **Request Body Construction**: Builds a JSON body with the `orderList` key containing validated orders.
#' 3. **Authentication**: Generates headers with API credentials using `build_headers()`.
#' 4. **API Request**: Sends a POST request to the KuCoin API with a 3-second timeout.
#' 5. **Response Processing**: Parses the response and returns results as a `data.table`.
#'
#' ### API Endpoint
#' `POST https://api.kucoin.com/api/v1/hf/orders/multi`
#'
#' ### Usage
#' Used to place multiple spot trading orders on KuCoin in a single request. Each order can be a limit or market order,
#' with appropriate parameters. Requires sufficient funds and adheres to KuCoin's limits (e.g., max 20 orders per request,
#' 2000 active orders per account).
#'
#' ### Official Documentation
#' [KuCoin Batch Add Orders](https://www.kucoin.com/docs-new/rest/spot-trading/orders/batch-add-orders)
#'
#' @param keys List; API configuration parameters from `get_api_keys()`, including:
#'   - `api_key` (character): KuCoin API key.
#'   - `api_secret` (character): KuCoin API secret.
#'   - `api_passphrase` (character): KuCoin API passphrase.
#'   - `key_version` (character): API key version (e.g., "2"). Defaults to `get_api_keys()`.
#' @param base_url Character string; base URL for the KuCoin API. Defaults to `get_base_url()`.
#' @param order_list List; a list of orders, where each order is a list with parameters:
#'   - `symbol` (character): Trading pair (e.g., "BTC-USDT"). Required.
#'   - `type` (character): Order type: "limit" or "market". Required.
#'   - `side` (character): Order side: "buy" or "sell". Required.
#'   - `clientOid` (character): Unique client order ID (max 40 chars). Optional.
#'   - `price` (character): Price for limit orders. Required for limit.
#'   - `size` (character): Quantity for limit or market orders. Required for limit, optional for market.
#'   - `funds` (character): Funds for market orders. Optional for market, mutually exclusive with `size`.
#'   - `stp` (character): Self-trade prevention: "CN", "CO", "CB", or "DC". Optional.
#'   - `tags` (character): Order tag (max 20 ASCII chars). Optional.
#'   - `remark` (character): Order remarks (max 20 ASCII chars). Optional.
#'   - `timeInForce` (character): Time-in-force: "GTC", "GTT", "IOC", or "FOK". Optional, defaults to "GTC".
#'   - `cancelAfter` (integer): Cancel after n seconds (for GTT). Optional.
#'   - `postOnly` (logical): Passive order flag. Optional, defaults to FALSE.
#'   - `hidden` (logical): Hide order from order book. Optional, defaults to FALSE.
#'   - `iceberg` (logical): Iceberg order flag. Optional, defaults to FALSE.
#'   - `visibleSize` (character): Visible quantity for iceberg orders. Optional.
#' @return Promise resolving to a `data.table` containing results for each order, with columns:
#'   - `success` (logical): Whether the order placement was successful.
#'   - `orderId` (character): Unique order ID (if successful).
#'   - `clientOid` (character): Client-specified order ID (if provided).
#'   - `failMsg` (character): Error message (if failed).
#' @examples
#' \dontrun{
#' main_async <- coro::async(function() {
#'   # Define two orders
#'   order1 <- list(
#'     clientOid = uuid::UUIDgenerate(),
#'     symbol = "BTC-USDT",
#'     type = "limit",
#'     side = "buy",
#'     price = "30000",
#'     size = "0.00001",
#'     remark = "Batch buy"
#'   )
#'   order2 <- list(
#'     clientOid = uuid::UUIDgenerate(),
#'     symbol = "ETH-USDT",
#'     type = "market",
#'     side = "sell",
#'     size = "0.01"
#'   )
#'   # Place batch orders
#'   result <- await(add_batch_order_impl(order_list = list(order1, order2)))
#'   print(result)
#' })
#' main_async()
#' while (!later::loop_empty()) later::run_now()
#' }
#' @importFrom coro async await
#' @importFrom data.table as.data.table
#' @importFrom httr POST timeout content_type_json
#' @importFrom jsonlite toJSON
#' @importFrom rlang abort arg_match0
#' @export
add_batch_order_impl <- coro::async(function(
    keys = get_api_keys(),
    base_url = get_base_url(),
    order_list
) {
    tryCatch({
        # Validate order_list
        if (!is.list(order_list) || length(order_list) == 0 || length(order_list) > 20) {
            rlang::abort("Parameter 'order_list' must be a list containing 1 to 20 orders.")
        }

        # Validate each order in the list
        validated_orders <- lapply(order_list, validate_order)

        # Construct request body
        body_list <- list(orderList = validated_orders)
        body_json <- jsonlite::toJSON(body_list, auto_unbox = TRUE)

        # Prepare API request
        endpoint <- "/api/v1/hf/orders/multi"
        url <- paste0(base_url, endpoint)
        method <- "POST"

        # Generate authentication headers
        headers <- await(build_headers(method, endpoint, body_json, keys))

        # Send POST request
        response <- httr::POST(
            url = url,
            body = body_json,
            headers,
            httr::content_type_json(),
            httr::timeout(3)
        )

        # Process response
        parsed_response <- process_kucoin_response(response, url)
        if (parsed_response$code != "200000") {
            rlang::abort(sprintf("API error: %s - %s", parsed_response$code, parsed_response$msg))
        }

        # Convert response data to data.table
        result_dt <- data.table::as.data.table(parsed_response$data)

        return(result_dt)
    }, error = function(e) {
        rlang::abort(sprintf("Error in add_batch_order_impl: %s", conditionMessage(e)))
    })
})
