# File: ./R/impl_market_data_new.R

box::use(
    ./helpers_api[ process_kucoin_response ],
    ./utils[ build_query, get_base_url ],
    ./utils2
)

#' Get Klines market data allowed frequencies
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
#' @param freq A character string representing the frequency (e.g. "1min", "3min", etc.).
#' @export
check_allowed_frequency_str <- function(freq_str) {
    if (!freq_str %in% names(freq_to_second_map)) {
        rlang::abort(paste("Invalid frequency. Allowed values are:", paste(names(freq_to_second_map), collapse = ", ")))
    }
}

#' Check Allowed Frequency in Seconds
#' @param freq A numeric value representing the frequency in seconds.
#' @export
check_allowed_frequency_s <- function(freq_s) {
    if (!freq_s %in% unlist(freq_to_second_map)) {
        rlang::abort(paste("Invalid frequency in seconds. Allowed values are:", paste(unlist(freq_to_second_map), collapse = ", ")))
    }
}

#' Convert Frequency String to Seconds
#'
#' Given a frequency string (e.g. "1min", "3min", "1hour", etc.), this function returns
#' the corresponding duration in seconds.
#'
#' @param freq A character string representing the frequency. Allowed values are:
#'   "1min", "3min", "5min", "15min", "30min", "1hour", "2hour", "4hour", "6hour", "8hour",
#'   "12hour", "1day", "1week", "1month".
#'
#' @return A numeric value representing the duration in seconds.
#'
#' @examples
#' frequency_to_seconds("1min")  # returns 60
#'
#' @export
frequency_to_seconds <- function(freq) {
    check_allowed_frequency_str(freq)
    return(freq_to_second_map[[freq]])
}

#' Split a Time Range into Segments by Maximum Candle Count
#'
#' Given a start and end time (POSIXct) and the duration of a single candle (in seconds),
#' this function splits the overall time range into segments such that each segment covers at most
#' `max_candles` candles.
#' 
#' Note: The function extends the end of each segment by `overlap` seconds to ensure that the last candle
#' when fetching data segments make sure to deduplicate the data.
#'
#' @param from A POSIXct object representing the start time.
#' @param to A POSIXct object representing the end time.
#' @param candle_duration_s A numeric value; the duration of one candle in seconds.
#' @param max_candles Maximum number of candles per segment (default is 1500).
#' @param overlap Number of seconds to extend the end of each segment (default is 1).
#'
#' @return A data.table with two columns, `from` and `to`, where each row defines a segment.
#'
#' @examples
#' # For a 1min candle, a segment covers 1500 minutes.
#' from <- lubridate::now() - 2 * 3600
#' to <- lubridate::now()
#' candle_duration_s <- 60
#' split_time_range_by_candles(from, to, candle_duration_s)
#'
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

    from_s <- utils2$time_convert_to_kucoin_s(from)
    to_s <- utils2$time_convert_to_kucoin_s(to)
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
#' This asynchronous helper function retrieves a segment of candlestick (klines) data for a specified trading pair
#' from the KuCoin API. Because the API returns a maximum of 1500 candles per request, this function is intended to be
#' used to fetch data for a smaller segment of the total requested time range.
#'
#' **Workflow Overview:**
#'
#' 1. **Optional Delay:**  
#'    If a delay (in milliseconds) is specified via `delay_ms`, the function pauses for that duration before issuing
#'    the HTTP request. This delay can help in throttling concurrent requests to avoid rate limiting.
#'
#' 2. **Endpoint & Query Construction:**  
#'    Constructs the full API URL by appending the appropriate query parameters to the base URL. The query parameters include:
#'    - `symbol`: The trading pair (e.g., "BTC-USDT").
#'    - `type`: The candlestick interval (e.g., "15min").
#'    - `startAt`: The segment's start time converted to a UNIX timestamp in seconds.
#'    - `endAt`: The segment's end time converted to a UNIX timestamp in seconds.
#'
#' 3. **HTTP Request:**  
#'    Sends a GET request using `httr::RETRY()` with the specified number of retries and a timeout.
#'
#' 4. **Response Processing:**  
#'    Processes the API response using `process_kucoin_response()` to ensure it is valid, converts the raw data into a
#'    `data.table`, standardizes the column names, coerces numeric values, and adds a `datetime` column by converting the
#'    `timestamp`.
#'
#' **API Documentation:**  
#' [KuCoin Get Klines](https://www.kucoin.com/docs-new/rest/spot-trading/market-data/get-klines)
#'
#' @param base_url A character string representing the base URL for the KuCoin API. Defaults to `get_base_url()`.
#' @param symbol A character string representing the trading pair in KuCoin format (e.g., "BTC-USDT").
#' @param freq A character string specifying the candlestick interval. Allowed values include "1min", "3min", "5min", "15min",
#'             "30min", "1hour", "2hour", "4hour", "6hour", "8hour", "12hour", "1day", "1week", "1month". Default is "15min".
#' @param from A POSIXct object representing the start time of the segment. Defaults to one hour before the current time.
#' @param to A POSIXct object representing the end time of the segment. Defaults to the current time.
#' @param retries An integer specifying the number of retry attempts for the HTTP request in case of failure. Default is 3.
#' @param delay_ms A numeric value representing the delay in milliseconds before sending the request. Default is 0.
#'
#' @return A promise that resolves to a `data.table` containing the klines data for the specified segment.
#'         The resulting data.table includes:
#'         \describe{
#'           \item{timestamp}{Numeric, the raw timestamp in seconds.}
#'           \item{open}{Numeric, the opening price.}
#'           \item{close}{Numeric, the closing price.}
#'           \item{high}{Numeric, the highest price in the interval.}
#'           \item{low}{Numeric, the lowest price in the interval.}
#'           \item{volume}{Numeric, the trading volume.}
#'           \item{turnover}{Numeric, the trading turnover.}
#'           \item{datetime}{POSIXct, the converted datetime from the timestamp.}
#'         }
#'
#' @details
#' This function is a low-level helper intended to be used as part of a segmented approach for retrieving historical market data.
#' It does not perform authentication since the endpoint is public. Users should note that concurrent requests using this function
#' may lead to rate limiting; consider using the `delay_ms` parameter or sequential execution if necessary.
#'
#' @examples
#' \dontrun{
#'   # Retrieve a 15min segment of klines data for BTC-USDT over the past hour with a 100ms delay
#'   dt_segment <- await(fetch_klines_segment(
#'       symbol = "BTC-USDT",
#'       freq = "15min",
#'       from = lubridate::now() - 3600,
#'       to = lubridate::now(),
#'       retries = 3,
#'       delay_ms = 100
#'   ))
#'   print(dt_segment)
#' }
#'
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
        startAt = utils2$time_convert_to_kucoin_s(from),
        endAt   = utils2$time_convert_to_kucoin_s(to)
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

################################################################################
# Main Implementation: get_klines_impl
################################################################################
#' Retrieve Historical Klines Data
#'
#' This asynchronous function retrieves historical candlestick (klines) data for a single trading pair from the KuCoin API.
#' To overcome the API limitation of returning a maximum of 1500 candles per request, the function automatically splits the
#' requested time range into segments (each covering at most 1500 candles), fetches each segment (either concurrently or sequentially),
#' and aggregates the results.
#'
#' **Workflow Overview:**
#'
#' 1. **Input Validation and Time Conversion:**  
#'    Converts the input `from` and `to` parameters to POSIXct objects and checks that `from` is earlier than `to`.
#'
#' 2. **Frequency Conversion:**  
#'    Converts the frequency string (e.g., "15min") to its corresponding duration in seconds using `frequency_to_seconds()`.
#'
#' 3. **Time Range Segmentation:**  
#'    Splits the overall time range into segments via `split_time_range_by_candles()`, ensuring that each segment covers no more than 1500 candles.
#'
#' 4. **Segment Data Retrieval:**  
#'    For each segment, creates a promise by calling `fetch_klines_segment()` to retrieve the corresponding data.
#'
#' 5. **Concurrent vs. Sequential Execution:**  
#'    - When `concurrent = TRUE` (default), all segment requests are executed concurrently using `promises::promise_all()`.
#'    - When `concurrent = FALSE`, the segment requests are executed sequentially.
#'
#' 6. **Aggregation:**  
#'    Once all segment requests complete, the resulting data.tables are combined using `data.table::rbindlist()` and sorted by `datetime`.
#'
#' **API Documentation:**  
#' [KuCoin Get Klines](https://www.kucoin.com/docs-new/rest/spot-trading/market-data/get-klines)
#'
#' @param base_url A character string representing the base URL for the KuCoin API. Defaults to the value returned by `get_base_url()`.
#' @param symbol A single character string representing the trading pair (e.g., "BTC-USDT").
#' @param freq A character string specifying the candlestick interval. Allowed values include "1min", "3min", "5min", "15min",
#'             "30min", "1hour", "2hour", "4hour", "6hour", "8hour", "12hour", "1day", "1week", "1month". Default is "15min".
#' @param from A POSIXct object specifying the start time for data retrieval. Defaults to 24 hours before the current time.
#' @param to A POSIXct object specifying the end time for data retrieval. Defaults to the current time.
#' @param concurrent A logical value indicating whether to execute segment requests concurrently. Default is TRUE.
#'                   **Caution:** Concurrent requests may trigger rate limiting.
#' @param delay_ms A numeric value representing the delay (in milliseconds) to insert before each request. This helps to control the request rate.
#' @param retries An integer specifying the number of retry attempts for each segment request. Default is 3.
#'
#' @return A promise that resolves to a `data.table` containing the aggregated historical klines data. The table includes:
#'         \describe{
#'           \item{timestamp}{Numeric, the raw timestamp in seconds.}
#'           \item{open}{Numeric, the opening price.}
#'           \item{close}{Numeric, the closing price.}
#'           \item{high}{Numeric, the highest price in the interval.}
#'           \item{low}{Numeric, the lowest price in the interval.}
#'           \item{volume}{Numeric, the trading volume.}
#'           \item{turnover}{Numeric, the trading turnover.}
#'           \item{datetime}{POSIXct, the timestamp converted to a datetime object.}
#'         }
#'
#' @details
#' This function is designed to fetch large ranges of historical market data by segmenting the request to comply with the KuCoin API limit of 1500 candles per request.
#' The user has the option to execute the segmented requests concurrently for speed or sequentially for increased safety against rate limiting.
#' Adjust the `delay_ms` parameter to insert a pause between requests if necessary.
#'
#' **Caution:**  
#' Using concurrent requests can lead to hitting API rate limits. Users should consider setting `concurrent = FALSE` or increasing `delay_ms` if they encounter rate limit errors.
#'
#' @examples
#' \dontrun{
#'   # Retrieve 15min candles for BTC-USDT for the last 24 hours concurrently:
#'   dt <- await(get_klines_impl(symbol = "BTC-USDT", freq = "15min"))
#'   print(dt)
#'
#'   # Retrieve the same data sequentially with a 200ms delay between requests:
#'   dt_seq <- await(get_klines_impl(symbol = "BTC-USDT", freq = "15min", concurrent = FALSE, delay_ms = 200))
#'   print(dt_seq)
#' }
#'
#' @export
get_klines_impl <- coro::async(function(
    base_url = get_base_url(),
    symbol = "BTC-USDT",
    freq = "15min",
    from = lubridate::now() - 24 * 3600,
    to = lubridate::now(),
    concurrent = TRUE,
    delay_ms = 0,
    retries = 3
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
