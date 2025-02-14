# File: ./R/impl_market_data.R

box::use(
  ./helpers_api[ build_headers, process_kucoin_response ],
  ./utils[ build_query, get_base_url ]
)

check_klines_frequency <- function(freq) {
    allowed_freq <- c(
        "1min", "3min", "5min", "15min", "30min",
        "1hour", "2hour", "4hour", "6hour", "8hour", "12hour",
        "1day", "1week", "1month"
    )
    if (!freq %in% allowed_freq) {
        rlang::abort(paste("Invalid frequency. Allowed values are:", paste(allowed_freq, collapse = ", ")))
    }
}

#' Get Klines (Candlestick Data) Implementation
#'
#' This asynchronous function retrieves candlestick (Kline) data for a specified trading symbol from the KuCoin Spot Trading API.
#' It sends a GET request to the `/api/v1/market/candles` endpoint with query parameters that include:
#'
#' - **symbol:** The trading pair (e.g., "BTC-USDT").
#' - **frequency:** The candlestick interval. Allowed values are:
#'   `"1min"`, `"3min"`, `"5min"`, `"15min"`, `"30min"`, `"1hour"`, `"2hour"`, `"4hour"`, `"6hour"`, `"8hour"`, `"12hour"`, `"1day"`, `"1week"`, `"1month"`.
#' - **startAt:** A lubridate datetime object representing the start time.
#' - **endAt:** A lubridate datetime object representing the end time.
#'
#' The function converts the datetime objects to Unix timestamps (in seconds), validates that the provided frequency is allowed,
#' and then constructs the full URL for the API request. It sends the GET request, processes the JSON response, and converts the
#' resulting array of arrays into a data.table with the following column names:
#'
#' - **timestamp:** Start time of the candle (as a character string).
#' - **open:** Opening price.
#' - **close:** Closing price.
#' - **high:** Highest price.
#' - **low:** Lowest price.
#' - **volume:** Transaction volume.
#' - **turnover:** Transaction turnover.
#'
#' **API Endpoint:**  
#' `GET https://api.kucoin.com/api/v1/market/candles`
#'
#' **Official Documentation:**  
#' [Get Klines](https://www.kucoin.com/docs-new/rest/spot-trading/market-data/get-klines)
#'
#' ## Function Workflow
#'
#' 1. **Validate Frequency:**  
#'    Checks that the supplied frequency is one of the allowed values.
#'
#' 2. **Datetime Conversion:**  
#'    Converts the supplied lubridate datetime objects for `startAt` and `endAt` to Unix timestamps (in seconds).
#'
#' 3. **Query String Construction:**  
#'    Uses the `build_query()` helper to create a query string from the parameters.
#'
#' 4. **URL Assembly:**  
#'    Retrieves the base URL using `get_base_url()` and concatenates the endpoint and query string.
#'
#' 5. **HTTP Request:**  
#'    Sends a GET request to the constructed URL with a 3-second timeout.
#'
#' 6. **Response Processing:**  
#'    Uses `process_kucoin_response()` to validate and parse the JSON response.
#'
#' 7. **Data Conversion:**  
#'    Converts the raw response (an array of arrays) into a `data.table` and renames its columns.
#'
#' ## Parameters
#'
#' - **symbol:**  
#'   A character string representing the trading pair (e.g., "BTC-USDT").
#'
#' - **frequency:**  
#'   A character string specifying the candlestick interval. Allowed values are:  
#'   `"1min"`, `"3min"`, `"5min"`, `"15min"`, `"30min"`, `"1hour"`, `"2hour"`, `"4hour"`, `"6hour"`, `"8hour"`, `"12hour"`, `"1day"`, `"1week"`, `"1month"`.
#'
#' - **startAt:**  
#'   A lubridate datetime object representing the start time.
#'
#' - **endAt:**  
#'   A lubridate datetime object representing the end time.
#'
#' - **config:**  
#'   (Optional) A list containing API configuration parameters. If not provided, the default base URL is used.
#'
#' ## Return Value
#'
#' Returns a promise that resolves to a `data.table` with columns:  
#' `timestamp`, `open`, `close`, `high`, `low`, `volume`, and `turnover`.
#'
#' ## Example Usage
#'
#' ```r
#' \dontrun{
#'   library(lubridate)
#'   symbol <- "BTC-USDT"
#'   frequency <- "1min"
#'   start_time <- ymd_hms("2022-01-01 00:00:00", tz = "UTC")
#'   end_time   <- ymd_hms("2022-01-01 01:00:00", tz = "UTC")
#'
#'   coro::run(function() {
#'     dt <- await(get_klines(symbol, frequency, start_time, end_time))
#'     print(dt)
#'   })
#' }
#' ```
#'
#' @export
#' @md
get_klines_impl <- coro::async(function(symbol, frequency, startAt, endAt, config = NULL) {
    tryCatch({
        # Validate the frequency parameter.
        check_klines_frequency(frequency)
        
        # Convert lubridate datetime objects to Unix timestamps (in seconds).
        start_seconds <- as.integer(as.numeric(lubridate::as_datetime(startAt)))
        end_seconds   <- as.integer(as.numeric(lubridate::as_datetime(endAt)))
        
        # Use default configuration if not provided.
        base_url <- get_base_url()
        endpoint <- "/api/v1/market/candles"
        
        # Build query parameters.
        query <- list(
        symbol = symbol,
        type = frequency,
        startAt = start_seconds,
        endAt = end_seconds
        )
        qs <- build_query(query)
        full_endpoint <- paste0(endpoint, qs)
        url <- paste0(base_url, full_endpoint)
        
        # Send GET request with a timeout.
        response <- httr::GET(url, httr::timeout(3))
        
        # Process the response.
        raw_data <- process_kucoin_response(response, url)
        
        # Convert raw data (an array of arrays) into a data.table.
        dt <- data.table::as.data.table(raw_data)
        # Rename columns to: timestamp, open, close, high, low, volume, turnover.
        if (nrow(dt) > 0) {
        setnames(dt, c("timestamp", "open", "close", "high", "low", "volume", "turnover"))
        }
        return(dt)
    }, error = function(e) {
        rlang::abort(paste("Error in get_klines:", conditionMessage(e)))
    })
})
