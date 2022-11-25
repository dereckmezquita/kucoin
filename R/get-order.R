# get order details -------------------------------------------------------

#' @title Get an order details
#'
#' @param order_ids A `character` vector of one or more which contain the order id(s).
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

get_kucoin_order <- function(order_ids) {
    # force order id to unique
    order_ids <- unique(order_ids)

    # get queried results
    if (length(order_ids) > 1) {
        results <- data.table::data.table()

        for (id in order_ids) {
            result <- get_an_order(orderId = id)

            results <- rbind(results, result)
        }

        # results <- results[order(results$created_at), ]
        data.table::setorder(results, created_at)
    } else {
        results <- get_an_order(orderId = order_ids)
    }

    # return the results
    return(results[])
}

get_an_order <- function(orderId) { # TODO: remove old code
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
    response <- httr::GET(
        url = get_base_url(),
        path = get_paths("orders", append = orderId),
        config = httr::add_headers(.headers = get_header)
    )

    # analyze response
    response <- analyze_response(response)

    # parse json result
    parsed <- jsonlite::fromJSON(httr::content(response, "text", encoding = "UTF-8"))

    # tidy the parsed data
    results <- data.table::data.table(parsed$data, check.names = FALSE)

    colnames(results) <- c(
        "symbol", "hidden", "op_type", "fee", "channel",
        "fee_currency", "type", "is_active", "created_at",
        "visible_size", "price", "iceberg", "stop_triggered",
        "funds", "order_id", "time_in_force", "side",
        "deal_size", "cancel_after", "deal_funds", "stp",
        "post_only", "stop_price", "size", "stop",
        "cancel_exist", "client_oid"
    )

    data.table::setcolorder(results, c(
        "order_id", "client_oid", "created_at", "is_active",
        "symbol", "side", "type", "price", "size", "funds",
        "deal_size", "deal_funds", "visible_size",
        "fee", "fee_currency", "stop", "stop_price",
        "stop_triggered", "cancel_exist", "cancel_after",
        "channel", "time_in_force", "op_type", "hidden",
        "iceberg", "stp", "post_only"
    ))

    # results[, c(8:14, 17)] <- lapply(results[, c(8:14, 17)], as.numeric)
    results[, colnames(results)[c(8:14, 17)] := lapply(.SD, as.numeric), .SDcols = c(8:14, 17)]

    # results$symbol <- prep_symbols(results$symbol, revert = TRUE)
    results[, symbol := prep_symbols(symbol, revert = TRUE)]

    # results$created_at <- lubridate::as_datetime(floor(results$created_at / 1000))
    results[, created_at := lubridate::as_datetime(floor(created_at / 1000))]

    # return the result
    return(results)
}
