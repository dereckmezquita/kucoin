
#' @title Cancel order(s)
#'
#' @param order_ids A `character` vector of one or more which contain the order id(s) designated by KuCoin.
#' @param delay A `numeric` value to delay data request in milliseconds.
#' @param retries A `numeric` value to specify the number of retries in case of failure.
#'
#' @return If success returns `character` vector of n order id(s); designated by KuCoin.
#' 
#' @details
#' 
#' This API is restricted for each account, the request rate limit is 60 times/3s.
#' 
#' For more information see documentation: [KuCoin - cancel-order](https://docs.kucoin.com/#cancel-an-order)
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
#' # set a limit order
#' order_id <- kucoin::post_kucoin_limit_order(
#'    symbol = "ETH/USDT",
#'    side = "sell",
#'    base_size = 1,
#'    price = 100000
#' )
#'
#' # get order details
#' cancelled <- kucoin::cancel_kucoin_order(order_id)
#'
#' }
#'
#' @export

cancel_kucoin_order <- function(orderId, delay = 0, retries = 3) {
    # force order id to unique
    order_ids <- unique(orderId)

    results <- vector(mode = "character", length = length(order_ids))

    # TODO: consider using a tryCatch and return list(success, failure)
    for (i in seq_along(order_ids)) {
        results[i] <- cancel_an_order(orderId = order_ids[i], retries = retries)

        Sys.sleep(delay)
    }

    return(results)
}

# This endpoint requires the Trade permission.

# This API is restricted for each account, the request rate limit is 60 times/3s.

# This interface is only for cancellation requests. The cancellation result needs to be obtained by querying the order status or subscribing to websocket. It is recommended that you DO NOT cancel the order until receiving the Open message, otherwise the order cannot be cancelled successfully.
cancel_an_order <- function(orderId, retries = 3) {
    # get current timestamp
    current_timestamp <- as.character(get_kucoin_time(raw = TRUE))

    # prepare get headers
    sig <- paste0(current_timestamp, "DELETE", get_paths("orders", type = "endpoint", append = orderId))
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
        verb = "DELETE",
        url = get_base_url(),
        path = get_paths("orders", append = orderId),
        httr::add_headers(.headers = get_header),
        times = retries
    )

    # analyse response
    response <- analyze_response(response)

    # parse json result
    parsed <- jsonlite::fromJSON(httr::content(response, as = "text", encoding = "UTF-8"))

    return(parsed$data$cancelledOrderIds)
}