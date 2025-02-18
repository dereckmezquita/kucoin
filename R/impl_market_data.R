# File: ./R/impl_market_data_new.R

box::use(
    ./helpers_api[ process_kucoin_response ],
    ./utils[ build_query, get_base_url ],
    ./utils2[ verify_symbol, time_convert_from_kucoin_ms ]
)

#' Get Currency Details (Implementation)
#'
#' This asynchronous function retrieves detailed information for a specified currency from the KuCoin API.
#' The endpoint returns metadata such as the unique currency code, name, full name, precision, and other relevant
#' details including margin and debit support as well as a list of supported chains for multi-chain currencies.
#'
#' **Workflow Overview:**
#'
#' 1. **Input Validation:**  
#'    Validates that a non-empty currency code is provided.
#'
#' 2. **Query String Construction:**  
#'    Uses the helper function \code{build_query()} to build a query string from the optional \code{chain} parameter.
#'
#' 3. **URL Construction:**  
#'    Constructs the full URL by concatenating the base URL (obtained via \code{get_base_url()}), the endpoint path
#'    \code{/api/v3/currencies/} with the provided currency code, and the query string.
#'
#' 4. **HTTP Request:**  
#'    Sends a GET request to the constructed URL using \code{httr::GET()} with a 10‑second timeout.
#'
#' 5. **Response Processing:**  
#'    Processes the response using \code{process_kucoin_response()} which validates the HTTP status and API code,
#'    then extracts the \code{data} field.
#'
#' 6. **Data Conversion:**  
#'    Converts the resulting data (a named list of currency details) into a \code{data.table} and returns it.
#'
#' **API Documentation:**  
#' [KuCoin Get Currency](https://www.kucoin.com/docs-new/rest/spot-trading/market-data/get-currency)
#'
#' @param base_url A character string representing the base URL for the KuCoin API. Defaults to the value returned by \code{get_base_url()}.
#' @param currency A character string representing the currency code (e.g., "BTC", "USDT").
#' @param chain (Optional) A character string specifying the chain to query (e.g., "ERC20", "TRC20"). This applies to multi‑chain currencies.
#'
#' @return A promise that resolves to a \code{data.table} containing the currency details. The resulting data.table includes columns such as:
#'         \describe{
#'           \item{currency}{(string) The unique currency code.}
#'           \item{name}{(string) The short name of the currency.}
#'           \item{fullName}{(string) The full name of the currency.}
#'           \item{precision}{(integer) The number of decimal places for the currency.}
#'           \item{confirms}{(integer or NULL) The number of block confirmations required (if applicable).}
#'           \item{contractAddress}{(string or NULL) The contract address for tokenized currencies.}
#'           \item{isMarginEnabled}{(boolean) Indicates whether margin trading is enabled.}
#'           \item{isDebitEnabled}{(boolean) Indicates whether debit is enabled.}
#'           \item{chains}{(list) A list of chain objects containing chain‑specific details.}
#'         }
#'
#' @details
#' **Endpoint:** \code{GET https://api.kucoin.com/api/v3/currencies/{currency}}  
#'
#' This function uses a public endpoint and does not require authentication.
#'
#' @examples
#' \dontrun{
#'   # Retrieve details for Bitcoin:
#'   dt_currency <- await(get_currency_impl(currency = "BTC"))
#'   print(dt_currency)
#'
#'   # Retrieve details for USDT on the ERC20 chain:
#'   dt_currency <- await(get_currency_impl(currency = "USDT", chain = "ERC20"))
#'   print(dt_currency)
#' }
#'
#' @md
#' @export
get_currency_impl <- coro::async(function(
    base_url = get_base_url(),
    currency,
    chain = NULL
) {
    endpoint <- "/api/v3/currencies/"

    # Build query string from the optional chain parameter
    qs <- build_query(list(chain = chain))

    # Construct the full URL by appending the currency code to the endpoint
    endpoint <- paste0(endpoint, currency)
    url <- paste0(base_url, endpoint, qs)

    # Send the GET request with a 10-second timeout
    response <- httr::GET(url, httr::timeout(10))

    # Process the response and extract the 'data' field
    parsed_response <- process_kucoin_response(response, url)

    # Convert the resulting data (a named list) into a data.table and return it
    summary_fields <- c(
        "currency", "name", "fullName", "precision", "confirms",
        "contractAddress", "isMarginEnabled", "isDebitEnabled"
    )

    # TODO: benchmark what is more efficient cbind or := new cols
    summary_dt <- data.table::as.data.table(parsed_response$data[summary_fields])

    currency_dt <- data.table::as.data.table(parsed_response$data$chains)

    return(cbind(
        summary_dt,
        currency_dt
    ))
})

#' Get All Currencies (Implementation)
#'
#' This asynchronous function retrieves a list of all currencies available on the KuCoin API.
#' Each currency is returned along with its associated summary details and nested chain-specific details.
#' For currencies that support multiple chains, the summary information is replicated for each chain,
#' so that each row in the resulting data.table corresponds to a unique (currency, chain) combination.
#' If a currency has no associated chain data, dummy chain columns (filled with NA) are appended.
#'
#' **Workflow Overview:**
#'
#' 1. **URL Construction:**  
#'    Constructs the URL by concatenating the base URL (obtained via \code{get_base_url()})
#'    with the endpoint path \code{/api/v3/currencies}.
#'
#' 2. **HTTP Request:**  
#'    Sends a GET request to the constructed URL using \code{httr::GET()} with a 10‑second timeout.
#'
#' 3. **Response Processing:**  
#'    Processes the response using \code{process_kucoin_response()} to validate the HTTP status and API code,
#'    then extracts the \code{data} field.
#'
#' 4. **Data Conversion:**  
#'    Iterates over each row (currency) in the returned data.frame. For each currency, its summary fields are
#'    extracted and its nested \code{chains} data (if available) is converted to a data.table.
#'
#' 5. **Result Assembly:**  
#'    If chain data exists, the summary row is replicated for each chain row and combined with the chain data.
#'    Otherwise, dummy chain columns (filled with \code{NA}) are appended.
#'
#' **API Documentation:**  
#' [KuCoin Get All Currencies](https://www.kucoin.com/docs-new/rest/spot-trading/market-data/get-all-currencies)
#'
#' @param base_url A character string representing the base URL for the KuCoin API.
#'        Defaults to the value returned by \code{get_base_url()}.
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
#' This function uses a public endpoint and does not require authentication.
#'
#' @examples
#' \dontrun{
#'   # Retrieve all available currencies:
#'   dt_all_currencies <- await(get_all_currencies_impl())
#'   print(dt_all_currencies)
#' }
#'
#' @md
#' @export
get_all_currencies_impl <- coro::async(function(
    base_url = get_base_url()
) {
    tryCatch({
        endpoint <- "/api/v3/currencies"
        url <- paste0(base_url, endpoint)

        # Send a GET request to the endpoint with a timeout of 10 seconds.
        response <- httr::GET(url, httr::timeout(10))

        # Process and validate the response.
        parsed_response <- process_kucoin_response(response, url)

        # Iterate over each row (currency) in the returned data.frame.
        result_list <- lapply(seq_len(nrow(parsed_response$data)), function(i) {
            # Extract the i-th row as a one-row data.frame.
            curr <- parsed_response$data[i, , drop = FALSE]

            # Build a summary data.table from the currency row.
            summary_dt <- data.table::data.table(
                currency = curr$currency,
                name = curr$name,
                fullName = curr$fullName,
                precision = curr$precision,
                confirms = curr$confirms,
                contractAddress = curr$contractAddress,
                isMarginEnabled = curr$isMarginEnabled,
                isDebitEnabled = curr$isDebitEnabled
            )

            # Attempt to extract the chains data.
            chains_data <- curr$chains[[1]]

            # Check if chains_data is a data.frame with at least one row.
            if (is.data.frame(chains_data) && nrow(chains_data) > 0) {
                chains_dt <- data.table::as.data.table(chains_data, fill = TRUE)
                # Rename the chain-level 'contractAddress' to avoid conflicts.
                if ("contractAddress" %in% names(chains_dt)) {
                    data.table::setnames(chains_dt, "contractAddress", "chain_contractAddress")
                }
                # Replicate the summary row for each chain.
                summary_dt <- summary_dt[rep(1, nrow(chains_dt))]
                return(cbind(summary_dt, chains_dt))
            } else {
                # If no chains exist, create dummy chain columns (all NA).
                dummy_chain <- data.table::data.table(
                    chainName = NA_character_,
                    withdrawalMinSize = NA_character_,
                    depositMinSize = NA_character_,
                    withdrawFeeRate = NA_character_,
                    withdrawalMinFee = NA_character_,
                    isWithdrawEnabled = NA,
                    isDepositEnabled = NA,
                    confirms = NA_integer_,
                    preConfirms = NA_integer_,
                    chain_contractAddress = NA_character_,
                    withdrawPrecision = NA_integer_,
                    maxWithdraw = NA_character_,
                    maxDeposit = NA_character_,
                    needTag = NA,
                    chainId = NA_character_,
                    depositFeeRate = NA_character_,
                    withdrawMaxFee = NA_character_,
                    depositTierFee = NA_character_
                )
                return(cbind(summary_dt, dummy_chain))
            }
        })

        final_dt <- data.table::rbindlist(result_list, fill = TRUE)
        return(final_dt)
    }, error = function(e) {
        rlang::abort(paste("Error in get_all_currencies_impl:", conditionMessage(e)))
    })
})

#' Get Symbol (Implementation)
#'
#' This asynchronous function retrieves detailed information about a specified trading symbol from the KuCoin API.
#' It returns a promise that resolves to a \code{data.table} containing all available symbol details.
#'
#' **Workflow Overview:**
#'
#' 1. **Input Validation:**  
#'    Validates that a valid trading symbol is provided using the helper function \code{verify_symbol()}.
#'
#' 2. **URL Construction:**  
#'    Constructs the full API URL by concatenating the base URL (obtained via \code{get_base_url()}), the endpoint
#'    path \code{/api/v2/symbols/}, and the provided \code{symbol}.
#'
#' 3. **HTTP Request:**  
#'    Sends a GET request to the constructed URL using \code{httr::GET()} with a 10‑second timeout.
#'
#' 4. **Response Processing:**  
#'    Processes the response using \code{process_kucoin_response()} to validate the HTTP status and API code,
#'    then extracts the \code{data} field.
#'
#' 5. **Data Conversion:**  
#'    Converts the entire \code{data} property (a named list of symbol details) into a \code{data.table} without filtering.
#'
#' #' **API Documentation:**  
#' [KuCoin Get Symbol](https://www.kucoin.com/docs-new/rest/spot-trading/market-data/get-all-symbols)
#'
#' @param base_url A character string representing the base URL for the KuCoin API.
#'        Defaults to the value returned by \code{get_base_url()}.
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
#' This function uses a public API endpoint that does not require authentication.
#'
#' @examples
#' \dontrun{
#'   # Retrieve details for the BTC-USDT trading pair:
#'   dt_symbol <- await(get_symbol_impl(symbol = "BTC-USDT"))
#'   print(dt_symbol)
#' }
#'
#' @md
#' @export
get_symbol_impl <- coro::async(function(
    base_url = get_base_url(),
    symbol
) {
    tryCatch({
        endpoint <- "/api/v2/symbols/"
        url <- paste0(base_url, endpoint, symbol)

        # Send a GET request to the endpoint with a 10-second timeout.
        response <- httr::GET(url, httr::timeout(10))

        # Process and validate the response.
        parsed_response <- process_kucoin_response(response, url)

        # Convert the entire 'data' field from the response into a data.table.
        symbol_dt <- data.table::as.data.table(parsed_response$data)

        return(symbol_dt)
    }, error = function(e) {
        rlang::abort(paste("Error in get_symbol_impl:", conditionMessage(e)))
    })
})

#' Get All Symbols (Implementation)
#'
#' This asynchronous function retrieves a list of all available trading symbols (currency pairs)
#' from the KuCoin API. The endpoint returns an array of symbol objects with details such as the
#' symbol code, base currency, quote currency, fee currency, order size limits, price increments,
#' and fee coefficients.
#'
#' **Workflow Overview:**
#'
#' 1. **Query String Construction (Optional):**  
#'    Uses the helper function \code{build_query()} to build a query string from the optional \code{market} parameter.
#'
#' 2. **URL Construction:**  
#'    Constructs the full URL by concatenating the base URL (obtained via \code{get_base_url()}),
#'    the endpoint path \code{/api/v2/symbols}, and the optional query string.
#'
#' 3. **HTTP Request:**  
#'    Sends a GET request to the constructed URL using \code{httr::GET()} with a 10‑second timeout.
#'
#' 4. **Response Processing:**  
#'    Processes the response using \code{process_kucoin_response()} to validate the HTTP status and API code,
#'    then extracts the \code{data} field.
#'
#' 5. **Data Conversion:**  
#'    Converts the \code{data} property (an array of symbol objects) into a \code{data.table}.
#'
#' **API Documentation:**  
#' [KuCoin Get All Symbols](https://www.kucoin.com/docs-new/rest/spot-trading/market-data/get-all-symbols)
#'
#' @param base_url A character string representing the base URL for the KuCoin API.
#'        Defaults to the value returned by \code{get_base_url()}.
#' @param market (Optional) A character string specifying the trading market to filter symbols (e.g., "ALTS", "USDS", "ETF").
#'
#' @return A promise that resolves to a \code{data.table} containing the symbol details. The resulting data.table includes:
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
# Note: below new additions:
#'           \item{callauctionIsEnabled}{(boolean) Indicates whether call auction is enabled for the symbol.}
#'           \item{callauctionPriceFloor}{(string) The price floor for call auction.}
#'           \item{callauctionPriceCeiling}{(string) The price ceiling for call auction.}
#'           \item{callauctionFirstStageStartTime}{(integer) The start time of the first stage of call auction.}
#'           \item{callauctionSecondStageStartTime}{(integer) The start time of the second stage of call auction.}
#'           \item{callauctionThirdStageStartTime}{(integer) The start time of the third stage of call auction.}
#'           \item{tradingStartTime}{(integer) The start time of trading for the symbol.}
#'         }
#'
#' @details
#' **Endpoint:** \code{GET https://api.kucoin.com/api/v2/symbols}  
#'
#' This function uses a public endpoint and does not require authentication.
#'
#' @examples
#' \dontrun{
#'   # Retrieve all trading symbols:
#'   dt_symbols <- await(get_all_symbols_impl())
#'   print(dt_symbols)
#'
#'   # Retrieve all symbols filtered by market "ALTS":
#'   dt_symbols_alts <- await(get_all_symbols_impl(market = "ALTS"))
#'   print(dt_symbols_alts)
#' }
#'
#' @md
#' @export
get_all_symbols_impl <- coro::async(function(
    base_url = get_base_url(),
    market = NULL
) {
    tryCatch({
        # Build query string from the optional market parameter.
        qs <- build_query(list(market = market))
        endpoint <- "/api/v2/symbols"
        url <- paste0(base_url, endpoint, qs)

        # Send a GET request to the endpoint with a 10-second timeout.
        response <- httr::GET(url, httr::timeout(10))

        # Process and validate the response.
        parsed_response <- process_kucoin_response(response, url)

        # Convert the entire 'data' field (an array of symbol objects) into a data.table.
        symbols_dt <- data.table::as.data.table(parsed_response$data)

        return(symbols_dt)
    }, error = function(e) {
        rlang::abort(paste("Error in get_all_symbols_impl:", conditionMessage(e)))
    })
})

#' Get Ticker (Implementation)
#'
#' This asynchronous function retrieves Level 1 market data (ticker information) for a specified trading symbol from the KuCoin API.
#' The endpoint returns details such as the last traded price and size, the best bid and ask prices and sizes, as well as additional metadata.
#'
#' **Workflow Overview:**
#'
#' 1. **Query String Construction:**  
#'    Uses the helper function \code{build_query()} to construct a query string containing the required \code{symbol} parameter.
#'
#' 2. **URL Construction:**  
#'    Constructs the full URL by concatenating the base URL (obtained via \code{get_base_url()}), the endpoint path 
#'    \code{/api/v1/market/orderbook/level1}, and the query string.
#'
#' 3. **HTTP Request:**  
#'    Sends a GET request to the constructed URL using \code{httr::GET()} with a 10‑second timeout.
#'
#' 4. **Response Processing:**  
#'    Processes the response using \code{process_kucoin_response()} to validate the HTTP status and API code,
#'    then extracts the \code{data} field.
#'
#' 5. **Data Conversion:**  
#'    Converts the returned \code{data} (a named list containing ticker information) into a \code{data.table}.
#'
#' **API Documentation:**  
#' [KuCoin Get Ticker](https://www.kucoin.com/docs-new/rest/spot-trading/market-data/get-ticker)
#'
#' @param base_url A character string representing the base URL for the KuCoin API.
#'        Defaults to the value returned by \code{get_base_url()}.
#' @param symbol A character string representing the trading symbol (e.g., "BTC-USDT").
#'
#' @return A promise that resolves to a \code{data.table} containing the ticker information. The data.table includes:
#'         \describe{
#'           \item{symbol}{(string) The trading symbol (e.g., "BTC-USDT").}
#'           \item{timestamp}{(POSIXct) The timestamp of the ticker data in UTC.}
#'           \item{time_ms}{(integer) The timestamp of the ticker data (in milliseconds).}
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
#' **Endpoint:** \code{GET https://api.kucoin.com/api/v1/market/orderbook/level1?symbol=BTC-USDT}  
#'
#' This function uses a public endpoint and does not require authentication.
#'
#' @examples
#' \dontrun{
#'   # Retrieve ticker information for the BTC-USDT trading pair:
#'   dt_ticker <- await(get_ticker_impl(symbol = "BTC-USDT"))
#'   print(dt_ticker)
#' }
#'
#' @md
#' @export
get_ticker_impl <- coro::async(function(
    base_url = get_base_url(),
    symbol
) {
    tryCatch({
        qs <- build_query(list(symbol = symbol))
        endpoint <- "/api/v1/market/orderbook/level1"
        url <- paste0(base_url, endpoint, qs)

        # Send a GET request with a 10-second timeout.
        response <- httr::GET(url, httr::timeout(10))

        # Process and validate the response.
        parsed_response <- process_kucoin_response(response, url)

        # Convert the 'data' field (a named list) to a data.table.
        ticker_dt <- data.table::as.data.table(parsed_response$data)
        ticker_dt[, symbol := symbol]

        # convert kucoin time to POSIXct
        ticker_dt[, timestamp := time_convert_from_kucoin_ms(time)]
        # rename the time col to time_ms
        data.table::setnames(ticker_dt, "time", "time_ms")

        move_cols <- c("symbol", "timestamp", "time_ms")
        data.table::setcolorder(ticker_dt, c(move_cols, setdiff(names(ticker_dt), move_cols)))
        return(ticker_dt)
    }, error = function(e) {
        rlang::abort(paste("Error in get_ticker_impl:", conditionMessage(e)))
    })
})


#' Get All Tickers (Implementation)
#'
#' This asynchronous function retrieves market tickers for all trading pairs from the KuCoin API.
#' The endpoint returns a snapshot of market data, including 24-hour volume, for all symbols.
#' The response contains a global timestamp and an array of ticker objects. Each ticker object includes
#' details such as the last traded price and size, best bid/ask prices and sizes, and other trading parameters.
#'
#' **Workflow Overview:**
#'
#' 1. **URL Construction:**  
#'    Constructs the full API URL by concatenating the base URL (obtained via \code{get_base_url()})
#'    with the endpoint path \code{/api/v1/market/allTickers}. An optional query string can be built using the
#'    \code{build_query()} helper if needed (though no parameters are required by default).
#'
#' 2. **HTTP Request:**  
#'    Sends a GET request to the constructed URL using \code{httr::GET()} with a 10‑second timeout.
#'
#' 3. **Response Processing:**  
#'    Processes the response using \code{process_kucoin_response()} to validate the HTTP status and API code,
#'    then extracts the \code{data} field. The \code{data} object contains a global \code{time} field and a \code{ticker} array.
#'
#' 4. **Data Conversion:**  
#'    Converts the \code{ticker} array (an array of ticker objects) into a \code{data.table}.
#'
#' 5. **Snapshot Time Augmentation:**  
#'    Adds columns for the global snapshot time both in its original millisecond format and as a converted
#'    POSIXct datetime (using the helper function \code{time_convert_from_kucoin_ms()}).
#'
#' **API Documentation:**  
#' [KuCoin Get All Tickers](https://www.kucoin.com/docs-new/rest/spot-trading/market-data/get-all-tickers)
#'
#' @param base_url A character string representing the base URL for the KuCoin API.
#'        Defaults to the value returned by \code{get_base_url()}.
#'
#' @return A promise that resolves to a \code{data.table} containing the ticker information.
#'         The data.table includes the following columns:
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
#'           \item{globalTime_ms}{(integer) The snapshot timestamp in milliseconds (from the parent data object).}
#'           \item{snapshotTime}{(POSIXct) The snapshot timestamp converted to a datetime (UTC).}
#'         }
#'
#' @details
#' **Endpoint:** \code{GET https://api.kucoin.com/api/v1/market/allTickers}  
#'
#' This function uses a public endpoint and does not require authentication.
#'
#' @examples
#' \dontrun{
#'   # Retrieve all market tickers:
#'   dt_tickers <- await(market_data$get_all_tickers())
#'   print(dt_tickers)
#' }
#'
#' @md
#' @export
get_all_tickers_impl <- coro::async(function(
    base_url = get_base_url()
) {
    tryCatch({
        endpoint <- "/api/v1/market/allTickers"
        url <- paste0(base_url, endpoint)

        # Send a GET request to the endpoint with a timeout of 10 seconds.
        response <- httr::GET(url, httr::timeout(10))

        # Process and validate the response.
        parsed_response <- process_kucoin_response(response, url)

        # Extract the global snapshot time and the ticker array.
        global_time <- parsed_response$data$time
        ticker_list <- parsed_response$data$ticker

        # Convert the ticker array into a data.table.
        ticker_dt <- data.table::as.data.table(ticker_list)

        # Add the snapshot time information.
        ticker_dt[, globalTime_ms := global_time]
        ticker_dt[, globalTime_datetime := time_convert_from_kucoin_ms(global_time)]

        return(ticker_dt)
    }, error = function(e) {
        rlang::abort(paste("Error in get_all_tickers_impl:", conditionMessage(e)))
    })
})

#' Get Trade History (Implementation)
#'
#' This asynchronous function retrieves the trade history for a specified trading symbol from the KuCoin API.
#' The endpoint returns the most recent 100 trade records, with each record including details such as the sequence number,
#' filled price, filled size, trade side (buy/sell), and the timestamp (in nanoseconds).
#'
#' **Workflow Overview:**
#'
#' 1. **Query String Construction:**  
#'    Uses the helper function \code{build_query()} to construct a query string containing the required \code{symbol} parameter.
#'
#' 2. **URL Construction:**  
#'    Constructs the full URL by concatenating the base URL (obtained via \code{get_base_url()}), the endpoint path 
#'    \code{/api/v1/market/histories}, and the query string.
#'
#' 3. **HTTP Request:**  
#'    Sends a GET request to the constructed URL using \code{httr::GET()} with a 10‑second timeout.
#'
#' 4. **Response Processing:**  
#'    Processes the response using \code{process_kucoin_response()} to validate the HTTP status and API code,
#'    then extracts the \code{data} field which contains an array of trade history objects.
#'
#' 5. **Data Conversion:**  
#'    Converts the array of trade history objects into a \code{data.table}.
#'
#' 6. **Timestamp Conversion:**  
#'    Converts the trade timestamp from nanoseconds to a POSIXct datetime by dividing by 1e6 (to get milliseconds)
#'    and applying the helper function \code{time_convert_from_kucoin_ms()}.
#'
#' **API Documentation:**  
#' [KuCoin Get Trade History](https://www.kucoin.com/docs-new/rest/spot-trading/market-data/get-trade-history)
#'
#' @param base_url A character string representing the base URL for the KuCoin API.
#'        Defaults to the value returned by \code{get_base_url()}.
#' @param symbol A character string representing the trading symbol (e.g., "BTC-USDT").
#'
#' @return A promise that resolves to a \code{data.table} containing the trade history records.
#'         The data.table includes the following columns:
#'         \describe{
#'           \item{sequence}{(string) The sequence number for the trade.}
#'           \item{price}{(string) The filled price of the trade.}
#'           \item{size}{(string) The filled amount for the trade.}
#'           \item{side}{(string) The side of the trade ("buy" or "sell").}
#'           \item{time}{(integer) The original trade timestamp in nanoseconds.}
#'           \item{datetime}{(POSIXct) The trade timestamp converted to a datetime (UTC).}
#'         }
#'
#' @details
#' **Endpoint:** \code{GET https://api.kucoin.com/api/v1/market/histories?symbol=<symbol>}  
#'
#' This function uses a public API endpoint and does not require authentication.
#'
#' @examples
#' \dontrun{
#'   # Retrieve the trade history for the BTC-USDT trading pair:
#'   dt_trade_history <- await(market_data$get_trade_history(symbol = "BTC-USDT"))
#'   print(dt_trade_history)
#' }
#'
#' @md
#' @export
get_trade_history_impl <- coro::async(function(
    base_url = get_base_url(),
    symbol
) {
    tryCatch({
        qs <- build_query(list(symbol = symbol))
        endpoint <- "/api/v1/market/histories"
        url <- paste0(base_url, endpoint, qs)

        # Send a GET request to the endpoint with a 10-second timeout.
        response <- httr::GET(url, httr::timeout(10))

        # Process and validate the response.
        parsed_response <- process_kucoin_response(response, url)

        # Convert the 'data' field (an array of trade history objects) into a data.table.
        trade_history_dt <- data.table::as.data.table(parsed_response$data)

        # Convert the trade timestamp from nanoseconds to a POSIXct datetime.
        trade_history_dt[, timestamp := time_convert_from_kucoin_ms(time / 1e6)]

        return(trade_history_dt)
    }, error = function(e) {
        rlang::abort(paste("Error in get_trade_history_impl:", conditionMessage(e)))
    })
})
