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
        
  )
)
