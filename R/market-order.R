# post market order -------------------------------------------------------

#' @title Post a market order
#'
#' @param symbol A `character` vector of one or more pair symbol.
#' @param side A `character` vector of one which specify the order side: `"buy"` or `"sell"`.
#' @param base_size A `numeric` vector of one determining the base size of the order.
#' @param quote_size A `numeric` vector which specify the base or quote currency size.
#' 
#' @details
#' This API is restricted for each account, the request rate limit is 45 times/3s.
#'
#' @return If the transaction success, it will return a `character` vector which showing the order id
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
#' # post a market order: buy 1 KCS
#' order_id <- post_kucoin_market_order(
#'   symbol = "KCS/BTC",
#'   side = "buy",
#'   base_size = 1
#' )
#'
#' # quick check
#' order_id
#'
#' # post a market order: sell 1 KCS
#' order_id <- post_kucoin_market_order(
#'   symbol = "KCS/BTC",
#'   side = "sell",
#'   base_size = 1
#' )
#'
#' # quick check
#' order_id
#'
#' # post a market order: buy KCS worth 0.0001 BTC
#' order_id <- post_kucoin_market_order(
#'   symbol = "KCS/BTC",
#'   side = "buy",
#'   quote_size = 0.0001
#' )
#'
#' # quick check
#' order_id
#'
#' # post a market order: sell KCS worth 0.0001 BTC
#' order_id <- post_kucoin_market_order(
#'   symbol = "KCS/BTC",
#'   side = "sell",
#'   base_size = 0.0001
#' )
#'
#' # quick check
#' order_id
#'
#' }
#'
#' @export

post_kucoin_market_order <- function(symbol, side, base_size = NULL, quote_size = NULL) {
    if (!is.null(base_size) & !is.null(quote_size)) {
        rlang::abort('Choose either "base_size" or "quote_size" arguments!')
    } else if (is.null(base_size) & is.null(quote_size)) {
        rlang::abort('There is no specified size argument!')
    }

    # post market order
    if (!is.null(base_size)) {
        results <- post_market_order(
            symbol = prep_symbols(symbol),
            side = side,
            size = format(base_size, scientific = FALSE)
        )
    } else {
        results <- post_market_order(
            symbol = prep_symbols(symbol),
            side = side,
            funds = format(quote_size, scientific = FALSE)
        )
    }

    # return the result
    return(results)
}

post_market_order <- function(symbol, side, size = NULL, funds = NULL) {
    # get current timestamp
    current_timestamp <- as.character(get_kucoin_time(raw = TRUE))

    # get client id; create unique identifier for our order
    # TODO: make unique ids more unique: paste0("O", current_timestamp, sample(100000000:999999999, 1))
    clientOid <- jsonlite::base64_enc(as.character(current_timestamp))

    # prepare post body
    # TODO: look into setting the "tradeType"; if not set funds are frozen by default
    # https://docs.kucoin.com/#place-a-new-order
    # TODO: look at setting "TIME IN FORCE"
    post_body <- list(
        clientOid = clientOid,
        symbol = symbol,
        side = side,
        type = "market",
        size = size,
        funds = funds
    )

    post_body <- post_body[!sapply(post_body, is.null)]

    post_body_json <- jsonlite::toJSON(post_body, auto_unbox = TRUE)

    # prepare post headers
    sig <- paste0(current_timestamp, "POST", get_paths("orders", type = "endpoint"), post_body_json)
    sig <- digest::hmac(object = sig, algo = "sha256", key = Sys.getenv("KC-API-SECRET"), raw = TRUE)
    sig <- jsonlite::base64_enc(input = sig)

    post_header <- c(
        "KC-API-KEY" = Sys.getenv("KC-API-KEY"),
        "KC-API-SIGN" = sig,
        "KC-API-TIMESTAMP" = current_timestamp,
        "KC-API-PASSPHRASE" = Sys.getenv("KC-API-PASSPHRASE")
    )

    # post to server
    response <- httr::POST(
        url = get_base_url(),
        path = get_paths("orders"),
        body = post_body,
        encode = "json",
        config = httr::add_headers(.headers = post_header)
    )

    # analyze response
    response <- analyze_response(response)

    # parse json result
    parsed <- jsonlite::fromJSON(httr::content(response, "text", encoding = "UTF-8"))

    if (parsed$code != "200000") {
        rlang::abort(stringr::str_interp('Got error/warning with message: ${parsed$msg}'))
    }

    # tidy the parsed data
    results <- data.table::data.table(parsed$data, check.names = FALSE)
    results <- results$orderId

    # return the result
    return(results[])
}

