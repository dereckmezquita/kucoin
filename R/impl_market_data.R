# File: ./R/impl_market_data_new.R

box::use(
    ./helpers_api[ process_kucoin_response ],
    ./utils[ build_query, get_base_url ],
    ./utils2[ time_convert_from_kucoin_ms, time_convert_to_kucoin_ms ]
)

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
    lookup <- list(
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
        "1month"  = 2592000  # approximate
    )
    if (!freq %in% names(lookup)) {
        rlang::abort(paste("Invalid frequency. Allowed values are:", paste(names(lookup), collapse = ", ")))
    }
    return(lookup[[freq]])
}

#' Split a Time Range into Segments by Maximum Candle Count
#'
#' Given a start and end time (POSIXct) and the duration of a single candle (in seconds),
#' this function splits the overall time range into segments such that each segment covers at most
#' `max_candles` candles.
#'
#' @param from A POSIXct object representing the start time.
#' @param to A POSIXct object representing the end time.
#' @param candle_duration A numeric value; the duration of one candle in seconds.
#' @param max_candles Maximum number of candles per segment (default is 1500).
#'
#' @return A data.table with two columns, `from` and `to`, where each row defines a segment.
#'
#' @examples
#' # For a 1min candle, a segment covers 1500 minutes.
#' split_time_range_by_candles(Sys.time() - 2*3600, Sys.time(), 60)
#'
#' @export
split_time_range_by_candles <- function(from, to, candle_duration, max_candles = 1500) {
    total_seconds <- as.numeric(difftime(to, from, units = "secs"))
    segment_seconds <- max_candles * candle_duration
    if (total_seconds <= segment_seconds) {
        return(data.table::data.table(from = from, to = to))
    }
    seg_starts <- seq(from, to, by = segment_seconds)
    seg_ends <- pmin(seg_starts + segment_seconds, to)
    return(data.table::data.table(from = seg_starts, to = seg_ends))
}

#' Fetch Candlestick Data for a Time Segment
#'
#' This asynchronous helper function sends a GET request for a given time segment to the KuCoin klines endpoint.
#' Note that this endpoint is public and requires no authentication.
#'
#' @param symbol A character string representing the symbol (e.g. "BTC-USDT"). Must be in KuCoin format.
#' @param type A character string representing the candle interval; allowed frequencies:
#'    "1min", "3min", "5min", "15min", "30min", "1hour", "2hour", "4hour",
#'    "6hour", "8hour", "12hour", "1day", "1week", "1month".
#' @param seg_from A POSIXct object representing the start time for this segment.
#' @param seg_to A POSIXct object representing the end time for this segment.
#' @param base_url A character string for the base URL (default is obtained via `get_base_url()`).
#' @param retries Number of retries in case of request failure (default is 3).
#' @param delay_ms Optional delay (in milliseconds) before sending this request (default is 0).
#'
#' @return A promise that resolves to a data.table with the candlestick data for that segment.
#'
#' @details
#' The returned data.table has the following columns:
#' - `timestamp`: The time stamp (as a numeric value in seconds).
#' - `open`: Opening price.
#' - `close`: Closing price.
#' - `high`: Highest price.
#' - `low`: Lowest price.
#' - `volume`: Trading volume.
#' - `turnover`: Turnover.
#' - `datetime`: POSIXct object derived from `timestamp`.
#'
#' @examples
#' \dontrun{
#'   # Fetch klines for a 1-hour segment:
#'   fetch_klines_segment("BTC-USDT", "1min", lubridate::now() - 3600, lubridate::now())
#' }
#'
#' @export
fetch_klines_segment <- coro::async(function(
    symbol,
    type,
    seg_from,
    seg_to,
    base_url = get_base_url(),
    retries = 3,
    delay_ms = 0
) {
    if (delay_ms > 0) Sys.sleep(delay_ms / 1000)

    endpoint <- "/api/v1/market/candles"
    method <- "GET"
    qs <- build_query(list(
        symbol = symbol,
        type = type,
        startAt = as.integer(as.numeric(seg_from)),
        endAt   = as.integer(as.numeric(seg_to))
    ))
    url <- paste0(base_url, get_paths("klines"), qs)

    # Since this is a public endpoint, we use a simple GET with retries.
    response <- httr::RETRY(
        "GET",
        url = base_url,
        path = get_paths("klines"),
        query = query_params,
        times = retries,
        httr::timeout(10)
    )
    response <- process_kucoin_response(response, url)
    dt <- data.table::as.data.table(response$data)

    if (nrow(dt) > 0) {
        colnames(dt) <- c("timestamp", "open", "close", "high", "low", "volume", "turnover")
        dt[, (1:7) := lapply(.SD, as.numeric), .SDcols = 1:7]
        dt[, datetime := lubridate::as_datetime(timestamp)]
        data.table::setorder(dt, datetime)
    }
    return(dt)
})

################################################################################
# Main Implementation: get_klines_impl
################################################################################
#' Get Historical Klines Data (Candlestick Data)
#'
#' This asynchronous function retrieves historical candlestick data for a single symbol from the KuCoin API.
#' Because the API limits responses to 1,500 candles per request, the overall time range is split into segments.
#' These segment requests can be executed concurrently or sequentially (controlled by the `concurrent` parameter).
#'
#' @param symbol A character string representing the trading pair in KuCoin format (e.g., "BTC-USDT").
#' @param type A character string representing the candle interval (e.g., "1min", "3min", "5min", etc.).
#' @param startAt A POSIXct datetime object representing the start of the desired time range. If not provided, defaults to 24 hours before the current time.
#' @param endAt A POSIXct datetime object representing the end of the desired time range. If not provided, defaults to the current time.
#' @param concurrent A logical indicating whether to execute segment requests concurrently (default is TRUE). Setting to FALSE will execute them sequentially.
#' @param delay_ms A numeric value specifying a delay in milliseconds to apply before each segment request (default is 0). Use this to mitigate rate‐limiting.
#' @param retries A numeric value indicating the number of retries per request in case of failures (default is 3).
#' @param base_url A character string representing the base URL for the KuCoin API. Defaults to `get_base_url()`.
#'
#' @return A promise that resolves to a data.table containing the aggregated candlestick data.
#'
#' @details
#' The returned data.table contains the following columns:
#' - `timestamp`: The raw timestamp (in seconds) from the API.
#' - `open`: The opening price.
#' - `close`: The closing price.
#' - `high`: The highest price.
#' - `low`: The lowest price.
#' - `volume`: The trading volume.
#' - `turnover`: The turnover.
#' - `datetime`: A POSIXct datetime converted from the timestamp.
#'
#' **Caution:**
#' Concurrent requests may trigger rate limits. Use the `delay_ms` parameter to slow down requests or set
#' `concurrent = FALSE` to run them sequentially.
#'
#' **Official Documentation:**
#' [KuCoin Get Klines](https://www.kucoin.com/docs-new/rest/spot-trading/market-data/get-klines)
#'
#' @examples
#' \dontrun{
#'   # Retrieve 1-minute candles for BTC-USDT for the last 24 hours concurrently:
#'   dt <- await(get_klines_impl("BTC-USDT", "1min"))
#'   print(dt)
#'
#'   # Or run sequentially with a 200ms delay between requests:
#'   dt_seq <- await(get_klines_impl("BTC-USDT", "1min", concurrent = FALSE, delay_ms = 200))
#'   print(dt_seq)
#' }
#'
#' @export
get_klines_impl <- coro::async(function(symbol, type, startAt = NULL, endAt = NULL, concurrent = TRUE, delay_ms = 0, retries = 3, base_url = get_base_url()) {
  # Validate required parameters
  if (missing(symbol) || !is.character(symbol) || length(symbol) != 1) {
    rlang::abort('Argument "symbol" must be a single character string in KuCoin format (e.g., "BTC-USDT").')
  }
  if (missing(type) || !is.character(type) || length(type) != 1) {
    rlang::abort('Argument "type" must be a single character string representing the candle interval (e.g., "1min").')
  }
  
  # Ensure startAt and endAt are POSIXct; default to last 24 hours if not provided.
  if (is.null(startAt)) startAt <- Sys.time() - 24*3600
  if (is.null(endAt)) endAt <- Sys.time()
  startAt <- lubridate::as_datetime(startAt)
  endAt <- lubridate::as_datetime(endAt)
  if (startAt >= endAt) {
    rlang::abort('"startAt" must be earlier than "endAt".')
  }
  
  # Convert frequency string to seconds.
  candle_duration <- frequency_to_seconds(type)
  
  # Split the overall time range into segments that return at most 1500 candles.
  segments <- split_time_range_by_candles(startAt, endAt, candle_duration, max_candles = 1500)
  
  # Create a list of promises (one for each segment)
  fetch_promises <- lapply(1:nrow(segments), function(i) {
    seg <- segments[i]
    fetch_klines_segment(symbol, type, seg$from, seg$to, base_url, retries, delay_ms)
  })
  
  if (concurrent) {
    # Execute all segment requests concurrently.
    result <- promises::when_all(.list = fetch_promises)$then(function(results_list) {
      combined <- data.table::rbindlist(results_list, fill = TRUE)
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
    data.table::setorder(combined, datetime)
    result <- combined
  }
  
  return(result)
})