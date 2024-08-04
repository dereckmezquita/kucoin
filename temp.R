#' @title Cancel all order(s) for a symbol
#' 
#' @description
#' 
#' TODO: in development.
#'
#' @param symbols A `character` vector of one or more symbols; format "BTC/USDT" (optional - default `NULL`).
#' @param tradeType A `character` vector of one either "TRADE" or "MARGIN_ISOLATED_TRADE" (optional - default `NULL`).
#' @param delay A `numeric` value to delay data request in milliseconds (optional - default `0`).
#' @param retries A `numeric` value to specify the number of retries in case of failure (optional - default `3`).
#'
#' @return Success returns `character` vector of n order id(s) (designated by KuCoin).
#' 
#' @details
#' 
#' This endpoint requires the Trade permission.
#' 
#' This API is restricted for each account, the request rate limit is 3 times/3s.
#' 
#' # ---------------
#' For more information see documentation: [KuCoin - cancel-all-orders](https://docs.kucoin.com/#cancel-all-orders)
#'
#' TODO: if no symbols provided cancel all
#' 
#' @examples
#'
#' \dontrun{
#'
#' # to run this example, make sure
#' # you already setup the API key
#' # in a proper .Renviron file
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
#' cancelled <- kucoin::cancel_all_orders(symbol); cancelled
#' 
#' # cancel all orders for all symbols and trade types
#' cancelled <- kucoin::cancel_all_orders(); cancelled
#' 
#' # see funds released
#' balances3 <- kucoin::get_kucoin_balances(); balances3
#'
#' }
#'
#' @export

cancel_all_orders <- function(symbols = NULL, tradeType = NULL, delay = 0, retries = 3) {

    order_symbols <- unique(symbols)

    # cancel_all_pair_order returns a vector of length n
    # we want the final result to return a single vector
    results <- vector(mode = "character", length = 0)

    # TODO: consider using a tryCatch and return list(success, failure); or by symbol list(symbolA = list(success, failure))
    for (symbol in order_symbols) {
        results <- c(results, .cancel_all_orders(symbol = symbol, tradeType = tradeType, retries = retries))

        Sys.sleep(delay)
    }

    return(results)
}

# https://docs.kucoin.com/#cancel-all-orders
.cancel_all_orders <- function(symbol = NULL, tradeType = NULL, retries = 3) {
    # arguments not required - only if tradeType is not TRADE/MARGIN_ISOLATED_TRADE throw error
    if (!is.null(tradeType) && !tradeType %in% c("TRADE", "MARGIN_ISOLATED_TRADE")) {
        rlang::abort(stringr::str_interp('Argument "tradeType" must be one of "TRADE" or "MARGIN_ISOLATED_TRADE"; received ${tradeType}.'))
    }

    current_timestamp <- as.character(get_kucoin_time(raw = TRUE))

    # example
    # DELETE /api/v1/orders?symbol=ETH-BTC&tradeType=TRADE
    # DELETE /api/v1/orders?symbol=ETH-BTC&tradeType=MARGIN_ISOLATED_TRADE

    # prepare query params
    query_params <- list(
        symbol = (\() {
            if (!is.null(symbol)) prep_symbols(symbol)
            return(NULL)
        })(),
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

    results <- parsed$data$cancelledOrderIds

    if (length(results) == 0) {
        message(stringr::str_interp('No orders cancelled for symbol: ${symbol} and tradeType: ${tradeType}.'))
    }

    return(results)
}

#' @title Cancel order(s)
#'
#' @param orderIds A `character` vector of one or more which contains the order id(s) designated by KuCoin (required - default `NULL`).
#' @param delay A `numeric` value to delay data request in milliseconds (optional - default `0`).
#' @param retries A `numeric` value to specify the number of retries in case of failure (optional - default `3`).
#'
#' @return If success returns `character` vector of n order id(s); designated by KuCoin.
#' 
#' @details
#' 
#' This endpoint requires the Trade permission.
#' 
#' This API is restricted for each account, the request rate limit is 60 times/3s.
#' 
#' This interface is only for cancellation requests. The cancellation result needs to be obtained by querying the order status, you can use [kucoin::get_orders_by_id()]. 
#' 
#' It is recommended that you DO NOT cancel the order until receiving the Open message, otherwise the order cannot be cancelled successfully.
#' 
#' # ---------------
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
#' # set a limit order
#' order_id1 <- kucoin::post_kucoin_limit_order(
#'    symbol = "ETH/USDT",
#'    side = "sell",
#'    base_size = 1,
#'    price = 100000
#' )
#' 
#' order_id2 <- kucoin::post_kucoin_limit_order(
#'    symbol = "ETH/USDT",
#'    side = "sell",
#'    base_size = 1,
#'    price = 100000
#' )
#'
#' # get order details
#' cancelled <- kucoin::cancel_order(c(order_id1, order_id2))
#'
#' }
#'
#' @export

cancel_order <- function(orderIds = NULL, delay = 0, retries = 3) {
    if (is.null(orderIds)) {
        rlang::abort('Argument "orderIds" must be provided.')
    }

    # force order id to unique
    order_ids <- unique(orderIds)

    results <- vector(mode = "character", length = length(order_ids))

    # TODO: consider using a tryCatch and return list(success, failure)
    for (i in seq_along(order_ids)) {
        results[i] <- .cancel_order(orderId = order_ids[i], retries = retries)

        Sys.sleep(delay)
    }

    return(results)
}

# https://docs.kucoin.com/#cancel-an-order
.cancel_order <- function(orderId = NULL, retries = 3) {
    if (is.null(orderId)) {
        rlang::abort('Argument "orderId" must be provided.')
    }

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

    results <- parsed$data$cancelledOrderIds

    if (length(results) == 0) {
        message(stringr::str_interp('No order cancelled for order id: ${orderId}'))
    }

    return(results)
}#' @title Get all market symbols' metadata --deprecated--
#' 
#' @param retries A `numeric` value to specify the number of retries in case of failure (optional - default `3`).
#'
#' @return A `data.table` with metadata
#' 
#' @details
#' 
#' TODO: this function needs to be updated to v2 of the API.
#' 
#' # ---------------
#' For more information see documentation: [KuCoin - get-symbols-list-deprecated](https://docs.kucoin.com/#get-symbols-list-deprecated)
#'
#' @examples
#' # import library
#' library("kucoin")
#'
#' # get all symbols' most recent metadata
#' metadata <- kucoin::get_market_metadata()
#'
#' # quick check
#' metadata
#'
#' @export

get_market_metadata.deprecated <- function(retries = 3) {
    # get server response
    response <- httr::RETRY(
        verb = "GET",
        url = get_base_url(),
        path = get_paths("symbols-deprecated"),
        times = retries
    )

    # analyze response
    response <- analyze_response(response)

    # parse json result
    parsed <- jsonlite::fromJSON(httr::content(response, "text", encoding = "UTF-8"))

    # tidy the parsed data
    results <- data.table::data.table(parsed$data, check.names = FALSE)

    # seems that the only thing that changes in colnames is they are made to snake_case
    # https://github.com/dereckmezquita/kucoin/issues/1
    # Error in setnames(x, value) : 
    # Can't assign 14 names to a 17 column data.table
    # colnames(results) <- c(
    #     "symbol", "quote_max_size", "enable_trading", "price_increment",
    #     "fee_currency", "base_max_size", "base_currency", "quote_currency",
    #     "market", "quote_increment", "base_min_size", "quote_min_size",
    #     "name", "base_increment"
    # )
    
    colnames(results) <- to_snake_case(colnames(results))

    # since we are not sure to get the same data from the api forever
    # I will programmatically modify what we receive rather than set colnames manually

    # will no longer re-order the table
    # common_cols <- c(
    #     "symbol", "name", "enable_trading",
    #     "base_currency", "quote_currency",
    #     "market", # TOOD: added market column; might remove later
    #     "base_min_size", "quote_min_size",
    #     "base_max_size", "quote_max_size",
    #     "base_increment", "quote_increment",
    #     "price_increment", "fee_currency"
    # )
    # data.table::setcolorder(results, c(common_cols, setdiff(colnames(results), common_cols)))

    numeric_cols <- c(
        "base_min_size", "quote_min_size", "base_max_size",
        "quote_max_size", "base_increment", "quote_increment",
        "price_increment", "price_limit_rate", "min_funds"
    )

    # sandbox api does not have "min_funds" column
    # filter out columns that are not in the data; warn user that they are not in the data
    numeric_missing_cols <- setdiff(numeric_cols, colnames(results))

    if (length(numeric_missing_cols) > 0) {
        rlang::warn(stringr::str_interp("The following columns are not in the data: ${collapse(numeric_missing_cols)}"))

        # keep only columns that are in the data
        numeric_cols <- numeric_cols[!numeric_cols %in% numeric_missing_cols]
    }

    logical_cols <- c("is_margin_enabled", "enable_trading")

    logical_missing_cols <- setdiff(logical_cols, colnames(results))

    if (length(logical_missing_cols) > 0) {
        rlang::warn(stringr::str_interp("The following columns are not in the data: ${collapse(logical_missing_cols)}"))

        # keep only columns that are in the data
        logical_cols <- logical_cols[!logical_cols %in% logical_missing_cols]
    }

    ## -----------------
    results[, (numeric_cols) := lapply(.SD, as.numeric), .SDcols = numeric_cols]
    # results[, colnames(results)[6:12] := lapply(.SD, as.numeric), .SDcols = 6:12]

    results[, c("symbol", "name") := lapply(.SD, prep_symbols, revert = TRUE), .SDcols = c("symbol", "name")]
    # results[, colnames(results)[1:2] := lapply(.SD, prep_symbols, revert = TRUE), .SDcols = 1:2]

    results[, (logical_cols) := lapply(.SD, as.logical), .SDcols = logical_cols]

    # data.table::setorder(results, base_currency, quote_currency)
    data.table::setorder(results, symbol, fee_currency)

    # return the result
    return(results[])
}
#' @title Get user's balance(s) list
#'
#' @param currency A `character` vector of one currency symbol (optional).
#' @param type A `character` vector of one indicating the `"main"` or `"trade"` account type (optional).
#'
#' @return A `data.table` containing balance details
#'
#' @examples
#'
#' \dontrun{
#'
#' # to run this example, make sure
#' # you already setup the API key
#' # in a proper .Renviron file
#'
#' # get user's balance details
#' kucoin::get_account_balances()
#'
#' # get user's balance details for BTC only
#' kucoin::get_account_balances(currency = "BTC")
#'
#' # get user's balance details for trade account only
#' kucoin::get_account_balances(type = "trade")
#'
#' }
#'
#' @export

get_account_balances <- function(currency = NULL, type = NULL) {
    # get current timestamp
    current_timestamp <- as.character(get_kucoin_time(raw = TRUE))

    # prepare query params
    query_params <- list(
        currency = currency,
        type = type
    )

    query_params <- query_params[!sapply(query_params, is.null)]

    # prepare query strings
    query_strings <- prep_query_strings(query_params)

    # prepare get headers
    sig <- paste0(current_timestamp, "GET", get_paths("accounts", type = "endpoint"), query_strings)
    sig <- digest::hmac(object = sig, algo = "sha256", key = Sys.getenv("KC-API-SECRET"), raw = TRUE)
    sig <- jsonlite::base64_enc(input = sig)

    get_header <- c(
        "KC-API-KEY" = Sys.getenv("KC-API-KEY"),
        "KC-API-SIGN" = sig,
        "KC-API-TIMESTAMP" = current_timestamp,
        "KC-API-PASSPHRASE" = Sys.getenv("KC-API-PASSPHRASE")
    )

    # get server response
    response <- httr::GET(
        url = get_base_url(),
        path = get_paths("accounts"),
        query = query_params,
        config = httr::add_headers(.headers = get_header)
    )

    # analyze response
    response <- analyze_response(response)

    # parse json result
    parsed <- jsonlite::fromJSON(httr::content(response, "text", encoding = "UTF-8"))

    # tidy the parsed data
    results <- data.table::data.table(parsed$data, check.names = FALSE)

    if (nrow(results) == 0) {
        message("No assets found.")
        return(results)
    }

    results <- results[, c("type", "id", "currency", "balance", "available", "holds")]

    # results[, 4:6] <- lapply(results[, 4:6], as.numeric)
    results[, colnames(results)[4:6] := lapply(.SD, as.numeric), .SDcols = 4:6]

    # results <- results[order(results$type, results$currency), ]
    data.table::setorder(results, type, currency)

    # return the result
    return(results[])
}
#' @title Get currencies' details
#' 
#' @description
#' 
#' Get a currencies' details. This includes what chains are available for depositing; this function is useful for then generating a deposit address by use of [kucoin::get_deposit_address()].
#'
#' | currency | name | full_name | precision | is_margin_enabled | is_debit_enabled | chain_name | chain  | withdrawal_min_size | withdrawal_min_fee | is_withdraw_enabled | is_deposit_enabled | confirms | pre_confirms | contract_address                           |
#' |----------|------|-----------|-----------|-------------------|------------------|------------|--------|---------------------|--------------------|---------------------|--------------------|----------|--------------|--------------------------------------------|
#' | BTC      | BTC  | Bitcoin   | 8         | TRUE              | TRUE             | BTC        | btc    | 0.0008              | 0.0005             | TRUE                | TRUE               | 3        | 1            |                                            |
#' | BTC      | BTC  | Bitcoin   | 8         | TRUE              | TRUE             | KCC        | kcc    | 0.0008              | 0.00002            | TRUE                | TRUE               | 20       | 20           | 0xfa93c12cd345c658bc4644d1d4e1b9615952258c |
#' | BTC      | BTC  | Bitcoin   | 8         | TRUE              | TRUE             | BTC-Segwit | bech32 | 0.0008              | 0.0005             | FALSE               | TRUE               | 2        | 2            |                                            |
#' 
#' @param currencies A `character` vector to specify the currencies to get details for (required - default `NULL`).
#' 
#' @seealso `kucoin::get_deposit_address()`
#' 
#' @return A `data.table` with currency information
#' 
#' @details
#' 
#' For more information see documentation: [KuCoin - get-currency-detail](https://docs.kucoin.com/#get-currency-detail-recommend)
#' 
#' Using v2 of the api.
#' 
#' @examples
#' 
#' # get a currencies' details
#' kucoin::get_currency_details(c("BTC", "XMR"))
#' 
#' @export

get_currency_details <- function(currencies = NULL) {
    if (is.null(currencies)) {
        rlang::abort('Argument "currencies" must be provided.')
    }

    # get currencies details
    results <- lapply(currencies, .get_currency_details)

    # combine results
    results <- data.table::rbindlist(results)

    return(results[])
}


# https://docs.kucoin.com/#get-currency-detail-recommend
.get_currency_details <- function(currency = NULL) {
    if (is.null(currency)) {
        rlang::abort('Argument "currency" must be provided.')
    }

    # GET /api/v2/currencies/{currency}
    # GET /api/v2/currencies/BTC

    response <- httr::GET(
        url = get_base_url(),
        path = get_paths("currencies", append = currency)
    )

    # analyze response
    response <- analyze_response(response)

    # parse json result
    parsed <- jsonlite::fromJSON(httr::content(response, "text", encoding = "UTF-8"))

    results <- data.table::as.data.table(parsed$data, check.names = FALSE)

    # clean up column names
    colnames(results) <- gsub("chains\\.", "", colnames(results))

    # to snake case
    colnames(results) <- to_snake_case(colnames(results))

    return(results[])
}
#' @title Get a deposit address for a currency
#' 
#' @description
#' 
#' Get a deposit address for a currency. This function is useful for generating a deposit address for a currency. Note you must provide the chain (network) to use for the deposit address. This can be obtained by use of [kucoin::get_currency_details()].
#' 
#' @param currency A `character` vector length 1 to specify the currencies to get deposit addresses for (required - default `NULL`)
#' @param chain A `character` vector length 1 to specify the chain (network) to use for the deposit address (required - default `NULL`).
#' 
#' @seealso `kucoin::get_currency_details()()`
#' 
#' @return A `data.table` containing deposit address information
#' 
#' @details
#' 
#' For more information see documentation: [KucCoin - get-deposit-addresses-v2](https://docs.kucoin.com/#get-deposit-addresses-v2).
#' 
#' @examples
#' 
#' \dontrun{
#' 
#' # to run this example, make sure
#' # you already setup the API key
#' # in a proper .Renviron file
#' 
#' # check market metadata
#' kucoin::get_currency_details("BTC")
#' 
#' # get a deposit address for a currency
#' deposit_address <- kucoin::get_deposit_address("BTC", "btc")
#' 
#' # quick check
#' deposit_address
#' 
#' }
#' 
#' @export

# https://docs.kucoin.com/#get-deposit-addresses-v2
get_deposit_address <- function(currency = NULL, chain = NULL) {
    if (is.null(currency)) {
        rlang::abort('Argument "currency" must be provided.')
    }

    if (is.null(chain)) {
        rlang::abort('Argument "chain" must be provided.')
    }

    # GET /api/v2/deposit-addresses
    # Example
    # GET /api/v2/deposit-addresses?currency=BTC

    # get current timestamp
    current_timestamp <- as.character(get_kucoin_time(raw = TRUE))

    # prepare query params
    query_params <- list(
        currency = currency,
        chain = chain
    )

    query_params <- query_params[!sapply(query_params, is.null)]

    # prepare query strings
    query_strings <- prep_query_strings(query_params)

    # prepare get headers
    sig <- paste0(current_timestamp, "GET", get_paths("deposit-addresses", type = "endpoint"), query_strings)
    sig <- digest::hmac(object = sig, algo = "sha256", key = Sys.getenv("KC-API-SECRET"), raw = TRUE)
    sig <- jsonlite::base64_enc(input = sig)

    get_header <- c(
        "KC-API-KEY" = Sys.getenv("KC-API-KEY"),
        "KC-API-SIGN" = sig,
        "KC-API-TIMESTAMP" = current_timestamp,
        "KC-API-PASSPHRASE" = Sys.getenv("KC-API-PASSPHRASE")
    )

    # get server response
    response <- httr::GET(
        url = get_base_url(),
        path = get_paths("deposit-addresses"),
        query = query_params,
        config = httr::add_headers(.headers = get_header)
    )

    # analyze response
    response <- analyze_response(response)

    # parse json result
    parsed <- jsonlite::fromJSON(httr::content(response, "text", encoding = "UTF-8"))
    
    results <- data.table::as.data.table(parsed$data, check.names = FALSE)

    colnames(results) <- to_snake_case(colnames(results))

    results[, currency := currency]

    data.table::setcolorder(results, c("currency", "address", "memo", "chain", "contract_address"))

    return(results[])
}
#' @title Get historical market data for symbols
#'
#' @param symbols A `character` vector of one or more pair symbol (required - default `NULL`).
#' @param from A `character` with valid `date`/`datetime` format, or `date`/`datetime` object as a start of datetime range (required - default `NULL`).
#' @param to A `character` with valid `date`/`datetime` format, or `date`/`datetime` object as an end of datetime range (required - default `NULL`).
#' @param frequency A `character` vector of one which specify the frequency option, see details for further information (required - default `NULL`).
#' @param delay A `numeric` value to delay data request in milliseconds (optional - default `0`).
#' @param retries A `numeric` value to specify the number of retries in case of failure (optional - default `3`).
#' 
#' @details
#'
#'  There are several supported frequencies:
#'
#'  * `"1 minute"`
#'  * `"3 minutes"`
#'  * `"5 minutes"`
#'  * `"15 minutes"`
#'  * `"30 minutes"`
#'  * `"1 hour"`
#'  * `"2 hours"`
#'  * `"4 hours"`
#'  * `"6 hours"`
#'  * `"8 hours"`
#'  * `"12 hours"`
#'  * `"1 day"`
#'  * `"1 week"`
#'
#' # ---------------
#' For more information see documentation: [KuCoin - get-klines](https://docs.kucoin.com/#get-klines)
#' 
#' @return A `data.table` with price data
#'
#' @examples
#'
#' # get one symbol
#' kucoin::get_market_data(
#'     symbols = "BTC/USDT",
#'     from = "2022-11-05 00:00:00",
#'     to = "2022-11-06 00:00:00",
#'     frequency = "1 hour"
#' )
#' 
#' # get multiple symbols
#' kucoin::get_market_data(
#'     symbols = c("BTC/USDT", "XMR/BTC", "KCS/USDT"),
#'     from = "2022-11-05 00:00:00",
#'     to = "2022-11-06 00:00:00",
#'     frequency = "1 hour"
#' )
#'
#' @export

get_market_data <- function(symbols = NULL, from = NULL, to = NULL, frequency = NULL, delay = 0, retries = 3) {
    if (is.null(symbols)) {
        rlang::abort('Argument "symbols" must be an n length character vector of symbols in the format "BASE/QUOTE".')
    }

    if (is.null(from)) {
        rlang::abort('Argument "from" must be a datetime object or character coercible to datetime.')
    }

    if (is.null(to)) {
        rlang::abort('Argument "to" must be a datetime object or character coercible to datetime.')
    }

    if (is.null(frequency)) {
        rlang::abort('Argument "frequency" must be a character vector of one; specifying the frequency option - see ?get_market_data for details.')
    }

    # get datetime ranges
    times <- prep_datetime_range(
        from = lubridate::as_datetime(from),
        to = lubridate::as_datetime(to),
        frequency = frequency
    )

    # get result for multiple symbols
    results <- data.table::data.table()

    for (symbol in symbols) {

        # get queried results
        result <- data.table::data.table()

        for (i in 1:nrow(times)) {

            queried <- get_klines(
                symbol = prep_symbols(symbol),
                startAt = prep_datetime(times$from[i]),
                endAt = prep_datetime(times$to[i]),
                type = prep_frequency(frequency),
                retries = retries
            )

            if (nrow(queried) == 0) {
                message(stringr::str_interp('No data for ${symbol} ${times$from[i]} to ${times$to[i]}'))
            } else {
                result <- rbind(result, queried)
            }

            Sys.sleep(delay)
        }

        if (nrow(result) == 0) {
            message(stringr::str_interp('Skipping data for ${symbol}'))
        } else {
            init_names <- data.table::copy(colnames(result))

            result[, symbol := symbol]

            # result <- result[, c("symbol", init_names)]
            data.table::setcolorder(result, c("symbol", init_names))

            # result <- result[order(result$datetime), ] # TODO: port to data.table
            data.table::setorder(result, datetime)

            results <- rbind(results, result)
        }
    }

    # return the result
    return(results[])
}

# query klines (prices) data
# https://docs.kucoin.com/#get-klines
get_klines <- function(symbol = NULL, startAt = NULL, endAt = NULL, type = NULL, retries = 3) {
    if (is.null(symbol)) {
        rlang::abort('Argument "symbol" must be provided.')
    }

    if (is.null(startAt)) {
        rlang::abort('Argument "startAt" must be provided.')
    }

    if (is.null(endAt)) {
        rlang::abort('Argument "endAt" must be provided.')
    }

    if (is.null(type)) {
        rlang::abort('Argument "type" must be provided.')
    }

    
    # TODO: api allows for startAt/endAt to be set to 0; test this
    
    # prepare query params
    query_params <- list(
        symbol = symbol,
        startAt = startAt,
        endAt = endAt,
        type = type
    )

    # get server response
    response <- httr::RETRY(
        verb = "GET",
        url = get_base_url(),
        path = get_paths("klines"),
        query = query_params,
        times = retries
    )

    # analyze response
    response <- analyze_response(response)

    # parse json result
    parsed <- jsonlite::fromJSON(httr::content(response, "text", encoding = "UTF-8"))

    # parsed$data is a matrix array no colnames
    results <- data.table::data.table(parsed$data, check.names = FALSE)

    if (nrow(results) == 0) {
        message("Specified symbols and period returning no data")
    } else {
        colnames(results) <- c("datetime", "open", "close", "high", "low", "volume", "turnover")

        results <- results[, c("datetime", "open", "high", "low", "close", "volume", "turnover")]

        # results[, 1:7] <- lapply(results[, 1:7], as.numeric)
        results[, colnames(results)[1:7] := lapply(.SD, as.numeric), .SDcols = 1:7]

        # results$datetime <- as_datetime(results$datetime)
        results[, datetime := lubridate::as_datetime(datetime)]

        # results <- results[order(results$datetime), ]
        data.table::setorder(results, datetime)
    }

    # return the result
    return(results[])
}
#' @title Get all market symbols' metadata
#' 
#' @param retries A `numeric` value to specify the number of retries in case of failure (optional - default `3`).
#'
#' @return A `data.table` with metadata
#' 
#' @details
#' 
#' # ---------------
#' For more information see documentation: [KuCoin - get-symbols-list-deprecated](https://docs.kucoin.com/#get-symbols-list-deprecated)
#'
#' @examples
#'
#' # get all symbols' most recent metadata
#' kucoin::get_market_metadata()
#'
#' @export

get_market_metadata <- function(retries = 3) {
    # get server response
    response <- httr::RETRY(
        verb = "GET",
        url = get_base_url(),
        path = get_paths("symbols"),
        times = retries
    )

    # analyze response
    response <- analyze_response(response)

    # parse json result
    parsed <- jsonlite::fromJSON(httr::content(response, "text", encoding = "UTF-8"))

    results <- data.table::as.data.table(parsed$data, check.names = FALSE)
    
    colnames(results) <- to_snake_case(colnames(results))

    numeric_cols <- c(
        "base_min_size", "quote_min_size", "base_max_size",
        "quote_max_size", "base_increment", "quote_increment",
        "price_increment", "price_limit_rate", "min_funds"
    )

    # sandbox api does not have "min_funds" column
    # filter out columns that are not in the data; warn user that they are not in the data
    numeric_missing_cols <- setdiff(numeric_cols, colnames(results))

    if (length(numeric_missing_cols) > 0) {
        rlang::warn(stringr::str_interp("The following columns are not in the data: ${collapse(numeric_missing_cols)}"))

        # keep only columns that are in the data
        numeric_cols <- numeric_cols[!numeric_cols %in% numeric_missing_cols]
    }

    logical_cols <- c("is_margin_enabled", "enable_trading")

    logical_missing_cols <- setdiff(logical_cols, colnames(results))

    if (length(logical_missing_cols) > 0) {
        rlang::warn(stringr::str_interp("The following columns are not in the data: ${collapse(logical_missing_cols)}"))

        # keep only columns that are in the data
        logical_cols <- logical_cols[!logical_cols %in% logical_missing_cols]
    }

    ## -----------------
    results[, (numeric_cols) := lapply(.SD, as.numeric), .SDcols = numeric_cols]

    results[, c("symbol", "name") := lapply(.SD, prep_symbols, revert = TRUE), .SDcols = c("symbol", "name")]

    results[, (logical_cols) := lapply(.SD, as.logical), .SDcols = logical_cols]

    data.table::setorder(results, symbol, fee_currency)

    # return the result
    return(results[])
}

#' @title Get all order(s)
#' 
#' @description 
#' 
#' TODO: experimental.
#' 
#' @param symbol A `character` vector of one or more which contain symbol(s) of format "BTC/USDT" (optional - default `NULL`).
#' @param status A `character` vector of one either "done" or "active" (optional - default `NULL`).
#' @param side A `character` vector of one either "buy" or "sell" (optional - default `NULL`).
#' @param type A `character` vector of one either "limit", "market", "limit_stop", "market_stop" (optional - default `NULL`).
#' @param tradeType A `character` vector of one either "TRADE" (spot trading), "MARGIN_TRADE" (cross margin trading), "MARGIN_ISOLATED_TRADE" (isolated margin trading) (required - default `TRADE`).
#' @param from A `character` with valid `date`/`datetime` format, or `date`/`datetime` object as a start of datetime range (optional - default `NULL`).
#' @param to A `character` with valid `date`/`datetime` format, or `date`/`datetime` object as an end of datetime range (optional - default `NULL`).
#' @param delay A `numeric` value to delay data request in milliseconds (optional - default `0.1`).
#' @param retries A `numeric` value to specify the number of retries in case of failure (optional - default `3`).
#'
#' @return A `data.table` containing order details
#' 
#' @details
#' 
#' For more information see documentation: [KuCoin - list-orders](https://docs.kucoin.com/#list-orders)
#'
#' @examples
#'
#' \dontrun{
#'
#' # to run this example, make sure
#' # you already setup the API key
#' # in a proper .Renviron file
#'
#' kucoin::get_orders_all()
#'
#' }
#'
#' @export

get_orders_all <- function(
    # all NULL are optional
    symbol = NULL, # expects format "KCS-BTC"
    status = NULL, # expects "active" or "done"
    side = NULL,
    type = NULL,
    tradeType = "TRADE", # TRADE (Spot Trading), MARGIN_TRADE (Cross Margin Trading), MARGIN_ISOLATED_TRADE (Isolated Margin Trading)
    from = NULL, # expects format "2021-01-01 00:00:00 UTC"
    to = NULL,
    retries = 3,
    delay = 0.1
) {

    if (!is.null(status) && !status %in% c("active", "done")) {
        rlang::abort(stringr::str_interp('Argument status must be one of "active", "done"; received ${status}.'))
    }

    if (!is.null(side) && !side %in% c("buy", "sell")) {
        rlang::abort(stringr::str_interp('Argument side must be one of "buy", "sell"; received ${side}.'))
    }

    if (!tradeType %in% c("TRADE", "MARGIN_TRADE", "MARGIN_ISOLATED_TRADE")) {
        rlang::abort(stringr::str_interp('Argument tradeType must be one of "TRADE", "MARGIN_TRADE", "MARGIN_ISOLATED_TRADE"; received ${tradeType}.'))
    }

    current_timestamp <- as.character(get_kucoin_time(raw = TRUE))

    # example
    # GET /api/v1/orders?status=active
    # GET /api/v1/orders?status=active?tradeType=MARGIN_ISOLATED_TRADE

    # prepare query params; need to return NULL if no params
    query_params <- list(
        symbol = (\() {
            if (!is.null(symbol)) return(prep_symbols(symbol))
            return(NULL)
        })(),
        status = status,
        side = side,
        type = type,
        tradeType = tradeType,
        startAt = (\() {
            if (!is.null(from)) return(lubridate::as_datetime(from))
            return(NULL)
        })(),
        endAt = (\() {
            if (!is.null(to)) return(lubridate::as_datetime(to))
            return(NULL)
        })(),
        currentPage = 1,
        pageSize = 10 # min 10 max 500
    )

    query_params <- query_params[!sapply(query_params, is.null)]

    # prepare query strings
    query_strings <- prep_query_strings(query_params)

    # prepare get request
    sig <- paste0(current_timestamp, "GET", get_paths("orders", type = "endpoint"), query_strings)
    sig <- digest::hmac(object = sig, algo = "sha256", key = Sys.getenv("KC-API-SECRET"), raw = TRUE)
    sig <- jsonlite::base64_enc(input = sig)

    get_header <- c(
        "KC-API-KEY" = Sys.getenv("KC-API-KEY"),
        "KC-API-SIGN" = sig,
        "KC-API-TIMESTAMP" = current_timestamp,
        "KC-API-PASSPHRASE" = Sys.getenv("KC-API-PASSPHRASE")
    )

    # get server response: This API is restricted for each account, the request rate limit is 30 times/3s.
    response <- httr::RETRY(
        verb = "GET",
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

    results <- data.table::as.data.table(parsed$data$items, check.names = TRUE)

    # to get subsequent pages another get request is necessary
    # GET /api/v1/orders?currentPage=1&pageSize=50

    # if there are more pages, get them
    if (parsed$data$currentPage < parsed$data$totalPage) {
        message(stringr::str_interp('There are ${parsed$data$totalNum} orders in total; getting next page(s)...'))

        # if there are more pages the result for example (initial request was set to 10 items):
        # $code
        # [1] "200000"
        # $data
        # $data$currentPage
        # [1] 1
        # $data$pageSize
        # [1] 10
        # $data$totalNum
        # [1] 38
        # $data$totalPage
        # [1] 4
        # $data$items

        # get subsequent pages start from 2 (1 is already retrieved)
        for (i in (parsed$data$currentPage + 1):parsed$data$totalPage) {
            message(stringr::str_interp('Getting page ${i} of ${parsed$data$totalPage}.'))

            current_timestamp <- as.character(get_kucoin_time(raw = TRUE))

            # set current page
            query_params$currentPage <- i

            # prepare query strings - example: "?tradeType=TRADE&currentPage=2&pageSize=10"
            query_strings <- prep_query_strings(query_params)

            # prepare get request
            sig <- paste0(current_timestamp, "GET", get_paths("orders", type = "endpoint"), query_strings)
            sig <- digest::hmac(object = sig, algo = "sha256", key = Sys.getenv("KC-API-SECRET"), raw = TRUE)
            sig <- jsonlite::base64_enc(input = sig)

            get_header <- c(
                "KC-API-KEY" = Sys.getenv("KC-API-KEY"),
                "KC-API-SIGN" = sig,
                "KC-API-TIMESTAMP" = current_timestamp,
                "KC-API-PASSPHRASE" = Sys.getenv("KC-API-PASSPHRASE")
            )

            # get server response: This API is restricted for each account, the request rate limit is 30 times/3s.
            # sleep to meet rate limit of 10 requests per second
            Sys.sleep(delay)

            response <- httr::RETRY(
                verb = "GET",
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

            results <- rbind(results, data.table::as.data.table(parsed$data$items, check.names = TRUE))
        }
    }

    if (nrow(results) == 0) {
        message("No orders found.")
        return(results)
    }

    colnames(results) <- to_snake_case(colnames(results))

    numeric_cols <- c("price", "size", "funds", "deal_funds", "deal_size", "fee", "stop_price", "visible_size", "cancel_after", "created_at")

    numeric_missing_cols <- setdiff(numeric_cols, colnames(results))

    if (length(numeric_missing_cols) > 0) {
        rlang::warn(stringr::str_interp('The following columns are missing: ${collapse(numeric_missing_cols)}'))

        # keep only columns that are in results
        numeric_cols <- numeric_cols[!numeric_cols %in% numeric_missing_cols]
    }

    logical_cols <- c("stop_triggered", "post_only", "hidden", "iceberg", "is_active", "cancel_exist")

    logical_missing_cols <- setdiff(logical_cols, colnames(results))

    if (length(logical_missing_cols) > 0) {
        rlang::warn(stringr::str_interp('The following columns are missing: ${collapse(logical_missing_cols)}'))

        # keep only columns that are in results
        logical_cols <- logical_cols[!logical_cols %in% logical_missing_cols]
    }

    ## -----------------
    results[, (numeric_cols) := lapply(.SD, as.numeric), .SDcols = numeric_cols]

    results[, (logical_cols) := lapply(.SD, as.logical), .SDcols = logical_cols]

    return(results[])
}
#' @title Get order(s) details by order id
#'
#' @param orderIds A `character` vector of one or more which contain the order id(s) designated by KuCoin (required - default `NULL`).
#' @param delay A `numeric` value to delay data request in milliseconds (optional - default `0`).
#' @param retries A `numeric` value to specify the number of retries in case of failure (optional - default `3`).
#'
#' @return A `data.table` containing order details
#' 
#' @details
#' 
#' For more information see documentation: [KuCoin - get-order](https://docs.kucoin.com/#get-an-order)
#'
#' @examples
#'
#' \dontrun{
#'
#' # to run this example, make sure
#' # you already setup the API key
#' # in a proper .Renviron file
#'
#' # get order details
#' order_details <- kucoin::get_orders_by_id(order_ids = "insertorderid")
#'
#' # quick check
#' order_details
#'
#' }
#'
#' @export

get_orders_by_id <- function(orderIds = NULL, delay = 0, retries = 3) {
    if (is.null(orderIds)) {
        rlang::abort('Argument "orderIds" must be provided.')
    }

    # force order id to unique
    order_ids <- unique(orderIds)

    # get queried results
    if (length(order_ids) > 1) {
        results <- data.table::data.table()

        for (id in order_ids) {
            result <- .get_order_by_id(orderId = id, retries = retries)

            results <- rbind(results, result)

            Sys.sleep(delay)
        }

        # results <- results[order(results$created_at), ]
        data.table::setorder(results, created_at)
    } else {
        results <- .get_order_by_id(orderId = orderIds)
    }

    # return the results
    return(results[])
}

.get_order_by_id <- function(orderId = NULL, retries = 3) {
    if (is.null(orderId)) {
        rlang::abort('Argument "orderId" must be provided.')
    }

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
# response processor ------------------------------------------------------
# response analyzer
analyze_response <- function(x) {
    # stop if not return json
    if (httr::http_type(x) != "application/json") {
        rlang::abort("Server not responded correctly")
    }

    # stop if server responding with error
    if (httr::http_error(x)) {
        rlang::abort(stringr::str_interp('Stopped with message: "${httr::http_status(x)$message}"'))
    }

    # return original if all success
    return(x)
}

# input processor ---------------------------------------------------------
# convert conventional pair symbol to KuCoin's API standard
prep_symbols <- function(x, revert = FALSE) {
    if (!is.character(x) || length(x) == 0) {
        rlang::warn('Argument "x" must be a character vector of length 1 or greater.')
    }

    if (revert) {
        x <- gsub("\\-", "\\/", x)
    } else {
        x <- gsub("\\/", "\\-", x)
    }

    return(x)
}

# format date input
prep_datetime <- function(x) {
    x <- as.numeric(x)

    if (nchar(as.character(x)) > 10) {
        x <- floor(x)
    }

    return(x)
}

# format frequency input
prep_frequency <- function(x) {
    if (!(is.character(x) & length(x) == 1)) {
        rlang::abort("Frequency should be a character vector with length equal to one")
    }

    lkp <- data.table::fread(
        '"freq", "formatted"
        "1 minute", "1min"
        "3 minutes", "3min"
        "5 minutes", "5min"
        "15 minutes", "15min"
        "30 minutes", "30min"
        "1 hour", "1hour"
        "2 hours", "2hour"
        "4 hours", "4hour"
        "6 hours", "6hour"
        "8 hours", "8hour"
        "12 hours", "12hour"
        "1 day", "1day"
        "1 week", "1week"'
    )

    x <- lkp[freq == x, ]$formatted

    if (length(x) == 0) {
        rlang::abort("Unsupported frequency! See function documentation for help")
    }

    return(x)
}

# prepare datetime range
prep_datetime_range <- function(from, to, frequency) {
    this.frequency <- frequency

    # readjust input
    from <- lubridate::floor_date(from, frequency)
    to <- lubridate::ceiling_date(to, frequency)

    # prepare frequency lookup table
    lkp <- data.table::fread(
        '"frequency", "num", "chr"
        "1 minute", 1, "mins"
        "3 minutes", 3, "mins"
        "5 minutes", 5, "mins"
        "15 minutes", 15, "mins"
        "30 minutes", 30, "mins"
        "1 hour", 1, "hours"
        "2 hours", 2, "hours"
        "4 hours", 4, "hours"
        "6 hours", 6, "hours"
        "8 hours", 8, "hours"
        "12 hours", 12, "hours"
        "1 day", 1, "days"
        "1 week", 1, "weeks"'
    )

    # get numeric and character part from frequency
    num <- lkp[frequency == this.frequency, ]$num
    chr <- lkp[frequency == this.frequency, ]$chr

    # calculate time difference
    timelength <- difftime(
        time1 = to,
        time2 = from,
        units = chr
    )

    timelength <- floor(as.numeric(timelength) / num) + 1

    # create time sequence
    timeseq <- seq.POSIXt(from, by = paste(num, chr), length.out = timelength)

    # prepare time range lookup table
    start_index <- c(1, c(2:timelength)[2:timelength %% 1500 == 0])
    end_index <- c(start_index[-1] - 1, timelength)

    results <- data.table::data.table(
        from = timeseq[start_index],
        to = timeseq[end_index]
    )

    # return the results
    return(results)
}

prep_query_strings <- function(queries) {
    # convert to query strings
    if (length(queries) > 0) {
        results <- c()

        for (i in names(queries)) {
            result <- paste(i, queries[[i]], sep = "=")
            results <- c(results, result)
        }

        results <- paste0("?", paste0(results, collapse = "&"))
    } else {
        results <- ""
    }

    # return the results
    return(results)
}

# api base data -----------------------------------------------------------
# paths/endpoints urls lookup
get_base_url <- function(endpoint = "https://api.kucoin.com") {
    # https://openapi-sandbox.kucoin.com
    # https://api.kucoin.com/

    if (nchar(Sys.getenv("KC-API-ENDPOINT")) != 0) {
        return(Sys.getenv("KC-API-ENDPOINT"))
    }

    return(endpoint)
}

# paths/endpoints urls lookup
get_paths <- function(x, type = "path", append = NULL) {
    this.x <- x

    # --------------------
    # TODO: Get Symbols List(deprecated) - GET /api/v1/symbols

    # https://docs.kucoin.com/#get-klines

    # lookup table
    lkp <- data.table::fread(
        '"x", "endpoint", "path"
        "accounts", "/api/v1/accounts", "api/v1/accounts"
        "klines", "/api/v1/market/candles", "api/v1/market/candles"
        "orders", "/api/v1/orders", "api/v1/orders"
        "symbols", "/api/v2/symbols", "api/v2/symbols"
        "symbols-deprecated", "/api/v1/symbols", "api/v1/symbols"
        "time", "/api/v1/timestamp", "api/v1/timestamp"
        "currencies", "/api/v2/currencies", "api/v2/currencies"
        "deposit-addresses", "/api/v2/deposit-addresses", "api/v2/deposit-addresses"'
    )

    # get specified endpoint
    results <- lkp[x == this.x, ][[type]]

    # append if not null
    if (!is.null(append)) {
        results <- paste0(results, "/", append)
    }

    # return the result
    return(results)
}

# miscellaneous -----------------------------------------------------------
# convert names to snake case
# https://stackoverflow.com/questions/73203811/how-to-convert-any-string-to-snake-case-using-only-base-r
to_snake_case <- function(vector) {
    return(gsub(" ", "_", tolower(gsub("(.)([A-Z])", "\\1 \\2", vector))))
}

collapse <- function(vector) {
    if (length(vector) == 0) {
        return(vector)
    }

    return(paste0(vector, collapse = ","))
}# package description -----------------------------------------------------

#' @title `kucoin`: An R API to KuCoin Crytocurrency Exchange Market
#'
#' @import data.table
#' 
#' @importFrom data.table data.table
#' @importFrom data.table fread
#' @importFrom data.table setcolorder
#' @importFrom data.table setorder
#' @importFrom digest hmac
#' @importFrom stringr str_interp
#' @importFrom httr GET
#' @importFrom httr POST
#' @importFrom httr add_headers
#' @importFrom httr content
#' @importFrom httr http_error
#' @importFrom httr http_status
#' @importFrom httr http_type
#' @importFrom jsonlite base64_enc
#' @importFrom jsonlite fromJSON
#' @importFrom jsonlite toJSON
#' @importFrom lubridate as_datetime
#' @importFrom lubridate floor_date
#' @importFrom lubridate ceiling_date
#' @importFrom rlang abort
NULL

#' @title Post a limit order
#'
#' @param symbol A `character` vector of one or more pair symbol (required - default `NULL`).
#' @param side A `character` vector of one which specify the order side: `"buy"` or `"sell"` (required - default `NULL`).
#' @param base_size A `numeric` vector of one determining the base size of the order; n units of the first currency in the pair (required - default `NULL`).
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
#' # check our balances
#' kucoin::get_account_balances()
#' 
#' ## -------
#' # to avoid errors we will calculate our price and order size
#' # kucoin accepts these values in specific increments per ticker symbol
#' 
#' # get the market metadata
#' ticker <- "BTC/USDT"
#' price_per_coin <- 10000
#' amount_to_spend <- 300
#' 
#' metadata <- kucoin::get_market_metadata.deprecated()[symbol == ticker, ]
#' price_increment <- metadata[symbol == ticker, ]$price_increment
#' size_increment <- metadata[symbol == ticker, ]$base_increment
#' 
#' # calculate size and price
#' size <- floor(amount_to_spend / price_per_coin / size_increment) * size_increment
#' price <- floor(price_per_coin / price_increment) * price_increment
#' 
#' ## ----
#' # submit order
#' message(stringr::str_interp('${ticker}: selling ${size} ${gsub("\\\\/.*", "", ticker)} @ ${price} ${gsub(".*\\\\/", "", ticker)}.'))
#' order_id <- kucoin::submit_limit_order(
#'     symbol = ticker,
#'     side = "sell",
#'     base_size = size,
#'     price = price
#' ); order_id
#' 
#' 
#' ## ----
#' # buying asset so recalculate
#' price_per_coin <- 0.0005
#' amount_to_spend <- 300
#' 
#' # calculate size and price
#' size <- floor(amount_to_spend / price_per_coin / size_increment) * size_increment
#' price <- floor(price_per_coin / price_increment) * price_increment
#' 
#' message(stringr::str_interp('${ticker}: buying ${size} ${gsub("\\\\/.*", "", ticker)} @ ${price} ${gsub(".*\\\\/", "", ticker)}.'))
#' order_id2 <- kucoin::submit_limit_order(
#'     symbol = ticker,
#'     side = "buy",
#'     base_size = size,
#'     price = price
#' ); order_id2
#' 
#' kucoin::get_orders_by_id(c(order_id, order_id2))
#' 
#'
#' }
#' 
#' @export
submit_limit_order <- function(
    symbol = NULL, # accepts format "KCS/BTC"
    side = NULL, # buy or sell
    base_size = NULL, # base size
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

    if (is.null(base_size)) {
        rlang::abort('Argument "base_size" must be provided.')
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

    # return result
    return(results)
}

# https://docs.kucoin.com/#place-a-new-order
.submit_limit_order <- function(
    symbol, # requires prep_symbols() format; "BTC-USDT"
    side, # buy or sell
    size = NULL, # amount of base currency to buy or sell
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
        size = size
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
#' ## -------
#' # to avoid errors we will calculate our price and order size
#' # kucoin accepts these values in specific increments per ticker symbol
#' 
#' # get the market metadata
#' ticker <- "BTC/USDT"
#' base_to_buy <- 0.0001 # amount of btc
#' quote_to_spend <- 1 # 1 usdt
#' 
#' metadata <- kucoin::get_market_metadata.deprecated()[symbol == ticker, ]
#' base_size_increment <- metadata[symbol == ticker, ]$base_increment
#' quote_size_increment <- metadata[symbol == ticker, ]$quote_increment
#' 
#' # calculate size
#' base_size <- floor(amount_to_buy / base_size_increment) * base_size_increment
#' quote_size <- floor(amount_to_spend / quote_size_increment) * quote_size_increment
#' 
#' # post a market order: buy 1 ETH
#' order_id1 <- kucoin::submit_market_order(
#'     symbol = ticker,
#'     side = "buy",
#'     base_size = base_size
#' ); order_id1
#' 
#' # post a market order: sell 1 ETH
#' order_id2 <- kucoin::submit_market_order(
#'     symbol = ticker,
#'     side = "sell",
#'     base_size = base_size
#' ); order_id2
#' 
#' # post a market order: buy ETH worth 0.0001 BTC
#' order_id3 <- kucoin::submit_market_order(
#'     symbol = ticker,
#'     side = "buy",
#'     quote_size = quote_size
#' ); order_id3
#' 
#' # post a market order: sell ETH worth 0.0001 BTC
#' order_id4 <- kucoin::submit_market_order(
#'     symbol = ticker,
#'     side = "sell",
#'     quote_size = quote_size
#' ); order_id4
#' 
#' kucoin::get_orders_by_id(c(order_id1, order_id2, order_id3, order_id4))
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

# time utilities ----------------------------------------------------------

#' @title Get current KuCoin API server time
#'
#' @param raw A `logical` vector to specify whether to return a raw results or not. The default is `FALSE`.
#'
#' @return A `datetime` object
#'
#' @examples
#' # import library
#' library("kucoin")
#'
#' # get current server time
#' get_kucoin_time()
#'
#' @export

get_kucoin_time <- function(raw = FALSE) {
    # get server response
    response <- httr::GET(
        url = get_base_url(),
        path = get_paths("time")
    )

    # analyze response
    response <- analyze_response(response)

    # parse json result
    parsed <- jsonlite::fromJSON(httr::content(response, "text", encoding = "UTF-8"))

    # get timestamp
    results <- as.numeric(parsed$data)

    # parse datetime if raw == FALSE
    if (!raw) {
        # readjust result
        results <- floor(parsed$data / 1000)

        # convert to proper datetime
        results <- lubridate::as_datetime(results)
    }

    # return the results
    return(results)
}

#' @title Convert raw Kucoin time to a `datetime` object
#'
#' @param time A `numeric` vector of time returned from KuCoin API (milliseconds) to be converted to a `datetime` object.
#'
#' @return A `datetime` object
#'
#' @examples
#' # import library
#' library("kucoin")
#'
#' # get current server time
#' kucoin_time_to_datetime(1.669401e+12)
#'
#' @export
#' 
# https://docs.kucoin.com/#server-time

kucoin_time_to_datetime <- function(time) {
    # readjust result
    results <- floor(time / 1000)

    # convert to proper datetime
    results <- lubridate::as_datetime(results)

    # return the results
    return(results)
}
