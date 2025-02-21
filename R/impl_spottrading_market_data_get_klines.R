# File: ./R/impl_spottrading_market_data_get_klines.R

# box::use(
#     ./helpers_api[ process_kucoin_response ],
#     ./utils[ build_query, get_base_url ],
#     ./utils_time_convert_kucoin[ time_convert_from_kucoin, time_convert_to_kucoin ],
#     coro[async, await],
#     data.table[as.data.table, data.table, setnames, setcolorder, setorder, rbindlist],
#     httr[RETRY, timeout],
#     lubridate[as_datetime, now],
#     promises[promise_all],
#     rlang[abort]
# )

#' Get Klines Market Data Allowed Frequencies
#'
#' Provides a named list mapping KuCoin klines frequency strings to their equivalent durations in seconds.
#'
#' ### Workflow Overview
#' Not applicable (static data definition).
#'
#' ### API Endpoint
#' Not applicable (helper data structure).
#'
#' ### Usage
#' Utilised to reference valid frequency options and their durations for klines data retrieval functions.
#'
#' ### Official Documentation
#' Not directly tied to a specific endpoint; see KuCoin klines API documentation for supported intervals.
#'
#' @return Named list with frequency strings as names (e.g., `"1min"`) and durations in seconds as values (e.g., `60`).
#' @examples
#' \dontrun{
#' print(freq_to_second_map)
#' # Access a specific frequency
#' freq_to_second_map[["1hour"]]  # Returns 3600
#' }
#' @export
freq_to_second_map <- list(
    "1min"    = 60,
    "3min"    = 180,
    "5min"    = 300,
    "15min"   = 900,
    "30min"   = 1800,
    "1hour"   = 3600,
    "2hour"   = 7200,
    "4hour"   = 14400,
    "6hour"   = 21600,
    "8hour"   = 28800,
    "12hour"  = 43200,
    "1day"    = 86400,
    "1week"   = 604800,
    "1month"  = 2592000
)

#' Check Allowed Frequency String
#'
#' Validates whether a frequency string is among the allowed options for KuCoin klines data.
#'
#' ### Workflow Overview
#' 1. **Validation**: Checks if `freq_str` exists in `freq_to_second_map`, aborting with an error message listing allowed values if not.
#'
#' ### API Endpoint
#' Not applicable (helper validation function).
#'
#' ### Usage
#' Utilised to ensure frequency inputs for klines data retrieval are valid before API calls.
#'
#' ### Official Documentation
#' Not directly tied to a specific endpoint; see KuCoin klines API documentation for frequency options.
#'
#' @param freq_str Character string representing the frequency (e.g., `"1min"`, `"3min"`).
#' @return Invisible `NULL` if valid; aborts with an error if invalid.
#' @examples
#' \dontrun{
#' check_allowed_frequency_str("1min")  # Proceeds silently
#' check_allowed_frequency_str("10min") # Aborts with error
#' }
#' @importFrom rlang abort
#' @export
check_allowed_frequency_str <- function(freq_str) {
    if (!freq_str %in% names(freq_to_second_map)) {
        rlang::abort(paste("Invalid frequency. Allowed values are:", paste(names(freq_to_second_map), collapse = ", ")))
    }
}

#' Check Allowed Frequency in Seconds
#'
#' Validates whether a frequency duration in seconds corresponds to an allowed KuCoin klines interval.
#'
#' ### Workflow Overview
#' 1. **Validation**: Checks if `freq_s` matches any value in `freq_to_second_map`, aborting with an error message listing allowed values if not.
#'
#' ### API Endpoint
#' Not applicable (helper validation function).
#'
#' ### Usage
#' Utilised to confirm frequency durations in seconds are valid for klines data segmentation.
#'
#' ### Official Documentation
#' Not directly tied to a specific endpoint; see KuCoin klines API documentation for frequency durations.
#'
#' @param freq_s Numeric value representing the frequency in seconds.
#' @return Invisible `NULL` if valid; aborts with an error if invalid.
#' @examples
#' \dontrun{
#' check_allowed_frequency_s(60)   # Proceeds silently (matches "1min")
#' check_allowed_frequency_s(120)  # Aborts with error
#' }
#' @importFrom rlang abort
#' @export
check_allowed_frequency_s <- function(freq_s) {
    if (!freq_s %in% unlist(freq_to_second_map)) {
        rlang::abort(paste("Invalid frequency in seconds. Allowed values are:", paste(unlist(freq_to_second_map), collapse = ", ")))
    }
}

#' Convert Frequency String to Seconds
#'
#' Converts a KuCoin klines frequency string into its equivalent duration in seconds.
#'
#' ### Workflow Overview
#' 1. **Validation**: Calls `check_allowed_frequency_str()` to ensure `freq` is valid.
#' 2. **Conversion**: Retrieves the corresponding duration in seconds from `freq_to_second_map`.
#'
#' ### API Endpoint
#' Not applicable (helper conversion function).
#'
#' ### Usage
#' Utilised to translate frequency strings into seconds for time range calculations in klines data retrieval.
#'
#' ### Official Documentation
#' Not directly tied to a specific endpoint; see KuCoin klines API documentation for frequency mappings.
#'
#' @param freq Character string representing the frequency (e.g., `"1min"`, `"1hour"`). Allowed values: `"1min"`, `"3min"`, `"5min"`, `"15min"`, `"30min"`, `"1hour"`, `"2hour"`, `"4hour"`, `"6hour"`, `"8hour"`, `"12hour"`, `"1day"`, `"1week"`, `"1month"`.
#' @return Numeric value representing the duration in seconds.
#' @examples
#' \dontrun{
#' frequency_to_seconds("1min")   # Returns 60
#' frequency_to_seconds("1hour")  # Returns 3600
#' }
#' @export
frequency_to_seconds <- function(freq) {
    check_allowed_frequency_str(freq)
    return(freq_to_second_map[[freq]])
}

#' Split a Time Range into Segments by Maximum Candle Count
#'
#' Splits a time range into segments based on a maximum number of candles, given a candle duration in seconds, adding an overlap to ensure data continuity.
#'
#' ### Workflow Overview
#' 1. **Time Validation**: Ensures `from` is earlier than `to`, aborting if not.
#' 2. **Frequency Validation**: Confirms `candle_duration_s` is an allowed KuCoin frequency using `check_allowed_frequency_s()`.
#' 3. **Time Conversion**: Converts `from` and `to` to UNIX seconds with `time_convert_to_kucoin()`.
#' 4. **Segment Calculation**: Calculates segment start times based on `max_candles` and `candle_duration_s`, extending ends by `overlap` seconds, capped at `to`.
#' 5. **Output Construction**: Returns a `data.table` with `from` and `to` columns for each segment.
#'
#' ### API Endpoint
#' Not applicable (helper segmentation function).
#'
#' ### Usage
#' Utilised to divide large time ranges into manageable segments for fetching KuCoin klines data, respecting the API’s 1500-candle limit per request.
#'
#' ### Official Documentation
#' Not directly tied to a specific endpoint; supports KuCoin klines API pagination.
#'
#' @param from POSIXct object representing the start time.
#' @param to POSIXct object representing the end time.
#' @param candle_duration_s Numeric value; duration of one candle in seconds.
#' @param max_candles Integer; maximum number of candles per segment (default 1500).
#' @param overlap Numeric; seconds to extend each segment’s end for overlap (default 1).
#' @return `data.table` with columns `from` and `to`, each row defining a segment as POSIXct objects.
#' @examples
#' \dontrun{
#' from <- lubridate::now() - 2 * 3600
#' to <- lubridate::now()
#' candle_duration_s <- 60
#' segments <- split_time_range_by_candles(from = from, to = to, candle_duration_s = candle_duration_s)
#' print(segments)
#' }
#' @importFrom data.table data.table
#' @importFrom lubridate now
#' @importFrom rlang abort
#' @export
split_time_range_by_candles <- function(
    from,
    to,
    candle_duration_s,
    max_candles = 1500,
    overlap = 1
) {
    if (from >= to) {
        rlang::abort('"from" must be earlier than "to".')
    }
    check_allowed_frequency_s(candle_duration_s)

    from_s <- time_convert_to_kucoin(from, "s")
    to_s <- time_convert_to_kucoin(to, "s")
    total_seconds <- to_s - from_s

    segment_seconds <- max_candles * candle_duration_s
    if (total_seconds <= segment_seconds) {
        return(data.table::data.table(from = from, to = to))
    }
    # Generate segment start times
    seg_starts <- seq(from, to, by = segment_seconds)
    # For each segment, extend the end by 'overlap' seconds, but do not go past the overall 'to'
    seg_ends <- pmin(seg_starts + segment_seconds + overlap, to)
    return(data.table::data.table(from = seg_starts, to = seg_ends))
}

#' Fetch a Segment of Klines Data
#'
#' Retrieves a segment of candlestick (klines) data for a specified trading pair from the KuCoin API asynchronously, handling up to 1500 candles per request.
#'
#' ### Workflow Overview
#' 1. **Delay Application**: Pauses for `delay_ms` milliseconds if specified, to throttle requests.
#' 2. **Query Construction**: Builds the query string with `symbol`, `type` (frequency), `startAt`, and `endAt` using `build_query()`.
#' 3. **URL Assembly**: Combines `base_url` with the endpoint `/api/v1/market/candles` and query string.
#' 4. **API Request**: Sends a GET request with retries using `httr::RETRY()` and a 10-second timeout.
#' 5. **Response Processing**: Processes the response with `process_kucoin_response()`, converts data to a `data.table`, standardises column names, coerces numerics, adds a `datetime` column, and orders by `datetime`.
#'
#' ### API Endpoint
#' `GET https://api.kucoin.com/api/v1/market/candles`
#'
#' ### Usage
#' Utilised as a helper to fetch individual segments of klines data, typically within a broader segmented retrieval strategy.
#'
#' ### Official Documentation
#' [KuCoin Get Klines](https://www.kucoin.com/docs-new/rest/spot-trading/market-data/get-klines)
#'
#' @param base_url Character string; base URL for the KuCoin API. Defaults to `get_base_url()`.
#' @param symbol Character string; trading pair in KuCoin format (e.g., `"BTC-USDT"`).
#' @param freq Character string; candlestick interval (e.g., `"15min"`). Allowed values: `"1min"`, `"3min"`, `"5min"`, `"15min"`, `"30min"`, `"1hour"`, `"2hour"`, `"4hour"`, `"6hour"`, `"8hour"`, `"12hour"`, `"1day"`, `"1week"`, `"1month"`. Defaults to `"15min"`.
#' @param from POSIXct object; start time of the segment. Defaults to one hour before the current time.
#' @param to POSIXct object; end time of the segment. Defaults to the current time.
#' @param retries Integer; number of retry attempts for the HTTP request (default 3).
#' @param delay_ms Numeric; delay in milliseconds before sending the request (default 0).
#' @return Promise resolving to a `data.table` containing:
#'   - `datetime` (POSIXct): Converted timestamp.
#'   - `timestamp` (numeric): Raw timestamp in seconds.
#'   - `open` (numeric): Opening price.
#'   - `close` (numeric): Closing price.
#'   - `high` (numeric): Highest price in the interval.
#'   - `low` (numeric): Lowest price in the interval.
#'   - `volume` (numeric): Trading volume.
#'   - `turnover` (numeric): Trading turnover.
#' @examples
#' \dontrun{
#' main_async <- coro::async(function() {
#'   dt_segment <- await(fetch_klines_segment(
#'     symbol = "BTC-USDT",
#'     freq = "15min",
#'     from = lubridate::now() - 3600,
#'     to = lubridate::now(),
#'     retries = 3,
#'     delay_ms = 100
#'   ))
#'   print(dt_segment)
#' })
#' main_async()
#' while (!later::loop_empty()) later::run_now()
#' }
#' @importFrom coro async await
#' @importFrom httr RETRY timeout
#' @importFrom data.table as.data.table setnames setcolorder setorder
#' @importFrom lubridate as_datetime now
#' @export
fetch_klines_segment <- coro::async(function(
    base_url = get_base_url(),
    symbol,
    freq = "15min",
    from = lubridate::now() - 1 * 3600,
    to = lubridate::now(),
    retries = 3,
    delay_ms = 0
) {
    if (delay_ms > 0) Sys.sleep(delay_ms / 1000)

    endpoint <- "/api/v1/market/candles"
    method <- "GET"
    query <- list(
        symbol = symbol,
        type = freq,
        startAt = time_convert_to_kucoin(from, "s"),
        endAt   = time_convert_to_kucoin(to, "s")
    )
    qs <- build_query(query)

    url <- paste0(base_url, endpoint, qs)

    # Since this is a public endpoint, we use a simple GET with retries.
    response <- httr::RETRY(
        "GET",
        url = url,
        times = retries,
        httr::timeout(10)
    )
    response <- process_kucoin_response(response, url)
    data <- data.table::as.data.table(response$data)

    if (nrow(data) > 0) {
        old_cnames <- names(data)
        new_cnames <- c("timestamp", "open", "close", "high", "low", "volume", "turnover")
        data.table::setnames(data, old_cnames, new_cnames)
        data[, (1:7) := lapply(.SD, as.numeric), .SDcols = 1:7]
        data[, datetime := lubridate::as_datetime(timestamp)]
        data.table::setcolorder(data, c("datetime", new_cnames))
        data.table::setorder(data, datetime)
    }
    return(data)
})

#' Retrieve Historical Klines Data (Implementation)
#'
#' Retrieves historical candlestick (klines) data for a single trading pair from the KuCoin API asynchronously, segmenting requests to handle the 1500-candle limit per request.
#'
#' ### Workflow Overview
#' 1. **Input Validation**: Converts `from` and `to` to POSIXct and ensures `from` is earlier than `to`.
#' 2. **Frequency Conversion**: Translates `freq` to seconds using `frequency_to_seconds()`.
#' 3. **Segmentation**: Splits the time range into segments with `split_time_range_by_candles()`, each up to 1500 candles.
#' 4. **Segment Fetching**: Creates promises for each segment via `fetch_klines_segment()`.
#' 5. **Execution Mode**: Fetches segments concurrently with `promises::promise_all()` if `concurrent = TRUE`, or sequentially otherwise.
#' 6. **Aggregation**: Combines segment results with `data.table::rbindlist()`, removes duplicates by `timestamp`, and orders by `datetime`.
#'
#' ### API Endpoint
#' `GET https://api.kucoin.com/api/v1/market/candles` (via `fetch_klines_segment()`)
#'
#' ### Usage
#' Utilised to fetch and aggregate historical klines data for analysis, supporting both concurrent and sequential retrieval.
#'
#' ### Official Documentation
#' [KuCoin Get Klines](https://www.kucoin.com/docs-new/rest/spot-trading/market-data/get-klines)
#'
#' @param base_url Character string; base URL for the KuCoin API. Defaults to `get_base_url()`.
#' @param symbol Character string; trading pair (e.g., `"BTC-USDT"`). Defaults to `"BTC-USDT"`.
#' @param freq Character string; candlestick interval (e.g., `"15min"`). Allowed values: `"1min"`, `"3min"`, `"5min"`, `"15min"`, `"30min"`, `"1hour"`, `"2hour"`, `"4hour"`, `"6hour"`, `"8hour"`, `"12hour"`, `"1day"`, `"1week"`, `"1month"`. Defaults to `"15min"`.
#' @param from POSIXct object; start time for data retrieval. Defaults to 24 hours before now.
#' @param to POSIXct object; end time for data retrieval. Defaults to now.
#' @param concurrent Logical; whether to fetch segments concurrently (default `TRUE`). Caution: May trigger rate limits.
#' @param delay_ms Numeric; delay in milliseconds before each request (default 0).
#' @param retries Integer; number of retry attempts per segment request (default 3).
#' @param verbose Logical; whether to print progress messages (default `FALSE`).
#' @return Promise resolving to a `data.table` containing:
#'   - `datetime` (POSIXct): Converted timestamp.
#'   - `timestamp` (numeric): Raw timestamp in seconds.
#'   - `open` (numeric): Opening price.
#'   - `close` (numeric): Closing price.
#'   - `high` (numeric): Highest price in the interval.
#'   - `low` (numeric): Lowest price in the interval.
#'   - `volume` (numeric): Trading volume.
#'   - `turnover` (numeric): Trading turnover.
#' @examples
#' \dontrun{
#' main_async <- coro::async(function() {
#'   dt <- await(get_klines_impl(symbol = "BTC-USDT", freq = "15min"))
#'   print(dt)
#'   dt_seq <- await(get_klines_impl(
#'     symbol = "BTC-USDT",
#'     freq = "15min",
#'     concurrent = FALSE,
#'     delay_ms = 200
#'   ))
#'   print(dt_seq)
#' })
#' main_async()
#' while (!later::loop_empty()) later::run_now()
#' }
#' @importFrom coro async await
#' @importFrom data.table data.table rbindlist setorder
#' @importFrom lubridate as_datetime now
#' @importFrom promises promise_all
#' @importFrom rlang abort
#' @export
get_klines_impl <- coro::async(function(
    base_url = get_base_url(),
    symbol = "BTC-USDT",
    freq = "15min",
    from = lubridate::now() - 24 * 3600,
    to = lubridate::now(),
    concurrent = TRUE,
    delay_ms = 0,
    retries = 3,
    verbose = FALSE
) {
    from <- lubridate::as_datetime(from)
    to <- lubridate::as_datetime(to)
    if (from >= to) {
        rlang::abort('"from" must be earlier than "to".')
    }

    # Convert frequency string to seconds.
    candle_duration_s <- frequency_to_seconds(freq)

    # Split the overall time range into segments that return at most 1500 candles.
    segments_dt <- split_time_range_by_candles(from, to, candle_duration_s, max_candles = 1500)

    # Create a list of promises (one for each segment)
    fetch_promises <- lapply(1:nrow(segments_dt), function(idx) {
        if (verbose) cat("Fetching segment", idx, "of", nrow(segments_dt), "\n")
        curr_seg <- segments_dt[idx]
        return(fetch_klines_segment(
            base_url = base_url,
            symbol = symbol,
            freq = freq,
            from = curr_seg$from,
            to = curr_seg$to,
            retries = retries,
            delay_ms = delay_ms
        ))
    })

    if (concurrent) {
        # Execute all segment requests concurrently.
        result <- promises::promise_all(.list = fetch_promises)$then(function(datas) {
            combined <- data.table::rbindlist(datas, fill = TRUE)
            # Remove duplicates based on the timestamp (or datetime) column
            combined <- unique(combined, by = "timestamp")
            data.table::setorder(combined, datetime)
            return(combined)
        })
    } else {
        # Execute requests sequentially.
        combined <- data.table::data.table()
        for (p in fetch_promises) {
            dt_seg <- await(p)
            combined <- data.table::rbindlist(list(combined, dt_seg), fill = TRUE)
        }
        combined <- unique(combined, by = "timestamp")
        data.table::setorder(combined, datetime)
        result <- combined
    }

    return(result)
})
