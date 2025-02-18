# File: ./R/impl_market_data_new.R

box::use(
    ./helpers_api[ process_kucoin_response ],
    ./utils[ build_query, get_base_url ],
    ./utils2[ verify_ticker ]
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
    if (verify_ticker(currency)) {
        rlang::abort("Invalid currency format. Use 'BTC-USDT' format.")
    }

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
#' Each currency entry includes metadata such as its name, full name, precision, confirmation requirements,
#' and contract address, as well as a nested list of supported chains for multi-chain currencies.
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
#'    Converts the selected currency summary fields into a \code{data.table}. It also converts the nested
#'    \code{chains} data into a separate \code{data.table}.
#'
#' 5. **Column Renaming:**  
#'    Renames the \code{contractAddress} column in the chains table to \code{chain_contractAddress} to avoid
#'    potential name conflicts when combining with the summary table.
#'
#' 6. **Result Assembly:**  
#'    Combines the summary currency table and the chains table using \code{cbind()} and returns the result.
#'
#' **API Documentation:**  
#' [KuCoin Get All Currencies](https://www.kucoin.com/docs-new/rest/spot-trading/market-data/get-all-currencies)
#'
#' @param base_url A character string representing the base URL for the KuCoin API.
#'        Defaults to the value returned by \code{get_base_url()}.
#'
#' @return A promise that resolves to a \code{data.table} containing combined currency details.
#'         The resulting data.table includes:
#'         \describe{
#'           \item{chainName}{(string) The name of the blockchain network associated with the currency.}
#'           \item{withdrawalMinSize}{(string) The minimum withdrawal amount permitted on this chain.}
#'           \item{depositMinSize}{(string) The minimum deposit amount permitted on this chain.}
#'           \item{withdrawFeeRate}{(string) The fee rate applied to withdrawals on this chain.}
#'           \item{withdrawalMinFee}{(string) The minimum fee charged for a withdrawal transaction on this chain.}
#'           \item{isWithdrawEnabled}{(boolean) Indicates whether withdrawals are enabled on this chain.}
#'           \item{isDepositEnabled}{(boolean) Indicates whether deposits are enabled on this chain.}
#'           \item{confirms}{(integer) The number of blockchain confirmations required on this chain.}
#'           \item{preConfirms}{(integer) The number of pre-confirmations required for on-chain verification on this chain.}
#'           \item{chain_contractAddress}{(string) The contract address specific to this chain (renamed from \code{contractAddress}).}
#'           \item{withdrawPrecision}{(integer) The withdrawal precision, indicating the maximum number of decimal places for withdrawal amounts on this chain.}
#'           \item{maxWithdraw}{(string or NULL) The maximum amount allowed per withdrawal transaction on this chain.}
#'           \item{maxDeposit}{(string or NULL) The maximum amount allowed per deposit transaction on this chain (applicable to some chains such as Lightning Network).}
#'           \item{needTag}{(boolean) Indicates whether a memo/tag is required for transactions on this chain.}
#'           \item{chainId}{(string) The unique identifier for the blockchain network associated with the currency.}
#'           \item{depositFeeRate}{(string, optional) The fee rate applied to deposits on this chain, if provided by the API.}
#'           \item{withdrawMaxFee}{(string, optional) The maximum fee charged for a withdrawal on this chain, if provided by the API.}
#'           \item{depositTierFee}{(string, optional) The tiered fee structure for deposits on this chain, if provided by the API.}
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

        summary_fields <- c(
            "name", "fullName", "precision", "confirms",
            "contractAddress", "isMarginEnabled", "isDebitEnabled"
        )

        summary_dt <- data.table::as.data.table(parsed_response$data[summary_fields])
        currency_dt <- data.table::rbindlist(parsed_response$data$chains, fill = TRUE)

        # Rename the chain-level 'contractAddress' to avoid conflicts.
        currency_dt[, chain_contractAddress := contractAddress]
        currency_dt[, contractAddress := NULL]

        return(cbind(
            summary_dt,
            currency_dt
        ))
    }, error = function(e) {
        rlang::abort(paste("Error in get_all_currencies_impl:", conditionMessage(e)))
    })
})
