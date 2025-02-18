# File: ./R/impl_market_data_new.R

box::use(
    ./helpers_api[ process_kucoin_response ],
    ./utils[ build_query, get_base_url ],
    ./utils2[ verify_symbol ]
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
