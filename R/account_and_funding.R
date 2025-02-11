# File: account_and_funding.R

box::use(
    httr[GET, status_code, content, timeout, add_headers],
    jsonlite[fromJSON],
    rlang[abort],
    coro,
    promises,
    data.table[as.data.table],
    ./helpers_api[build_headers],
    ./utils[get_base_url, build_query]
)

#' Get Account Summary Information Implementation
#'
#' This asynchronous function implements the logic for retrieving account summary information
#' from the KuCoin API. It constructs the full URL, builds the authentication headers, sends the
#' GET request, and returns the parsed response data as a data.table.
#'
#' @param config A list containing API configuration parameters.
#'
#' @return A promise that resolves to a data.table containing the account summary data.
#'
#' @details
#' **Endpoint:** `GET https://api.kucoin.com/api/v2/user-info`
#'
#' **Response Schema:**
#' - **code** (string): `"200000"` indicates success.
#' - **data** (object): Contains fields such as `level`, `subQuantity`, `spotSubQuantity`,
#'   `marginSubQuantity`, `futuresSubQuantity`, `optionSubQuantity`, `maxSubQuantity`,
#'   `maxDefaultSubQuantity`, `maxSpotSubQuantity`, `maxMarginSubQuantity`, `maxFuturesSubQuantity`, and `maxOptionSubQuantity`.
#'
#' The returned data is converted to a data.table before resolving the promise.
#'
#' @examples
#' \dontrun{
#'   config <- list(
#'       api_key = "your_api_key",
#'       api_secret = "your_api_secret",
#'       api_passphrase = "your_api_passphrase",
#'       base_url = "https://api.kucoin.com",
#'       key_version = "2"
#'   )
#'   # Run the asynchronous request using coro::run
#'   coro::run(function() {
#'       dt <- await(get_account_summary_info_impl(config))
#'       print(dt)
#'   })
#' }
#'
#' @export
get_account_summary_info_impl <- coro::async(function(config) {
    tryCatch({
        # Retrieve the base URL from the configuration.
        base_url <- get_base_url(config)
        # Define the endpoint for account summary information.
        endpoint <- "/api/v2/user-info"
        method <- "GET"
        body <- ""
        # Build the authentication headers asynchronously.
        headers <- await(build_headers(method, endpoint, body, config))
        # Construct the full URL.
        url <- paste0(base_url, endpoint)
        
        # Send the GET request to the KuCoin API using the headers directly.
        response <- GET(url, headers, timeout(3))
        
        # Check that the HTTP status code is 200 (OK).
        if (status_code(response) != 200) {
            abort(paste("Request failed with status code", status_code(response)))
        }
        
        # Retrieve and parse the response content.
        response_text <- content(response, as = "text", encoding = "UTF-8")
        parsed_response <- fromJSON(response_text)
        
        # Validate the structure of the API response.
        if (!all(c("code", "data") %in% names(parsed_response))) {
            abort("Invalid API response structure.")
        }
        
        # Check for a successful API response code.
        if (parsed_response$code != "200000") {
            abort(paste("KuCoin API returned an error:", parsed_response$code))
        }
        
        # Convert the returned data into a data.table.
        dt <- as.data.table(parsed_response$data)
        return(dt)
    }, error = function(e) {
        abort(paste("Error in get_account_summary_info_impl:", conditionMessage(e)))
    })
})

#' Get API Key Information Implementation
#'
#' This asynchronous function implements the logic for retrieving API key information
#' from the KuCoin API. It constructs the full URL, builds the authentication headers, sends the
#' GET request, and returns the parsed response data as a data.table.
#'
#' @param config A list containing API configuration parameters.
#'
#' @return A promise that resolves to a data.table containing the API key information.
#'
#' @details
#' **Endpoint:** `GET https://api.kucoin.com/api/v1/user/api-key`
#'
#' **Response Schema:**
#' - **code** (string): `"200000"` indicates success.
#' - **data** (object): Contains fields such as:
#'     - **uid** (integer): Account UID.
#'     - **subName** (string, optional): Sub account name (if applicable).
#'     - **remark** (string): Remarks.
#'     - **apiKey** (string): The API key.
#'     - **apiVersion** (integer): API version.
#'     - **permission** (string): Comma-separated list of permissions.
#'     - **ipWhitelist** (string, optional): IP whitelist.
#'     - **isMaster** (boolean): Whether it is the master account.
#'     - **createdAt** (integer): API key creation time in milliseconds.
#'
#' The returned data is converted to a data.table before resolving the promise.
#'
#' @examples
#' \dontrun{
#'   coro::run(function() {
#'       dt <- await(get_apikey_info_impl(config))
#'       print(dt)
#'   })
#' }
#'
#' @export
get_apikey_info_impl <- coro::async(function(config) {
    tryCatch({
        base_url <- get_base_url(config)
        endpoint <- "/api/v1/user/api-key"
        method <- "GET"
        body <- ""
        headers <- await(build_headers(method, endpoint, body, config))
        url <- paste0(base_url, endpoint)
        response <- GET(url, headers, timeout(3))
        if (status_code(response) != 200) {
            abort(paste("Request failed with status code", status_code(response)))
        }
        response_text <- content(response, as = "text", encoding = "UTF-8")
        parsed_response <- fromJSON(response_text)
        if (!all(c("code", "data") %in% names(parsed_response))) {
            abort("Invalid API response structure.")
        }
        if (parsed_response$code != "200000") {
            abort(paste("KuCoin API returned an error:", parsed_response$code))
        }
        dt <- as.data.table(parsed_response$data)
        return(dt)
    }, error = function(e) {
        abort(paste("Error in get_apikey_info_impl:", conditionMessage(e)))
    })
})

#' Get Spot Account Type Implementation
#'
#' This asynchronous function retrieves the spot account type information from the KuCoin API.
#' It sends a GET request to the `/api/v1/hf/accounts/opened` endpoint, which determines whether the
#' current user is a high-frequency spot user (returns TRUE) or a low-frequency spot user (returns FALSE).
#'
#' @param config A list containing API configuration parameters.
#'
#' @return A promise that resolves to a boolean indicating the spot account type.
#'
#' @details
#' **Endpoint:** `GET https://api.kucoin.com/api/v1/hf/accounts/opened`
#'
#' **Response Schema:**
#' - **code** (string): `"200000"` indicates success.
#' - **data** (boolean): `TRUE` indicates that the current user is a high-frequency spot user;
#'   `FALSE` indicates a low-frequency spot user.
#'
#' For further details, refer to the [KuCoin API Documentation](https://www.kucoin.com/docs-new/rest/account-info/account-funding/get-account-type-spot).
#'
#' @examples
#' \dontrun{
#'   config <- list(
#'       api_key = "your_api_key",
#'       api_secret = "your_api_secret",
#'       api_passphrase = "your_api_passphrase",
#'       base_url = "https://api.kucoin.com",
#'       key_version = "2"
#'   )
#'   coro::run(function() {
#'       is_high_freq <- await(get_spot_account_type_impl(config))
#'       print(is_high_freq)
#'   })
#' }
#'
#' @export
get_spot_account_type_impl <- coro::async(function(config) {
    tryCatch({
        # Retrieve the base URL from the configuration.
        base_url <- get_base_url(config)
        # Define the endpoint for spot account type.
        endpoint <- "/api/v1/hf/accounts/opened"
        method <- "GET"
        body <- ""
        # Build the authentication headers asynchronously.
        headers <- await(build_headers(method, endpoint, body, config))
        # Construct the full URL.
        url <- paste0(base_url, endpoint)
        
        # Send the GET request using the headers directly.
        response <- GET(url, headers, timeout(3))
        
        # Check that the HTTP status code is 200 (OK).
        if (status_code(response) != 200) {
            abort(paste("Request failed with status code", status_code(response)))
        }
        
        # Retrieve and parse the response content.
        response_text <- content(response, as = "text", encoding = "UTF-8")
        parsed_response <- fromJSON(response_text)
        
        # Validate the structure of the API response.
        if (!all(c("code", "data") %in% names(parsed_response))) {
            abort("Invalid API response structure.")
        }
        
        # Check for a successful API response code.
        if (parsed_response$code != "200000") {
            abort(paste("KuCoin API returned an error:", parsed_response$code))
        }
        
        # Return the boolean result from the API.
        return(parsed_response$data)
    }, error = function(e) {
        abort(paste("Error in get_spot_account_type_impl:", conditionMessage(e)))
    })
})

#' Get Spot Account List Implementation
#'
#' This asynchronous function retrieves a list of spot accounts from the KuCoin API.
#' It sends a GET request to the `/api/v1/accounts` endpoint with optional query parameters
#' (such as `currency` and `type`) and returns the account list as a data.table.
#'
#' @param config A list containing API configuration parameters.
#' @param query A list of query parameters to filter the account list.
#'              Supported parameters include:
#'              - **currency** (string, optional): e.g., "USDT".
#'              - **type** (string, optional): Allowed values include "main" or "trade".
#'
#' @return A promise that resolves to a data.table containing the spot account list.
#'
#' @details
#' **Endpoint:** `GET https://api.kucoin.com/api/v1/accounts`
#'
#' **Response Schema:**
#' - **code** (string): `"200000"` indicates success.
#' - **data** (array of objects): Each object contains:
#'     - **id** (string): Account ID.
#'     - **currency** (string): Currency code.
#'     - **type** (string): Account type (e.g., "main", "trade", "balance").
#'     - **balance** (string): Total funds in the account.
#'     - **available** (string): Funds available for withdrawal or trading.
#'     - **holds** (string): Funds on hold (not available for use).
#'
#' For further details, refer to the [KuCoin API Documentation](https://www.kucoin.com/docs-new/rest/account-info/account-funding/get-account-list-spot).
#'
#' @examples
#' \dontrun{
#'   config <- list(
#'       api_key = "your_api_key",
#'       api_secret = "your_api_secret",
#'       api_passphrase = "your_api_passphrase",
#'       base_url = "https://api.kucoin.com",
#'       key_version = "2"
#'   )
#'   # Optionally filter by currency and account type:
#'   query <- list(currency = "USDT", type = "main")
#'   coro::run(function() {
#'       dt <- await(get_spot_account_list_impl(config, query))
#'       print(dt)
#'   })
#' }
#'
#' @export
get_spot_account_list_impl <- coro::async(function(config, query = list()) {
    tryCatch({
        # Retrieve the base URL from the configuration.
        base_url <- get_base_url(config)
        # Define the endpoint for spot accounts.
        endpoint <- "/api/v1/accounts"
        method <- "GET"
        body <- ""
        # Build the query string using the provided query parameters.
        qs <- build_query(query)
        # Build the authentication headers asynchronously.
        headers <- await(build_headers(method, endpoint, body, config))
        # Construct the full URL (including the query string).
        url <- paste0(base_url, endpoint, qs)
        
        # Send the GET request to the KuCoin API using the headers directly.
        response <- GET(url, headers, timeout(3))
        
        # Check that the HTTP status code is 200 (OK).
        if (status_code(response) != 200) {
            abort(paste("Request failed with status code", status_code(response)))
        }
        
        # Retrieve and parse the response content.
        response_text <- content(response, as = "text", encoding = "UTF-8")
        parsed_response <- fromJSON(response_text)
        
        # Validate the structure of the API response.
        if (!all(c("code", "data") %in% names(parsed_response))) {
            abort("Invalid API response structure.")
        }
        
        # Check for a successful API response code.
        if (parsed_response$code != "200000") {
            abort(paste("KuCoin API returned an error:", parsed_response$code))
        }
        
        # Convert the returned data into a data.table.
        dt <- as.data.table(parsed_response$data)
        return(dt)
    }, error = function(e) {
        abort(paste("Error in get_spot_account_list_impl:", conditionMessage(e)))
    })
})