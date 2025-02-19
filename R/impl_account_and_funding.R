# File: ./R/impl_account_and_funding.R

box::use(
    ./helpers_api[ auto_paginate, build_headers, process_kucoin_response ],
    ./utils[ build_query, get_api_keys, get_base_url ],
    ./utils_time_convert_kucoin[ time_convert_from_kucoin ]
)

#' Get Account Summary Information (Implementation)
#'
#' This asynchronous function implements the retrieval of account summary information from the KuCoin API.
#' It is designed for internal use as a method in an R6 class and is **not** intended for direct consumption by end-users.
#' The function performs the following operations:
#'
#' 1. **URL Construction:** Constructs the full API URL by calling \code{get_base_url()} (or using the user-supplied \code{base_url})
#'    and appending the endpoint.
#' 2. **Header Preparation:** Builds the authentication headers based on the HTTP method, endpoint, and request body.
#' 3. **API Request:** Sends a \code{GET} request to the KuCoin API endpoint for account summary information.
#' 4. **Response Processing:** Processes the API response using a helper function and converts the \code{"data"} field to a \code{data.table}.
#'
#' @param keys A list containing API configuration parameters, as returned by \code{get_api_keys()}. The list must include:
#'   - \code{api_key}: Your KuCoin API key.
#'   - \code{api_secret}: Your KuCoin API secret.
#'   - \code{api_passphrase}: Your KuCoin API passphrase.
#'   - \code{key_version}: The version of the API key (e.g., "2").
#' @param base_url A character string representing the base URL for the API. If not provided, the function uses \code{get_base_url()} to determine the base URL.
#'
#' @return A promise that resolves to a \code{data.table} containing the account summary data. The resulting data table is constructed from the raw API response and includes the following columns:
#'   - \strong{level} (integer): The user's VIP level.
#'   - \strong{subQuantity} (integer): Total number of sub-accounts.
#'   - \strong{spotSubQuantity} (integer): Number of sub-accounts with spot trading permissions.
#'   - \strong{marginSubQuantity} (integer): Number of sub-accounts with margin trading permissions.
#'   - \strong{futuresSubQuantity} (integer): Number of sub-accounts with futures trading permissions.
#'   - \strong{optionSubQuantity} (integer): Number of sub-accounts with option trading permissions.
#'   - \strong{maxSubQuantity} (integer): Maximum allowed sub-accounts (calculated as the sum of 
#'     \code{maxDefaultSubQuantity} and \code{maxSpotSubQuantity}).
#'   - \strong{maxDefaultSubQuantity} (integer): Maximum default open sub-accounts based on VIP level.
#'   - \strong{maxSpotSubQuantity} (integer): Maximum additional sub-accounts with spot trading permissions.
#'   - \strong{maxMarginSubQuantity} (integer): Maximum additional sub-accounts with margin trading permissions.
#'   - \strong{maxFuturesSubQuantity} (integer): Maximum additional sub-accounts with futures trading permissions.
#'   - \strong{maxOptionSubQuantity} (integer): Maximum additional sub-accounts with option trading permissions.
#'
#' @details
#' **Endpoint:** \code{GET https://api.kucoin.com/api/v2/user-info}  
#'
#' **Raw Response Schema:**  
#' - \code{code} (string): Status code, where "200000" indicates success.  
#' - \code{data} (object): Contains the account summary details as described above.
#'
#' For more detailed information, please see the [KuCoin API Documentation](https://www.kucoin.com/docs-new/rest/account-info/account-funding/get-account-summary-info).
#'
#' @examples
#' \dontrun{
#'   # Retrieve API keys from the environment using get_api_keys()
#'   keys <- get_api_keys()
#'
#'   # Optionally, specify a base URL; if not provided, defaults to the value from get_base_url()
#'   base_url <- "https://api.kucoin.com"
#'
#'   # Execute the asynchronous request using coro::run:
#'   main_async <- coro::async(function() {
#'     dt <- await(get_account_summary_info_impl(keys, base_url))
#'     print(dt)
#'   })
#' 
#´   main_async()
#'   while(!later::loop_empty()) {
#'     later::run_now()
#    }
#' }
#'
#' @md
#' @export
get_account_summary_info_impl <- coro::async(function(
    keys = get_api_keys(),
    base_url = get_base_url()
) {
    tryCatch({
        endpoint <- "/api/v2/user-info"
        method <- "GET"
        body <- ""
        headers <- await(build_headers(method, endpoint, body, keys))

        url <- paste0(base_url, endpoint)
        response <- httr::GET(url, headers, httr::timeout(3))

        # Process the response and extract the "data" field.
        parsed_response <- process_kucoin_response(response, url)

        return(data.table::as.data.table(parsed_response$data))
    }, error = function(e) {
        rlang::abort(paste("Error in get_account_summary_info_impl:", conditionMessage(e)))
    })
})

#' Get API Key Information (Implementation)
#'
#' This asynchronous function implements the logic for retrieving API key information from the KuCoin API.
#' It is designed for internal use as a method in an R6 class and is **not** intended for direct consumption by end-users.
#' The function constructs the full API URL by calling \code{get_base_url()} (or using the user-supplied \code{base_url}),
#' builds the authentication headers, sends the \code{GET} request to the endpoint, and processes the response,
#' converting the \code{"data"} field into a \code{data.table}.
#'
#' @param keys A list containing API configuration parameters, as returned by \code{get_api_keys()}. The list must include:
#'   - \code{api_key}: Your KuCoin API key.
#'   - \code{api_secret}: Your KuCoin API secret.
#'   - \code{api_passphrase}: Your KuCoin API passphrase.
#'   - \code{key_version}: The version of the API key (e.g., "2").
#' @param base_url A character string representing the base URL for the API. If not provided, the function uses \code{get_base_url()} to determine the base URL.
#'
#' @return A promise that resolves to a \code{data.table} containing the API key information. The resulting data table is constructed
#' from the \code{"data"} field of the raw API response and includes the following columns:
#'   - \strong{uid} (integer): Account UID.
#'   - \strong{subName} (string, optional): Sub account name (if applicable; not provided for master accounts).
#'   - \strong{remark} (string): Remarks associated with the API key.
#'   - \strong{apiKey} (string): The API key.
#'   - \strong{apiVersion} (integer): API version.
#'   - \strong{permission} (string): A comma-separated list of permissions (e.g., "General, Spot, Margin, Futures, InnerTransfer, Transfer, Earn").
#'   - \strong{ipWhitelist} (string, optional): IP whitelist, if applicable.
#'   - \strong{isMaster} (boolean): Indicates whether the API key belongs to the master account.
#'   - \strong{createdAt} (integer): API key creation time in milliseconds.
#'
#' @details
#' **Endpoint:** \code{GET https://api.kucoin.com/api/v1/user/api-key}  
#'
#' **Raw Response Schema:**  
#' - \code{code} (string): Status code, where "200000" indicates success.
#' - \code{data} (object): Contains API key details as described above.
#'
#' For additional details, please refer to the [KuCoin API Documentation](https://www.kucoin.com/docs-new/rest/account-info/account-funding/get-apikey-info).
#'
#' @examples
#' \dontrun{
#'   # Retrieve API keys from the environment using get_api_keys()
#'   keys <- get_api_keys()
#'
#'   # Optionally, specify a base URL; if not provided, defaults to the value from get_base_url()
#'   base_url <- "https://api.kucoin.com"
#'
#'   # Execute the asynchronous request using coro::run:
#'   main_async <- coro::async(function() {
#'     dt <- await(get_apikey_info_impl(keys, base_url))
#'     print(dt)
#'   })
#'
#'   main_async()
#'   while(!later::loop_empty()) {
#'     later::run_now()
#'   }
#' }
#'
#' @md
#' @export
get_apikey_info_impl <- coro::async(function(
    keys = get_api_keys(),
    base_url = get_base_url()
) {
    tryCatch({
        endpoint <- "/api/v1/user/api-key"
        method <- "GET"
        body <- ""
        headers <- await(build_headers(method, endpoint, body, keys))

        url <- paste0(base_url, endpoint)
        response <- httr::GET(url, headers, httr::timeout(3))

        # Process the response and extract the "data" field.
        parsed_response <- process_kucoin_response(response, url)

        return(data.table::as.data.table(parsed_response$data))
    }, error = function(e) {
        rlang::abort(paste("Error in get_apikey_info_impl:", conditionMessage(e)))
    })
})

#' Get Spot Account Type Implementation
#'
#' This asynchronous function retrieves spot account type information from the KuCoin API.
#' It is designed for internal use as a method in an R6 class and is **not** intended for direct consumption by end-users.
#' The function performs the following operations:
#'
#' 1. **URL Construction:** Constructs the full API URL by calling \code{get_base_url()} (or using the user-supplied \code{base_url})
#'    and appending the endpoint.
#' 2. **Header Preparation:** Builds the authentication headers based on the HTTP method, endpoint, and request body.
#' 3. **API Request:** Sends a \code{GET} request to the \code{/api/v1/hf/accounts/opened} endpoint.
#' 4. **Response Processing:** Processes the API response using a helper function and extracts the \code{"data"} field,
#'    which is expected to be a boolean value indicating the spot account type.
#'
#' @param keys A list containing API configuration parameters, as returned by \code{get_api_keys()}. The list must include:
#'   - \code{api_key}: Your KuCoin API key.
#'   - \code{api_secret}: Your KuCoin API secret.
#'   - \code{api_passphrase}: Your KuCoin API passphrase.
#'   - \code{key_version}: The version of the API key (e.g., "2").
#' @param base_url A character string representing the base URL for the API. If not provided, the function uses \code{get_base_url()} to determine the base URL.
#'
#' @return A promise that resolves to a boolean value:
#'   - \code{TRUE} indicates that the current user is a high-frequency spot user.
#'   - \code{FALSE} indicates that the current user is a low-frequency spot user.
#'
#' @details
#' **Endpoint:** \code{GET https://api.kucoin.com/api/v1/hf/accounts/opened}  
#'
#' **Raw Response Schema:**  
#' - \code{code} (string): Status code, where "200000" indicates success.  
#' - \code{data} (boolean): Spot account type; \code{TRUE} means high-frequency and \code{FALSE} means low-frequency.
#'
#' For more information, please refer to the [KuCoin API Documentation](https://www.kucoin.com/docs-new/rest/account-info/account-funding/get-account-type-spot).
#'
#' @examples
#' \dontrun{
#'   # Retrieve API keys from the environment using get_api_keys()
#'   keys <- get_api_keys()
#'
#'   # Optionally, specify a base URL; if not provided, defaults to the value from get_base_url()
#'   base_url <- "https://api.kucoin.com"
#'
#'   # Execute the asynchronous request using coro::run:
#'   main_async <- coro::async(function() {
#'     is_high_freq <- await(get_spot_account_type_impl(keys, base_url))
#'     print(is_high_freq)
#'   })
#'
#'   main_async()
#'   while (!later::loop_empty()) {
#'     later::run_now()
#'   }
#' }
#'
#' @md
#' @export
get_spot_account_type_impl <- coro::async(function(
    keys = get_api_keys(),
    base_url = get_base_url()
) {
    tryCatch({
        endpoint <- "/api/v1/hf/accounts/opened"
        method <- "GET"
        body <- ""
        headers <- await(build_headers(method, endpoint, body, keys))

        url <- paste0(base_url, endpoint)
        response <- httr::GET(url, headers, httr::timeout(3))

        # Process the response and extract the "data" field, expected to be boolean.
        parsed_response <- process_kucoin_response(response, url)
        return(parsed_response$data)
    }, error = function(e) {
        rlang::abort(paste("Error in get_spot_account_type_impl:", conditionMessage(e)))
    })
})

#' Get Spot Account List Implementation
#'
#' This asynchronous function retrieves a list of spot accounts from the KuCoin API.
#' It sends a `GET` request to the `/api/v1/accounts` endpoint with optional query parameters and returns the
#' account list as a `data.table`. This function is intended for internal use within an R6 class and is **not**
#' meant for direct end-user consumption.
#'
#' 1. **URL Construction:** Constructs the full API URL by calling \code{get_base_url()} (or using the user-supplied \code{base_url})
#'    and appending the endpoint and query string.
#' 2. **Header Preparation:** Builds the authentication headers based on the HTTP method, full endpoint, and request body.
#' 3. **API Request:** Sends a \code{GET} request to the endpoint.
#' 4. **Response Processing:** Processes the API response using a helper function and converts the \code{"data"} field to a \code{data.table}.
#'
#' @param keys A list containing API configuration parameters, as returned by \code{get_api_keys()}. The list must include:
#'   - \code{api_key}: Your KuCoin API key.
#'   - \code{api_secret}: Your KuCoin API secret.
#'   - \code{api_passphrase}: Your KuCoin API passphrase.
#'   - \code{key_version}: The version of the API key (e.g., "2").
#' @param base_url A character string representing the base URL for the API. If not provided, the function uses \code{get_base_url()} to determine the base URL.
#' @param query A named list of query parameters to filter the account list. Supported parameters include:
#'   - \code{currency} (string, optional): e.g., "USDT".
#'   - \code{type} (string, optional): Allowed values include "main" or "trade".
#'
#' @return A promise that resolves to a \code{data.table} containing the list of spot accounts.
#' The resulting data table is constructed from the \code{"data"} field of the raw API response, where each row represents an account with the following columns:
#'   - \strong{id} (string): Account ID.
#'   - \strong{currency} (string): Currency code.
#'   - \strong{type} (string): Account type (e.g., "main", "trade", or "balance").
#'   - \strong{balance} (numeric): Total funds in the account.
#'   - \strong{available} (numeric): Funds available for withdrawal or trading.
#'   - \strong{holds} (numeric): Funds on hold.
#'
#' @details
#' **Endpoint:** \code{GET https://api.kucoin.com/api/v1/accounts}  
#'
#' **Raw Response Schema:**  
#' - \code{code} (string): Status code, where "200000" indicates success.
#' - \code{data} (array): An array of account objects as described above.
#'
#' The response JSON data looks like this:
#' \preformatted{{
#' {
#'     "code": "200000",
#'     "data": [
#'         {
#'             "id": "548674591753",
#'             "currency": "USDT",
#'             "type": "trade",
#'             "balance": "26.66759503",
#'             "available": "26.66759503",
#'             "holds": "0"
#'         },
#'         {
#'             "id": "63355cd156298d0001b66e61",
#'             "currency": "USDT",
#'             "type": "main",
#'             "balance": "0.01",
#'             "available": "0.01",
#'             "holds": "0"
#'         }
#'     ]
#' }
#' }}
#'
#' For more detailed information, please refer to the [KuCoin API Documentation](https://www.kucoin.com/docs-new/rest/account-info/account-funding/get-account-list-spot).
#'
#' @examples
#' \dontrun{
#'   # Retrieve API keys from the environment using get_api_keys()
#'   keys <- get_api_keys()
#'
#'   # Optionally, specify a base URL; if not provided, defaults to the value from get_base_url()
#'   base_url <- "https://api.kucoin.com"
#'
#'   # Define query parameters to filter the account list (e.g., for USDT and main account)
#'   query <- list(currency = "USDT", type = "main")
#'
#'   # Execute the asynchronous request using coro::run:
#'   main_async <- coro::async(function() {
#'     dt <- await(get_spot_account_dt_impl(keys, base_url, query))
#'     print(dt)
#'   })
#'
#'   main_async()
#'   while (!later::loop_empty()) {
#'     later::run_now()
#'   }
#' }
#'
#' @md
#' @export
get_spot_account_dt_impl <- coro::async(function(
    keys = get_api_keys(),
    base_url = get_base_url(),
    query = list()
) {
    tryCatch({
        endpoint <- "/api/v1/accounts"
        method <- "GET"
        body <- ""
        qs <- build_query(query)
        full_endpoint <- paste0(endpoint, qs)
        headers <- await(build_headers(method, full_endpoint, body, keys))

        url <- paste0(base_url, full_endpoint)
        response <- httr::GET(url, headers, httr::timeout(3))

        parsed_response <- process_kucoin_response(response, url)
        # $data: list of lists
        account_dt <- data.table::rbindlist(parsed_response$data)

        if (nrow(account_dt) == 0) {
            return(data.table::data.table(
                id        = character(0),
                currency  = character(0),
                type      = character(0),
                balance   = numeric(0),
                available = numeric(0),
                holds     = numeric(0)
            ))
        }

        account_dt[, `:=`(
            id        = as.character(id),
            currency  = as.character(currency),
            type      = as.character(type),
            balance   = as.numeric(balance),
            available = as.numeric(available),
            holds     = as.numeric(holds)
        )]

        return(account_dt)
    }, error = function(e) {
        rlang::abort(paste("Error in get_spot_account_dt_impl:", conditionMessage(e)))
    })
})

#' Get Spot Account Detail Implementation
#'
#' This asynchronous function retrieves detailed information for a single spot account from the KuCoin API.
#' It is designed for internal use as a method in an R6 class and is **not** intended for direct end-user consumption.
#' The function performs the following steps:
#'
#' 1. **URL Construction:** Constructs the full API URL by calling \code{get_base_url()} (or using the user-supplied \code{base_url})
#'    and embedding the provided \code{accountId} into the endpoint.
#' 2. **Header Preparation:** Builds the authentication headers based on the HTTP method, endpoint, and an empty request body.
#' 3. **API Request:** Sends a \code{GET} request to the \code{/api/v1/accounts/{accountId}} endpoint.
#' 4. **Response Processing:** Processes the API response using a helper function and converts the \code{"data"} field to a \code{data.table}.
#'
#' @param keys A list containing API configuration parameters, as returned by \code{get_api_keys()}. The list must include:
#'   - \code{api_key}: Your KuCoin API key.
#'   - \code{api_secret}: Your KuCoin API secret.
#'   - \code{api_passphrase}: Your KuCoin API passphrase.
#'   - \code{key_version}: The version of the API key (e.g., "2").
#' @param base_url A character string representing the base URL for the API. If not provided, the function uses \code{get_base_url()}.
#' @param accountId A string representing the account ID for which the spot account details are requested.
#'
#' @return A promise that resolves to a \code{data.table} containing detailed information for the specified spot account.
#' The resulting data table is constructed from the \code{"data"} field of the raw API response, and includes the following columns:
#'   - \strong{currency} (string): The currency of the account.
#'   - \strong{balance} (string): Total funds in the account.
#'   - \strong{available} (string): Funds available for withdrawal or trading.
#'   - \strong{holds} (string): Funds on hold (not available for use).
#'
#' @details
#' **Endpoint:** \code{GET https://api.kucoin.com/api/v1/accounts/{accountId}}  
#'
#' **Raw Response Schema:**  
#' - \code{code} (string): Status code, where "200000" indicates success.
#' - \code{data} (object): Contains the account details, including:
#'   - \code{currency} (string): The currency of the account.
#'   - \code{balance} (string): Total funds in the account.
#'   - \code{available} (string): Funds available for withdrawal or trading.
#'   - \code{holds} (string): Funds on hold.
#'
#' For more detailed information, please see the [KuCoin API Documentation](https://www.kucoin.com/docs-new/rest/account-info/account-funding/get-account-detail-spot).
#'
#' @examples
#' \dontrun{
#'   # Retrieve API keys from the environment using get_api_keys()
#'   keys <- get_api_keys()
#'
#'   # Optionally, specify a base URL; if not provided, defaults to the value from get_base_url()
#'   base_url <- "https://api.kucoin.com"
#'
#'   # Specify the account ID for which details are requested, e.g., "123456789"
#'   accountId <- "123456789"
#'
#'   # Execute the asynchronous request using coro::run:
#'   main_async <- coro::async(function() {
#'     dt <- await(get_spot_account_detail_impl(keys, base_url, accountId))
#'     print(dt)
#'   })
#'
#'   main_async()
#'   while (!later::loop_empty()) {
#'     later::run_now()
#'   }
#' }
#'
#' @md
#' @export
get_spot_account_detail_impl <- coro::async(function(
    keys = get_api_keys(),
    base_url = get_base_url(),
    accountId
) {
    tryCatch({
        endpoint <- paste0("/api/v1/accounts/", accountId)
        method <- "GET"
        body <- ""
        headers <- await(build_headers(method, endpoint, body, keys))
        url <- paste0(base_url, endpoint)

        response <- httr::GET(url, headers, httr::timeout(3))
        parsed_response <- process_kucoin_response(response, url)

        account_detal_dt <- data.table::as.data.table(parsed_response$data)
        if (nrow(account_detal_dt) == 0) {
            return(data.table::data.table(
                currency  = character(0),
                balance   = numeric(0),
                available = numeric(0),
                holds     = numeric(0)
            ))
        }

        account_detal_dt[, `:=`(
            currency  = as.character(currency),
            balance   = as.numeric(balance),
            available = as.numeric(available),
            holds     = as.numeric(holds)
        )]

        return(account_detal_dt)
    }, error = function(e) {
        rlang::abort(paste("Error in get_spot_account_detail_impl:", conditionMessage(e)))
    })
})

#' Get Cross Margin Account Implementation
#'
#' This asynchronous function retrieves information about the cross margin account from the KuCoin API.
#' It sends a `GET` request to the `/api/v3/margin/accounts` endpoint with optional query parameters and
#' returns the parsed response as a list of two data tables: one containing the overall summary and one containing the detailed margin account list.
#'
#' 1. **URL Construction:** Constructs the full API URL by calling \code{get_base_url()} (or using the user-supplied \code{base_url})
#'    and appending the endpoint and query string.
#' 2. **Header Preparation:** Builds the authentication headers based on the HTTP method, full endpoint, and request body.
#' 3. **API Request:** Sends a `GET` request to the endpoint.
#' 4. **Response Processing:** Processes the API response using a helper function and converts the result into two separate data tables:
#'    - A summary data table for the overall cross margin account information.
#'    - A detailed data table for the list of margin accounts.
#'
#' @param keys A list containing API configuration parameters, as returned by \code{get_api_keys()}. The list must include:
#'   - \code{api_key}: Your KuCoin API key.
#'   - \code{api_secret}: Your KuCoin API secret.
#'   - \code{api_passphrase}: Your KuCoin API passphrase.
#'   - \code{key_version}: The version of the API key (e.g., "2").
#' @param base_url A character string representing the base URL for the API. If not provided, the function uses \code{get_base_url()}.
#' @param query A named list of query parameters to filter the account information. Supported parameters include:
#'   \describe{
#'     \item{\code{quoteCurrency}}{(string, optional): The quote currency. Allowed values are "USDT", "KCS", or "BTC". Defaults to "USDT" if not provided.}
#'     \item{\code{queryType}}{(string, optional): The type of account query. Allowed values are:
#'         \itemize{
#'           \item "MARGIN" - Only query low-frequency cross margin accounts.
#'           \item "MARGIN_V2" - Only query high-frequency cross margin accounts.
#'           \item "ALL" - Aggregate query, as seen on the website.
#'         }
#'         Defaults to "MARGIN".}
#'   }
#'
#' @return A promise that resolves to a named list with two elements:
#'   \describe{
#'     \item{\code{summary}}{A data.table containing the overall cross margin account summary with the following columns:
#'         \describe{
#'           \item{\code{totalAssetOfQuoteCurrency}}{(string) Total assets in the quote currency.}
#'           \item{\code{totalLiabilityOfQuoteCurrency}}{(string) Total liabilities in the quote currency.}
#'           \item{\code{debtRatio}}{(string) The debt ratio.}
#'           \item{\code{status}}{(string) The position status (e.g., "EFFECTIVE", "BANKRUPTCY", "LIQUIDATION", "REPAY", or "BORROW").}
#'         }
#'     }
#'     \item{\code{accounts}}{A data.table containing detailed margin account information. Each row represents a margin account with the following columns:
#'         \describe{
#'           \item{\code{currency}}{(string) Currency code.}
#'           \item{\code{total}}{(string) Total funds in the account.}
#'           \item{\code{available}}{(string) Funds available for withdrawal or trading.}
#'           \item{\code{hold}}{(string) Funds on hold.}
#'           \item{\code{liability}}{(string) Current liabilities.}
#'           \item{\code{maxBorrowSize}}{(string) Maximum borrowable amount.}
#'           \item{\code{borrowEnabled}}{(boolean) Indicates whether borrowing is enabled.}
#'           \item{\code{transferInEnabled}}{(boolean) Indicates whether transfers into the account are enabled.}
#'         }
#'     }
#'   }
#'
#' @details
#' **Endpoint:** \code{GET https://api.kucoin.com/api/v3/margin/accounts}
#'
#' For further details, please refer to the [KuCoin API Documentation](https://www.kucoin.com/docs-new/rest/account-info/account-funding/get-account-cross-margin).
#'
#' @examples
#' \dontrun{
#'   # Retrieve API keys from the environment using get_api_keys()
#'   keys <- get_api_keys()
#'
#'   # Optionally, specify a base URL; if not provided, defaults to the value from get_base_url()
#'   base_url <- "https://api.kucoin.com"
#'
#'   # Define query parameters to filter the account information
#'   query <- list(quoteCurrency = "USDT", queryType = "MARGIN")
#'
#'   # Execute the asynchronous request using coro::run:
#'   main_async <- coro::async(function() {
#'     result <- await(get_cross_margin_account_impl(keys, base_url, query))
#'     # 'result' is a list with two data.tables:
#'     print(result$summary)
#'     print(result$accounts)
#'   })
#'
#'   main_async()
#'   while (!later::loop_empty()) {
#'     later::run_now()
#'   }
#' }
#'
#' @md
#' @export
get_cross_margin_account_impl <- coro::async(function(
    keys = get_api_keys(),
    base_url = get_base_url(),
    query = list()
) {
    tryCatch({
        endpoint <- "/api/v3/margin/accounts"
        method <- "GET"
        body <- ""
        qs <- build_query(query)
        full_endpoint <- paste0(endpoint, qs)
        headers <- await(build_headers(method, full_endpoint, body, keys))

        url <- paste0(base_url, full_endpoint)
        response <- httr::GET(url, headers, httr::timeout(3))

        parsed_response <- process_kucoin_response(response, url)
        data_obj <- parsed_response$data

        # Extract summary fields into a data.table
        summary_fields <- c("totalAssetOfQuoteCurrency", "totalLiabilityOfQuoteCurrency", "debtRatio", "status")
        summary_dt <- data.table::as.data.table(data_obj[summary_fields])

        # Convert the 'accounts' array into a data.table
        accounts_dt <- data.table::as.data.table(data_obj$accounts)

        # Return a list of two data tables
        return(list(summary = summary_dt, accounts = accounts_dt))
    }, error = function(e) {
        rlang::abort(paste("Error in get_cross_margin_account_impl:", conditionMessage(e)))
    })
})

#' Get Isolated Margin Account Implementation
#'
#' This asynchronous function retrieves isolated margin account information from the KuCoin API.
#' It sends a `GET` request to the `/api/v3/isolated/accounts` endpoint with optional query parameters
#' and returns the parsed response as a named list of two flat data.tables.
#'
#' 1. **URL Construction:** Constructs the full API URL by calling \code{get_base_url()} (or using the supplied \code{base_url})
#'    and appending the endpoint and query string.
#' 2. **Header Preparation:** Builds the authentication headers using the provided API keys.
#' 3. **API Request:** Sends an asynchronous GET request to the endpoint.
#' 4. **Response Processing:** Processes the API response using a helper function and then:
#'    \itemize{
#'      \item Extracts overall summary fields into a data.table and adds a new column \code{datetime} by converting the raw \code{timestamp} using \code{time_convert_from_kucoin("ms")}.
#'      \item Flattens the nested \code{baseAsset} and \code{quoteAsset} objects from each asset into separate columns with prefixes.
#'    }
#'
#' @param keys A list containing API configuration parameters, as returned by \code{get_api_keys()}. The list must include:
#'   \describe{
#'     \item{\code{api_key}}{Your KuCoin API key.}
#'     \item{\code{api_secret}}{Your KuCoin API secret.}
#'     \item{\code{api_passphrase}}{Your KuCoin API passphrase.}
#'     \item{\code{key_version}}{The version of the API key (e.g., "2").}
#'   }
#' @param base_url A character string representing the base URL for the API. If not provided, \code{get_base_url()} is used.
#' @param query A named list of query parameters to filter the isolated margin account information. Supported parameters include:
#'   \describe{
#'     \item{\code{symbol}}{(string, optional) For isolated trading pairs; if omitted, queries all pairs.}
#'     \item{\code{quoteCurrency}}{(string, optional) The quote currency. Allowed values: "USDT", "KCS", "BTC". Defaults to "USDT".}
#'     \item{\code{queryType}}{(string, optional) The type of account query. Allowed values: "ISOLATED", "ISOLATED_V2", "ALL". Defaults to "ISOLATED".}
#'   }
#'
#' @return A promise that resolves to a named list with two elements:
#'   \describe{
#'     \item{\code{summary}}{
#'       A data.table with the following columns:
#'       \describe{
#'         \item{\code{totalAssetOfQuoteCurrency}}{(string) Total assets in the quote currency.}
#'         \item{\code{totalLiabilityOfQuoteCurrency}}{(string) Total liabilities in the quote currency.}
#'         \item{\code{timestamp}}{(integer) The raw timestamp in milliseconds.}
#'         \item{\code{datetime}}{(POSIXct) The converted date-time value (obtained via \code{time_convert_from_kucoin("ms")}).}
#'       }
#'     }
#'     \item{\code{assets}}{
#'       A data.table where each row represents one isolated margin account asset. The flattened columns include:
#'       \describe{
#'         \item{\code{symbol}}{(string) Trading pair symbol (e.g., "BTC-USDT").}
#'         \item{\code{status}}{(string) Position status.}
#'         \item{\code{debtRatio}}{(string) Debt ratio.}
#'         \item{\code{base_currency}}{(string) Currency code from the base asset.}
#'         \item{\code{base_borrowEnabled}}{(boolean) Whether borrowing is enabled for the base asset.}
#'         \item{\code{base_transferInEnabled}}{(boolean) Whether transfers into the base asset account are enabled.}
#'         \item{\code{base_liability}}{(string) Liability for the base asset.}
#'         \item{\code{base_total}}{(string) Total base asset amount.}
#'         \item{\code{base_available}}{(string) Available base asset amount.}
#'         \item{\code{base_hold}}{(string) Base asset amount on hold.}
#'         \item{\code{base_maxBorrowSize}}{(string) Maximum borrowable base asset amount.}
#'         \item{\code{quote_currency}}{(string) Currency code from the quote asset.}
#'         \item{\code{quote_borrowEnabled}}{(boolean) Whether borrowing is enabled for the quote asset.}
#'         \item{\code{quote_transferInEnabled}}{(boolean) Whether transfers into the quote asset account are enabled.}
#'         \item{\code{quote_liability}}{(string) Liability for the quote asset.}
#'         \item{\code{quote_total}}{(string) Total quote asset amount.}
#'         \item{\code{quote_available}}{(string) Available quote asset amount.}
#'         \item{\code{quote_hold}}{(string) Quote asset amount on hold.}
#'         \item{\code{quote_maxBorrowSize}}{(string) Maximum borrowable quote asset amount.}
#'       }
#'     }
#'   }
#'
#' @details
#' **Endpoint:** \code{GET https://api.kucoin.com/api/v3/isolated/accounts}
#'
#' For further details, please refer to the [KuCoin API Documentation](https://www.kucoin.com/docs-new/rest/account-info/account-funding/get-account-isolated-margin).
#'
#' @examples
#' \dontrun{
#'   keys <- get_api_keys()
#'   base_url <- "https://api.kucoin.com"
#'
#'   query <- list(quoteCurrency = "USDT", queryType = "ISOLATED")
#'
#'   main_async <- coro::async(function() {
#'     result <- await(get_isolated_margin_account_impl(keys, base_url, query))
#'     # 'result' is a list with two data.tables: summary and assets.
#'     print(result$summary)
#'     print(result$assets)
#'   })
#'
#'   main_async()
#'   while (!later::loop_empty()) {
#'     later::run_now()
#'   }
#' }
#'
#' @md
#' @export
get_isolated_margin_account_impl <- coro::async(function(
    keys = get_api_keys(),
    base_url = get_base_url(),
    query = list()
) {
    tryCatch({
        endpoint <- "/api/v3/isolated/accounts"
        method <- "GET"
        body <- ""
        qs <- build_query(query)
        full_endpoint <- paste0(endpoint, qs)
        headers <- await(build_headers(method, full_endpoint, body, keys))

        url <- paste0(base_url, full_endpoint)
        response <- httr::GET(url, headers, httr::timeout(3))

        parsed_response <- process_kucoin_response(response, url)
        data_obj <- parsed_response$data

        # Extract summary fields into a data.table and add a converted datetime column.
        summary_fields <- c("totalAssetOfQuoteCurrency", "totalLiabilityOfQuoteCurrency", "timestamp")
        summary_dt <- data.table::as.data.table(data_obj[summary_fields])
        summary_dt[, datetime := time_convert_from_kucoin(timestamp, "ms")]

        # Flatten the 'assets' array:
        assets_list <- lapply(data_obj$assets, function(asset) {
            # Remove nested objects from the top-level asset list.
            top <- asset
            top$baseAsset <- NULL
            top$quoteAsset <- NULL
            dt_row <- data.table::as.data.table(top)

            # Flatten baseAsset
            base <- data.table::as.data.table(asset$baseAsset)
            data.table::setnames(base, names(base), paste0("base_", names(base)))

            # Flatten quoteAsset
            quote <- data.table::as.data.table(asset$quoteAsset)
            data.table::setnames(quote, names(quote), paste0("quote_", names(quote)))

            # Combine all columns
            cbind(dt_row, base, quote)
        })
        assets_dt <- data.table::rbindlist(assets_list)

        return(list(summary = summary_dt, assets = assets_dt))
    }, error = function(e) {
        rlang::abort(paste("Error in get_isolated_margin_account_impl:", conditionMessage(e)))
    })
})

#' Get Spot Ledger Implementation
#'
#' This asynchronous function retrieves transaction records (ledgers) for spot/margin accounts from the KuCoin API.
#' It uses the pagination helper function \code{auto_paginate} to automatically fetch all pages of results and aggregate
#' the ledger records into a single flat \code{data.table}. Pagination is handled via separate arguments.
#'
#' 1. **URL Construction:** Constructs the full API URL by calling \code{get_base_url()} (or using the supplied \code{base_url})
#'    and appending the endpoint `/api/v1/accounts/ledgers` along with any user-supplied query parameters.
#' 2. **Header Preparation:** Builds the authentication headers using the provided API keys.
#' 3. **API Request:** Sends an asynchronous GET request to the endpoint.
#' 4. **Response Processing:** Uses the \code{auto_paginate} helper function to retrieve all pages of ledger records.
#'    The pagination parameters (\code{currentPage} and \code{pageSize}) are supplied as separate arguments.
#'    The helper aggregates the items from each page (from the \code{"items"} field) using \code{data.table::rbindlist}
#'    and returns a single flat \code{data.table}.
#'
#' @param keys A list containing API configuration parameters, as returned by \code{get_api_keys()}. The list must include:
#'   \describe{
#'     \item{\code{api_key}}{Your KuCoin API key.}
#'     \item{\code{api_secret}}{Your KuCoin API secret.}
#'     \item{\code{api_passphrase}}{Your KuCoin API passphrase.}
#'     \item{\code{key_version}}{The version of the API key (e.g., "2").}
#'   }
#' @param base_url A character string representing the base URL for the API. If not provided, defaults to the value returned by \code{get_base_url()}.
#' @param page_size (integer, optional) Number of results per page (minimum 10, maximum 500; default is 50).
#' @param max_pages (integer, optional) The maximum number of pages to fetch. Defaults to \code{Inf} (all pages).
#' @param query A named list of additional query parameters to filter the ledger records. Supported parameters include:
#'   \describe{
#'     \item{\code{currency}}{(string, optional): One or more currencies (up to 10) to filter by; if omitted, all currencies are returned.}
#'     \item{\code{direction}}{(string, optional): Transaction direction, either `"in"` or `"out"`.}
#'     \item{\code{bizType}}{(string, optional): Business type of the transaction (e.g., `"DEPOSIT"`, `"WITHDRAW"`, `"TRANSFER"`, `"SUB_TRANSFER"`, `"TRADE_EXCHANGE"`, etc.).}
#'     \item{\code{startAt}}{(integer, optional): Start time in milliseconds.}
#'     \item{\code{endAt}}{(integer, optional): End time in milliseconds.}
#'   }
#'   Note: The pagination parameters (\code{currentPage} and \code{pageSize}) are managed internally.
#'
#' @return A promise that resolves to a \code{data.table} containing the aggregated ledger records.
#' Each row represents a ledger record with the following columns:
#'   \describe{
#'     \item{\code{id}}{(string) Ledger record ID.}
#'     \item{\code{currency}}{(string) The currency.}
#'     \item{\code{amount}}{(string) Transaction amount.}
#'     \item{\code{fee}}{(string) Transaction fee.}
#'     \item{\code{balance}}{(string) Account balance after the transaction.}
#'     \item{\code{accountType}}{(string) The account type (e.g., "TRADE").}
#'     \item{\code{bizType}}{(string) Business type (e.g., "TRANSFER").}
#'     \item{\code{direction}}{(string) Transaction direction ("in" or "out").}
#'     \item{\code{createdAt}}{(integer) Timestamp of the transaction in milliseconds.}
#'     \item{\code{createdAtDatetime}}{(POSIXct) The converted date-time value (obtained via \code{time_convert_from_kucoin("ms")}).}
#'     \item{\code{context}}{(string) Additional context provided with the transaction.}
#'     \item{\code{currentPage}}{(integer) The current page number (from the response).}
#'     \item{\code{pageSize}}{(integer) The page size (from the response).}
#'     \item{\code{totalNum}}{(integer) The total number of records (from the response).}
#'     \item{\code{totalPage}}{(integer) The total number of pages (from the response).}
#'   }
#'
#' @details
#' **Endpoint:** \code{GET https://api.kucoin.com/api/v1/accounts/ledgers}
#'
#' For further details, please refer to the [KuCoin API Documentation](https://www.kucoin.com/docs-new/rest/account-info/account-funding/get-account-ledgers-spot-margin).
#'
#' @examples
#' \dontrun{
#'   keys <- get_api_keys()
#'   base_url <- "https://api.kucoin.com"
#'
#'   # Define additional query parameters (do not include pagination parameters)
#'   query <- list(currency = "BTC", direction = "in", bizType = "TRANSFER", startAt = 1728663338000, endAt = 1728692138000)
#'
#'   main_async <- coro::async(function() {
#'     dt <- await(get_spot_ledger_impl(keys, base_url, page_size = 50, max_pages = 10, query = query))
#'     print(dt)
#'   })
#'
#'   main_async()
#'   while (!later::loop_empty()) {
#'     later::run_now()
#'   }
#' }
#'
#' @md
#' @export
get_spot_ledger_impl <- coro::async(function(
    keys = get_api_keys(),
    base_url = get_base_url(),
    query = list(),
    page_size = 50,
    max_pages = Inf
) {
    tryCatch({
        # Initialize the query with default pagination parameters merged with additional query parameters.
        initial_query <- c(list(currentPage = 1, pageSize = page_size), query)

        fetch_page <- coro::async(function(q) {
            endpoint <- "/api/v1/accounts/ledgers"
            method <- "GET"
            body <- ""
            qs <- build_query(q)
            full_endpoint <- paste0(endpoint, qs)
            headers <- await(build_headers(method, full_endpoint, body, keys))
            url <- paste0(base_url, full_endpoint)
            response <- httr::GET(url, headers, httr::timeout(3))
            parsed_response <- process_kucoin_response(response, url)
            return(parsed_response$data)
        })

        # Automatically paginate through all pages using the auto_paginate helper.
        result <- await(auto_paginate(
            fetch_page = fetch_page,
            query = initial_query,
            items_field = "items",
            paginate_fields = list(currentPage = "currentPage", totalPage = "totalPage"),
            aggregate_fn = function(acc) {
                data <- data.table::rbindlist(acc, fill = TRUE)
                data[, createdAtDatetime := time_convert_from_kucoin(createdAt, "ms")]
                return(data)
            },
            max_pages = max_pages
        ))
        return(result)
    }, error = function(e) {
        rlang::abort(paste("Error in get_spot_ledger_impl:", conditionMessage(e)))
    })
})
