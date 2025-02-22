# File: ./R/impl_account_account_and_funding.R

box::use(
    ./helpers_api[auto_paginate, build_headers, process_kucoin_response],
    ./utils[build_query, get_api_keys, get_base_url],
    ./utils_time_convert_kucoin[time_convert_from_kucoin],
    coro[async, await],
    data.table[data.table, as.data.table, rbindlist, setnames],
    httr[GET, timeout],
    rlang[abort]
)

#' Retrieve Account Summary Information (Implementation)
#'
#' Retrieves account summary information from the KuCoin API asynchronously. This internal function is designed for use within an R6 class and is not intended for direct end-user consumption. It fetches details such as VIP level, sub-account counts, and limits.
#'
#' ### Workflow Overview
#' 1. **URL Construction**: Combines the base URL (from `get_base_url()` or provided `base_url`) with the endpoint `/api/v2/user-info`.
#' 2. **Header Preparation**: Constructs authentication headers using `build_headers()` with the HTTP method, endpoint, and an empty request body.
#' 3. **API Request**: Sends a GET request to the KuCoin API with a 3-second timeout via `httr::GET()`.
#' 4. **Response Processing**: Processes the response with `process_kucoin_response()` and converts the `"data"` field into a `data.table`.
#'
#' ### API Endpoint
#' `GET https://api.kucoin.com/api/v2/user-info`
#'
#' ### Usage
#' Utilised internally by the `KucoinAccountAndFunding` class to provide account summary data.
#'
#' ### Official Documentation
#' [KuCoin Get Account Summary Info](https://www.kucoin.com/docs-new/rest/account-info/account-funding/get-account-summary-info)
#'
#' @param keys List containing API configuration parameters from `get_api_keys()`, including:
#'   - `api_key`: Character string; your KuCoin API key.
#'   - `api_secret`: Character string; your KuCoin API secret.
#'   - `api_passphrase`: Character string; your KuCoin API passphrase.
#'   - `key_version`: Character string; API key version (e.g., `"2"`).
#'   Defaults to `get_api_keys()`.
#' @param base_url Character string representing the base URL for the API. Defaults to `get_base_url()`.
#' @return Promise resolving to a `data.table` containing:
#'   - `level` (integer): User's VIP level.
#'   - `subQuantity` (integer): Total number of sub-accounts.
#'   - `spotSubQuantity` (integer): Number of spot trading sub-accounts.
#'   - `marginSubQuantity` (integer): Number of margin trading sub-accounts.
#'   - `futuresSubQuantity` (integer): Number of futures trading sub-accounts.
#'   - `optionSubQuantity` (integer): Number of option trading sub-accounts.
#'   - `maxSubQuantity` (integer): Maximum allowed sub-accounts (sum of `maxDefaultSubQuantity` and `maxSpotSubQuantity`).
#'   - `maxDefaultSubQuantity` (integer): Maximum default sub-accounts based on VIP level.
#'   - `maxSpotSubQuantity` (integer): Maximum additional spot sub-accounts.
#'   - `maxMarginSubQuantity` (integer): Maximum additional margin sub-accounts.
#'   - `maxFuturesSubQuantity` (integer): Maximum additional futures sub-accounts.
#'   - `maxOptionSubQuantity` (integer): Maximum additional option sub-accounts.
#' @examples
#' \dontrun{
#' keys <- get_api_keys()
#' base_url <- "https://api.kucoin.com"
#' main_async <- coro::async(function() {
#'   dt <- await(get_account_summary_info_impl(keys = keys, base_url = base_url))
#'   print(dt)
#' })
#' main_async()
#' while (!later::loop_empty()) later::run_now()
#' }
#' @importFrom coro async await
#' @importFrom httr GET timeout
#' @importFrom data.table as.data.table
#' @importFrom rlang abort
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
        # saveRDS(response, "./api-responses/impl_account_account_and_funding/response-get_account_summary_info_impl.ignore.Rds")

        parsed_response <- process_kucoin_response(response, url)
        # saveRDS(parsed_response, "./api-responses/impl_account_account_and_funding/parsed_response-get_account_summary_info_impl.Rds")
        return(data.table::as.data.table(parsed_response$data))
    }, error = function(e) {
        rlang::abort(paste("Error in get_account_summary_info_impl:", conditionMessage(e)))
    })
})

#' Retrieve API Key Information (Implementation)
#'
#' Fetches detailed API key metadata from the KuCoin API asynchronously. This internal function is intended for use within an R6 class and is not meant for direct end-user consumption, providing details such as permissions and creation time.
#'
#' ### Workflow Overview
#' 1. **URL Construction**: Combines the base URL (from `get_base_url()` or provided `base_url`) with the endpoint `/api/v1/user/api-key`.
#' 2. **Header Preparation**: Constructs authentication headers using `build_headers()`.
#' 3. **API Request**: Sends a GET request with a 3-second timeout via `httr::GET()`.
#' 4. **Response Processing**: Processes the response with `process_kucoin_response()` and converts the `"data"` field into a `data.table`.
#'
#' ### API Endpoint
#' `GET https://api.kucoin.com/api/v1/user/api-key`
#'
#' ### Usage
#' Utilised internally by the `KucoinAccountAndFunding` class to expose API key details.
#'
#' ### Official Documentation
#' [KuCoin Get API Key Info](https://www.kucoin.com/docs-new/rest/account-info/account-funding/get-apikey-info)
#'
#' @param keys List containing API configuration parameters from `get_api_keys()`, including:
#'   - `api_key`: Character string; your KuCoin API key.
#'   - `api_secret`: Character string; your KuCoin API secret.
#'   - `api_passphrase`: Character string; your KuCoin API passphrase.
#'   - `key_version`: Character string; API key version (e.g., `"2"`).
#'   Defaults to `get_api_keys()`.
#' @param base_url Character string representing the base URL for the API. Defaults to `get_base_url()`.
#' @return Promise resolving to a `data.table` containing:
#'   - `uid` (integer): Account UID.
#'   - `subName` (character, optional): Sub-account name (if applicable).
#'   - `remark` (character): API key remarks.
#'   - `apiKey` (character): API key string.
#'   - `apiVersion` (integer): API version.
#'   - `permission` (character): Comma-separated permissions list (e.g., "General, Spot").
#'   - `ipWhitelist` (character, optional): IP whitelist.
#'   - `isMaster` (logical): Master account indicator.
#'   - `createdAt` (integer): Creation time in milliseconds.
#' @examples
#' \dontrun{
#' keys <- get_api_keys()
#' base_url <- "https://api.kucoin.com"
#' main_async <- coro::async(function() {
#'   dt <- await(get_apikey_info_impl(keys = keys, base_url = base_url))
#'   print(dt)
#' })
#' main_async()
#' while (!later::loop_empty()) later::run_now()
#' }
#' @importFrom coro async await
#' @importFrom httr GET timeout
#' @importFrom data.table as.data.table
#' @importFrom rlang abort
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
        # saveRDS(response, "./api-responses/impl_account_account_and_funding/response-get_apikey_info_impl.ignore.Rds")

        parsed_response <- process_kucoin_response(response, url)
        # saveRDS(parsed_response, "./api-responses/impl_account_account_and_funding/parsed_response-get_apikey_info_impl.Rds")
        return(data.table::as.data.table(parsed_response$data))
    }, error = function(e) {
        rlang::abort(paste("Error in get_apikey_info_impl:", conditionMessage(e)))
    })
})

#' Determine Spot Account Type (Implementation)
#'
#' Determines whether the spot account is high-frequency or low-frequency from the KuCoin API asynchronously. This internal function is designed for use within an R6 class and is not intended for direct end-user consumption, impacting asset transfer endpoints.
#'
#' ### Workflow Overview
#' 1. **URL Construction**: Combines the base URL (from `get_base_url()` or provided `base_url`) with the endpoint `/api/v1/hf/accounts/opened`.
#' 2. **Header Preparation**: Constructs authentication headers using `build_headers()`.
#' 3. **API Request**: Sends a GET request with a 3-second timeout via `httr::GET()`.
#' 4. **Response Processing**: Processes the response with `process_kucoin_response()` and extracts the boolean `"data"` field indicating account type.
#'
#' ### API Endpoint
#' `GET https://api.kucoin.com/api/v1/hf/accounts/opened`
#'
#' ### Usage
#' Utilised internally by `KucoinAccountAndFunding` to ascertain spot account frequency.
#'
#' ### Official Documentation
#' [KuCoin Get Account Type Spot](https://www.kucoin.com/docs-new/rest/account-info/account-funding/get-account-type-spot)
#'
#' @param keys List containing API configuration parameters from `get_api_keys()`, including:
#'   - `api_key`: Character string; your KuCoin API key.
#'   - `api_secret`: Character string; your KuCoin API secret.
#'   - `api_passphrase`: Character string; your KuCoin API passphrase.
#'   - `key_version`: Character string; API key version (e.g., `"2"`).
#'   Defaults to `get_api_keys()`.
#' @param base_url Character string representing the base URL for the API. Defaults to `get_base_url()`.
#' @return Promise resolving to a logical value: `TRUE` for high-frequency, `FALSE` for low-frequency.
#' @examples
#' \dontrun{
#' keys <- get_api_keys()
#' base_url <- "https://api.kucoin.com"
#' main_async <- coro::async(function() {
#'   is_high_freq <- await(get_spot_account_type_impl(keys = keys, base_url = base_url))
#'   print(is_high_freq)
#' })
#' main_async()
#' while (!later::loop_empty()) later::run_now()
#' }
#' @importFrom coro async await
#' @importFrom httr GET timeout
#' @importFrom rlang abort
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
        # saveRDS(response, "./api-responses/impl_account_account_and_funding/response-get_spot_account_type_impl.ignore.Rds")

        parsed_response <- process_kucoin_response(response, url)
        # saveRDS(parsed_response, "./api-responses/impl_account_account_and_funding/parsed_response-get_spot_account_type_impl.Rds")
        return(parsed_response$data)
    }, error = function(e) {
        rlang::abort(paste("Error in get_spot_account_type_impl:", conditionMessage(e)))
    })
})

#' Retrieve Spot Account List (Implementation)
#'
#' Fetches a list of spot accounts from the KuCoin API asynchronously with optional filters. This internal function is designed for use within an R6 class and is not intended for direct end-user consumption, returning financial metrics in a `data.table`.
#'
#' ### Workflow Overview
#' 1. **URL Construction**: Combines the base URL (from `get_base_url()` or provided `base_url`) with `/api/v1/accounts` and a query string from `build_query()`.
#' 2. **Header Preparation**: Constructs authentication headers using `build_headers()`.
#' 3. **API Request**: Sends a GET request with a 3-second timeout via `httr::GET()`.
#' 4. **Response Processing**: Processes the response with `process_kucoin_response()`, converts the `"data"` array into a `data.table`, and handles empty responses with a typed empty table.
#'
#' ### API Endpoint
#' `GET https://api.kucoin.com/api/v1/accounts`
#'
#' ### Usage
#' Utilised internally by `KucoinAccountAndFunding` to list spot accounts.
#'
#' ### Official Documentation
#' [KuCoin Get Account List Spot](https://www.kucoin.com/docs-new/rest/account-info/account-funding/get-account-list-spot)
#'
#' @param keys List containing API configuration parameters from `get_api_keys()`, including:
#'   - `api_key`: Character string; your KuCoin API key.
#'   - `api_secret`: Character string; your KuCoin API secret.
#'   - `api_passphrase`: Character string; your KuCoin API passphrase.
#'   - `key_version`: Character string; API key version (e.g., `"2"`).
#'   Defaults to `get_api_keys()`.
#' @param base_url Character string representing the base URL for the API. Defaults to `get_base_url()`.
#' @param query Named list of query parameters, e.g., `list(currency = "USDT", type = "main")`. Supported:
#'   - `currency` (character, optional): Filter by currency (e.g., `"USDT"`).
#'   - `type` (character, optional): Filter by account type (`"main"`, `"trade"`).
#' @return Promise resolving to a `data.table` containing:
#'   - `id` (character): Account ID.
#'   - `currency` (character): Currency code.
#'   - `type` (character): Account type (e.g., `"main"`, `"trade"`).
#'   - `balance` (numeric): Total funds.
#'   - `available` (numeric): Available funds.
#'   - `holds` (numeric): Funds on hold.
#' @examples
#' \dontrun{
#' keys <- get_api_keys()
#' base_url <- "https://api.kucoin.com"
#' query <- list(currency = "USDT", type = "main")
#' main_async <- coro::async(function() {
#'   dt <- await(get_spot_account_list_impl(keys = keys, base_url = base_url, query = query))
#'   print(dt)
#' })
#' main_async()
#' while (!later::loop_empty()) later::run_now()
#' }
#' @importFrom coro async await
#' @importFrom httr GET timeout
#' @importFrom data.table data.table as.data.table rbindlist
#' @importFrom rlang abort
#' @export
get_spot_account_list_impl <- coro::async(function(
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
        # saveRDS(response, "./api-responses/impl_account_account_and_funding/response-get_spot_account_list_impl.ignore.Rds")

        parsed_response <- process_kucoin_response(response, url)
        # saveRDS(parsed_response, "./api-responses/impl_account_account_and_funding/parsed_response-get_spot_account_list_impl.Rds")
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
        rlang::abort(paste("Error in get_spot_account_list_impl:", conditionMessage(e)))
    })
})

#' Retrieve Spot Account Details (Implementation)
#'
#' Fetches detailed financial metrics for a specific spot account from the KuCoin API asynchronously. This internal function is designed for use within an R6 class and is not intended for direct end-user consumption, using the account ID.
#'
#' ### Workflow Overview
#' 1. **URL Construction**: Combines the base URL (from `get_base_url()` or provided `base_url`) with `/api/v1/accounts/{accountId}`, embedding `accountId`.
#' 2. **Header Preparation**: Constructs authentication headers using `build_headers()`.
#' 3. **API Request**: Sends a GET request with a 3-second timeout via `httr::GET()`.
#' 4. **Response Processing**: Processes the response with `process_kucoin_response()`, converts the `"data"` field into a `data.table`, and handles empty responses with a typed empty table.
#'
#' ### API Endpoint
#' `GET https://api.kucoin.com/api/v1/accounts/{accountId}`
#'
#' ### Usage
#' Utilised internally by `KucoinAccountAndFunding` to detail a specific spot account.
#'
#' ### Official Documentation
#' [KuCoin Get Account Detail Spot](https://www.kucoin.com/docs-new/rest/account-info/account-funding/get-account-detail-spot)
#'
#' @param keys List containing API configuration parameters from `get_api_keys()`, including:
#'   - `api_key`: Character string; your KuCoin API key.
#'   - `api_secret`: Character string; your KuCoin API secret.
#'   - `api_passphrase`: Character string; your KuCoin API passphrase.
#'   - `key_version`: Character string; API key version (e.g., `"2"`).
#'   Defaults to `get_api_keys()`.
#' @param base_url Character string representing the base URL for the API. Defaults to `get_base_url()`.
#' @param accountId Character string; unique account ID (e.g., from `get_spot_account_detail_impl()`).
#' @return Promise resolving to a `data.table` containing:
#'   - `currency` (character): Currency of the account.
#'   - `balance` (numeric): Total funds.
#'   - `available` (numeric): Available funds.
#'   - `holds` (numeric): Funds on hold.
#' @examples
#' \dontrun{
#' keys <- get_api_keys()
#' base_url <- "https://api.kucoin.com"
#' accountId <- "123456789"
#' main_async <- coro::async(function() {
#'   dt <- await(get_spot_account_detail_impl(keys = keys, base_url = base_url, accountId = accountId))
#'   print(dt)
#' })
#' main_async()
#' while (!later::loop_empty()) later::run_now()
#' }
#' @importFrom coro async await
#' @importFrom httr GET timeout
#' @importFrom data.table data.table as.data.table
#' @importFrom rlang abort
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
        # saveRDS(response, "./api-responses/impl_account_account_and_funding/response-get_spot_account_detail_impl.ignore.Rds")
        parsed_response <- process_kucoin_response(response, url)
        # saveRDS(parsed_response, "./api-responses/impl_account_account_and_funding/parsed_response-get_spot_account_detail_impl.Rds")

        account_detail_dt <- data.table::as.data.table(parsed_response$data)
        if (nrow(account_detail_dt) == 0) {
            return(data.table::data.table(
                currency  = character(0),
                balance   = numeric(0),
                available = numeric(0),
                holds     = numeric(0)
            ))
        }

        account_detail_dt[, `:=`(
            currency  = as.character(currency),
            balance   = as.numeric(balance),
            available = as.numeric(available),
            holds     = as.numeric(holds)
        )]

        return(account_detail_dt)
    }, error = function(e) {
        rlang::abort(paste("Error in get_spot_account_detail_impl:", conditionMessage(e)))
    })
})

#' Retrieve Cross Margin Account Information (Implementation)
#'
#' Fetches cross margin account details from the KuCoin API asynchronously, including overall metrics and individual accounts. This internal function is designed for use within an R6 class and is not intended for direct end-user consumption.
#'
#' ### Workflow Overview
#' 1. **URL Construction**: Combines the base URL (from `get_base_url()` or provided `base_url`) with `/api/v3/margin/accounts` and a query string from `build_query()`.
#' 2. **Header Preparation**: Constructs authentication headers using `build_headers()`.
#' 3. **API Request**: Sends a GET request with a 3-second timeout via `httr::GET()`.
#' 4. **Response Processing**: Processes the response with `process_kucoin_response()`, splitting the `"data"` field into `summary` and `accounts` `data.table` objects.
#'
#' ### API Endpoint
#' `GET https://api.kucoin.com/api/v3/margin/accounts`
#'
#' ### Usage
#' Utilised internally by `KucoinAccountAndFunding` to provide cross margin account data.
#'
#' ### Official Documentation
#' [KuCoin Get Account Cross Margin](https://www.kucoin.com/docs-new/rest/account-info/account-funding/get-account-cross-margin)
#'
#' @param keys List containing API configuration parameters from `get_api_keys()`, including:
#'   - `api_key`: Character string; your KuCoin API key.
#'   - `api_secret`: Character string; your KuCoin API secret.
#'   - `api_passphrase`: Character string; your KuCoin API passphrase.
#'   - `key_version`: Character string; API key version (e.g., `"2"`).
#'   Defaults to `get_api_keys()`.
#' @param base_url Character string representing the base URL for the API. Defaults to `get_base_url()`.
#' @param query Named list of query parameters:
#'   - `quoteCurrency` (character, optional): Quote currency (e.g., `"USDT"`, `"KCS"`, `"BTC"`; default `"USDT"`).
#'   - `queryType` (character, optional): Account type (`"MARGIN"`, `"MARGIN_V2"`, `"ALL"`; default `"MARGIN"`).
#' @return Promise resolving to a named list containing:
#'   - `summary`: `data.table` with:
#'     - `totalAssetOfQuoteCurrency` (character): Total assets.
#'     - `totalLiabilityOfQuoteCurrency` (character): Total liabilities.
#'     - `debtRatio` (character): Debt ratio.
#'     - `status` (character): Position status (e.g., `"EFFECTIVE"`).
#'   - `accounts`: `data.table` with:
#'     - `currency` (character): Currency code.
#'     - `total` (character): Total funds.
#'     - `available` (character): Available funds.
#'     - `hold` (character): Funds on hold.
#'     - `liability` (character): Liabilities.
#'     - `maxBorrowSize` (character): Maximum borrowable amount.
#'     - `borrowEnabled` (logical): Borrowing enabled.
#'     - `transferInEnabled` (logical): Transfer-in enabled.
#' @examples
#' \dontrun{
#' keys <- get_api_keys()
#' base_url <- "https://api.kucoin.com"
#' query <- list(quoteCurrency = "USDT", queryType = "MARGIN")
#' main_async <- coro::async(function() {
#'   result <- await(get_cross_margin_account_impl(keys = keys, base_url = base_url, query = query))
#'   print(result$summary)
#'   print(result$accounts)
#' })
#' main_async()
#' while (!later::loop_empty()) later::run_now()
#' }
#' @importFrom coro async await
#' @importFrom httr GET timeout
#' @importFrom data.table as.data.table
#' @importFrom rlang abort
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
        # saveRDS(response, "./api-responses/impl_account_account_and_funding/response-get_cross_margin_account_impl.ignore.Rds")

        parsed_response <- process_kucoin_response(response, url)
        # saveRDS(parsed_response, "./api-responses/impl_account_account_and_funding/parsed_response-get_cross_margin_account_impl.Rds")
        data_obj <- parsed_response$data

        summary_fields <- c("totalAssetOfQuoteCurrency", "totalLiabilityOfQuoteCurrency", "debtRatio", "status")
        summary_dt <- data.table::as.data.table(data_obj[summary_fields])
        accounts_dt <- data.table::as.data.table(data_obj$accounts)

        return(list(summary = summary_dt, accounts = accounts_dt))
    }, error = function(e) {
        rlang::abort(paste("Error in get_cross_margin_account_impl:", conditionMessage(e)))
    })
})

#' Retrieve Isolated Margin Account Information (Implementation)
#'
#' Fetches isolated margin account details from the KuCoin API asynchronously for specific trading pairs. This internal function is designed for use within an R6 class and is not intended for direct end-user consumption, segregating collateral by pair.
#'
#' ### Workflow Overview
#' 1. **URL Construction**: Combines the base URL (from `get_base_url()` or provided `base_url`) with `/api/v3/isolated/accounts` and a query string from `build_query()`.
#' 2. **Header Preparation**: Constructs authentication headers using `build_headers()`.
#' 3. **API Request**: Sends a GET request with a 3-second timeout via `httr::GET()`.
#' 4. **Response Processing**: Processes the response with `process_kucoin_response()`, converting the `"data"` field into `summary` and flattened `assets` `data.table` objects, adding a `datetime` column.
#'
#' ### API Endpoint
#' `GET https://api.kucoin.com/api/v3/isolated/accounts`
#'
#' ### Usage
#' Utilised internally by `KucoinAccountAndFunding` to provide isolated margin account data.
#'
#' ### Official Documentation
#' [KuCoin Get Account Isolated Margin](https://www.kucoin.com/docs-new/rest/account-info/account-funding/get-account-isolated-margin)
#'
#' @param keys List containing API configuration parameters from `get_api_keys()`, including:
#'   - `api_key`: Character string; your KuCoin API key.
#'   - `api_secret`: Character string; your KuCoin API secret.
#'   - `api_passphrase`: Character string; your KuCoin API passphrase.
#'   - `key_version`: Character string; API key version (e.g., `"2"`).
#'   Defaults to `get_api_keys()`.
#' @param base_url Character string representing the base URL for the API. Defaults to `get_base_url()`.
#' @param query Named list of query parameters:
#'   - `symbol` (character, optional): Trading pair (e.g., `"BTC-USDT"`).
#'   - `quoteCurrency` (character, optional): Quote currency (e.g., `"USDT"`, `"KCS"`, `"BTC"`; default `"USDT"`).
#'   - `queryType` (character, optional): Type (`"ISOLATED"`, `"ISOLATED_V2"`, `"ALL"`; default `"ISOLATED"`).
#' @return Promise resolving to a named list containing:
#'   - `summary`: `data.table` with:
#'     - `totalAssetOfQuoteCurrency` (character): Total assets.
#'     - `totalLiabilityOfQuoteCurrency` (character): Total liabilities.
#'     - `timestamp` (integer): Timestamp in milliseconds.
#'     - `datetime` (POSIXct): Converted datetime.
#'   - `assets`: `data.table` with:
#'     - `symbol` (character): Trading pair.
#'     - `status` (character): Position status.
#'     - `debtRatio` (character): Debt ratio.
#'     - `base_currency` (character): Base currency code.
#'     - `base_borrowEnabled` (logical): Base borrowing enabled.
#'     - `base_transferInEnabled` (logical): Base transfer-in enabled.
#'     - `base_liability` (character): Base liability.
#'     - `base_total` (character): Base total funds.
#'     - `base_available` (character): Base available funds.
#'     - `base_hold` (character): Base funds on hold.
#'     - `base_maxBorrowSize` (character): Base max borrowable.
#'     - `quote_currency` (character): Quote currency code.
#'     - `quote_borrowEnabled` (logical): Quote borrowing enabled.
#'     - `quote_transferInEnabled` (logical): Quote transfer-in enabled.
#'     - `quote_liability` (character): Quote liability.
#'     - `quote_total` (character): Quote total funds.
#'     - `quote_available` (character): Quote available funds.
#'     - `quote_hold` (character): Quote funds on hold.
#'     - `quote_maxBorrowSize` (character): Quote max borrowable.
#' @examples
#' \dontrun{
#' keys <- get_api_keys()
#' base_url <- "https://api.kucoin.com"
#' query <- list(symbol = "BTC-USDT", quoteCurrency = "USDT")
#' main_async <- coro::async(function() {
#'   result <- await(get_isolated_margin_account_impl(keys = keys, base_url = base_url, query = query))
#'   print(result$summary)
#'   print(result$assets)
#' })
#' main_async()
#' while (!later::loop_empty()) later::run_now()
#' }
#' @importFrom coro async await
#' @importFrom httr GET timeout
#' @importFrom data.table as.data.table rbindlist setnames
#' @importFrom rlang abort
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
        # saveRDS(response, "./api-responses/impl_account_account_and_funding/response-get_isolated_margin_account_impl.ignore.Rds")

        parsed_response <- process_kucoin_response(response, url)
        # saveRDS(parsed_response, "./api-responses/impl_account_account_and_funding/parsed_response-get_isolated_margin_account_impl.Rds")
        data_obj <- parsed_response$data

        summary_fields <- c("totalAssetOfQuoteCurrency", "totalLiabilityOfQuoteCurrency", "timestamp")
        summary_dt <- data.table::as.data.table(data_obj[summary_fields])
        summary_dt[, datetime := time_convert_from_kucoin(timestamp, "ms")]

        assets_list <- lapply(data_obj$assets, function(asset) {
            top <- asset
            top$baseAsset <- NULL
            top$quoteAsset <- NULL
            dt_row <- data.table::as.data.table(top)

            base <- data.table::as.data.table(asset$baseAsset)
            data.table::setnames(base, names(base), paste0("base_", names(base)))

            quote <- data.table::as.data.table(asset$quoteAsset)
            data.table::setnames(quote, names(quote), paste0("quote_", names(quote)))

            cbind(dt_row, base, quote)
        })
        assets_dt <- data.table::rbindlist(assets_list)

        return(list(summary = summary_dt, assets = assets_dt))
    }, error = function(e) {
        rlang::abort(paste("Error in get_isolated_margin_account_impl:", conditionMessage(e)))
    })
})

#' Retrieve Spot Ledger Records (Implementation)
#'
#' Fetches detailed ledger records for spot and margin accounts from the KuCoin API asynchronously with pagination. This internal function is designed for use within an R6 class and is not intended for direct end-user consumption, aggregating transaction histories into a `data.table`.
#'
#' ### Workflow Overview
#' 1. **URL Construction**: Combines the base URL (from `get_base_url()` or provided `base_url`) with `/api/v1/accounts/ledgers`, merging query parameters with pagination settings.
#' 2. **Header Preparation**: Constructs authentication headers using `build_headers()` within an inner async function.
#' 3. **API Request**: Utilises `auto_paginate` to fetch all pages asynchronously via an inner `fetch_page` function.
#' 4. **Response Processing**: Aggregates `"items"` from each page into a `data.table` with `data.table::rbindlist()`, adding a `createdAtDatetime` column via `time_convert_from_kucoin()`.
#'
#' ### API Endpoint
#' `GET https://api.kucoin.com/api/v1/accounts/ledgers`
#'
#' ### Usage
#' Utilised internally by `KucoinAccountAndFunding` to retrieve ledger records for spot and margin accounts.
#'
#' ### Official Documentation
#' [KuCoin Get Account Ledgers Spot Margin](https://www.kucoin.com/docs-new/rest/account-info/account-funding/get-account-ledgers-spot-margin)
#'
#' @param keys List containing API configuration parameters from `get_api_keys()`, including:
#'   - `api_key`: Character string; your KuCoin API key.
#'   - `api_secret`: Character string; your KuCoin API secret.
#'   - `api_passphrase`: Character string; your KuCoin API passphrase.
#'   - `key_version`: Character string; API key version (e.g., `"2"`).
#'   Defaults to `get_api_keys()`.
#' @param base_url Character string representing the base URL for the API. Defaults to `get_base_url()`.
#' @param query Named list of query parameters (excluding pagination):
#'   - `currency` (character, optional): Filter by currency (up to 10).
#'   - `direction` (character, optional): `"in"` or `"out"`.
#'   - `bizType` (character, optional): Business type (e.g., `"DEPOSIT"`, `"TRANSFER"`).
#'   - `startAt` (integer, optional): Start time in milliseconds.
#'   - `endAt` (integer, optional): End time in milliseconds.
#' @param page_size Integer; number of results per page (10–500, default 50).
#' @param max_pages Numeric; maximum number of pages to fetch (default `Inf` for all pages).
#' @return Promise resolving to a `data.table` containing:
#'   - `id` (character): Ledger record ID.
#'   - `currency` (character): Currency.
#'   - `amount` (character): Transaction amount.
#'   - `fee` (character): Transaction fee.
#'   - `balance` (character): Post-transaction balance.
#'   - `accountType` (character): Account type.
#'   - `bizType` (character): Business type.
#'   - `direction` (character): Transaction direction.
#'   - `createdAt` (integer): Timestamp in milliseconds.
#'   - `createdAtDatetime` (POSIXct): Converted datetime.
#'   - `context` (character): Transaction context.
#'   - `currentPage` (integer): Current page number.
#'   - `pageSize` (integer): Page size.
#'   - `totalNum` (integer): Total records.
#'   - `totalPage` (integer): Total pages.
#' @examples
#' \dontrun{
#' keys <- get_api_keys()
#' base_url <- "https://api.kucoin.com"
#' query <- list(
#'   currency = "BTC",
#'   direction = "in",
#'   bizType = "TRANSFER",
#'   startAt = 1728663338000L,
#'   endAt = 1728692138000L
#' )
#' main_async <- coro::async(function() {
#'   dt <- await(get_spot_ledger_impl(
#'     keys = keys,
#'     base_url = base_url,
#'     query = query,
#'     page_size = 50L,
#'     max_pages = 10
#'   ))
#'   print(dt)
#' })
#' main_async()
#' while (!later::loop_empty()) later::run_now()
#' }
#' @importFrom coro async await
#' @importFrom httr GET timeout
#' @importFrom data.table data.table as.data.table rbindlist
#' @importFrom lubridate as_datetime
#' @importFrom rlang abort
#' @export
get_spot_ledger_impl <- coro::async(function(
    keys = get_api_keys(),
    base_url = get_base_url(),
    query = list(),
    page_size = 50,
    max_pages = Inf
) {
    tryCatch({
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
            # file_name <- paste0("get_spot_ledger_impl_", q$current_page)
            # saveRDS(response, paste0("./api-responses/impl_account_account_and_funding/response-", file_name, ".ignore.Rds"))
            parsed_response <- process_kucoin_response(response, url)
            # saveRDS(parsed_response, paste0("./api-responses/impl_account_account_and_funding/parsed_response-", file_name, ".Rds"))
            return(parsed_response$data)
        })

        result <- await(auto_paginate(
            fetch_page = fetch_page,
            query = initial_query,
            items_field = "items",
            paginate_fields = list(currentPage = "currentPage", totalPage = "totalPage"),
            aggregate_fn = function(acc) {
                if (length(acc) == 0 || all(sapply(acc, function(x) length(x) == 0))) {
                    return(data.table::data.table(
                        id = character(),
                        currency = character(),
                        amount = character(),
                        fee = character(),
                        balance = character(),
                        accountType = character(),
                        bizType = character(),
                        direction = character(),
                        createdAt = integer(),
                        context = character(),
                        createdAtDatetime = lubridate::as_datetime(character())
                    ))
                }

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
