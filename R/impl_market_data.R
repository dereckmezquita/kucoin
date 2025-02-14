# File: ./R/impl_market_data.R

box::use(
  ./helpers_api[ build_headers, process_kucoin_response ],
  ./utils[ build_query, get_base_url ]
)

#' Get Klines (Candlestick Data) Implementation
#'
#' This asynchronous function retrieves candlestick (Kline) data for a specified trading symbol from the KuCoin Spot Trading API.
#' It sends a GET request to the `/api/v1/market/candles` endpoint with query parameters that specify the symbol, interval type,
#' and an optional time range (in seconds). The endpoint returns at most 1500 candlesticks per request; to obtain more data, you
#' must paginate by time. Note that if there are no trades during a particular interval, no candlestick data will be published.
#'
#' ## Endpoint Details
#'
#' **API Endpoint:**  
#' `GET https://api.kucoin.com/api/v1/market/candles`
#'
#' **Purpose:**  
#' This endpoint provides historical candlestick (Kline) data for the specified trading pair and interval. Each candlestick represents:
#'
#' - **timestamp:** Start time of the candle (as a string).
#' - **open:** Opening price.
#' - **close:** Closing price.
#' - **high:** Highest price.
#' - **low:** Lowest price.
#' - **volume:** Transaction volume (the sum of traded amounts).
#' - **turnover:** Transaction turnover (the monetary value of traded volume).
#'
#' **Official Documentation:**  
#' [Get Klines](https://www.kucoin.com/docs-new/rest/spot-trading/market-data/get-klines)
#'
#' ## Function Workflow
#'
#' 1. **Query String Construction:**  
#'    The function builds a query string using the \code{build_query()} utility with the following parameters:
#'    - \code{symbol} (e.g., "BTC-USDT")
#'    - \code{type} (e.g., "1min", "15min", "1day", etc.)
#'    - \code{startAt} (optional; start time in seconds, default is 0)
#'    - \code{endAt} (optional; end time in seconds, default is 0)
#'
#' 2. **URL Assembly:**  
#'    Retrieves the base URL using \code{get_base_url()} from the provided configuration and appends the endpoint and query string.
#'
#' 3. **HTTP Request:**  
#'    Sends a GET request to the constructed URL with a timeout of 3 seconds.
#'
#' 4. **Response Processing:**  
#'    Processes the response using \code{process_kucoin_response()} to validate and extract the "data" field from the JSON response.
#'
#' 5. **Data Conversion:**  
#'    Converts the raw response (an array of arrays) into a \code{data.table} and assigns column names.
#'
#' ## Parameters
#'
#' - **symbol:**  
#'   A character string representing the trading pair (e.g., "BTC-USDT").
#'
#' - **type:**  
#'   A character string representing the candlestick interval. Allowed values include:
#'   \code{"1min", "3min", "5min", "15min", "30min", "1hour", "2hour", "4hour", "6hour", "8hour", "12hour", "1day", "1week", "1month"}.
#'
#' - **startAt:**  
#'   (Optional) An integer representing the start time in seconds (default is 0).
#'
#' - **endAt:**  
#'   (Optional) An integer representing the end time in seconds (default is 0).
#'
#' - **config:**  
#'   (Optional) A list containing API configuration parameters. If not provided, the default base URL is used.
#'
#' ## Return Value
#'
#' Returns a promise that resolves to a \code{data.table} containing the candlestick data with the following columns:
#' - \code{timestamp}: Start time of the candle (as a character string).
#' - \code{open}: Opening price.
#' - \code{close}: Closing price.
#' - \code{high}: Highest price.
#' - \code{low}: Lowest price.
#' - \code{volume}: Transaction volume.
#' - \code{turnover}: Transaction turnover.
#'
#' ## Example Usage
#'
#' ```r
#' \dontrun{
#'   symbol <- "BTC-USDT"
#'   type <- "1min"
#'   startAt <- 1566703297  # Example start time (in seconds)
#'   endAt <- 1566789757    # Example end time (in seconds)
#'
#'   coro::run(function() {
#'     dt_klines <- await(get_klines(symbol, type, startAt, endAt))
#'     print(dt_klines)
#'   })
#' }
#' ```
#'
#' @export
#' @md
get_klines <- coro::async(function(symbol, type, startAt = 0, endAt = 0, config = NULL) {
    tryCatch({
        # Use default configuration if not provided.
        if (is.null(config)) {
            config <- list(base_url = "https://api.kucoin.com")
        }
        base_url <- get_base_url(config)
        endpoint <- "/api/v1/market/candles"
        query <- list(
            symbol = symbol,
            type = type,
            startAt = startAt,
            endAt = endAt
        )
        qs <- build_query(query)
        full_endpoint <- paste0(endpoint, qs)
        url <- paste0(base_url, full_endpoint)
        response <- httr::GET(url, httr::timeout(3))
        raw_data <- process_kucoin_response(response, url)

        # Convert the raw data (an array of arrays) into a data.table.
        dt <- data.table::as.data.table(raw_data)
        # Assign column names: timestamp, open, close, high, low, volume, turnover.
        if (nrow(dt) > 0) {
            setnames(dt, c("timestamp", "open", "close", "high", "low", "volume", "turnover"))
        }
        return(dt)
    }, error = function(e) {
        rlang::abort(paste("Error in get_klines:", conditionMessage(e)))
    })
})
