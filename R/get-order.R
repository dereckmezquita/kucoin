# get order details -------------------------------------------------------

#' @title Get an order details
#'
#' @param order_ids A `character` vector of one or more which contain the order id(s) designated by KuCoin.
#' @param delay A `numeric` value to delay data request in milliseconds.
#' @param retries A `numeric` value to specify the number of retries in case of failure.
#'
#' @return A `data.table` containing order details
#'
#' @examples
#'
#' \dontrun{
#'
#' # to run this example, make sure
#' # you already setup the API key
#' # in a proper .Renviron file
#'
#' # import library
#' library("kucoin")
#'
#' # get order details
#' order_details <- get_kucoin_order(
#'   order_ids = "insertorderid"
#' )
#'
#' # quick check
#' order_details
#'
#' }
#'
#' @export

get_kucoin_order <- function(order_ids, delay = 0, retries = 3) {
    # force order id to unique
    order_ids <- unique(order_ids)

    # get queried results
    if (length(order_ids) > 1) {
        results <- data.table::data.table()

        for (id in order_ids) {
            result <- get_an_order(orderId = id, retries = retries)

            results <- rbind(results, result)

            Sys.sleep(delay)
        }

        # results <- results[order(results$created_at), ]
        data.table::setorder(results, created_at)
    } else {
        results <- get_an_order(orderId = order_ids)
    }

    # return the results
    return(results[])
}

get_an_order <- function(orderId, retries = 3) {
    # get current timestamp
    current_timestamp <- as.character(get_kucoin_time(raw = TRUE))

    # prepare get headers
    sig <- paste0(current_timestamp, "GET", get_paths("orders", type = "endpoint", append = orderId))
    sig <- digest::hmac(object = sig, algo = "sha256", key = Sys.getenv("KC-API-SECRET"), raw = TRUE)
    sig <- jsonlite::base64_enc(input = sig)

    get_header <- c(
        "KC-API-KEY" = Sys.getenv("KC-API-KEY"),
        "KC-API-SIGN" = sig,
        "KC-API-TIMESTAMP" = current_timestamp,
        "KC-API-PASSPHRASE" = Sys.getenv("KC-API-PASSPHRASE")
    )

    # get from server
    response <- httr::RETRY(
        verb = "GET",
        url = get_base_url(),
        path = get_paths("orders", append = orderId),
        config = httr::add_headers(.headers = get_header),
        times = retries
    )

    # analyze response
    response <- analyze_response(response)

    # parse json result
    parsed <- jsonlite::fromJSON(httr::content(response, "text", encoding = "UTF-8"))

    # tidy the parsed data
    results <- data.table::as.data.table(parsed$data, check.names = FALSE)

    # 2022-11-25 columns returned by the API:
    # c("id", "symbol", "opType", "type", "side", "price", "size", "funds", "dealFunds", "dealSize", "fee", "feeCurrency", "stp", "stop", "stopTriggered", "stopPrice", "timeInForce", "postOnly", "hidden", "iceberg", "visibleSize", "cancelAfter", "channel", "clientOid", "isActive", "cancelExist", "createdAt", "tradeType")

    colnames(results) <- to_snake_case(colnames(results))

    ## ----------------------------------------
    # cast columns types
    ## ----------------------------------------

    # cast numeric columns
    numeric_cols <- c(
        "price", "size", "funds", "deal_funds",
        "deal_size", "fee", "stop_price",
        "visible_size", "cancel_after"
    )

    numeric_missing_cols <- setdiff(numeric_cols, colnames(results))

    if (length(numeric_missing_cols) > 0) {
        rlang::warn(stringr::str_interp('The following columns are not in the data: ${numeric_missing_cols}'))

        # keep only columns in the data
        numeric_cols <- setdiff(numeric_cols, numeric_missing_cols)
    }

    logical_cols <- c(
        "stop_triggered", "post_only", "hidden",
        "iceberg", "is_active", "cancel_exist"
    )

    logical_missing_cols <- setdiff(logical_cols, colnames(results))

    if (length(logical_missing_cols) > 0) {
        rlang::warn(stringr::str_interp('The following columns are not in the data: ${logical_missing_cols}'))

        # keep only columns in the data
        logical_cols <- setdiff(logical_cols, logical_missing_cols)
    }

    results[, (numeric_cols) := lapply(.SD, as.numeric), .SDcols = numeric_cols]

    results[, (logical_cols) := lapply(.SD, as.logical), .SDcols = logical_cols]

    results[, symbol := prep_symbols(symbol, revert = TRUE)]

    results[, created_at := kucoin_time_to_datetime(created_at)]

    # return the result
    return(results)
}
