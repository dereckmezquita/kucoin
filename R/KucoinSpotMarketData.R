# File: ./R/KucoinSpotMarketData.R

box::use(
    ./impl_market_data_get_klines[ get_klines_impl ],
    ./impl_market_data[ get_currency_impl, get_all_currencies_impl, get_symbol_impl ],
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
        #' Each currency entry includes both summary information and detailed chain-specific data.
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
        #'    then extracts the \code{data} field.
        #'
        #' 4. **Data Conversion:**  
        #'    Converts the selected currency summary fields into a \code{data.table} and the nested \code{chains} data
        #'    into another \code{data.table}.
        #'
        #' 5. **Column Renaming:**  
        #'    Renames the chain-level \code{contractAddress} column to \code{chain_contractAddress} to avoid conflicts
        #'    with the currency-level field.
        #'
        #' 6. **Result Assembly:**  
        #'    Combines the currency summary and chain-specific data using \code{cbind()} and returns the final
        #'    \code{data.table}.
        #'
        #' **Returned Data Structure:**
        #'
        #' The promise resolves to a \code{data.table} containing the following columns:
        #'
        #' **Currency Summary Fields:**
        #' \describe{
        #'   \item{name}{(string) The short name of the currency.}
        #'   \item{fullName}{(string) The full descriptive name of the currency.}
        #'   \item{precision}{(integer) The number of decimal places supported by the currency.}
        #'   \item{confirms}{(integer or NULL) The number of block confirmations required at the currency level.}
        #'   \item{contractAddress}{(string or NULL) The primary contract address for tokenized currencies.}
        #'   \item{isMarginEnabled}{(boolean) Indicates whether margin trading is enabled for the currency.}
        #'   \item{isDebitEnabled}{(boolean) Indicates whether debit transactions are enabled for the currency.}
        #' }
        #'
        #' **Chain-Specific Fields:**
        #' \describe{
        #'   \item{chainName}{(string) The name of the blockchain network associated with the currency.}
        #'   \item{withdrawalMinSize}{(string) The minimum withdrawal amount permitted on this chain.}
        #'   \item{depositMinSize}{(string) The minimum deposit amount permitted on this chain.}
        #'   \item{withdrawFeeRate}{(string) The fee rate applied to withdrawals on this chain.}
        #'   \item{withdrawalMinFee}{(string) The minimum fee charged for a withdrawal on this chain.}
        #'   \item{isWithdrawEnabled}{(boolean) Indicates whether withdrawals are enabled on this chain.}
        #'   \item{isDepositEnabled}{(boolean) Indicates whether deposits are enabled on this chain.}
        #'   \item{confirms}{(integer) The number of blockchain confirmations required on this chain.}
        #'   \item{preConfirms}{(integer) The number of pre-confirmations required for on-chain verification on this chain.}
        #'   \item{chain_contractAddress}{(string) The chain-specific contract address (renamed from \code{contractAddress}).}
        #'   \item{withdrawPrecision}{(integer) The withdrawal precision, indicating the maximum number of decimal places for withdrawal amounts on this chain.}
        #'   \item{maxWithdraw}{(string or NULL) The maximum amount allowed per withdrawal transaction on this chain.}
        #'   \item{maxDeposit}{(string or NULL) The maximum amount allowed per deposit transaction on this chain (applicable to certain chains such as Lightning Network).}
        #'   \item{needTag}{(boolean) Indicates whether a memo/tag is required for transactions on this chain.}
        #'   \item{chainId}{(string) The unique identifier for the blockchain network associated with the currency.}
        #'   \item{depositFeeRate}{(string, optional) The fee rate applied to deposits on this chain, if provided by the API.}
        #'   \item{withdrawMaxFee}{(string, optional) The maximum fee charged for a withdrawal on this chain, if provided by the API.}
        #'   \item{depositTierFee}{(string, optional) The tiered fee structure for deposits on this chain, if provided by the API.}
        #' }
        #'
        #' @return A promise that resolves to a \code{data.table} containing the combined currency details as described above.
        #'
        #' @details
        #' **Endpoint:** \code{GET https://api.kucoin.com/api/v3/currencies}  
        #'
        #' This method uses a public API endpoint that does not require authentication.
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
        }
    )
)
