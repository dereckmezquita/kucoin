
#' @title Cancel all order(s) for a symbol
#'
#' @param symbol A `character` vector of one or more symbols; format "KCS/BTC".
#' @param tradeType A `character` vector of one either "TRADE" or "MARGIN_ISOLATED_TRADE".
#' @param delay A `numeric` value to delay data request in milliseconds.
#' @param retries A `numeric` value to specify the number of retries in case of failure.
#'
#' @return If success returns `character` vector of n order id(s); designated by KuCoin.
#' 
#' @details
#' 
#' This API is restricted for each account, the request rate limit is 3 times/3s.
#' 
#' For more information see documentation: [KuCoin - cancel-all-orders](https://docs.kucoin.com/#cancel-all-orders)
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
#' symbol <- "ETH/USDT"
#' 
#' # check balances
#' balances <- kucoin::get_kucoin_balances(); balances
#' 
#' order_id <- kucoin::post_kucoin_limit_order(
#'     symbol = symbol,
#'     side = "sell",
#'     base_size = 1,
#'     price = 1000000
#' ); order_id
#' 
#' order_id2 <- kucoin::post_kucoin_limit_order(
#'     symbol = symbol,
#'     side = "sell",
#'     base_size = 1,
#'     price = 1000000
#' ); order_id
#' 
#' # see funds on hold
#' balances2 <- kucoin::get_kucoin_balances(); balances2
#' 
#' # cancel all orders for symbol
#' cancelled <- kucoin::cancel_kucoin_all_pairs_order(symbol); cancelled
#' 
#' # see funds released
#' balances3 <- kucoin::get_kucoin_balances(); balances3
#'
#' }
#'
#' @export

cancel_kucoin_all_pairs_order <- function(symbols, tradeType = "TRADE", delay = 0, retries = 3) {
    order_symbols <- unique(symbols)

    # cancel_all_pair_order returns a vector of length n
    # we want the final result to return a single vector
    results <- vector(mode = "character", length = 0)

    # TODO: consider using a tryCatch and return list(success, failure); or by symbol list(symbolA = list(success, failure))
    for (symbol in order_symbols) {
        results <- c(results, cancel_all_pair_order(symbol = symbol, tradeType = tradeType, retries = retries))

        Sys.sleep(delay)
    }

    return(results)
}

cancel_all_pair_order <- function(symbol, tradeType = "TRADE", retries = 3) {
    current_timestamp <- as.character(get_kucoin_time(raw = TRUE))

    if (!tradeType %in% c("TRADE", "MARGIN_ISOLATED_TRADE")) {
        rlang::abort(stringr::str_interp('Argument "tradeType" must be one of "TRADE" or "MARGIN_ISOLATED_TRADE"; received ${tradeType}.'))
    }

    # example
    # DELETE /api/v1/orders?symbol=ETH-BTC&tradeType=TRADE
    # DELETE /api/v1/orders?symbol=ETH-BTC&tradeType=MARGIN_ISOLATED_TRADE

    # prepare query params
    query_params <- list(
        symbol = prep_symbols(symbol),
        tradeType = tradeType
    )

    query_params <- query_params[!sapply(query_params, is.null)]

    # prepare query strings
    query_strings <- prep_query_strings(query_params)

    # prepare get request
    sig <- paste0(current_timestamp, "DELETE", get_paths("orders", type = "endpoint"), query_strings)
    sig <- digest::hmac(object = sig, algo = "sha256", key = Sys.getenv("KC-API-SECRET"), raw = TRUE)
    sig <- jsonlite::base64_enc(input = sig)

    get_header <- c(
        "KC-API-KEY" = Sys.getenv("KC-API-KEY"),
        "KC-API-SIGN" = sig,
        "KC-API-TIMESTAMP" = current_timestamp,
        "KC-API-PASSPHRASE" = Sys.getenv("KC-API-PASSPHRASE")
    )

    # get server response
    response <- httr::RETRY(
        verb = "DELETE",
        url = get_base_url(),
        path = get_paths("orders"),
        query = query_params,
        config = httr::add_headers(.headers = get_header),
        times = retries
    )

    # analyze response
    response <- analyze_response(response)

    # parse json result
    parsed <- jsonlite::fromJSON(httr::content(response, "text", encoding = "UTF-8"))

    return(parsed$data$cancelledOrderIds)
}

