# File: ./R/KucoinSpotMarketData.R

box::use(
    ./impl_market_data_get_klines[ get_klines_impl ],
    ./impl_market_data[
        get_currency_impl, get_all_currencies_impl, get_symbol_impl,
        get_all_symbols_impl, get_ticker_impl, get_all_tickers_impl
    ],
    ./utils[ get_base_url ]
)

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
        #' This method uses a public API endpoint that does not require authentication.
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
        #' This asynchronous method retrieves detailed information for a specified currency from the KuCoin API.
        #' It returns a promise that resolves to a \code{data.table} containing various details about the currency,
        #' such as its unique code, name, full name, precision, margin and debit support, and chain information (if applicable).
        #'
        #' **Workflow Overview:**
        #'
        #' 1. **Input Validation:**  
        #'    The method verifies that a non-empty currency code is provided.
        #'
        #' 2. **Query String Construction:**  
        #'    If a \code{chain} parameter is specified, it is incorporated into the query string via the \code{build_query()} helper.
        #'
        #' 3. **URL Construction:**  
        #'    Constructs the full API URL by concatenating the base URL (stored in the class), the endpoint path 
        #'    \code{/api/v3/currencies/} (with the provided currency code as a path parameter), and the optional query string.
        #'
        #' 4. **HTTP Request and Response Processing:**  
        #'    Sends a GET request to the constructed URL (with a 10-second timeout) and processes the response
        #'    using \code{process_kucoin_response()} to ensure the request was successful.
        #'
        #' 5. **Data Conversion:**  
        #'    Converts the returned data (a named list of currency details) into a \code{data.table} for easy consumption.
        #'
        #' **API Documentation:**  
        #' [KuCoin Get Currency](https://www.kucoin.com/docs-new/rest/spot-trading/market-data/get-currency)
        #'
        #' @param currency A character string representing the currency code (e.g., "BTC", "USDT").
        #' @param chain (Optional) A character string specifying the chain to query (e.g., "ERC20", "TRC20"). This parameter applies only to multi‑chain currencies.
        #'
        #' @return A promise that resolves to a \code{data.table} containing the currency details.
        #' 
        #'    currency   name fullName precision isMarginEnabled isDebitEnabled
        #'      <char> <char>   <char>     <int>          <lgcl>         <lgcl>
        #' 1:      BTC    BTC  Bitcoin         8            TRUE           TRUE
        #' 2:      BTC    BTC  Bitcoin         8            TRUE           TRUE
        #' 3:      BTC    BTC  Bitcoin         8            TRUE           TRUE
        #' 4:      BTC    BTC  Bitcoin         8            TRUE           TRUE
        #'            chainName withdrawalMinSize depositMinSize withdrawFeeRate
        #'               <char>            <char>         <char>          <char>
        #' 1:               BTC            0.0006         0.0002               0
        #' 2: Lightning Network           0.00001        0.00001               0
        #' 3:               KCC            0.0008           <NA>               0
        #' 4:        BTC-Segwit            0.0008         0.0002               0
        #'    withdrawalMinFee isWithdrawEnabled isDepositEnabled confirms preConfirms
        #'              <char>            <lgcl>           <lgcl>    <int>       <int>
        #' 1:          0.00035              TRUE             TRUE        3           1
        #' 2:         0.000015              TRUE             TRUE        1           1
        #' 3:          0.00002              TRUE             TRUE       20          20
        #' 4:           0.0005             FALSE             TRUE        2           2
        #'                               contractAddress withdrawPrecision maxWithdraw
        #'                                        <char>             <int>      <lgcl>
        #' 1:                                                            8          NA
        #' 2:                                                            8          NA
        #' 3: 0xfa93c12cd345c658bc4644d1d4e1b9615952258c                 8          NA
        #' 4:                                                            8          NA
        #'    maxDeposit needTag chainId
        #'        <char>  <lgcl>  <char>
        #' 1:       <NA>   FALSE     btc
        #' 2:       0.03   FALSE   btcln
        #' 3:       <NA>   FALSE     kcc
        #' 4:       <NA>   FALSE  bech32
        #'
        #' This method uses a public API endpoint that does not require authentication.
        get_currency = function(currency, chain = NULL) {
            return(get_currency_impl(
                base_url = self$base_url,
                currency = currency,
                chain = chain
            ))
        },

        #' Retrieve All Currencies
        #'
        #' This asynchronous method retrieves a complete list of all currencies available on the KuCoin API.
        #' Each currency is returned with its summary details and nested chain-specific information.
        #' For currencies that support multiple chains, the summary data is replicated for each chain, resulting in one row per
        #' currency/chain combination. If a currency has no chain data, dummy chain columns (filled with NA) are appended.
        #'
        #' **Workflow Overview:**
        #'
        #' 1. **URL Construction:**  
        #'    Constructs the full API URL by concatenating the base URL (stored in the class) with the endpoint
        #'    \code{/api/v3/currencies}.
        #'
        #' 2. **HTTP Request:**  
        #'    Sends a GET request to the constructed URL using \code{httr::GET()} with a 10‑second timeout.
        #'
        #' 3. **Response Processing:**  
        #'    Processes the response using \code{process_kucoin_response()} to validate the HTTP status and API code,
        #'    then extracts the \code{data} field. The returned data is a data.frame with one row per currency,
        #'    and the nested chain information is stored in a list-column.
        #'
        #' 4. **Data Conversion:**  
        #'    Iterates over each row (currency) in the data.frame. For each currency, the summary fields are extracted,
        #'    and its nested chain data (if available) is converted into a data.table.
        #'
        #' 5. **Result Assembly:**  
        #'    - If chain data exists, the summary row is replicated for each chain entry and then combined with the chain data.
        #'    - If no chain data is present or valid, dummy chain columns (all NA) are appended.
        #' 
        #' **API Documentation:**  
        #' [KuCoin Get All Currencies](https://www.kucoin.com/docs-new/rest/spot-trading/market-data/get-all-currencies)
        #'
        #' @return A promise that resolves to a \code{data.table} containing combined currency details.
        #'         Each row represents a unique currency/chain combination. The data.table includes:
        #'
        #'         **Currency Summary Fields:**
        #'         \describe{
        #'           \item{currency}{(string) The unique currency code.}
        #'           \item{name}{(string) The short name of the currency.}
        #'           \item{fullName}{(string) The full descriptive name of the currency.}
        #'           \item{precision}{(integer) The number of decimal places supported by the currency.}
        #'           \item{confirms}{(integer or NA) The number of block confirmations required at the currency level.}
        #'           \item{contractAddress}{(string or NA) The primary contract address for tokenized currencies.}
        #'           \item{isMarginEnabled}{(boolean) Indicates whether margin trading is enabled for the currency.}
        #'           \item{isDebitEnabled}{(boolean) Indicates whether debit transactions are enabled for the currency.}
        #'         }
        #'
        #'         **Chain-Specific Fields:**
        #'         \describe{
        #'           \item{chainName}{(string or NA) The name of the blockchain network associated with the currency.}
        #'           \item{withdrawalMinSize}{(string or NA) The minimum withdrawal amount permitted on this chain.}
        #'           \item{depositMinSize}{(string or NA) The minimum deposit amount permitted on this chain.}
        #'           \item{withdrawFeeRate}{(string or NA) The fee rate applied to withdrawals on this chain.}
        #'           \item{withdrawalMinFee}{(string or NA) The minimum fee charged for a withdrawal transaction on this chain.}
        #'           \item{isWithdrawEnabled}{(boolean or NA) Indicates whether withdrawals are enabled on this chain.}
        #'           \item{isDepositEnabled}{(boolean or NA) Indicates whether deposits are enabled on this chain.}
        #'           \item{confirms}{(integer or NA) The number of blockchain confirmations required on this chain.}
        #'           \item{preConfirms}{(integer or NA) The number of pre-confirmations required for on-chain verification on this chain.}
        #'           \item{chain_contractAddress}{(string or NA) The contract address specific to this chain (renamed from \code{contractAddress}).}
        #'           \item{withdrawPrecision}{(integer or NA) The withdrawal precision (maximum number of decimal places for withdrawal amounts on this chain).}
        #'           \item{maxWithdraw}{(string or NA) The maximum amount allowed per withdrawal transaction on this chain.}
        #'           \item{maxDeposit}{(string or NA) The maximum amount allowed per deposit transaction on this chain (applicable to some chains such as Lightning Network).}
        #'           \item{needTag}{(boolean or NA) Indicates whether a memo/tag is required for transactions on this chain.}
        #'           \item{chainId}{(string or NA) The unique identifier for the blockchain network associated with the currency.}
        #'           \item{depositFeeRate}{(string or NA) The fee rate applied to deposits on this chain, if provided by the API.}
        #'           \item{withdrawMaxFee}{(string or NA) The maximum fee charged for a withdrawal on this chain, if provided by the API.}
        #'           \item{depositTierFee}{(string or NA) The tiered fee structure for deposits on this chain, if provided by the API.}
        #'         }
        #'
        #' @details
        #' **Endpoint:** \code{GET https://api.kucoin.com/api/v3/currencies}  
        #'
        #' This method uses a public API endpoint and does not require authentication.
        #'
        #' @examples
        #' \dontrun{
        #'   # Retrieve all available currencies:
        #'   dt_all_currencies <- await(market_data$get_all_currencies())
        #'   print(dt_all_currencies)
        #' }
        #'
        #' @export
        get_all_currencies = function() {
            return(get_all_currencies_impl(base_url = self$base_url))
        },

        #' Retrieve Symbol Details
        #'
        #' This asynchronous method retrieves detailed information for a specified trading symbol from the KuCoin API.
        #' It returns a promise that resolves to a `data.table` containing various details about the trading symbol.
        #'
        #' **Workflow Overview:**
        #'
        #' 1. **Input Validation:**  
        #'    Validates that a valid trading symbol is provided using the helper function \code{verify_symbol()}.
        #'
        #' 2. **URL Construction:**  
        #'    Constructs the full API URL by concatenating the base URL (stored in the class) with the endpoint path 
        #'    \code{/api/v2/symbols/} and the provided symbol.
        #'
        #' 3. **HTTP Request and Response Processing:**  
        #'    Sends a GET request to the constructed URL using \code{httr::GET()} with a 10‑second timeout, and processes
        #'    the response using \code{process_kucoin_response()} to extract the \code{data} field.
        #'
        #' 4. **Data Conversion:**  
        #'    Converts the entire \code{data} property from the response into a \code{data.table}.
        #' 
        #' #' **API Documentation:**  
        #' [KuCoin Get Symbol](https://www.kucoin.com/docs-new/rest/spot-trading/market-data/get-all-symbols)
        #'
        #' @param symbol A character string representing the trading symbol (e.g., "BTC-USDT").
        #'
        #' @return A promise that resolves to a \code{data.table}:
        #' \describe{
        #'   \item{symbol}{(string) Unique code of the trading symbol (e.g., "BTC-USDT").}
        #'   \item{name}{(string) Name of the trading pair, which may change after renaming.}
        #'   \item{baseCurrency}{(string) The base currency of the trading pair (e.g., "BTC").}
        #'   \item{quoteCurrency}{(string) The quote currency of the trading pair (e.g., "USDT").}
        #'   \item{feeCurrency}{(string) The currency used for charging fees.}
        #'   \item{market}{(string) The trading market (e.g., "USDS", "BTC", "ALTS").}
        #'   \item{baseMinSize}{(string) The minimum order quantity required to place an order (in base currency).}
        #'   \item{quoteMinSize}{(string) The minimum order funds required to place a market order (in quote currency).}
        #'   \item{baseMaxSize}{(string) The maximum order size allowed (in base currency).}
        #'   \item{quoteMaxSize}{(string) The maximum order funds allowed (in quote currency).}
        #'   \item{baseIncrement}{(string) The quantity increment; order quantities must be a positive integer multiple of this value.}
        #'   \item{quoteIncrement}{(string) The quote increment; order funds must be a positive integer multiple of this value.}
        #'   \item{priceIncrement}{(string) The price increment; order prices must be a positive integer multiple of this value.}
        #'   \item{priceLimitRate}{(string) The threshold for price protection.}
        #'   \item{minFunds}{(string) The minimum trading amount required for an order.}
        #'   \item{isMarginEnabled}{(boolean) Indicates whether the trading pair is available for margin trading.}
        #'   \item{enableTrading}{(boolean) Indicates whether trading is enabled for this symbol.}
        #'   \item{feeCategory}{(integer) The fee category/type for the trading pair.}
        #'   \item{makerFeeCoefficient}{(string) The maker fee coefficient; the actual fee is calculated by multiplying by this value.}
        #'   \item{takerFeeCoefficient}{(string) The taker fee coefficient; the actual fee is calculated by multiplying by this value.}
        #'   \item{st}{(boolean) A flag indicating additional status information (usage context-specific).}
        #' }
        #'
        #' @details
        #' **Endpoint:** \code{GET https://api.kucoin.com/api/v2/symbols/{symbol}}  
        #'
        #' This method uses a public API endpoint that does not require authentication.
        get_symbol = function(symbol) {
            return(get_symbol_impl(
                base_url = self$base_url,
                symbol = symbol
            ))
        },

        #' Retrieve All Trading Symbols
        #'
        #' This asynchronous method retrieves a list of all available trading symbols (currency pairs) from the KuCoin API.
        #' The endpoint returns an array of symbol objects, each containing details such as the symbol code, base currency,
        #' quote currency, fee currency, trading market, order size limits, price increments, fee coefficients, and other trading-related parameters.
        #'
        #' **Workflow Overview:**
        #'
        #' 1. **Query String Construction (Optional):**  
        #'    Uses the helper function \code{build_query()} to construct a query string from the optional \code{market} parameter.
        #'
        #' 2. **URL Construction:**  
        #'    Constructs the full URL by concatenating the base URL (stored in the class) with the endpoint path 
        #'    \code{/api/v2/symbols} and the query string.
        #'
        #' 3. **HTTP Request:**  
        #'    Sends a GET request to the constructed URL using \code{httr::GET()} with a 10‑second timeout.
        #'
        #' 4. **Response Processing:**  
        #'    Processes the response using \code{process_kucoin_response()} to validate the HTTP status and API code,
        #'    then extracts the \code{data} field.
        #'
        #' 5. **Data Conversion:**  
        #'    Converts the entire \code{data} property (an array of symbol objects) into a \code{data.table}.
        #'
        #' **API Documentation:**  
        #' [KuCoin Get All Symbols](https://www.kucoin.com/docs-new/rest/spot-trading/market-data/get-all-symbols)
        #'
        #' @param market (Optional) A character string specifying the trading market filter (e.g., "ALTS", "USDS", "ETF").
        #'
        #' @return A promise that resolves to a \code{data.table} containing the trading symbol details. The data.table includes:
        #'         \describe{
        #'           \item{symbol}{(string) Unique code of the trading symbol (e.g., "BTC-USDT").}
        #'           \item{name}{(string) Name of the trading pair, which may change after renaming.}
        #'           \item{baseCurrency}{(string) The base currency of the trading pair (e.g., "BTC").}
        #'           \item{quoteCurrency}{(string) The quote currency of the trading pair (e.g., "USDT").}
        #'           \item{feeCurrency}{(string) The currency used for charging fees.}
        #'           \item{market}{(string) The trading market (e.g., "USDS", "BTC", "ALTS").}
        #'           \item{baseMinSize}{(string) The minimum order quantity required to place an order (in base currency).}
        #'           \item{quoteMinSize}{(string) The minimum order funds required to place a market order (in quote currency).}
        #'           \item{baseMaxSize}{(string) The maximum order size allowed (in base currency).}
        #'           \item{quoteMaxSize}{(string) The maximum order funds allowed (in quote currency).}
        #'           \item{baseIncrement}{(string) The quantity increment; order quantities must be a positive integer multiple of this value.}
        #'           \item{quoteIncrement}{(string) The quote increment; order funds must be a positive integer multiple of this value.}
        #'           \item{priceIncrement}{(string) The price increment; order prices must be a positive integer multiple of this value.}
        #'           \item{priceLimitRate}{(string) The threshold for price protection.}
        #'           \item{minFunds}{(string) The minimum trading amount required for an order.}
        #'           \item{isMarginEnabled}{(boolean) Indicates whether the trading pair is available for margin trading.}
        #'           \item{enableTrading}{(boolean) Indicates whether trading is enabled for this symbol.}
        #'           \item{feeCategory}{(integer) The fee category/type for the trading pair.}
        #'           \item{makerFeeCoefficient}{(string) The maker fee coefficient; the actual fee is calculated by multiplying by this value.}
        #'           \item{takerFeeCoefficient}{(string) The taker fee coefficient; the actual fee is calculated by multiplying by this value.}
        #'           \item{st}{(boolean) A flag indicating special treatment status for the symbol.}
        #'         }
        #'
        #' @details
        #' **Endpoint:** \code{GET https://api.kucoin.com/api/v2/symbols}  
        #'
        #' This method uses a public API endpoint and does not require authentication.
        #'
        #' @examples
        #' \dontrun{
        #'   # Retrieve all trading symbols:
        #'   dt_symbols <- await(market_data$get_all_symbols())
        #'   print(dt_symbols)
        #'
        #'   # Retrieve trading symbols filtered by market "ALTS":
        #'   dt_symbols_alts <- await(market_data$get_all_symbols(market = "ALTS"))
        #'   print(dt_symbols_alts)
        #' }
        #'
        #' @export
        get_all_symbols = function(market = NULL) {
            return(get_all_symbols_impl(
                base_url = self$base_url,
                market = market
            ))
        },

        #' Retrieve Ticker Information
        #'
        #' This asynchronous method retrieves Level 1 market data (ticker information) for a specified trading symbol from the KuCoin API.
        #' It returns a promise that resolves to a `data.table` containing the ticker details.
        #'
        #' **Workflow Overview:**
        #'
        #' 1. **Input Validation:**  
        #'    Validates that a trading symbol is provided.
        #'
        #' 2. **URL Construction:**  
        #'    Constructs the full URL by concatenating the base URL (stored in the class) with the endpoint path 
        #'    \code{/api/v1/market/orderbook/level1} and a query string built from the required \code{symbol} parameter.
        #'
        #' 3. **HTTP Request:**  
        #'    Sends a GET request to the constructed URL using \code{httr::GET()} with a 10‑second timeout.
        #'
        #' 4. **Response Processing:**  
        #'    Processes the response using \code{process_kucoin_response()} to validate the HTTP status and API code,
        #'    then extracts the \code{data} field.
        #'
        #' 5. **Data Conversion:**  
        #'    Converts the returned \code{data} (a named list containing ticker information) into a `data.table`.
        #'
        #' **API Documentation:**  
        #' [KuCoin Get Ticker](https://www.kucoin.com/docs-new/rest/spot-trading/market-data/get-ticker)
        #'
        #' @param symbol A character string representing the trading symbol (e.g., "BTC-USDT").
        #'
        #' @return A promise that resolves to a `data.table` containing the following columns:
        #'         \describe{
        #'           \item{time}{(integer) The timestamp of the ticker data (in milliseconds).}
        #'           \item{sequence}{(string) The sequence identifier for the ticker update.}
        #'           \item{price}{(string) The last traded price.}
        #'           \item{size}{(string) The last traded size.}
        #'           \item{bestBid}{(string) The best bid price.}
        #'           \item{bestBidSize}{(string) The best bid size.}
        #'           \item{bestAsk}{(string) The best ask price.}
        #'           \item{bestAskSize}{(string) The best ask size.}
        #'         }
        #'
        #' @details
        #' **Endpoint:** \code{GET https://api.kucoin.com/api/v1/market/orderbook/level1?symbol=<symbol>}  
        #'
        #' This method uses a public endpoint and does not require authentication.
        #'
        #' @examples
        #' \dontrun{
        #'   # Retrieve ticker information for BTC-USDT:
        #'   dt_ticker <- await(market_data$get_ticker(symbol = "BTC-USDT"))
        #'   print(dt_ticker)
        #' }
        #'
        #' @export
        get_ticker = function(symbol) {
            return(get_ticker_impl(
                base_url = self$base_url,
                symbol = symbol
            ))
        },

        #' Retrieve All Tickers
        #'
        #' This asynchronous method retrieves market tickers for all trading pairs from the KuCoin API.
        #' It returns a promise that resolves to a `data.table` containing detailed ticker information for each trading pair,
        #' including the global snapshot timestamp in both its original millisecond format and as a converted POSIXct datetime.
        #'
        #' **Workflow Overview:**
        #'
        #' 1. **HTTP Request:**  
        #'    Sends a GET request to the KuCoin endpoint using `httr::GET()` with a 10‑second timeout.
        #'
        #' 2. **Response Processing:**  
        #'    Processes the response using `process_kucoin_response()` to validate the HTTP status and API code,
        #'    then extracts the `data` field, which contains a global timestamp and an array of ticker objects.
        #'
        #' 3. **Data Conversion:**  
        #'    Converts the ticker array (an array of ticker objects) into a `data.table`.
        #'
        #' 4. **Snapshot Time Augmentation:**  
        #'    Adds the global snapshot time (in milliseconds) as well as a converted POSIXct datetime (using `time_convert_from_kucoin_ms()`).
        #'
        #' **API Documentation:**  
        #' [KuCoin Get All Tickers](https://www.kucoin.com/docs-new/rest/spot-trading/market-data/get-all-tickers)
        #'
        #' @return A promise that resolves to a `data.table` containing the following columns:
        #'         \describe{
        #'           \item{symbol}{(string) The trading symbol (e.g., "BTC-USDT").}
        #'           \item{symbolName}{(string) The symbol name (which may be updated if the currency name changes).}
        #'           \item{buy}{(string) The current best bid price.}
        #'           \item{bestBidSize}{(string) The size at the best bid price.}
        #'           \item{sell}{(string) The current best ask price.}
        #'           \item{bestAskSize}{(string) The size at the best ask price.}
        #'           \item{changeRate}{(string) The 24-hour change rate.}
        #'           \item{changePrice}{(string) The 24-hour price change.}
        #'           \item{high}{(string) The highest price in the last 24 hours.}
        #'           \item{low}{(string) The lowest price in the last 24 hours.}
        #'           \item{vol}{(string) The 24-hour trading volume.}
        #'           \item{volValue}{(string) The 24-hour trading turnover.}
        #'           \item{last}{(string) The last traded price.}
        #'           \item{averagePrice}{(string) The average price over the last 24 hours.}
        #'           \item{takerFeeRate}{(string) The taker fee rate.}
        #'           \item{makerFeeRate}{(string) The maker fee rate.}
        #'           \item{takerCoefficient}{(string) The taker fee coefficient.}
        #'           \item{makerCoefficient}{(string) The maker fee coefficient.}
        #'           \item{globalTime_ms}{(integer) The snapshot timestamp in milliseconds.}
        #'           \item{snapshotTime}{(POSIXct) The snapshot timestamp converted to a datetime (UTC).}
        #'         }
        #'
        #' @examples
        #' \dontrun{
        #'   # Retrieve all market tickers:
        #'   dt_tickers <- await(market_data$get_all_tickers())
        #'   print(dt_tickers)
        #' }
        #'
        #' @export
        get_all_tickers = function() {
            return(get_all_tickers_impl(base_url = self$base_url))
        }
    )    
)
