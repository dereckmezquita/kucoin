# File: ./R/impl_account_and_funding.R

box::use(
    ./helpers_api[ build_headers, process_kucoin_response ],
    ./utils[ build_query, convert_datetime_range_to_ms, get_api_keys, get_base_url ]
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
        response <- httr::GET(url, headers, timeout(3))

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
        response <- httr::GET(url, headers, timeout(3))

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
        response <- httr::GET(url, headers, timeout(3))

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
#'   - \strong{balance} (string): Total funds in the account.
#'   - \strong{available} (string): Funds available for withdrawal or trading.
#'   - \strong{holds} (string): Funds on hold.
#'
#' @details
#' **Endpoint:** \code{GET https://api.kucoin.com/api/v1/accounts}  
#'
#' **Raw Response Schema:**  
#' - \code{code} (string): Status code, where "200000" indicates success.
#' - \code{data} (array): An array of account objects as described above.
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
        response <- httr::GET(url, headers, timeout(3))

        parsed_response <- process_kucoin_response(response, url)
        return(data.table::as.data.table(parsed_response$data))
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

        response <- httr::GET(url, headers, timeout(3))
        parsed_response <- process_kucoin_response(response, url)

        return(data.table::as.data.table(parsed_response$data))
    }, error = function(e) {
        rlang::abort(paste("Error in get_spot_account_detail_impl:", conditionMessage(e)))
    })
})

#' Get Cross Margin Account Implementation
#'
#' This asynchronous function retrieves information about the cross margin account from the KuCoin API.
#' It sends a `GET` request to the `/api/v3/margin/accounts` endpoint with optional query parameters and
#' returns the parsed response data as a `data.table`. This function is intended for internal use within an R6 class
#' and is **not** meant for direct end-user consumption.
#'
#' 1. **URL Construction:** Constructs the full API URL by calling \code{get_base_url()} (or using the user-supplied \code{base_url})
#'    and appending the endpoint and query string.
#' 2. **Header Preparation:** Builds the authentication headers based on the HTTP method, full endpoint, and request body.
#' 3. **API Request:** Sends a `GET` request to the endpoint.
#' 4. **Response Processing:** Processes the API response using a helper function and converts the result to a `data.table`.
#'
#' @param keys A list containing API configuration parameters, as returned by \code{get_api_keys()}. The list must include:
#'   - \code{api_key}: Your KuCoin API key.
#'   - \code{api_secret}: Your KuCoin API secret.
#'   - \code{api_passphrase}: Your KuCoin API passphrase.
#'   - \code{key_version}: The version of the API key (e.g., "2").
#' @param base_url A character string representing the base URL for the API. If not provided, the function uses \code{get_base_url()}.
#' @param query A named list of query parameters to filter the account information. Supported parameters include:
#'   - \code{quoteCurrency} (string, optional): The quote currency. Allowed values are "USDT", "KCS", or "BTC". Defaults to "USDT" if not provided.
#'   - \code{queryType} (string, optional): The type of account query. Allowed values are:
#'       - "MARGIN": Only query low-frequency cross margin accounts.
#'       - "MARGIN_V2": Only query high-frequency cross margin accounts.
#'       - "ALL": Aggregate query, as seen on the website.
#'     Defaults to "MARGIN".
#'
#' @return A promise that resolves to a \code{data.table} containing the cross margin account information.
#' The returned data table includes the following fields:
#'   - \strong{totalAssetOfQuoteCurrency} (string): Total assets in the quote currency.
#'   - \strong{totalLiabilityOfQuoteCurrency} (string): Total liabilities in the quote currency.
#'   - \strong{debtRatio} (string): The debt ratio.
#'   - \strong{status} (string): The position status (e.g., "EFFECTIVE", "BANKRUPTCY", "LIQUIDATION", "REPAY", or "BORROW").
#'   - \strong{accounts} (list): A list of margin account details. Each element is an object containing:
#'       - \code{currency} (string): Currency code.
#'       - \code{total} (string): Total funds in the account.
#'       - \code{available} (string): Funds available for withdrawal or trading.
#'       - \code{hold} (string): Funds on hold.
#'       - \code{liability} (string): Current liabilities.
#'       - \code{maxBorrowSize} (string): Maximum borrowable amount.
#'       - \code{borrowEnabled} (boolean): Whether borrowing is enabled.
#'       - \code{transferInEnabled} (boolean): Whether transfers into the account are enabled.
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
#'     dt <- await(get_cross_margin_account_impl(keys, base_url, query))
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
        response <- httr::GET(url, headers, timeout(3))

        parsed_response <- process_kucoin_response(response, url)
        dt <- data.table::as.data.table(parsed_response$data)
        return(dt)
    }, error = function(e) {
        rlang::abort(paste("Error in get_cross_margin_account_impl:", conditionMessage(e)))
    })
})

#' Get Isolated Margin Account Implementation
#'
#' This asynchronous function retrieves information about the isolated margin account from the KuCoin API.
#' It sends a `GET` request to the `/api/v3/isolated/accounts` endpoint with optional query parameters and
#' returns the parsed response data as a `data.table`. This function is intended for internal use within an R6 class
#' and is **not** intended for direct end-user consumption.
#'
#' 1. **URL Construction:** Constructs the full API URL by calling \code{get_base_url()} (or using the user-supplied
#'    \code{base_url}) and appending the endpoint and query string.
#' 2. **Header Preparation:** Builds the authentication headers based on the HTTP method, full endpoint, and request body.
#' 3. **API Request:** Sends a `GET` request to the endpoint.
#' 4. **Response Processing:** Processes the API response using a helper function and converts the \code{"data"} field to a \code{data.table}.
#'
#' @param keys A list containing API configuration parameters, as returned by \code{get_api_keys()}. The list must include:
#'   - \code{api_key}: Your KuCoin API key.
#'   - \code{api_secret}: Your KuCoin API secret.
#'   - \code{api_passphrase}: Your KuCoin API passphrase.
#'   - \code{key_version}: The version of the API key (e.g., "2").
#' @param base_url A character string representing the base URL for the API. If not provided, the function uses \code{get_base_url()}.
#' @param query A named list of query parameters to filter the isolated margin account information. Supported parameters include:
#'   - \code{symbol} (string, optional): For isolated trading pairs; if omitted, queries all pairs.
#'   - \code{quoteCurrency} (string, optional): The quote currency. Allowed values: "USDT", "KCS", "BTC". Defaults to "USDT".
#'   - \code{queryType} (string, optional): The type of account query. Allowed values: "ISOLATED", "ISOLATED_V2", "ALL". Defaults to "ISOLATED".
#'
#' @return A promise that resolves to a \code{data.table} containing the isolated margin account information.
#'
#' @details
#' **Endpoint:** \code{GET https://api.kucoin.com/api/v3/isolated/accounts}
#'
#' **Raw Response Schema:**  
#' - \code{code} (string): Status code, where "200000" indicates success.
#' - \code{data} (object): Contains:
#'   - \code{totalAssetOfQuoteCurrency} (string): Total assets in the quote currency.
#'   - \code{totalLiabilityOfQuoteCurrency} (string): Total liabilities in the quote currency.
#'   - \code{timestamp} (integer): The timestamp.
#'   - \code{assets} (array): An array of objects, each representing an isolated margin account detail with fields such as:
#'       - \code{symbol} (string): Trading pair symbol (e.g., "BTC-USDT").
#'       - \code{status} (string): Position status.
#'       - \code{debtRatio} (string): Debt ratio.
#'       - \code{baseAsset} (object): Details of the base asset.
#'       - \code{quoteAsset} (object): Details of the quote asset.
#'
#' For more detailed information, please see the [KuCoin API Documentation](https://www.kucoin.com/docs-new/rest/account-info/account-funding/get-account-isolated-margin).
#'
#' @examples
#' \dontrun{
#'   # Retrieve API keys from the environment using get_api_keys()
#'   keys <- get_api_keys()
#'
#'   # Optionally, specify a base URL; if not provided, defaults to the value from get_base_url()
#'   base_url <- "https://api.kucoin.com"
#'
#'   # Define query parameters, for example:
#'   query <- list(quoteCurrency = "USDT", queryType = "ISOLATED")
#'
#'   # Execute the asynchronous request using coro::run:
#'   main_async <- coro::async(function() {
#'     dt <- await(get_isolated_margin_account_impl(keys, base_url, query))
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
        response <- httr::GET(url, headers, timeout(3))

        parsed_response <- process_kucoin_response(response, url)
        dt <- data.table::as.data.table(parsed_response$data)
        return(dt)
    }, error = function(e) {
        rlang::abort(paste("Error in get_isolated_margin_account_impl:", conditionMessage(e)))
    })
})

#' Get Spot Ledger Implementation
#'
#' This asynchronous function retrieves transaction records (ledgers) for spot/margin accounts from the KuCoin API.
#' It sends a `GET` request to the `/api/v1/accounts/ledgers` endpoint with optional query parameters and returns
#' the parsed ledger information as a `data.table`. This function is intended for internal use within an R6 class and is
#' **not** intended for direct end-user consumption.
#'
#' 1. **URL Construction:** Constructs the full API URL by calling \code{get_base_url()} (or using the user-supplied
#'    \code{base_url}) and appending the endpoint and query string.
#' 2. **Header Preparation:** Builds the authentication headers based on the HTTP method, the full endpoint (including query string),
#'    and an empty request body.
#' 3. **API Request:** Sends a \code{GET} request to the endpoint.
#' 4. **Response Processing:** Processes the API response using a helper function and converts the resulting \code{"data"}
#'    field into a \code{data.table}.
#'
#' @param keys A list containing API configuration parameters, as returned by \code{get_api_keys()}. The list must include:
#'   - \code{api_key}: Your KuCoin API key.
#'   - \code{api_secret}: Your KuCoin API secret.
#'   - \code{api_passphrase}: Your KuCoin API passphrase.
#'   - \code{key_version}: The version of the API key (e.g., "2").
#' @param base_url A character string representing the base URL for the API. If not provided, defaults to the value returned by \code{get_base_url()}.
#' @param query A named list of query parameters to filter the ledger records. Supported parameters include:
#'   - \code{currency} (string, optional): One or more currencies (up to 10) to filter by; if omitted, all currencies are returned.
#'   - \code{direction} (string, optional): The direction of the transaction, either `"in"` or `"out"`.
#'   - \code{bizType} (string, optional): The business type of the transaction (e.g., `"DEPOSIT"`, `"WITHDRAW"`, `"TRANSFER"`, `"SUB_TRANSFER"`, `"TRADE_EXCHANGE"`, etc.).
#'   - \code{startAt} (integer, optional): Start time in milliseconds.
#'   - \code{endAt} (integer, optional): End time in milliseconds.
#'   - \code{currentPage} (integer, optional): The page number (default is 1).
#'   - \code{pageSize} (integer, optional): Number of results per page (minimum 10, maximum 500; default is 50).
#'
#' @return A promise that resolves to a \code{data.table} containing the ledger information. The data table includes:
#'   - \strong{currentPage} (integer): The current page number.
#'   - \strong{pageSize} (integer): The number of results per page.
#'   - \strong{totalNum} (integer): The total number of records.
#'   - \strong{totalPage} (integer): The total number of pages.
#'   - \strong{items} (list): An array of ledger records.
#'
#' @details
#' **Endpoint:** \code{GET https://api.kucoin.com/api/v1/accounts/ledgers}
#'
#' For further details, refer to the [KuCoin API Documentation](https://www.kucoin.com/docs-new/rest/account-info/account-funding/get-account-ledgers-spot-margin).
#'
#' @examples
#' \dontrun{
#'   # Retrieve API keys from the environment using get_api_keys()
#'   keys <- get_api_keys()
#'
#'   # Optionally, specify a base URL; if not provided, defaults to the value from get_base_url()
#'   base_url <- "https://api.kucoin.com"
#'
#'   # Define query parameters, for example:
#'   query <- list(currency = "BTC", direction = "in", bizType = "TRANSFER", currentPage = 1, pageSize = 50)
#'
#'   # Execute the asynchronous request using coro::run:
#'   main_async <- coro::async(function() {
#'     dt <- await(get_spot_ledger_impl(keys, base_url, query))
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
    query = list()
) {
    tryCatch({
        endpoint <- "/api/v1/accounts/ledgers"
        method <- "GET"
        body <- ""
        qs <- build_query(query)
        full_endpoint <- paste0(endpoint, qs)
        headers <- await(build_headers(method, full_endpoint, body, keys))
        url <- paste0(base_url, full_endpoint)
        response <- httr::GET(url, headers, timeout(3))
        parsed_response <- process_kucoin_response(response, url)
        dt <- data.table::as.data.table(parsed_response$data)
        return(dt)
    }, error = function(e) {
        rlang::abort(paste("Error in get_spot_ledger_impl:", conditionMessage(e)))
    })
})
