# File: ./R/KucoinSpotMarketData.R

box::use(
    impl = ./impl_market_data,
    ./utils[ get_base_url ]
)

#' KucoinSpotMarketData Class for KuCoin Spot Market Data Endpoints
#'
#' The `KucoinSpotMarketData` class provides a user‑facing asynchronous interface to interact with KuCoin's
#' Spot Trading Market Data endpoints. In particular, it exposes a method to retrieve historical candlestick (klines)
#' data for a given trading pair. The class leverages segmented requests to overcome the KuCoin API limit of 1500 candles
#' per request. Users have the option to execute requests concurrently for speed or sequentially for increased safety
#' against rate limiting.
#'
#' **Usage:**
#'
#' Create an instance of the class using the default base URL (determined by `get_base_url()`) or supply your own.
#'
#' @section Methods:
#'
#' - **initialize(base_url):** Initializes the object with the provided base URL.
#' - **get_klines(symbol, freq, from, to, concurrent, delay_ms, retries):** Retrieves historical klines data for a single
#'   trading pair by splitting the requested time range into segments and aggregating the results.
#'
#' **Official Documentation:**  
#' [KuCoin Get Klines](https://www.kucoin.com/docs-new/rest/spot-trading/market-data/get-klines)
#'
#' @md
#' @export
KucoinSpotMarketData <- R6::R6Class(
    "KucoinSpotMarketData",
    public = list(
        base_url = NULL,
        initialize = function(base_url = get_base_url()) {
            self$base_url <- base_url
        },
        #' Retrieve Historical Klines Data
        #'
        #' This asynchronous method retrieves historical candlestick (klines) data for a single trading pair from the KuCoin API.
        #' To overcome the API limit of returning a maximum of 1500 candles per request, the method automatically splits the
        #' requested time range into segments, each covering at most 1500 candles. For each segment, the data is fetched using
        #' an asynchronous helper function and then aggregated into a single `data.table`.
        #' 
        #' **Workflow Overview:**
        #' 1. **Input Validation:**  
        #'    The method converts the input `from` and `to` parameters into POSIXct objects and checks that `from` is earlier than `to`.
        #' 
        #' 2. **Frequency Conversion:**  
        #'    The provided frequency string (e.g., "15min") is converted to its corresponding duration in seconds via `frequency_to_seconds()`.
        #' 
        #' 3. **Time Range Segmentation:**  
        #'    The overall time range is split into segments using `split_time_range_by_candles()`, ensuring that each segment
        #'    covers no more than 1500 candles.
        #' 
        #' 4. **Segment Data Retrieval:**  
        #'    For each time segment, an asynchronous request is issued via `fetch_klines_segment()` to retrieve the data.
        #' 
        #' 5. **Concurrent vs. Sequential Execution:**  
        #'    - When `concurrent = TRUE` (default), all segment requests are executed concurrently using `promises::promise_all()`.
        #'    - When `concurrent = FALSE`, the requests are executed sequentially.
        #' 
        #' 6. **Aggregation:**  
        #'    Once all segment requests complete, the resulting data.tables are combined using `data.table::rbindlist()` and
        #'    sorted by the `datetime` column.
        #' 
        #' **Caution:**  
        #' Concurrent requests may trigger rate limiting. Consider setting `concurrent = FALSE` or increasing `delay_ms` if you
        #' encounter rate limit errors.
        #' 
        #' **API Documentation:**  
        #' [KuCoin Get Klines](https://www.kucoin.com/docs-new/rest/spot-trading/market-data/get-klines)
        #' 
        #' @param symbol A character string representing the trading pair (e.g., "BTC-USDT").
        #' @param freq A character string specifying the candlestick interval. Allowed values are:
        #'   "1min", "3min", "5min", "15min", "30min", "1hour", "2hour", "4hour", "6hour", "8hour", "12hour", "1day", "1week", "1month".
        #'   Default is "15min".
        #' @param from A POSIXct object specifying the start time for data retrieval. Defaults to 24 hours before the current time.
        #' @param to A POSIXct object specifying the end time for data retrieval. Defaults to the current time.
        #' @param concurrent A logical indicating whether to execute segment requests concurrently. Default is TRUE.
        #' @param delay_ms A numeric value specifying the delay (in milliseconds) to insert before each segment request.
        #'                 This option helps control the request rate and mitigate rate limiting. Default is 0.
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
        #' This method internally uses the following helper functions:
        #' - `frequency_to_seconds()`: Converts a frequency string to its equivalent duration in seconds.
        #' - `split_time_range_by_candles()`: Splits the time range into segments to ensure each API request returns at most 1500 candles.
        #' - `fetch_klines_segment()`: Retrieves klines data for a given time segment using an asynchronous GET request.
        #' - `promises::promise_all()`: When running concurrently, waits for all segment promises to fulfill.
        #'
        #' @examples
        #' \dontrun{
        #'   # Create an instance of KucoinSpotMarketData
        #'   spot_data <- KucoinSpotMarketData$new()
        #'
        #'   # Retrieve 15-minute klines for BTC-USDT for the last 24 hours concurrently:
        #'   klines_data <- await(spot_data$get_klines(
        #'       symbol = "BTC-USDT",
        #'       freq = "15min",
        #'       from = lubridate::now() - 24*3600,
        #'       to = lubridate::now(),
        #'       concurrent = TRUE,
        #'       delay_ms = 0,
        #'       retries = 3
        #'   ))
        #'   print(klines_data)
        #'
        #'   # Retrieve the same data sequentially with a 200ms delay between requests:
        #'   klines_data_seq <- await(spot_data$get_klines(
        #'       symbol = "BTC-USDT",
        #'       freq = "15min",
        #'       concurrent = FALSE,
        #'       delay_ms = 200
        #'   ))
        #'   print(klines_data_seq)
        #' }
        #'
        #' @export
        get_klines = function(
            symbol,
            freq = "15min",
            from = lubridate::now() - 24 * 3600, 
            to = lubridate::now(),
            concurrent = TRUE,
            delay_ms = 0,
            retries = 3
        ) {
            return(impl$get_klines_impl(
                base_url = self$base_url,
                symbol = symbol,
                freq = freq,
                from = from,
                to = to,
                concurrent = concurrent,
                delay_ms = delay_ms,
                retries = retries
            ))
        }
    )
)
