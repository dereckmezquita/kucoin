
post_kucoin_limit_order <- function(
    symbol, # accepts format "KCS/BTC"
    side, # buy or sell
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
    if (!side %in% c("buy", "sell")) {
        rlang::abort(stringr::str_interp('Argument "side" must be either "buy" or "sell"; received ${side}!'))
    }

    if (!is.null(base_size) & !is.null(quote_size)) {
        rlang::abort('Choose either "base_size" or "quote_size" arguments!')
    } else if (is.null(base_size) & is.null(quote_size)) {
        rlang::abort('There is no specified size argument!')
    }

    if (is.null(price)) {
        rlang::abort('There is no specified price argument!')
    }

    # post limit order
    if (!is.null(base_size)) {
        results <- post_limit_order(
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
        results <- post_limit_order(
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
post_limit_order <- function(
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
    # get current timestamp
    current_timestamp <- as.character(get_kucoin_time(raw = TRUE))

    # create unique identifier for our order
    clientOid <- jsonlite::base64_enc(as.character(current_timestamp))

    if (!is.null(cancelAfter) && timeInForce != "GTT") {
        rlang::abort(stringr::str_interp('Argument "cancelAfter" requires "timeInForce" to be GTT; received ${timeInForce}!'))
    }

    if (!is.null(postOnly) && timeInForce %in% c("IOC", "FOK")) {
        rlang::abort(stringr::str_interp('Argument "postOnly" is invalid when "timeInForce" is ${timeInForce}!'))
    }

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
        price = format(price, scientific = FALSE),
        size = format(size, scientific = FALSE),
        funds = format(funds, scientific = FALSE)
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

    results <- data.table::data.table(parsed$data, check.names = FALSE)
    results[, orderId := results$orderId]

    # return results
    return(results[])
}
