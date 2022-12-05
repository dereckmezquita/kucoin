
#' @title Post a limit order
#'
#' @param symbol A `character` vector of one or more pair symbol (required - default `NULL`).
#' @param side A `character` vector of one which specify the order side: `"buy"` or `"sell"` (required - default `NULL`).
#' @param base_size A `numeric` vector of one determining the base size of the order; n units of the first currency in the pair (required if `quote_size` NULL - default `NULL`).
#' @param quote_size A `numeric` vector which specify the base or quote currency size; n units of the second currency in the pair (required if `base_size` NULL - default `NULL`).
#' @param price A `numeric` vector of one which specify the price of the order (required - default `NULL`).
#' @param timeInForce A `character` vector of one specifying the time in force policy: `"GTC"` (Good Till Canceled), `"GTT"` (Good Till Time), `"IOC"` (Immediate Or Cancel), or `"FOK"` (Fill Or Kill) (optional - default `"GTC"`).
#' @param cancelAfter A `numeric` vector of one specifying the number of seconds to wait before cancelling the order (optional - default `NULL`).
#' @param postOnly A `logical` vector of one specifying whether the order is post only; invalid when `timeInForce` is `"IOC"` or `"FOK"` (optional - default `NULL`).
#' @param hidden A `logical` vector of one specifying whether the order is hidden (optional - default `NULL`).
#' @param iceberg A `logical` vector of one specifying whether the order is iceberg (optional - default `NULL`).
#' @param visibleSize A `numeric` vector of one specifying the visible size of the iceberg order (optional - default `0`).
#' 
#' @details
#' 
#' This API is restricted for each account, the request rate limit is 45 times/3s.
#' 
#' Currencies are traded in pairs. The first currency is called the base currency and the second currency is called the quote currency. So for example, BTC/USDT, means that the base currency is the BTC and the quote currency is the USDT.
#' 
#' This function returns the order ID set by KuCoin typically looks like this: "63810a330091a60001ceeb04". This can be used to get the status of the order. See the function [kucoin::get_orders_by_id()].
#' 
#' # ---------------
#' Time in force policies provide guarantees about the lifetime of an order. There are four policies: Good Till Canceled GTC, Good Till Time GTT, Immediate Or Cancel IOC, and Fill Or Kill FOK.
#'
#' 1. GTC Good Till Canceled orders remain open on the book until canceled. This is the default behavior if no policy is specified.
#' 1. GTT Good Till Time orders remain open on the book until canceled or the allotted cancelAfter is depleted on the matching engine. GTT orders are guaranteed to cancel before any other order is processed after the cancelAfter seconds placed in order book.
#' 1. IOC Immediate Or Cancel orders instantly cancel the remaining size of the limit order instead of opening it on the book.
#' 1. FOK Fill Or Kill orders are rejected if the entire size cannot be matched.
#'
#' Note that self trades belong to match as well. For market orders, using the “TimeInForce” parameter has no effect.
#'
#' The post-only flag ensures that the trader always pays the maker fee and provides liquidity to the order book. If any part of the order is going to pay taker fee, the order will be fully rejected.
#'
#' If a post only order will get executed immediately against the existing orders (except iceberg and hidden orders) in the market, the order will be cancelled.
#'
#' For post only orders, it will get executed immediately against the iceberg orders and hidden orders in the market. Users placing the post only order will be charged the maker fees and the iceberg and hidden orders will be charged the taker fees.
#' 
#' # ---------------
#' For more information see the [KuCoin API documentation - new order](https://docs.kucoin.com/#place-a-new-order).
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
#' # import library
#' library("kucoin")
#'
#' # post a market order: buy 1 KCS
#' order_id <- submit_limit_order(
#'     symbol = "KCS/BTC",
#'     side = "buy",
#'     base_size = 1
#' )
#'
#' # quick check
#' order_id
#'
#' # post a market order: sell 1 KCS
#' order_id <- submit_limit_order(
#'     symbol = "KCS/BTC",
#'     side = "sell",
#'     base_size = 1
#' )
#'
#' # quick check
#' order_id
#'
#' # post a market order: buy KCS worth 0.0001 BTC
#' order_id <- submit_limit_order(
#'     symbol = "KCS/BTC",
#'     side = "buy",
#'     quote_size = 0.0001
#' )
#'
#' # quick check
#' order_id
#'
#' # post a market order: sell KCS worth 0.0001 BTC
#' order_id <- submit_limit_order(
#'     symbol = "KCS/BTC",
#'     side = "sell",
#'     quote_size = 0.0001
#' )
#'
#' # quick check
#' order_id
#'
#' }
#' 
#' @export
submit_limit_order <- function(
    symbol = NULL, # accepts format "KCS/BTC"
    side = NULL, # buy or sell
    base_size = NULL, # base size
    quote_size = NULL, # quote size
    price = NULL, # price per base currency
    timeInForce = "GTC", # default is GTC
    cancelAfter = NULL, # in seconds; requires timeInForce to be GTT
    postOnly = NULL, # invalid when timeInForce is IOC or FOK
    hidden = NULL, # order not displayed in order book
    iceberg = NULL, # only part of order displayed in order book
    visibleSize = NULL # max visible size of iceberg order
) {
    if (is.null(symbol)) {
        rlang::abort('Argument "symbol" must be provided.')
    }

    if (!side %in% c("buy", "sell")) {
        rlang::abort(stringr::str_interp('Argument "side" must be either "buy" or "sell"; received ${side}.'))
    }

    if (!is.null(base_size) & !is.null(quote_size)) {
        rlang::abort('Choose either "base_size" or "quote_size" arguments.')
    } else if (is.null(base_size) & is.null(quote_size)) {
        rlang::abort('There is no specified size argument.')
    }

    if (is.null(price)) {
        rlang::abort('There is no specified price argument.')
    }

    if (!timeInForce %in% c("GTC", "GTT", "IOC", "FOK")) {
        rlang::abort(stringr::str_interp('Argument "timeInForce" must be either "GTC", "GTT", "IOC", or "FOK"; received ${timeInForce}.'))
    }

    # cancelAfter requires timeInForce to be set to GTT
    if (!is.null(cancelAfter) && timeInForce != "GTT") {
        rlang::abort('Argument "cancelAfter" requires "timeInForce" to be set to "GTT".')
    }

    # postOnly is invalid when timeInForce is IOC or FOK
    if (!is.null(postOnly) & timeInForce %in% c("IOC", "FOK")) {
        rlang::abort('Argument "postOnly" is invalid when "timeInForce" is "IOC" or "FOK".')
    }
    

    # post limit order
    if (!is.null(base_size)) {
        results <- .submit_limit_order(
            symbol = prep_symbols(symbol),
            side = side,
            size = format(base_size, scientific = FALSE),
            price = format(price, scientific = FALSE),
            timeInForce = timeInForce,
            cancelAfter = cancelAfter,
            postOnly = postOnly,
            hidden = hidden,
            iceberg = iceberg,
            visibleSize = visibleSize
        )
    } else {
        results <- .submit_limit_order(
            symbol = prep_symbols(symbol),
            side = side,
            funds = format(quote_size, scientific = FALSE),
            price = format(price, scientific = FALSE),
            timeInForce = timeInForce,
            cancelAfter = cancelAfter,
            postOnly = postOnly,
            hidden = hidden,
            iceberg = iceberg,
            visibleSize = visibleSize
        )
    }

    # return result
    return(results)
}

# https://docs.kucoin.com/#place-a-new-order
.submit_limit_order <- function(
    symbol, # requires prep_symbols() format; "BTC-USDT"
    side, # buy or sell
    size = NULL, # amount of base currency to buy or sell
    funds = NULL, # amount of quote currency to spend
    price = NULL, # price per base currency
    timeInForce = "GTC", # default is GTC
    cancelAfter = NULL, # in seconds; requires timeInForce to be GTT
    postOnly = NULL, # invalid when timeInForce is IOC or FOK
    hidden = NULL, # order not displayed in order book
    iceberg = NULL, # only part of order displayed in order book
    visibleSize = NULL # max visible size of iceberg order
) {
    if (!is.null(cancelAfter) && timeInForce != "GTT") {
        rlang::abort(stringr::str_interp('Argument "cancelAfter" requires "timeInForce" to be GTT; received ${timeInForce}!'))
    }

    if (!is.null(postOnly) && timeInForce %in% c("IOC", "FOK")) {
        rlang::abort(stringr::str_interp('Argument "postOnly" is invalid when "timeInForce" is ${timeInForce}!'))
    }

    # get current timestamp
    current_timestamp <- as.character(get_kucoin_time(raw = TRUE))

    # create unique identifier for our order
    clientOid <- jsonlite::base64_enc(as.character(current_timestamp))

    # prepare post body
    post_body <- list(
        clientOid = clientOid,
        symbol = symbol,
        side = side,
        type = "limit",
        timeInForce = timeInForce,
        cancelAfter = cancelAfter,
        postOnly = postOnly,
        hidden = hidden,
        iceberg = iceberg,
        visibleSize = visibleSize,
        price = price,
        size = size,
        funds = funds
    )

    # remove NULL values
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

    # analyse response
    response <- analyze_response(response)

    # parse json result
    parsed <- jsonlite::fromJSON(httr::content(response, "text", encoding = "UTF-8"))

    if (parsed$code != "200000") {
        rlang::abort(stringr::str_interp('Got error/warning with message: ${parsed$msg}'))
    }

    return(parsed$data$orderId)
}
