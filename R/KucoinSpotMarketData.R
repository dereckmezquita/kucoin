# File: ./R/KucoinSpotMarketData.R

box::use(
  impl = ./impl_market_data,
  ./utils[ get_api_keys ]
)

#' KucoinSpotMarketData Class for KuCoin Spot Market Data Endpoints
#'
#' The `KucoinSpotMarketData` class provides a user‑facing interface to interact with KuCoin's Spot Trading Market Data endpoints.
#' It leverages asynchronous programming (via the `coro` package) to send HTTP requests and process responses without blocking.
#' In particular, it exposes methods to retrieve candlestick (Kline) data for a specified trading pair.
#'
#' ## Available Methods
#'
#' - **get_klines(symbol, type, startAt, endAt, config):**  
#'   Retrieves candlestick (Kline) data for the specified trading pair and interval. The data is returned as a `data.table`
#'   with columns: `timestamp`, `open`, `close`, `high`, `low`, `volume`, and `turnover`.
#'
#' **Official Documentation:**  
#' [Get Klines](https://www.kucoin.com/docs-new/rest/spot-trading/market-data/get-klines)
#'
#' @md
#' @export
KucoinSpotMarketData <- R6::R6Class(
    "KucoinSpotMarketData",
    public = list(
        #' Get Klines (Candlestick Data)
        #'
        #' @description
        #' Retrieves candlestick (Kline) data for a specified trading symbol from the KuCoin Spot Trading API.
        #' This method sends a GET request to the `/api/v1/market/candles` endpoint with query parameters that define:
        #' - **symbol:** The trading pair (e.g., "BTC-USDT").
        #' - **type:** The candlestick interval (e.g., "1min", "15min", "1day", etc.).
        #' - **startAt:** (Optional) The start time in seconds (default is 0).
        #' - **endAt:** (Optional) The end time in seconds (default is 0).
        #'
        #' The response is processed into a `data.table` with the following columns:
        #' - **timestamp:** The start time of the candle (as a string).
        #' - **open:** The opening price.
        #' - **close:** The closing price.
        #' - **high:** The highest price.
        #' - **low:** The lowest price.
        #' - **volume:** The transaction volume.
        #' - **turnover:** The transaction turnover (monetary value).
        #'
        #' **API Endpoint:**  
        #' `GET https://api.kucoin.com/api/v1/market/candles`
        #'
        #' **Official Documentation:**  
        #' [Get Klines](https://www.kucoin.com/docs-new/rest/spot-trading/market-data/get-klines)
        #'
        #' ## Function Workflow
        #' 1. **Query String Construction:**  
        #'    Builds a query string from parameters using `build_query()`.
        #' 2. **URL Assembly:**  
        #'    Retrieves the base URL via `get_base_url()` and appends the endpoint and query string.
        #' 3. **HTTP Request:**  
        #'    Sends a GET request with a 3-second timeout.
        #' 4. **Response Processing:**  
        #'    Validates and extracts the "data" field from the JSON response using `process_kucoin_response()`.
        #' 5. **Data Conversion:**  
        #'    Converts the response (an array of arrays) into a `data.table` and assigns column names:
        #'    `timestamp`, `open`, `close`, `high`, `low`, `volume`, and `turnover`.
        #'
        #' @param symbol A character string representing the trading pair (e.g., "BTC-USDT").
        #' @param type A character string specifying the candlestick interval. Allowed values include:
        #'   "1min", "3min", "5min", "15min", "30min", "1hour", "2hour", "4hour", "6hour", "8hour", "12hour", "1day", "1week", "1month".
        #' @param startAt (Optional) An integer for the start time in seconds (default is 0).
        #' @param endAt (Optional) An integer for the end time in seconds (default is 0).
        #' @param config (Optional) A list of API configuration parameters. If not provided, the default base URL is used.
        #'
        #' @return A promise that resolves to a `data.table` with columns: `timestamp`, `open`, `close`, `high`, `low`, `volume`, `turnover`.
        #'
        #' @examples
        #' \dontrun{
        #'   marketData <- KucoinSpotMarketData$new()
        #'   dt <- await(marketData$get_klines("BTC-USDT", "1min", 1566703297, 1566789757))
        #'   print(dt)
        #' }
        #' @md
        get_klines = function(symbol, type, startAt = 0, endAt = 0, config = NULL) {
            return(impl$get_klines(symbol, type, startAt, endAt, config))
        }
  )
)
