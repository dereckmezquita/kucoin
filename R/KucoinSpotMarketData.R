# File: ./R/KucoinSpotMarketData.R

# box::use(
#     ./impl_market_data_get_klines[ get_klines_impl ],
#     ./impl_market_data[
#         get_announcements_impl, get_currency_impl, get_all_currencies_impl,
#         get_symbol_impl, get_all_symbols_impl, get_ticker_impl,
#         get_all_tickers_impl, get_trade_history_impl, get_part_orderbook_impl,
#         get_full_orderbook_impl, get_24hr_stats_impl, get_market_list_impl
#     ],
#     ./utils[ get_api_keys, get_base_url ]
# )

#' KucoinSpotMarketData Class for KuCoin Spot Market Data Endpoints
#'
#' The `KucoinSpotMarketData` class provides an asynchronous interface for interacting with KuCoin's spot market data
#' API endpoints. It leverages the `coro` package for non-blocking HTTP requests, returning promises that typically
#' resolve to `data.table` objects or character vectors. This class supports retrieving market announcements, historical
#' klines data, currency details, trading symbols, ticker information, trade history, orderbook data, 24-hour statistics,
#' and market lists.
#'
#' ### Workflow Overview
#' Not applicable (class definition overview).
#'
#' ### API Endpoint
#' Not applicable (class-level documentation; see individual methods).
#'
#' ### Usage
#' Utilised by users to access KuCoin spot market data programmatically. The class is initialised with API credentials,
#' automatically loaded via `get_api_keys()` if not provided, and a base URL from `get_base_url()`. Most methods use
#' public endpoints, except `get_full_orderbook()` which requires authentication. For detailed endpoint information and
#' response schemas, refer to the official [KuCoin API Documentation](https://www.kucoin.com/docs-new).
#'
#' ### Official Documentation
#' [KuCoin API Documentation](https://www.kucoin.com/docs-new)
#'
#' @section Methods:
#' - **initialize(keys, base_url):** Initialises the object with API credentials and the base URL.
#' - **get_announcements(query, page_size, max_pages):** Retrieves paginated market announcements.
#' - **get_klines(symbol, freq, from, to, concurrent, delay_ms, retries):** Retrieves historical klines data with segmentation.
#' - **get_currency(currency, chain):** Retrieves details for a specific currency.
#' - **get_all_currencies():** Retrieves details for all available currencies.
#' - **get_symbol(symbol):** Retrieves details for a specific trading symbol.
#' - **get_all_symbols(market):** Retrieves details for all trading symbols, optionally filtered by market.
#' - **get_ticker(symbol):** Retrieves Level 1 ticker data for a trading symbol.
#' - **get_all_tickers():** Retrieves ticker data for all trading pairs.
#' - **get_trade_history(symbol):** Retrieves recent trade history for a trading symbol.
#' - **get_part_orderbook(symbol, size):** Retrieves partial orderbook data (20 or 100 levels).
#' - **get_full_orderbook(symbol):** Retrieves full orderbook data (authenticated).
#' - **get_24hr_stats(symbol):** Retrieves 24-hour market statistics for a trading symbol.
#' - **get_market_list():** Retrieves a list of all available trading markets.
#'
#' @return Not applicable (class definition; see individual methods for return values).
#'
#' @examples
#' \dontrun{
#' # Comprehensive example demonstrating all methods
#' main_async <- coro::async(function() {
#'   # Initialise the class
#'   market <- KucoinSpotMarketData$new()
#'
#'   # Get announcements
#'   announcements <- await(market$get_announcements(list(annType = "new-listings")))
#'   print("Announcements:")
#'   print(announcements)
#'
#'   # Get klines data
#'   klines <- await(market$get_klines("BTC-USDT", "1hour", lubridate::now() - 48 * 3600, lubridate::now()))
#'   print("Klines:")
#'   print(klines)
#'
#'   # Get currency details
#'   btc <- await(market$get_currency("BTC", "ERC20"))
#'   print("BTC (ERC20):")
#'   print(btc)
#'
#'   # Get all currencies
#'   currencies <- await(market$get_all_currencies())
#'   print("All Currencies:")
#'   print(currencies)
#'
#'   # Get symbol details
#'   symbol <- await(market$get_symbol("BTC-USDT"))
#'   print("BTC-USDT Symbol:")
#'   print(symbol)
#'
#'   # Get all symbols for a market
#'   markets <- await(market$get_market_list())
#'   if (length(markets) > 0) {
#'     alts_symbols <- await(market$get_all_symbols(markets[1]))
#'     print(paste("Symbols for", markets[1], ":"))
#'     print(alts_symbols)
#'   }
#'
#'   # Get ticker
#'   ticker <- await(market$get_ticker("BTC-USDT"))
#'   print("BTC-USDT Ticker:")
#'   print(ticker)
#'
#'   # Get all tickers
#'   all_tickers <- await(market$get_all_tickers())
#'   print("All Tickers:")
#'   print(all_tickers)
#'
#'   # Get trade history
#'   trades <- await(market$get_trade_history("BTC-USDT"))
#'   print("BTC-USDT Trade History:")
#'   print(trades)
#'
#'   # Get partial orderbook
#'   part_orderbook <- await(market$get_part_orderbook("BTC-USDT", 20))
#'   print("Partial Orderbook (20 levels):")
#'   print(part_orderbook)
#'
#'   # Get full orderbook (authenticated)
#'   full_orderbook <- await(market$get_full_orderbook("BTC-USDT"))
#'   print("Full Orderbook:")
#'   print(full_orderbook)
#'
#'   # Get 24-hour stats
#'   stats <- await(market$get_24hr_stats("BTC-USDT"))
#'   print("BTC-USDT 24hr Stats:")
#'   print(stats)
#'
#'   # Get market list
#'   market_list <- await(market$get_market_list())
#'   print("Market List:")
#'   print(market_list)
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
        #' @field keys Named list containing API keys for KuCoin (`api_key`, `api_secret`, `api_passphrase`, `key_version`).
        keys = NULL,
        #' @field base_url Character string representing the base URL for the KuCoin API.
        base_url = NULL,

        #' Initialise a New KucoinSpotMarketData Object
        #'
        #' ### Description
        #' Initialises a `KucoinSpotMarketData` object with API credentials and a base URL for accessing KuCoin spot market data
        #' endpoints asynchronously. If not provided, credentials are sourced from `get_api_keys()` and the base URL from
        #' `get_base_url()`.
        #'
        #' ### Workflow Overview
        #' 1. **Credential Assignment**: Sets `self$keys` to the provided or default API keys.
        #' 2. **URL Assignment**: Sets `self$base_url` to the provided or default base URL.
        #'
        #' ### API Endpoint
        #' Not applicable (initialisation method).
        #'
        #' ### Usage
        #' Utilised to create an instance of the class with authentication details for market data retrieval.
        #'
        #' ### Official Documentation
        #' [KuCoin API Authentication](https://www.kucoin.com/docs-new/rest/introduction)
        #'
        #' @param keys Named list containing API configuration parameters from `get_api_keys()`, including:
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

        #' Retrieve Announcements
        #'
        #' ### Description
        #' Retrieves paginated market announcements from the KuCoin API asynchronously, aggregating results into a `data.table`.
        #' This includes updates, promotions, and other news. This method calls `get_announcements_impl`.
        #'
        #' ### Workflow Overview
        #' 1. **Query Construction**: Merges defaults (`currentPage = 1`, `pageSize = 50`, `annType = "latest-announcements"`, `lang = "en_US"`) with `query`.
        #' 2. **URL Assembly**: Combines `base_url` with `/api/v3/announcements` and the query string.
        #' 3. **Page Fetching**: Uses an async helper to send GET requests with a 10-second timeout.
        #' 4. **Pagination**: Fetches all pages up to `max_pages` using `auto_paginate`, extracting `"items"`.
        #' 5. **Aggregation**: Combines results into a `data.table` with `data.table::rbindlist()`.
        #'
        #' ### API Endpoint
        #' `GET https://api.kucoin.com/api/v3/announcements`
        #'
        #' ### Usage
        #' Utilised by users to monitor market news and developments, correlating with other market data like tickers or stats.
        #'
        #' ### Official Documentation
        #' [KuCoin Get Announcements](https://www.kucoin.com/docs-new/rest/spot-trading/market-data/get-announcements)
        #'
        #' @param query Named list; additional query parameters to filter announcements:
        #'   - `currentPage` (integer, optional): Page number to retrieve.
        #'   - `pageSize` (integer, optional): Number of announcements per page.
        #'   - `annType` (string, optional): Type (e.g., `"latest-announcements"`, `"activities"`, `"new-listings"`).
        #'   - `lang` (string, optional): Language (e.g., `"en_US"`, `"zh_HK"`).
        #'   - `startTime` (integer, optional): Start time in milliseconds.
        #'   - `endTime` (integer, optional): End time in milliseconds.
        #' @param page_size Integer; results per page (default 50).
        #' @param max_pages Numeric; maximum pages to fetch (default `Inf` for all pages).
        #'
        #' @return Promise resolving to a `data.table` containing:
        #'   - `annId` (integer): Unique announcement ID.
        #'   - `annTitle` (character): Announcement title.
        #'   - `annType` (list): List of announcement types.
        #'   - `annDesc` (character): Announcement description.
        #'   - `cTime` (integer): Release time in milliseconds.
        #'   - `language` (character): Language of the announcement.
        #'   - `annUrl` (character): URL to the full announcement.
        #'   - `currentPage` (integer): Current page number.
        #'   - `pageSize` (integer): Records per page.
        #'   - `totalNum` (integer): Total announcements.
        #'   - `totalPage` (integer): Total pages.
        get_announcements = function(query = list(), page_size = 50, max_pages = Inf) {
            return(get_announcements_impl(
                base_url = self$base_url,
                query = query,
                page_size = page_size,
                max_pages = max_pages
            ))
        },

        #' Retrieve Historical Klines Data
        #'
        #' ### Description
        #' Retrieves historical candlestick (klines) data for a trading pair from the KuCoin API asynchronously, segmenting
        #' requests to handle the 1500-candle limit per request. This method calls `get_klines_impl`.
        #'
        #' ### Workflow Overview
        #' 1. **Input Validation**: Converts `from` and `to` to POSIXct, ensures `from` < `to`.
        #' 2. **Frequency Conversion**: Translates `freq` to seconds using `frequency_to_seconds()`.
        #' 3. **Segmentation**: Splits the time range into segments with `split_time_range_by_candles()`.
        #' 4. **Segment Fetching**: Creates promises for each segment via `fetch_klines_segment()`.
        #' 5. **Execution Mode**: Fetches concurrently with `promises::promise_all()` if `concurrent = TRUE`, or sequentially.
        #' 6. **Aggregation**: Combines results, removes duplicates by `timestamp`, orders by `datetime`.
        #'
        #' ### API Endpoint
        #' `GET https://api.kucoin.com/api/v1/market/candles`
        #'
        #' ### Usage
        #' Utilised by users to fetch historical price and volume data for analysis, with options for concurrent or sequential retrieval.
        #'
        #' ### Official Documentation
        #' [KuCoin Get Klines](https://www.kucoin.com/docs-new/rest/spot-trading/market-data/get-klines)
        #'
        #' @param symbol Character string; trading pair (e.g., `"BTC-USDT"`).
        #' @param freq Character string; candlestick interval (e.g., `"15min"`). Allowed values: `"1min"`, `"3min"`, `"5min"`, `"15min"`, `"30min"`, `"1hour"`, `"2hour"`, `"4hour"`, `"6hour"`, `"8hour"`, `"12hour"`, `"1day"`, `"1week"`, `"1month"`. Default `"15min"`.
        #' @param from POSIXct object; start time (default 24 hours ago).
        #' @param to POSIXct object; end time (default now).
        #' @param concurrent Logical; fetch segments concurrently (default `TRUE`). Caution: May trigger rate limits.
        #' @param delay_ms Numeric; delay in milliseconds before each request (default 0).
        #' @param retries Integer; retry attempts per segment (default 3).
        #'
        #' @return Promise resolving to a `data.table` containing:
        #'   - `datetime` (POSIXct): Converted timestamp.
        #'   - `timestamp` (numeric): Raw timestamp in seconds.
        #'   - `open` (numeric): Opening price.
        #'   - `close` (numeric): Closing price.
        #'   - `high` (numeric): Highest price.
        #'   - `low` (numeric): Lowest price.
        #'   - `volume` (numeric): Trading volume.
        #'   - `turnover` (numeric): Trading turnover.
        get_klines = function(
            symbol,
            freq = "15min",
            from = lubridate::now() - 24 * 3600,
            to = lubridate::now(),
            concurrent = TRUE,
            delay_ms = 0,
            retries = 3
        ) {
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

        #' Retrieve Currency Details
        #'
        #' ### Description
        #' Retrieves detailed information for a specified currency from the KuCoin API asynchronously, including chain-specific
        #' details for multi-chain currencies. This method calls `get_currency_impl`.
        #'
        #' ### Workflow Overview
        #' 1. **Query Construction**: Builds a query string with optional `chain` using `build_query()`.
        #' 2. **URL Assembly**: Combines `base_url`, `/api/v3/currencies/`, `currency`, and query string.
        #' 3. **HTTP Request**: Sends a GET request with a 10-second timeout via `httr::GET()`.
        #' 4. **Response Processing**: Validates with `process_kucoin_response()`, extracts `"data"`.
        #' 5. **Data Conversion**: Splits `"data"` into summary and `chains` data, combines into a `data.table`.
        #'
        #' ### API Endpoint
        #' `GET https://api.kucoin.com/api/v3/currencies/{currency}`
        #'
        #' ### Usage
        #' Utilised by users to obtain currency metadata (e.g., precision, chain support) for trading or configuration purposes.
        #'
        #' ### Official Documentation
        #' [KuCoin Get Currency](https://www.kucoin.com/docs-new/rest/spot-trading/market-data/get-currency)
        #'
        #' @param currency Character string; currency code (e.g., `"BTC"`, `"USDT"`).
        #' @param chain Character string (optional); specific chain (e.g., `"ERC20"`, `"TRC20"`).
        #'
        #' @return Promise resolving to a `data.table` containing:
        #'   - `currency` (character): Unique currency code.
        #'   - `name` (character): Short name.
        #'   - `fullName` (character): Full name.
        #'   - `precision` (integer): Decimal places.
        #'   - `confirms` (integer or NULL): Block confirmations.
        #'   - `contractAddress` (character or NULL): Primary contract address.
        #'   - `isMarginEnabled` (logical): Margin trading status.
        #'   - `isDebitEnabled` (logical): Debit status.
        #'   - Chain-specific fields (e.g., `chainName`, `withdrawalMinSize`).
        get_currency = function(currency, chain = NULL) {
            return(get_currency_impl(
                base_url = self$base_url,
                currency = currency,
                chain = chain
            ))
        },

        #' Retrieve All Currencies
        #'
        #' ### Description
        #' Retrieves a list of all currencies available on KuCoin asynchronously, combining summary and chain-specific details
        #' into a `data.table`. This method calls `get_all_currencies_impl`.
        #'
        #' ### Workflow Overview
        #' 1. **URL Assembly**: Combines `base_url` with `/api/v3/currencies`.
        #' 2. **HTTP Request**: Sends a GET request with a 10-second timeout via `httr::GET()`.
        #' 3. **Response Processing**: Validates with `process_kucoin_response()`, extracts `"data"`.
        #' 4. **Data Iteration**: Loops through currencies, extracting summary and chain data.
        #' 5. **Result Assembly**: Combines into a `data.table`, adding dummy chain columns if none exist.
        #'
        #' ### API Endpoint
        #' `GET https://api.kucoin.com/api/v3/currencies`
        #'
        #' ### Usage
        #' Utilised by users to fetch comprehensive currency details for market analysis or configuration.
        #'
        #' ### Official Documentation
        #' [KuCoin Get All Currencies](https://www.kucoin.com/docs-new/rest/spot-trading/market-data/get-all-currencies)
        #'
        #' @return Promise resolving to a `data.table` containing:
        #'   - **Summary Fields**:
        #'     - `currency` (character): Unique currency code.
        #'     - `name` (character): Short name.
        #'     - `fullName` (character): Full name.
        #'     - `precision` (integer): Decimal places.
        #'     - `confirms` (integer or NA): Block confirmations.
        #'     - `contractAddress` (character or NA): Primary contract address.
        #'     - `isMarginEnabled` (logical): Margin trading status.
        #'     - `isDebitEnabled` (logical): Debit status.
        #'   - **Chain-Specific Fields**:
        #'     - `chainName` (character or NA): Blockchain name.
        #'     - `withdrawalMinSize` (character or NA): Minimum withdrawal amount.
        #'     - And more (see implementation docs).
        get_all_currencies = function() {
            return(get_all_currencies_impl(base_url = self$base_url))
        },

        #' Retrieve Symbol Details
        #'
        #' ### Description
        #' Retrieves detailed information for a specified trading symbol from the KuCoin API asynchronously. This method calls
        #' `get_symbol_impl`.
        #'
        #' ### Workflow Overview
        #' 1. **URL Assembly**: Combines `base_url`, `/api/v2/symbols/`, and `symbol`.
        #' 2. **HTTP Request**: Sends a GET request with a 10-second timeout via `httr::GET()`.
        #' 3. **Response Processing**: Validates with `process_kucoin_response()`, extracts `"data"`.
        #' 4. **Data Conversion**: Converts `"data"` into a `data.table`.
        #'
        #' ### API Endpoint
        #' `GET https://api.kucoin.com/api/v2/symbols/{symbol}`
        #'
        #' ### Usage
        #' Utilised by users to fetch metadata for a specific trading symbol, such as price increments and trading limits.
        #'
        #' ### Official Documentation
        #' [KuCoin Get Symbol](https://www.kucoin.com/docs-new/rest/spot-trading/market-data/get-all-symbols)
        #'
        #' @param symbol Character string; trading symbol (e.g., `"BTC-USDT"`).
        #'
        #' @return Promise resolving to a `data.table` containing:
        #'   - `symbol` (character): Unique trading symbol code.
        #'   - `name` (character): Name of the trading pair.
        #'   - `baseCurrency` (character): Base currency.
        #'   - `quoteCurrency` (character): Quote currency.
        #'   - `feeCurrency` (character): Currency for fees.
        #'   - `market` (character): Trading market.
        #'   - `baseMinSize` (character): Minimum order quantity.
        #'   - And more (see implementation docs).
        get_symbol = function(symbol) {
            return(get_symbol_impl(
                base_url = self$base_url,
                symbol = symbol
            ))
        },

        #' Retrieve All Trading Symbols
        #'
        #' ### Description
        #' Retrieves a list of all available trading symbols from the KuCoin API asynchronously, optionally filtered by market.
        #' This method calls `get_all_symbols_impl`.
        #'
        #' ### Workflow Overview
        #' 1. **Query Construction**: Builds a query string with optional `market` using `build_query()`.
        #' 2. **URL Assembly**: Combines `base_url`, `/api/v2/symbols`, and query string.
        #' 3. **HTTP Request**: Sends a GET request with a 10-second timeout via `httr::GET()`.
        #' 4. **Response Processing**: Validates with `process_kucoin_response()`, extracts `"data"`.
        #' 5. **Data Conversion**: Converts `"data"` into a `data.table`.
        #'
        #' ### API Endpoint
        #' `GET https://api.kucoin.com/api/v2/symbols`
        #'
        #' ### Usage
        #' Utilised by users to obtain a comprehensive list of trading symbols for market exploration or filtering.
        #'
        #' ### Official Documentation
        #' [KuCoin Get All Symbols](https://www.kucoin.com/docs-new/rest/spot-trading/market-data/get-all-symbols)
        #'
        #' @param market Character string (optional); trading market filter (e.g., `"ALTS"`, `"USDS"`, `"ETF"`).
        #'
        #' @return Promise resolving to a `data.table` containing:
        #'   - `symbol` (character): Unique trading symbol code.
        #'   - `name` (character): Name of the trading pair.
        #'   - `baseCurrency` (character): Base currency.
        #'   - `quoteCurrency` (character): Quote currency.
        #'   - `feeCurrency` (character): Currency for fees.
        #'   - `market` (character): Trading market.
        #'   - `baseMinSize` (character): Minimum order quantity.
        #'   - And more (see implementation docs).
        get_all_symbols = function(market = NULL) {
            return(get_all_symbols_impl(
                base_url = self$base_url,
                market = market
            ))
        },

        #' Retrieve Ticker Information
        #'
        #' ### Description
        #' Retrieves Level 1 market data (ticker information) for a specified trading symbol from the KuCoin API asynchronously.
        #' This method calls `get_ticker_impl`.
        #'
        #' ### Workflow Overview
        #' 1. **Query Construction**: Builds a query string with `symbol` using `build_query()`.
        #' 2. **URL Assembly**: Combines `base_url`, `/api/v1/market/orderbook/level1`, and query string.
        #' 3. **HTTP Request**: Sends a GET request with a 10-second timeout via `httr::GET()`.
        #' 4. **Response Processing**: Validates with `process_kucoin_response()`, extracts `"data"`.
        #' 5. **Data Conversion**: Converts to a `data.table`, adds `symbol`, renames `time` to `time_ms`, adds `timestamp`.
        #'
        #' ### API Endpoint
        #' `GET https://api.kucoin.com/api/v1/market/orderbook/level1`
        #'
        #' ### Usage
        #' Utilised by users to obtain real-time ticker data (e.g., best bid/ask, last price) for a trading symbol.
        #'
        #' ### Official Documentation
        #' [KuCoin Get Ticker](https://www.kucoin.com/docs-new/rest/spot-trading/market-data/get-ticker)
        #'
        #' @param symbol Character string; trading symbol (e.g., `"BTC-USDT"`).
        #'
        #' @return Promise resolving to a `data.table` containing:
        #'   - `symbol` (character): Trading symbol.
        #'   - `timestamp` (POSIXct): Snapshot timestamp in UTC.
        #'   - `time_ms` (integer): Snapshot timestamp in milliseconds.
        #'   - `sequence` (character): Update sequence identifier.
        #'   - `price` (character): Last traded price.
        #'   - `size` (character): Last traded size.
        #'   - `bestBid` (character): Best bid price.
        #'   - `bestBidSize` (character): Best bid size.
        #'   - `bestAsk` (character): Best ask price.
        #'   - `bestAskSize` (character): Best ask size.
        get_ticker = function(symbol) {
            return(get_ticker_impl(
                base_url = self$base_url,
                symbol = symbol
            ))
        },

        #' Retrieve All Tickers
        #'
        #' ### Description
        #' Retrieves market tickers for all trading pairs from the KuCoin API asynchronously, including 24-hour volume data.
        #' This method calls `get_all_tickers_impl`.
        #'
        #' ### Workflow Overview
        #' 1. **URL Assembly**: Combines `base_url` with `/api/v1/market/allTickers`.
        #' 2. **HTTP Request**: Sends a GET request with a 10-second timeout via `httr::GET()`.
        #' 3. **Response Processing**: Validates with `process_kucoin_response()`, extracts `"data"`.
        #' 4. **Data Conversion**: Converts `"ticker"` array to a `data.table`, adds `globalTime_ms` and `globalTime_datetime`.
        #'
        #' ### API Endpoint
        #' `GET https://api.kucoin.com/api/v1/market/allTickers`
        #'
        #' ### Usage
        #' Utilised by users to fetch a snapshot of market data across all trading pairs for monitoring or analysis.
        #'
        #' ### Official Documentation
        #' [KuCoin Get All Tickers](https://www.kucoin.com/docs-new/rest/spot-trading/market-data/get-all-tickers)
        #'
        #' @return Promise resolving to a `data.table` containing:
        #'   - `symbol` (character): Trading symbol.
        #'   - `symbolName` (character): Symbol name.
        #'   - `buy` (character): Best bid price.
        #'   - `bestBidSize` (character): Best bid size.
        #'   - `sell` (character): Best ask price.
        #'   - `bestAskSize` (character): Best ask size.
        #'   - `changeRate` (character): 24-hour change rate.
        #'   - And more (see implementation docs).
        get_all_tickers = function() {
            return(get_all_tickers_impl(base_url = self$base_url))
        },

        #' Retrieve Trade History
        #'
        #' ### Description
        #' Retrieves the most recent 100 trade records for a specified trading symbol from the KuCoin API asynchronously.
        #' This method calls `get_trade_history_impl`.
        #'
        #' ### Workflow Overview
        #' 1. **Query Construction**: Builds a query string with `symbol` using `build_query()`.
        #' 2. **URL Assembly**: Combines `base_url`, `/api/v1/market/histories`, and query string.
        #' 3. **HTTP Request**: Sends a GET request with a 10-second timeout via `httr::GET()`.
        #' 4. **Response Processing**: Validates with `process_kucoin_response()`, extracts `"data"`.
        #' 5. **Data Conversion**: Converts to a `data.table`, adds `timestamp` via `time_convert_from_kucoin()`.
        #'
        #' ### API Endpoint
        #' `GET https://api.kucoin.com/api/v1/market/histories`
        #'
        #' ### Usage
        #' Utilised by users to fetch recent trade history for tracking market activity.
        #'
        #' ### Official Documentation
        #' [KuCoin Get Trade History](https://www.kucoin.com/docs-new/rest/spot-trading/market-data/get-trade-history)
        #'
        #' @param symbol Character string; trading symbol (e.g., `"BTC-USDT"`).
        #'
        #' @return Promise resolving to a `data.table` containing:
        #'   - `sequence` (character): Trade sequence number.
        #'   - `price` (character): Filled price.
        #'   - `size` (character): Filled amount.
        #'   - `side` (character): Trade side (`"buy"` or `"sell"`).
        #'   - `time` (integer): Trade timestamp in nanoseconds.
        #'   - `timestamp` (POSIXct): Converted timestamp in UTC.
        get_trade_history = function(symbol) {
            return(get_trade_history_impl(
                base_url = self$base_url,
                symbol = symbol
            ))
        },

        #' Retrieve Partial Orderbook
        #'
        #' ### Description
        #' Retrieves partial orderbook depth data (20 or 100 levels) for a specified trading symbol from the KuCoin API
        #' asynchronously. This method calls `get_part_orderbook_impl`.
        #'
        #' ### Workflow Overview
        #' 1. **Input Validation**: Ensures `size` is 20 or 100, aborts if invalid.
        #' 2. **Query Construction**: Builds a query string with `symbol` using `build_query()`.
        #' 3. **URL Assembly**: Combines `base_url`, `/api/v1/market/orderbook/level2_{size}`, and query string.
        #' 4. **HTTP Request**: Sends a GET request with a 10-second timeout via `httr::GET()`.
        #' 5. **Response Processing**: Validates with `process_kucoin_response()`, extracts `"data"`, converts bids/asks.
        #'
        #' ### API Endpoint
        #' `GET https://api.kucoin.com/api/v1/market/orderbook/level2_{size}`
        #'
        #' ### Usage
        #' Utilised by users to obtain a snapshot of the orderbook, showing aggregated bid and ask levels.
        #'
        #' ### Official Documentation
        #' [KuCoin Get Part OrderBook](https://www.kucoin.com/docs-new/rest/spot-trading/market-data/get-part-orderbook)
        #'
        #' @param symbol Character string; trading symbol (e.g., `"BTC-USDT"`).
        #' @param size Integer; orderbook depth (20 or 100, default 20).
        #'
        #' @return Promise resolving to a `data.table` containing:
        #'   - `timestamp` (POSIXct): Snapshot timestamp in UTC.
        #'   - `time_ms` (integer): Snapshot timestamp in milliseconds.
        #'   - `sequence` (character): Orderbook update sequence.
        #'   - `side` (character): Order side (`"bid"` or `"ask"`).
        #'   - `price` (character): Aggregated price level.
        #'   - `size` (character): Aggregated size.
        get_part_orderbook = function(symbol, size = 20) {
            return(get_part_orderbook_impl(
                base_url = self$base_url,
                symbol = symbol,
                size = size
            ))
        },

        #' Retrieve Full Orderbook (Authenticated)
        #'
        #' ### Description
        #' Retrieves full orderbook depth data for a specified trading symbol from the KuCoin API asynchronously, requiring
        #' authentication. This method calls `get_full_orderbook_impl`.
        #'
        #' ### Workflow Overview
        #' 1. **Header Preparation**: Constructs authentication headers with `build_headers()` using `keys`.
        #' 2. **Query Construction**: Builds a query string with `symbol` using `build_query()`.
        #' 3. **URL Assembly**: Combines `base_url`, `/api/v3/market/orderbook/level2`, and query string.
        #' 4. **HTTP Request**: Sends a GET request with headers and a 10-second timeout via `httr::GET()`.
        #' 5. **Response Processing**: Validates with `process_kucoin_response()`, extracts `"data"`, converts bids/asks.
        #'
        #' ### API Endpoint
        #' `GET https://api.kucoin.com/api/v3/market/orderbook/level2`
        #'
        #' ### Usage
        #' Utilised by users to fetch the complete orderbook, requiring API authentication for detailed depth data.
        #'
        #' ### Official Documentation
        #' [KuCoin Get Full OrderBook](https://www.kucoin.com/docs-new/rest/spot-trading/market-data/get-full-orderbook)
        #'
        #' @param symbol Character string; trading symbol (e.g., `"BTC-USDT"`).
        #'
        #' @return Promise resolving to a `data.table` containing:
        #'   - `timestamp` (POSIXct): Snapshot timestamp in UTC.
        #'   - `time_ms` (integer): Snapshot timestamp in milliseconds.
        #'   - `sequence` (character): Orderbook update sequence.
        #'   - `side` (character): Order side (`"bid"` or `"ask"`).
        #'   - `price` (character): Aggregated price level.
        #'   - `size` (character): Aggregated size.
        get_full_orderbook = function(symbol) {
            return(get_full_orderbook_impl(
                keys = self$keys,
                base_url = self$base_url,
                symbol = symbol
            ))
        },

        #' Retrieve 24-Hour Market Statistics
        #'
        #' ### Description
        #' Retrieves 24-hour market statistics for a specified trading symbol from the KuCoin API asynchronously. This method
        #' calls `get_24hr_stats_impl`.
        #'
        #' ### Workflow Overview
        #' 1. **Query Construction**: Builds a query string with `symbol` using `build_query()`.
        #' 2. **URL Assembly**: Combines `base_url`, `/api/v1/market/stats`, and query string.
        #' 3. **HTTP Request**: Sends a GET request with a 10-second timeout via `httr::GET()`.
        #' 4. **Response Processing**: Validates with `process_kucoin_response()`, extracts `"data"`.
        #' 5. **Data Conversion**: Converts to a `data.table`, renames `time` to `time_ms`, adds `timestamp`.
        #'
        #' ### API Endpoint
        #' `GET https://api.kucoin.com/api/v1/market/stats`
        #'
        #' ### Usage
        #' Utilised by users to fetch a 24-hour snapshot of market statistics, including volume and price changes.
        #'
        #' ### Official Documentation
        #' [KuCoin Get 24hr Stats](https://www.kucoin.com/docs-new/rest/spot-trading/market-data/get-24hr-stats)
        #'
        #' @param symbol Character string; trading symbol (e.g., `"BTC-USDT"`).
        #'
        #' @return Promise resolving to a `data.table` containing:
        #'   - `timestamp` (POSIXct): Snapshot timestamp in UTC.
        #'   - `time_ms` (integer): Snapshot timestamp in milliseconds.
        #'   - `symbol` (character): Trading symbol.
        #'   - `buy` (character): Best bid price.
        #'   - `sell` (character): Best ask price.
        #'   - `changeRate` (character): 24-hour change rate.
        #'   - And more (see implementation docs).
        get_24hr_stats = function(symbol) {
            return(get_24hr_stats_impl(
                base_url = self$base_url,
                symbol = symbol
            ))
        },

        #' Retrieve Market List
        #'
        #' ### Description
        #' Retrieves a list of all available trading markets from the KuCoin API asynchronously as a character vector.
        #' This method calls `get_market_list_impl`.
        #'
        #' ### Workflow Overview
        #' 1. **URL Assembly**: Combines `base_url` with `/api/v1/markets`.
        #' 2. **HTTP Request**: Sends a GET request with a 10-second timeout via `httr::GET()`.
        #' 3. **Response Processing**: Validates with `process_kucoin_response()`, extracts `"data"`.
        #'
        #' ### API Endpoint
        #' `GET https://api.kucoin.com/api/v1/markets`
        #'
        #' ### Usage
        #' Utilised by users to identify available trading markets for filtering or querying market-specific data.
        #'
        #' ### Official Documentation
        #' [KuCoin Get Market List](https://www.kucoin.com/docs-new/rest/spot-trading/market-data/get-market-list)
        #'
        #' @return Promise resolving to a character vector of market identifiers (e.g., `"USDS"`, `"TON"`).
        get_market_list = function() {
            return(get_market_list_impl(
                base_url = self$base_url
            ))
        }
    )
)
