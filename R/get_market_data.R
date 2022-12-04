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
#' # import library
#' library("kucoin")
#'
#' # get one pair of symbol prices
#' prices <- get_market_data(
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
#' prices <- get_market_data(
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
