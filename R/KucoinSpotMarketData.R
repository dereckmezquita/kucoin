# File: ./R/KucoinSpotMarketData.R

# box::use(
#     ./impl_spottrading_market_data[
#         get_announcements_impl,
#         get_currency_impl,
#         get_all_currencies_impl,
#         get_symbol_impl,
#         get_all_symbols_impl,
#         get_ticker_impl,
#         get_all_tickers_impl,
#         get_trade_history_impl,
#         get_part_orderbook_impl,
#         get_full_orderbook_impl,
#         get_24hr_stats_impl,
#         get_market_list_impl
#     ],
#     ./impl_spottrading_market_data_get_klines[
#         get_klines_impl
#     ],
#     ./utils[get_api_keys, get_base_url]
# )

#' KucoinSpotMarketData Class for KuCoin Spot Market Data Retrieval
#'
#' The `KucoinSpotMarketData` class provides an asynchronous interface for retrieving spot market data from KuCoin.
#' It leverages the `coro` package for non-blocking HTTP requests, returning promises that resolve to `data.table` objects
#' (or character vectors for simple lists). This class supports a comprehensive set of market data endpoints, including
#' announcements, historical klines, currency details, trading symbols, tickers, trade history, orderbooks, 24-hour stats,
#' and market lists.
#'
#' ### Purpose and Scope
#' This class is designed to facilitate market analysis and monitoring in the KuCoin Spot trading ecosystem, covering:
#' - **Market News**: Announcements for updates and events.
#' - **Historical Data**: Klines for technical analysis.
#' - **Asset Metadata**: Currency and symbol details for configuration.
#' - **Real-Time Data**: Tickers, trade history, and orderbooks for live market insights.
#' - **Market Overview**: 24-hour stats and market lists for broad monitoring.
#'
#' ### Usage
#' Utilised by traders and developers to programmatically access KuCoin Spot market data. The class is initialized with API
#' credentials (required only for `get_full_orderbook`), automatically loaded via `get_api_keys()` if not provided, and a
#' base URL from `get_base_url()`. Most endpoints are public, except `get_full_orderbook`, which requires authentication.
#' For detailed endpoint information, parameters, and response schemas, refer to the official [KuCoin API Documentation](https://www.kucoin.com/docs-new).
#'
#' ### Official Documentation
#' [KuCoin API Documentation - Spot Market Data](https://www.kucoin.com/docs-new/rest/spot-trading/market-data/introduction)
#'
#' @section Methods:
#' - **initialize(keys, base_url):** Initialises the object with API credentials and base URL.
#' - **get_announcements(query, page_size, max_pages):** Retrieves paginated market announcements.
#' - **get_klines(symbol, freq, from, to, concurrent, delay_ms, retries):** Fetches historical klines data with segmentation.
#' - **get_currency(currency, chain):** Retrieves details for a specific currency.
#' - **get_all_currencies():** Retrieves details for all available currencies.
#' - **get_symbol(symbol):** Retrieves details for a specific trading symbol.
#' - **get_all_symbols(market):** Retrieves all trading symbols, optionally filtered by market.
#' - **get_ticker(symbol):** Retrieves Level 1 ticker data for a symbol.
#' - **get_all_tickers():** Retrieves ticker data for all trading pairs.
#' - **get_trade_history(symbol):** Retrieves recent trade history for a symbol.
#' - **get_part_orderbook(symbol, size):** Retrieves partial orderbook data (20 or 100 levels).
#' - **get_full_orderbook(symbol):** Retrieves full orderbook data (authenticated).
#' - **get_24hr_stats(symbol):** Retrieves 24-hour market statistics for a symbol.
#' - **get_market_list():** Retrieves a list of all trading markets.
#'
#' @examples
#' \dontrun{
#' # Comprehensive example demonstrating key methods
#' main_async <- coro::async(function() {
#'   # Initialise the class
#'   market <- KucoinSpotMarketData$new()
#'
#'   # Get new listings announcements
#'   announcements <- await(market$get_announcements(list(annType = "new-listings"), page_size = 10, max_pages = 2))
#'   print("New Listings Announcements:"); print(announcements)
#'
#'   # Get 48 hours of hourly klines
#'   klines <- await(market$get_klines("BTC-USDT", "1hour", lubridate::now() - lubridate::dhours(48), lubridate::now()))
#'   print("BTC-USDT Klines:"); print(klines)
#'
#'   # Get ticker data
#'   ticker <- await(market$get_ticker("BTC-USDT"))
#'   print("BTC-USDT Ticker:"); print(ticker)
#'
#'   # Get full orderbook (authenticated)
#'   orderbook <- await(market$get_full_orderbook("BTC-USDT"))
#'   print("BTC-USDT Full Orderbook:"); print(orderbook)
#'
#'   # Get 24-hour stats
#'   stats <- await(market$get_24hr_stats("BTC-USDT"))
#'   print("BTC-USDT 24hr Stats:"); print(stats)
#' })
#' main_async()
#' while (!later::loop_empty()) later::run_now()
#' }
#'
#' @importFrom R6 R6Class
#' @export
KucoinSpotMarketData <- R6::R6Class(
    "KucoinSpotMarketData",
    public = list(
        #' @field keys List containing KuCoin API keys (`api_key`, `api_secret`, `api_passphrase`, `key_version`).
        keys = NULL,
        #' @field base_url Character string representing the base URL for KuCoin API endpoints.
        base_url = NULL,

        #' Initialise a New KucoinSpotMarketData Object
        #'
        #' ### Description
        #' Initialises a `KucoinSpotMarketData` object with API credentials and a base URL for retrieving Spot market data
        #' asynchronously. Credentials are only required for authenticated endpoints (e.g., `get_full_orderbook`).
        #'
        #' ### Workflow Overview
        #' 1. **Credential Assignment**: Sets `self$keys` to the provided or default API keys from `get_api_keys()`.
        #' 2. **URL Assignment**: Sets `self$base_url` to the provided or default base URL from `get_base_url()`.
        #'
        #' ### API Endpoint
        #' Not applicable (initialisation method).
        #'
        #' ### Usage
        #' Creates an instance for accessing KuCoin Spot market data, with most methods being public except where authentication is noted.
        #'
        #' ### Official Documentation
        #' [KuCoin API Authentication](https://www.kucoin.com/docs-new/rest/introduction#authentication)
        #'
        #' ### Automated Trading Usage
        #' - **Data Foundation**: Use as the primary market data source in your trading bot, feeding real-time and historical data into strategy engines.
        #' - **Secure Setup**: Provide explicit `keys` for authenticated methods or rely on `get_api_keys()` for portability across environments.
        #' - **Lifecycle**: Instantiate once and reuse across trading cycles, pairing with order management classes for a complete system.
        #'
        #' @param keys List containing API configuration parameters from `get_api_keys()`, including:
        #'   - `api_key`: Character string; your KuCoin API key.
        #'   - `api_secret`: Character string; your KuCoin API secret.
        #'   - `api_passphrase`: Character string; your KuCoin API passphrase.
        #'   - `key_version`: Character string; API key version (e.g., `"2"`).
        #'   Defaults to `get_api_keys()`.
        #' @param base_url Character string representing the base URL for the API. Defaults to `get_base_url()`.
        #'
        #' @return A new instance of the `KucoinSpotMarketData` class.
        initialize = function(keys = get_api_keys(), base_url = get_base_url()) {
            self$keys <- keys
            self$base_url <- base_url
        },

        #' Get Announcements
        #'
        #' ### Description
        #' Retrieves paginated market announcements asynchronously via a GET request to `/api/v3/announcements`.
        #' Calls `get_announcements_impl`.
        #'
        #' ### Workflow Overview
        #' 1. **Query Setup**: Merges defaults with user `query` (e.g., `annType = "latest-announcements"`).
        #' 2. **Pagination**: Fetches pages up to `max_pages` with `page_size` results each.
        #' 3. **Response**: Aggregates into a `data.table` of announcement details.
        #'
        #' ### API Endpoint
        #' `GET https://api.kucoin.com/api/v3/announcements`
        #'
        #' ### Usage
        #' Utilised to monitor KuCoin news, such as new listings or maintenance updates.
        #'
        #' ### Official Documentation
        #' [KuCoin Get Announcements](https://www.kucoin.com/docs-new/rest/spot-trading/market-data/get-announcements)
        #'
        #' ### Automated Trading Usage
        #' - **Event Detection**: Filter for `annType = "new-listings"` to detect new trading pairs, triggering symbol queries or strategy adjustments.
        #' - **Scheduled Polling**: Run hourly with `max_pages = 1` to capture recent updates, logging critical announcements (e.g., delistings) for risk management.
        #' - **Alerting**: Parse `annDesc` for keywords (e.g., "maintenance") to pause trading or notify users via your system’s alerting mechanism.
        #'
        #' @param query Named list; filters for announcements:
        #'   - `annType` (character): Type (e.g., `"new-listings"`, `"maintenance-updates"`). Optional.
        #'   - `lang` (character): Language (e.g., `"en_US"`). Optional.
        #'   - `startTime` (integer): Start time (ms). Optional.
        #'   - `endTime` (integer): End time (ms). Optional.
        #' @param page_size Integer; results per page (default 50).
        #' @param max_pages Numeric; max pages to fetch (default `Inf`).
        #' @return Promise resolving to a `data.table` with:
        #'   - `annId` (integer): Announcement ID.
        #'   - `annTitle` (character): Title.
        #'   - `annType` (list): Types.
        #'   - `annDesc` (character): Description.
        #'   - `cTime` (integer): Release time (ms).
        #'   - `language` (character): Language.
        #'   - `annUrl` (character): Full URL.
        #'   - Pagination fields: `currentPage`, `pageSize`, `totalNum`, `totalPage`.
        #' ### JSON Response Example
        #' ```json
        #' {"code": "200000", "data": {"items": [{"annId": 123, "annTitle": "New Listing", "annType": ["new-listings"], "annDesc": "BTC-USDT listed", "cTime": 1733049198863, "language": "en_US", "annUrl": "https://kucoin.com/news/123"}]}}
        #' ```
        get_announcements = function(query = list(), page_size = 50, max_pages = Inf) {
            return(get_announcements_impl(
                base_url = self$base_url,
                query = query,
                page_size = page_size,
                max_pages = max_pages
            ))
        },

        #' Get Klines
        #'
        #' ### Description
        #' Retrieves historical klines (candlestick) data asynchronously via a GET request to `/api/v1/market/candes`,
        #' segmenting requests to handle the 1500-candle limit. Calls `get_klines_impl`.
        #'
        #' ### Workflow Overview
        #' 1. **Segmentation**: Splits time range into segments based on `freq` and 1500-candle limit.
        #' 2. **Fetching**: Retrieves segments concurrently or sequentially based on `concurrent`.
        #' 3. **Aggregation**: Combines results, removes duplicates, and orders by time.
        #'
        #' ### API Endpoint
        #' `GET https://api.kucoin.com/api/v1/market/candles`
        #'
        #' ### Usage
        #' Utilised for historical price and volume analysis, supporting various intervals.
        #'
        #' ### Official Documentation
        #' [KuCoin Get Klines](https://www.kucoin.com/docs-new/rest/spot-trading/market-data/get-klines)
        #'
        #' ### Automated Trading Usage
        #' - **Technical Analysis**: Fetch daily klines (`freq = "1day"`) for moving averages or RSI, feeding into strategy signals.
        #' - **Backtesting**: Use with large time ranges (e.g., 1 year) and `concurrent = FALSE` to build datasets, ensuring rate limit compliance.
        #' - **Real-Time Feed**: Set `from` to recent past (e.g., 1 hour ago) and poll frequently, caching results to reduce API load.
        #'
        #' @param symbol Character string; trading pair (e.g., "BTC-USDT"). Required.
        #' @param freq Character string; interval (e.g., "15min"). Options: "1min", "3min", "5min", "15min", "30min", "1hour", "2hour", "4hour", "6hour", "8hour", "12hour", "1day", "1week", "1month". Default "15min".
        #' @param from POSIXct; start time (default 24 hours ago).
        #' @param to POSIXct; end time (default now).
        #' @param concurrent Logical; fetch segments concurrently (default TRUE). Caution: May hit rate limits.
        #' @param delay_ms Numeric; delay between requests (ms, default 0).
        #' @param retries Integer; retry attempts per segment (default 3).
        #' @return Promise resolving to a `data.table` with:
        #'   - `datetime` (POSIXct): Timestamp.
        #'   - `timestamp` (numeric): Time (seconds).
        #'   - `open` (numeric): Opening price.
        #'   - `close` (numeric): Closing price.
        #'   - `high` (numeric): High price.
        #'   - `low` (numeric): Low price.
        #'   - `volume` (numeric): Volume.
        #'   - `turnover` (numeric): Turnover.
        #' ### JSON Response Example
        #' ```json
        #' {"code": "200000", "data": [["1698777600", "30000", "30500", "31000", "29500", "10", "300000"]]}
        #' ```
        get_klines = function(symbol, freq = "15min", from = lubridate::now() - lubridate::dhours(24),
                              to = lubridate::now(), concurrent = TRUE, delay_ms = 0, retries = 3) {
            return(get_klines_impl(
                base_url = self$base_url,
                symbol = symbol,
                freq = freq,
                from = from,
                to = to,
                concurrent = concurrent,
                delay_ms = delay_ms,
                retries = retries
            ))
        },

        #' Get Currency
        #'
        #' ### Description
        #' Retrieves details for a specific currency asynchronously via a GET request to `/api/v3/currencies/{currency}`.
        #' Calls `get_currency_impl`.
        #'
        #' ### Workflow Overview
        #' 1. **Query**: Includes optional `chain` parameter.
        #' 2. **Request**: Fetches currency data.
        #' 3. **Response**: Combines summary and chain-specific details into a `data.table`.
        #'
        #' ### API Endpoint
        #' `GET https://api.kucoin.com/api/v3/currencies/{currency}`
        #'
        #' ### Usage
        #' Utilised to fetch currency metadata, such as precision and chain support.
        #'
        #' ### Official Documentation
        #' [KuCoin Get Currency](https://www.kucoin.com/docs-new/rest/spot-trading/market-data/get-currency)
        #'
        #' ### Automated Trading Usage
        #' - **Configuration**: Use `precision` to format order sizes correctly in your bot, avoiding rejection.
        #' - **Chain Selection**: Specify `chain` (e.g., "ERC20") to verify deposit/withdrawal support for multi-chain assets.
        #' - **Validation**: Check `isMarginEnabled` to enable/disable margin strategies per currency dynamically.
        #'
        #' @param currency Character string; currency code (e.g., "BTC"). Required.
        #' @param chain Character string; specific chain (e.g., "ERC20"). Optional.
        #' @return Promise resolving to a `data.table` with:
        #'   - `currency` (character): Code.
        #'   - `name` (character): Short name.
        #'   - `fullName` (character): Full name.
        #'   - `precision` (integer): Decimals.
        #'   - `chainName` (character): Blockchain name (if chain-specific).
        #'   - Full schema in implementation docs.
        #' ### JSON Response Example
        #' ```json
        #' {"code": "200000", "data": {"currency": "BTC", "name": "BTC", "fullName": "Bitcoin", "precision": 8, "chains": [{"chainName": "BTC"}]}}
        #' ```
        get_currency = function(currency, chain = NULL) {
            return(get_currency_impl(
                base_url = self$base_url,
                currency = currency,
                chain = chain
            ))
        },

        #' Get All Currencies
        #'
        #' ### Description
        #' Retrieves details for all available currencies asynchronously via a GET request to `/api/v3/currencies`.
        #' Calls `get_all_currencies_impl`.
        #'
        #' ### Workflow Overview
        #' 1. **Request**: Fetches all currency data.
        #' 2. **Response**: Combines summary and chain details into a `data.table`.
        #'
        #' ### API Endpoint
        #' `GET https://api.kucoin.com/api/v3/currencies`
        #'
        #' ### Usage
        #' Utilised to obtain a comprehensive currency list for market configuration.
        #'
        #' ### Official Documentation
        #' [KuCoin Get All Currencies](https://www.kucoin.com/docs-new/rest/spot-trading/market-data/get-all-currencies)
        #'
        #' ### Automated Trading Usage
        #' - **Asset Discovery**: Fetch periodically to update your system’s supported assets, triggering new trading pair setups.
        #' - **Fee Planning**: Use chain-specific fields (e.g., `withdrawFeeRate`) to calculate transaction costs in strategy logic.
        #' - **Portfolio Check**: Filter by `isMarginEnabled` to identify margin-eligible assets for leverage strategies.
        #'
        #' @return Promise resolving to a `data.table` with:
        #'   - `currency` (character): Code.
        #'   - `name` (character): Short name.
        #'   - `fullName` (character): Full name.
        #'   - `precision` (integer): Decimals.
        #'   - `chainName` (character): Blockchain name.
        #'   - Full schema in implementation docs.
        #' ### JSON Response Example
        #' ```json
        #' {"code": "200000", "data": [{"currency": "BTC", "name": "BTC", "fullName": "Bitcoin", "precision": 8, "chains": [{"chainName": "BTC"}]}]}
        #' ```
        get_all_currencies = function() {
            return(get_all_currencies_impl(base_url = self$base_url))
        },

        #' Get Symbol
        #'
        #' ### Description
        #' Retrieves details for a specific trading symbol asynchronously via a GET request to `/api/v2/symbols/{symbol}`.
        #' Calls `get_symbol_impl`.
        #'
        #' ### Workflow Overview
        #' 1. **Request**: Fetches symbol data.
        #' 2. **Response**: Returns metadata as a `data.table`.
        #'
        #' ### API Endpoint
        #' `GET https://api.kucoin.com/api/v2/symbols/{symbol}`
        #'
        #' ### Usage
        #' Utilised to fetch trading pair metadata, such as increments and limits.
        #'
        #' ### Official Documentation
        #' [KuCoin Get Symbol](https://www.kucoin.com/docs-new/rest/spot-trading/market-data/get-all-symbols)
        #'
        #' ### Automated Trading Usage
        #' - **Order Precision**: Use `priceIncrement` and `baseIncrement` to format orders correctly, ensuring API acceptance.
        #' - **Trading Status**: Check `enableTrading` to confirm pair availability before placing orders.
        #' - **Fee Adjustment**: Apply `makerFeeCoefficient` and `takerFeeCoefficient` to calculate precise trading costs.
        #'
        #' @param symbol Character string; trading symbol (e.g., "BTC-USDT"). Required.
        #' @return Promise resolving to a `data.table` with:
        #'   - `symbol` (character): Symbol code.
        #'   - `baseCurrency` (character): Base currency.
        #'   - `quoteCurrency` (character): Quote currency.
        #'   - `priceIncrement` (character): Price step.
        #'   - Full schema in implementation docs.
        #' ### JSON Response Example
        #' ```json
        #' {"code": "200000", "data": {"symbol": "BTC-USDT", "baseCurrency": "BTC", "quoteCurrency": "USDT", "priceIncrement": "0.01"}}
        #' ```
        get_symbol = function(symbol) {
            return(get_symbol_impl(
                base_url = self$base_url,
                symbol = symbol
            ))
        },

        #' Get All Symbols
        #'
        #' ### Description
        #' Retrieves all trading symbols asynchronously via a GET request to `/api/v2/symbols`, optionally filtered by market.
        #' Calls `get_all_symbols_impl`.
        #'
        #' ### Workflow Overview
        #' 1. **Request**: Fetches symbol list with optional `market` filter.
        #' 2. **Response**: Returns a `data.table` of all symbols.
        #'
        #' ### API Endpoint
        #' `GET https://api.kucoin.com/api/v2/symbols`
        #'
        #' ### Usage
        #' Utilised to explore available trading pairs or filter by market.
        #'
        #' ### Official Documentation
        #' [KuCoin Get All Symbols](https://www.kucoin.com/docs-new/rest/spot-trading/market-data/get-all-symbols)
        #'
        #' ### Automated Trading Usage
        #' - **Market Scanning**: Filter by `market` (e.g., "USDS") to identify pairs for specific strategies, updating trading lists dynamically.
        #' - **Pair Validation**: Use `baseMinSize` and `quoteMaxSize` to enforce order size limits in your bot.
        #' - **Periodic Sync**: Run daily to refresh symbol availability, logging new or disabled pairs (`enableTrading`).
        #'
        #' @param market Character string; trading market (e.g., "ALTS"). Optional.
        #' @return Promise resolving to a `data.table` with:
        #'   - `symbol` (character): Symbol code.
        #'   - `baseCurrency` (character): Base currency.
        #'   - `quoteCurrency` (character): Quote currency.
        #'   - `market` (character): Market identifier.
        #'   - Full schema in implementation docs.
        #' ### JSON Response Example
        #' ```json
        #' {"code": "200000", "data": [{"symbol": "BTC-USDT", "baseCurrency": "BTC", "quoteCurrency": "USDT", "market": "USDS"}]}
        #' ```
        get_all_symbols = function(market = NULL) {
            return(get_all_symbols_impl(
                base_url = self$base_url,
                market = market
            ))
        },

        #' Get Ticker
        #'
        #' ### Description
        #' Retrieves Level 1 ticker data asynchronously via a GET request to `/api/v1/market/orderbook/level1`.
        #' Calls `get_ticker_impl`.
        #'
        #' ### Workflow Overview
        #' 1. **Request**: Fetches real-time ticker data for a symbol.
        #' 2. **Response**: Returns a `data.table` with bid/ask and last price.
        #'
        #' ### API Endpoint
        #' `GET https://api.kucoin.com/api/v1/market/orderbook/level1`
        #'
        #' ### Usage
        #' Utilised for real-time price and liquidity monitoring.
        #'
        #' ### Official Documentation
        #' [KuCoin Get Ticker](https://www.kucoin.com/docs-new/rest/spot-trading/market-data/get-ticker)
        #'
        #' ### Automated Trading Usage
        #' - **Price Feed**: Poll every few seconds to update live price (`price`) and spread (`bestAsk - bestBid`) for entry/exit decisions.
        #' - **Liquidity Check**: Use `bestBidSize` and `bestAskSize` to assess market depth before placing large orders.
        #' - **Latency Monitoring**: Track `timestamp` latency to ensure data freshness, alerting if delays exceed thresholds.
        #'
        #' @param symbol Character string; trading symbol (e.g., "BTC-USDT"). Required.
        #' @return Promise resolving to a `data.table` with:
        #'   - `symbol` (character): Symbol.
        #'   - `timestamp` (POSIXct): Snapshot time.
        #'   - `time_ms` (integer): Time (ms).
        #'   - `price` (character): Last price.
        #'   - `bestBid` (character): Best bid.
        #'   - `bestAsk` (character): Best ask.
        #' ### JSON Response Example
        #' ```json
        #' {"code": "200000", "data": {"time": 1733049198863, "price": "30000", "bestBid": "29990", "bestAsk": "30010"}}
        #' ```
        get_ticker = function(symbol) {
            return(get_ticker_impl(
                base_url = self$base_url,
                symbol = symbol
            ))
        },

        #' Get All Tickers
        #'
        #' ### Description
        #' Retrieves ticker data for all trading pairs asynchronously via a GET request to `/api/v1/market/allTickers`.
        #' Calls `get_all_tickers_impl`.
        #'
        #' ### Workflow Overview
        #' 1. **Request**: Fetches a snapshot of all tickers.
        #' 2. **Response**: Returns a `data.table` with market-wide data.
        #'
        #' ### API Endpoint
        #' `GET https://api.kucoin.com/api/v1/market/allTickers`
        #'
        #' ### Usage
        #' Utilised for a broad market overview, including 24-hour metrics.
        #'
        #' ### Official Documentation
        #' [KuCoin Get All Tickers](https://www.kucoin.com/docs-new/rest/spot-trading/market-data/get-all-tickers)
        #'
        #' ### Automated Trading Usage
        #' - **Market Screening**: Filter by `changeRate` to identify trending pairs for momentum strategies, updating every minute.
        #' - **Volume Analysis**: Use `volValue` to prioritize high-liquidity pairs, avoiding low-volume markets.
        #' - **Snapshot Sync**: Cache results and compare `globalTime_datetime` to detect API delays or outages.
        #'
        #' @return Promise resolving to a `data.table` with:
        #'   - `symbol` (character): Symbol.
        #'   - `buy` (character): Best bid.
        #'   - `sell` (character): Best ask.
        #'   - `vol` (character): 24-hour volume.
        #'   - `globalTime_datetime` (POSIXct): Snapshot time.
        #'   - Full schema in implementation docs.
        #' ### JSON Response Example
        #' ```json
        #' {"code": "200000", "data": {"time": 1733049198863, "ticker": [{"symbol": "BTC-USDT", "buy": "29990", "sell": "30010"}]}}
        #' ```
        get_all_tickers = function() {
            return(get_all_tickers_impl(base_url = self$base_url))
        },

        #' Get Trade History
        #'
        #' ### Description
        #' Retrieves the most recent 100 trades for a symbol asynchronously via a GET request to `/api/v1/market/histories`.
        #' Calls `get_trade_history_impl`.
        #'
        #' ### Workflow Overview
        #' 1. **Request**: Fetches recent trade records.
        #' 2. **Response**: Returns a `data.table` with trade details.
        #'
        #' ### API Endpoint
        #' `GET https://api.kucoin.com/api/v1/market/histories`
        #'
        #' ### Usage
        #' Utilised to track recent market trades for a symbol.
        #'
        #' ### Official Documentation
        #' [KuCoin Get Trade History](https://www.kucoin.com/docs-new/rest/spot-trading/market-data/get-trade-history)
        #'
        #' ### Automated Trading Usage
        #' - **Momentum Tracking**: Analyze `side` and `price` trends to detect buying/selling pressure, triggering scalping trades.
        #' - **Execution Timing**: Use `timestamp` to measure trade frequency, adjusting order timing in high-frequency strategies.
        #' - **Volume Spike**: Sum `size` over recent trades to spot volume spikes, signaling potential breakouts.
        #'
        #' @param symbol Character string; trading symbol (e.g., "BTC-USDT"). Required.
        #' @return Promise resolving to a `data.table` with:
        #'   - `sequence` (character): Trade sequence.
        #'   - `price` (character): Price.
        #'   - `size` (character): Amount.
        #'   - `side` (character): "buy" or "sell".
        #'   - `timestamp` (POSIXct): Trade time.
        #' ### JSON Response Example
        #' ```json
        #' {"code": "200000", "data": [{"sequence": "123", "price": "30000", "size": "0.1", "side": "buy", "time": 1733049198863000000}]}
        #' ```
        get_trade_history = function(symbol) {
            return(get_trade_history_impl(
                base_url = self$base_url,
                symbol = symbol
            ))
        },

        #' Get Partial Orderbook
        #'
        #' ### Description
        #' Retrieves partial orderbook data (20 or 100 levels) asynchronously via a GET request to `/api/v1/market/orderbook/level2_{size}`.
        #' Calls `get_part_orderbook_impl`.
        #'
        #' ### Workflow Overview
        #' 1. **Request**: Fetches orderbook snapshot with specified depth.
        #' 2. **Response**: Returns a `data.table` of bids and asks.
        #'
        #' ### API Endpoint
        #' `GET https://api.kucoin.com/api/v1/market/orderbook/level2_{size}`
        #'
        #' ### Usage
        #' Utilised for a quick orderbook snapshot without authentication.
        #'
        #' ### Official Documentation
        #' [KuCoin Get Part Orderbook](https://www.kucoin.com/docs-new/rest/spot-trading/market-data/get-part-orderbook)
        #'
        #' ### Automated Trading Usage
        #' - **Liquidity Assessment**: Use `size` at `price` levels to gauge depth for slippage estimation, opting for `size = 100` in volatile markets.
        #' - **Spread Trading**: Calculate bid-ask spread (`max(bid) - min(ask)`) to identify arbitrage opportunities, polling frequently.
        #' - **Order Placement**: Adjust limit order prices based on top `price` levels to compete effectively in the book.
        #'
        #' @param symbol Character string; trading symbol (e.g., "BTC-USDT"). Required.
        #' @param size Integer; depth (20 or 100, default 20).
        #' @return Promise resolving to a `data.table` with:
        #'   - `timestamp` (POSIXct): Snapshot time.
        #'   - `sequence` (character): Sequence number.
        #'   - `side` (character): "bid" or "ask".
        #'   - `price` (character): Price level.
        #'   - `size` (character): Size at price.
        #' ### JSON Response Example
        #' ```json
        #' {"code": "200000", "data": {"time": 1733049198863, "bids": [["29990", "0.5"]], "asks": [["30010", "0.3"]]}}
        #' ```
        get_part_orderbook = function(symbol, size = 20) {
            return(get_part_orderbook_impl(
                base_url = self$base_url,
                symbol = symbol,
                size = size
            ))
        },

        #' Get Full Orderbook
        #'
        #' ### Description
        #' Retrieves full orderbook data asynchronously via a GET request to `/api/v3/market/orderbook/level2`, requiring authentication.
        #' Calls `get_full_orderbook_impl`.
        #'
        #' ### Workflow Overview
        #' 1. **Request**: Fetches complete orderbook with authentication.
        #' 2. **Response**: Returns a `data.table` of all bids and asks.
        #'
        #' ### API Endpoint
        #' `GET https://api.kucoin.com/api/v3/market/orderbook/level2`
        #'
        #' ### Usage
        #' Utilised for detailed orderbook analysis with authenticated access.
        #'
        #' ### Official Documentation
        #' [KuCoin Get Full Orderbook](https://www.kucoin.com/docs-new/rest/spot-trading/market-data/get-full-orderbook)
        #'
        #' ### Automated Trading Usage
        #' - **Depth Analysis**: Aggregate `size` by `price` to assess total liquidity, optimizing large order placement.
        #' - **HFT Strategies**: Poll frequently (e.g., every second) with `sequence` tracking to detect book changes, enabling rapid arbitrage.
        #' - **Risk Management**: Monitor deep levels to anticipate price walls, adjusting stop-loss triggers accordingly.
        #'
        #' @param symbol Character string; trading symbol (e.g., "BTC-USDT"). Required.
        #' @return Promise resolving to a `data.table` with:
        #'   - `timestamp` (POSIXct): Snapshot time.
        #'   - `sequence` (character): Sequence number.
        #'   - `side` (character): "bid" or "ask".
        #'   - `price` (character): Price level.
        #'   - `size` (character): Size at price.
        #' ### JSON Response Example
        #' ```json
        #' {"code": "200000", "data": {"time": 1733049198863, "bids": [["29990", "0.5"]], "asks": [["30010", "0.3"]]}}
        #' ```
        get_full_orderbook = function(symbol) {
            return(get_full_orderbook_impl(
                keys = self$keys,
                base_url = self$base_url,
                symbol = symbol
            ))
        },

        #' Get 24-Hour Stats
        #'
        #' ### Description
        #' Retrieves 24-hour market statistics asynchronously via a GET request to `/api/v1/market/stats`.
        #' Calls `get_24hr_stats_impl`.
        #'
        #' ### Workflow Overview
        #' 1. **Request**: Fetches 24-hour stats for a symbol.
        #' 2. **Response**: Returns a `data.table` with volume and price metrics.
        #'
        #' ### API Endpoint
        #' `GET https://api.kucoin.com/api/v1/market/stats`
        #'
        #' ### Usage
        #' Utilised for a 24-hour market performance snapshot.
        #'
        #' ### Official Documentation
        #' [KuCoin Get 24hr Stats](https://www.kucoin.com/docs-new/rest/spot-trading/market-data/get-24hr-stats)
        #'
        #' ### Automated Trading Usage
        #' - **Volatility Check**: Use `changeRate` to identify volatile pairs for breakout strategies, polling hourly.
        #' - **Volume Filter**: Filter pairs with `volValue` above a threshold for liquidity-focused trading.
        #' - **Trend Confirmation**: Compare `last` with `averagePrice` to confirm short-term trends, adjusting positions.
        #'
        #' @param symbol Character string; trading symbol (e.g., "BTC-USDT"). Required.
        #' @return Promise resolving to a `data.table` with:
        #'   - `timestamp` (POSIXct): Snapshot time.
        #'   - `symbol` (character): Symbol.
        #'   - `buy` (character): Best bid.
        #'   - `sell` (character): Best ask.
        #'   - `vol` (character): 24-hour volume.
        #'   - Full schema in implementation docs.
        #' ### JSON Response Example
        #' ```json
        #' {"code": "200000", "data": {"time": 1733049198863, "symbol": "BTC-USDT", "vol": "100", "last": "30000"}}
        #' ```
        get_24hr_stats = function(symbol) {
            return(get_24hr_stats_impl(
                base_url = self$base_url,
                symbol = symbol
            ))
        },

        #' Get Market List
        #'
        #' ### Description
        #' Retrieves a list of trading markets asynchronously via a GET request to `/api/v1/markets`.
        #' Calls `get_market_list_impl`.
        #'
        #' ### Workflow Overview
        #' 1. **Request**: Fetches all market identifiers.
        #' 2. **Response**: Returns a character vector of markets.
        #'
        #' ### API Endpoint
        #' `GET https://api.kucoin.com/api/v1/markets`
        #'
        #' ### Usage
        #' Utilised to identify available markets for filtering symbols.
        #'
        #' ### Official Documentation
        #' [KuCoin Get Market List](https://www.kucoin.com/docs-new/rest/spot-trading/market-data/get-market-list)
        #'
        #' ### Automated Trading Usage
        #' - **Market Selection**: Use as a filter for `get_all_symbols` to focus strategies on specific markets (e.g., "USDS").
        #' - **Portfolio Diversification**: Iterate over markets to ensure coverage across asset classes, automating pair selection.
        #' - **Static Cache**: Fetch once daily and cache, as market lists change infrequently, reducing API calls.
        #'
        #' @return Promise resolving to a character vector of market IDs (e.g., "USDS", "TON").
        #' ### JSON Response Example
        #' ```json
        #' {"code": "200000", "data": ["USDS", "TON"]}
        #' ```
        get_market_list = function() {
            return(get_market_list_impl(base_url = self$base_url))
        }
    )
)
