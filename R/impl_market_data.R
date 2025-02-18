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
