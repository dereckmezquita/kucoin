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

get_market_data <- function(symbols, from, to, frequency, delay = 0, retries = 3) {
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
get_klines <- function(symbol, startAt, endAt, type, retries = 3) {
    
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
