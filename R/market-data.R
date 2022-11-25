# get historical data -----------------------------------------------------

#' @title Get historical data from specified symbols
#'
#' @param symbols A `character` vector of one or more pair symbol.
#' @param from A `character` with valid `date`/`datetime` format, or `date`/`datetime` object as a start of datetime range.
#' @param to A `character` with valid `date`/`datetime` format, or `date`/`datetime` object as an end of datetime range.
#' @param frequency A `character` vector of one which specify the frequency option, see details for further information.
#' @param delay A `numeric` value to delay data request in milliseconds.
#' @param retries A `numeric` value to specify the number of retries in case of failure.
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
#' @return A `data.table` containing prices data
#'
#' @examples
#'
#' # import library
#' library("kucoin")
#'
#' # get one pair of symbol prices
#' prices <- get_kucoin_prices(
#'   symbols = "KCS/USDT",
#'   from = "2022-11-05 00:00:00",
#'   to = "2022-11-06 00:00:00",
#'   frequency = "1 hour"
#' )
#'
#' # quick check
#' prices
#'
#' # get multiple pair of symbols prices
#' prices <- get_kucoin_prices(
#'   symbols = c("KCS/USDT", "BTC/USDT", "KCS/BTC"),
#'   from = "2022-11-05 00:00:00",
#'   to = "2022-11-06 00:00:00",
#'   frequency = "1 hour"
#' )
#'
#' # quick check
#' prices
#'
#' @export

get_kucoin_prices <- function(symbols, from, to, frequency, delay = 0.5, retries = 3) {
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
get_klines <- function(symbol, startAt, endAt, type, retries) {
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

    # tidy the parsed data
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

# market metadata ---------------------------------------------------------

#' @title Get all symbols' most recent metadata
#' 
#' @param retries A `numeric` value to specify the number of retries in case of failure.
#'
#' @return A `data.table` containing some metadata
#'
#' @examples
#' # import library
#' library("kucoin")
#'
#' # get all symbols' most recent metadata
#' metadata <- get_kucoin_symbols()
#'
#' # quick check
#' metadata
#'
#' @export

get_kucoin_symbols <- function(retries = 3) {
    # get server response
    response <- httr::RETRY(
        verb = "GET",
        url = kucoin:::get_base_url(),
        path = kucoin:::get_paths("symbols"),
        times = retries
    )

    # analyze response
    response <- kucoin:::analyze_response(response)

    # parse json result
    parsed <- jsonlite::fromJSON(httr::content(response, "text", encoding = "UTF-8"))

    # tidy the parsed data
    results <- data.table::data.table(parsed$data, check.names = FALSE)

    # seems that the only thing that changes in colnames is they are made to snake_case
    # https://github.com/dereckdemezquita/kucoin/issues/1
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
