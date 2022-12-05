# post market order -------------------------------------------------------

#' @title Post a market order
#'
#' @param symbol A `character` vector of one or more pair symbol (required - default `NULL`).
#' @param side A `character` vector of one which specify the order side: `"buy"` or `"sell"` (required - default `NULL`).
#' @param base_size A `numeric` vector of one determining the base size of the order; n units of the first currency in the pair (required or `quote_size` - default `NULL`).
#' @param quote_size A `numeric` vector which specify the base or quote currency size; n units of the second currency in the pair (required or `base_size` - default `NULL`).
#' 
#' @details
#' For more information see the [KuCoin API documentation - new order](https://docs.kucoin.com/#place-a-new-order).
#' 
#' This API is restricted for each account, the request rate limit is 45 times/3s.
#' 
#' Currencies are traded in pairs. The first currency is called the base currency and the second currency is called the quote currency. So for example, BTC/USDT, means that the base currency is the BTC and the quote currency is the USDT.
#' 
#' This function returns the order ID set by KuCoin typically looks like this: "63810a330091a60001ceeb04". This can be used to get the status of the order. See the function [kucoin::get_orders_by_id()].
#'
#' @return If success returns `character` vector of one; order id designated by KuCoin.
#'
#' @examples
#'
#' \dontrun{
#'
#' # to run this example, make sure
#' # you already setup the API key
#' # in a proper .Renviron file
#'
#' # check our balances
#' kucoin::get_account_balances()
#' 
#' # post a market order: buy 1 ETH
#' order_id <- kucoin::submit_market_order(
#'     symbol = "ETH/BTC",
#'     side = "buy",
#'     base_size = 1
#' ); order_id
#' 
#' # post a market order: sell 1 ETH
#' order_id <- kucoin::submit_market_order(
#'     symbol = "ETH/BTC",
#'     side = "sell",
#'     base_size = 1
#' ); order_id
#' 
#' # post a market order: buy ETH worth 0.0001 BTC
#' order_id <- kucoin::submit_market_order(
#'     symbol = "ETH/BTC",
#'     side = "buy",
#'     quote_size = 0.0001
#' ); order_id
#' 
#' # post a market order: sell ETH worth 0.0001 BTC
#' order_id <- kucoin::submit_market_order(
#'     symbol = "ETH/BTC",
#'     side = "sell",
#'     quote_size = 0.0001
#' ); order_id
#'
#' }
#'
#' @export

submit_market_order <- function(symbol = NULL, side = NULL, base_size = NULL, quote_size = NULL) {
    if (is.null(symbol)) {
        rlang::abort('Argument "symbol" must be provided.')
    }

    if (is.null(side)) {
        rlang::abort('Argument "side" must be provided.')
    }

    # either base_size or quote_size must be provided but not both
    if (!is.null(base_size) & !is.null(quote_size)) {
        rlang::abort('Either "base_size" or "quote_size" must be provided.')
    } else if (is.null(base_size) & is.null(quote_size)) {
        rlang::abort('There is no specified size argument!')
    }

    # post market order
    if (!is.null(base_size)) {
        results <- .submit_market_order(
            symbol = prep_symbols(symbol),
            side = side,
            size = format(base_size, scientific = FALSE)
        )
    } else {
        results <- .submit_market_order(
            symbol = prep_symbols(symbol),
            side = side,
            funds = format(quote_size, scientific = FALSE)
        )
    }

    # return the result
    return(results)
}

.submit_market_order <- function(symbol = NULL, side = NULL, size = NULL, funds = NULL) {
    if (is.null(symbol)) {
        rlang::abort('Argument "symbol" must be provided.')
    }

    if (is.null(side)) {
        rlang::abort('Argument "side" must be provided.')
    }

    # either size or funds must be provided but not both
    if (!is.null(size) & !is.null(funds)) {
        rlang::abort('Either "size" or "funds" must be provided.')
    } else if (is.null(size) & is.null(funds)) {
        rlang::abort('There is no specified size argument!')
    }

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

    return(parsed$data$orderId)
}

