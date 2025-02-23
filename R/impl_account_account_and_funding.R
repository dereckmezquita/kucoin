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

#' Retrieve Account Summary Information
#'
#' Retrieves account summary information from the KuCoin API asynchronously.
#'
#' ### Workflow Overview
#' 1. **URL Construction**: Combines the base URL (from `get_base_url()` or provided `base_url`) with the endpoint `/api/v2/user-info`.
#' 2. **Header Preparation**: Constructs timestamped authentication headers using `build_headers()` with the HTTP method, endpoint, and an empty request body.
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
#'   - `api_key` (character): your KuCoin API key.
#'   - `api_secret` (character): your KuCoin API secret.
#'   - `api_passphrase` (character): your KuCoin API passphrase.
#'   - `key_version` (character): API key version (e.g., `"2"`).
#'   Defaults to `get_api_keys()`.
#' @param base_url Character string representing the base URL for the API. Defaults to `get_base_url()`.
#' 
#' @return Promise resolving to a `data.table` containing:
#'   - `level` (numeric): User's VIP level.
#'   - `subQuantity` (numeric): Total number of sub-accounts.
#'   - `spotSubQuantity` (numeric): Number of spot trading sub-accounts.
#'   - `marginSubQuantity` (numeric): Number of margin trading sub-accounts.
#'   - `futuresSubQuantity` (numeric): Number of futures trading sub-accounts.
#'   - `optionSubQuantity` (numeric): Number of option trading sub-accounts.
#'   - `maxSubQuantity` (numeric): Maximum allowed sub-accounts (sum of `maxDefaultSubQuantity` and `maxSpotSubQuantity`).
#'   - `maxDefaultSubQuantity` (numeric): Maximum default sub-accounts based on VIP level.
#'   - `maxSpotSubQuantity` (numeric): Maximum additional spot sub-accounts.
#'   - `maxMarginSubQuantity` (numeric): Maximum additional margin sub-accounts.
#'   - `maxFuturesSubQuantity` (numeric): Maximum additional futures sub-accounts.
#'   - `maxOptionSubQuantity` (numeric): Maximum additional option sub-accounts.
#' 
#' @details
#' **Raw Response Schema**:
#' - `code` (string): Status code, where `"200000"` indicates success.
#' - `data` (object): see below:
#' ```json
#' {
#'     "code": "200000",
#'     "data": {
#'         "level": 0,
#'         "subQuantity": 3,
#'         "spotSubQuantity": 3,
#'         "marginSubQuantity": 2,
#'         "futuresSubQuantity": 2,
#'         "optionSubQuantity": 0,
#'         "maxSubQuantity": 5,
#'         "maxDefaultSubQuantity": 5,
#'         "maxSpotSubQuantity": 0,
#'         "maxMarginSubQuantity": 0,
#'         "maxFuturesSubQuantity": 0,
#'         "maxOptionSubQuantity": 0
#'     }
#' }
#' ```
#' 
#' @examples
#' \dontrun{
#' main_async <- coro::async(function() {
#'   data <- await(get_account_summary_info_impl())
#'   print(data)
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
    # VERIFIED: saved RDS 2025-02-23 15h30
    tryCatch({
        endpoint <- "/api/v2/user-info"
        method <- "GET"
        body <- ""
        headers <- await(build_headers(method, endpoint, body, keys))

        url <- paste0(base_url, endpoint)
        response <- httr::GET(url, headers, httr::timeout(3))
        # saveRDS(response, "../../api-responses/impl_account_account_and_funding/response-get_account_summary_info_impl.ignore.Rds")

        parsed_response <- process_kucoin_response(response, url)
        # saveRDS(parsed_response, "../../api-responses/impl_account_account_and_funding/parsed_response-get_account_summary_info_impl.Rds")

        data_obj <- parsed_response$data

        if (is.null(data_obj) || length(data_obj) == 0) {
            return(data.table::data.table(
                level = numeric(0),
                subQuantity = numeric(0),
                spotSubQuantity = numeric(0),
                marginSubQuantity = numeric(0),
                futuresSubQuantity = numeric(0),
                optionSubQuantity = numeric(0),
                maxSubQuantity = numeric(0),
                maxDefaultSubQuantity = numeric(0),
                maxSpotSubQuantity = numeric(0),
                maxMarginSubQuantity = numeric(0),
                maxFuturesSubQuantity = numeric(0),
                maxOptionSubQuantity = numeric(0)
            ))
        }

        result_dt <- data.table::as.data.table(parsed_response$data)

        # convert all cols to numeric
        result_dt[, names(result_dt) := lapply(.SD, as.numeric)]
        return(result_dt[])
    }, error = function(e) {
        rlang::abort(paste("Error in get_account_summary_info_impl:", conditionMessage(e)))
    })
})

#' Retrieve API Key Information
#'
#' Fetches detailed API key metadata from the KuCoin API asynchronously, providing details such as permissions and creation time.
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
#' Utilised internally by the `KucoinAccountAndFunding` class to get API key details.
#'
#' ### Official Documentation
#' [KuCoin Get API Key Info](https://www.kucoin.com/docs-new/rest/account-info/account-funding/get-apikey-info)
#'
#' @param keys List containing API configuration parameters from `get_api_keys()`, including:
#'   - `api_key` (character): your KuCoin API key.
#'   - `api_secret` (character): your KuCoin API secret.
#'   - `api_passphrase` (character): your KuCoin API passphrase.
#'   - `key_version` (character): API key version (e.g., `"2"`).
#'   Defaults to `get_api_keys()`.
#' @param base_url Character string representing the base URL for the API. Defaults to `get_base_url()`.
#' @return Promise resolving to a `data.table` containing:
#'   - `uid` (numeric): Account UID.
#'   - `subName` (character, optional): Sub-account name (if applicable).
#'   - `remark` (character): API key remarks.
#'   - `apiKey` (character): API key string.
#'   - `apiVersion` (numeric): API version.
#'   - `permission` (character): Comma-separated permissions list (e.g., "General, Spot").
#'   - `ipWhitelist` (character, optional): IP whitelist.
#'   - `isMaster` (logical): Master account indicator.
#'   - `createdAt` (numeric): Creation time in milliseconds.
#' @examples
#' \dontrun{
#' main_async <- coro::async(function() {
#'   dt <- await(get_apikey_info_impl())
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

        data_obj <- parsed_response$data
        # TODO: review and validate
        if (is.null(data_obj)) {
            return(data.table::data.table(
                uid = numeric(0),
                subName = character(0),
                remark = character(0),
                apiKey = character(0),
                apiVersion = character(0),
                permission = character(0),
                ipWhiteList = character(0),
                isMaster = logical(0),
                createdAt = numeric(0)
            ))
        }
        return(data.table::as.data.table(data_obj))
    }, error = function(e) {
        rlang::abort(paste("Error in get_apikey_info_impl:", conditionMessage(e)))
    })
})

#' Determine Spot Account Type
#'
#' Determines whether the spot account is high-frequency or low-frequency from the KuCoin API asynchronously.
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
#'   - `api_key` (character): your KuCoin API key.
#'   - `api_secret` (character): your KuCoin API secret.
#'   - `api_passphrase` (character): your KuCoin API passphrase.
#'   - `key_version` (character): API key version (e.g., `"2"`).
#'   Defaults to `get_api_keys()`.
#' @param base_url Character string representing the base URL for the API. Defaults to `get_base_url()`.
#' @return Promise resolving to a logical value: `TRUE` for high-frequency, `FALSE` for low-frequency.
#' @examples
#' \dontrun{
#' main_async <- coro::async(function() {
#'   is_high_freq <- await(get_spot_account_type_impl())
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

        return(as.logical(parsed_response$data))
    }, error = function(e) {
        rlang::abort(paste("Error in get_spot_account_type_impl:", conditionMessage(e)))
    })
})

#' Retrieve Spot Account List
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
#'   - `api_key` (character): your KuCoin API key.
#'   - `api_secret` (character): your KuCoin API secret.
#'   - `api_passphrase` (character): your KuCoin API passphrase.
#'   - `key_version` (character): API key version (e.g., `"2"`).
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
#' main_async <- coro::async(function() {
#'   dt <- await(get_spot_account_list_impl(query = list(currency = "USDT", type = "main")))
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

#' Retrieve Spot Account Details
#'
#' Fetches detailed financial metrics for a specific spot account from the KuCoin API asynchronously.
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
#'   - `api_key` (character): your KuCoin API key.
#'   - `api_secret` (character): your KuCoin API secret.
#'   - `api_passphrase` (character): your KuCoin API passphrase.
#'   - `key_version` (character): API key version (e.g., `"2"`).
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
#' main_async <- coro::async(function() {
#'   dt <- await(get_spot_account_detail_impl(accountId = "123456789"))
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

#' Retrieve Cross Margin Account Information
#'
#' Fetches cross margin account details from the KuCoin API asynchronously, combining overall metrics and individual account details into a single `data.table`
#'
#' ### Workflow Overview
#' 1. **URL Construction**: Combines the base URL (from `get_base_url()` or provided `base_url`) with `/api/v3/margin/accounts` and a query string from `build_query()`.
#' 2. **Header Preparation**: Constructs authentication headers using `build_headers()`.
#' 3. **API Request**: Sends a GET request with a 3-second timeout via `httr::GET()`.
#' 4. **Response Processing**: Processes the response with `process_kucoin_response()`, transforming the `"data"` field into a single `data.table` with both summary metrics and account details.
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
#'   - `api_key` (character): your KuCoin API key.
#'   - `api_secret` (character): your KuCoin API secret.
#'   - `api_passphrase` (character): your KuCoin API passphrase.
#'   - `key_version` (character): API key version (e.g., `"2"`).
#'   Defaults to `get_api_keys()`.
#' @param base_url Character string representing the base URL for the API. Defaults to `get_base_url()`.
#' @param query Named list of query parameters:
#'   - `quoteCurrency` (character, optional): Quote currency (e.g., `"USDT"`, `"KCS"`, `"BTC"`; default `"USDT"`).
#'   - `queryType` (character, optional): Account type (`"MARGIN"`, `"MARGIN_V2"`, `"ALL"`; default `"MARGIN"`).
#' @return Promise resolving to a `data.table` containing the following columns:
#'   - `totalAssetOfQuoteCurrency` (numeric): Total assets in the quote currency across all accounts.
#'   - `totalLiabilityOfQuoteCurrency` (numeric): Total liabilities in the quote currency across all accounts.
#'   - `debtRatio` (numeric): Debt ratio for the cross margin account.
#'   - `status` (character): Position status (e.g., `"EFFECTIVE"`).
#'   - `currency` (character): Currency code of the individual account.
#'   - `total` (numeric): Total funds in the account.
#'   - `available` (numeric): Available funds in the account.
#'   - `hold` (numeric): Funds on hold in the account.
#'   - `liability` (numeric): Liabilities in the account.
#'   - `maxBorrowSize` (numeric): Maximum borrowable amount for the account.
#'   - `borrowEnabled` (logical): Whether borrowing is enabled for the account.
#'   - `transferInEnabled` (logical): Whether transfer-in is enabled for the account.
#'   If no data is present (e.g., no accounts), returns an empty `data.table` with the same columns.
#'   The function combines summary metrics (e.g., `totalAssetOfQuoteCurrency`) with individual account details into a single table, repeating summary values across each account row if multiple accounts are present.
#' @details
#' **Raw Response Schema**:  
#' - `code` (string): Status code, where `"200000"` indicates success.  
#' - `data` (object)
#' 
#' Example JSON response:  
#' ```
#' {
#'     "code": "200000",
#'     "data": {
#'         "totalAssetOfQuoteCurrency": "0.02",
#'         "totalLiabilityOfQuoteCurrency": "0",
#'         "debtRatio": "0",
#'         "status": "EFFECTIVE",
#'         "accounts": [
#'             {
#'                 "currency": "USDT",
#'                 "total": "0.02",
#'                 "available": "0.02",
#'                 "hold": "0",
#'                 "liability": "0",
#'                 "maxBorrowSize": "0",
#'                 "borrowEnabled": true,
#'                 "transferInEnabled": true
#'             }
#'         ]
#'     }
#' }
#' ```
#' @examples
#' \dontrun{
#' main_async <- coro::async(function() {
#'   result <- await(get_cross_margin_account_impl(query = list(quoteCurrency = "USDT", queryType = "MARGIN")))
#'   print(result)
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
        # saveRDS(response, "../../api-responses/impl_account_account_and_funding/response-get_cross_margin_account_impl.ignore.Rds")

        parsed_response <- process_kucoin_response(response, url)
        # saveRDS(parsed_response, "../../api-responses/impl_account_account_and_funding/parsed_response-get_cross_margin_account_impl.Rds")
        data_obj <- parsed_response$data

        if (is.null(data_obj) || length(data_obj$accounts) < 1) {
            return(data.table::data.table(
                totalAssetOfQuoteCurrency = numeric(0),
                totalLiabilityOfQuoteCurrency = numeric(0),
                debtRatio = numeric(0),
                status = character(0),
                # ----
                currency = character(0),
                total = numeric(0),
                available = numeric(0),
                hold = numeric(0),
                liability = numeric(0),
                maxBorrowSize = numeric(0),
                borrowEnabled = logical(0),
                transferInEnabled = logical(0)
            ))
        }

        # summary fields
        totalAssetOfQuoteCurrency <- as.numeric(data_obj$totalAssetOfQuoteCurrency)
        totalLiabilityOfQuoteCurrency <- as.numeric(data_obj$totalLiabilityOfQuoteCurrency)
        debtRatio <- as.numeric(data_obj$debtRatio)
        status <- as.character(data_obj$status)

        # accounts to be reformated into a data.table
        result_dt <- data.table::rbindlist(data_obj$accounts)


        result_dt[, `:=`(
            totalAssetOfQuoteCurrency = as.numeric(totalAssetOfQuoteCurrency),
            totalLiabilityOfQuoteCurrency = as.numeric(totalLiabilityOfQuoteCurrency),
            debtRatio = as.numeric(debtRatio),
            status = as.character(status),
            # ----
            currency = as.character(currency),
            total = as.numeric(total),
            available = as.numeric(available),
            hold = as.numeric(hold),
            liability = as.numeric(liability),
            maxBorrowSize = as.numeric(maxBorrowSize),
            borrowEnabled = as.logical(borrowEnabled),
            transferInEnabled = as.logical(transferInEnabled)
        )]

        data.table::setcolorder(result_dt, c(
            "totalAssetOfQuoteCurrency", "totalLiabilityOfQuoteCurrency", "debtRatio", "status",
            "currency", "total", "available", "hold", "liability", "maxBorrowSize", "borrowEnabled", "transferInEnabled"
        ))

        return(result_dt[])
    }, error = function(e) {
        rlang::abort(paste("Error in get_cross_margin_account_impl:", conditionMessage(e)))
    })
})

#' Retrieve Isolated Margin Account Information
#'
#' Fetches isolated margin account details from the KuCoin API asynchronously for specific trading pairs.
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
#'   - `api_key` (character): your KuCoin API key.
#'   - `api_secret` (character): your KuCoin API secret.
#'   - `api_passphrase` (character): your KuCoin API passphrase.
#'   - `key_version` (character): API key version (e.g., `"2"`).
#'   Defaults to `get_api_keys()`.
#' @param base_url Character string representing the base URL for the API. Defaults to `get_base_url()`.
#' @param query Named list of query parameters:
#'   - `symbol` (character, optional): Trading pair (e.g., `"BTC-USDT"`).
#'   - `quoteCurrency` (character, optional): Quote currency (e.g., `"USDT"`, `"KCS"`, `"BTC"`; default `"USDT"`).
#'   - `queryType` (character, optional): Type (`"ISOLATED"`, `"ISOLATED_V2"`, `"ALL"`; default `"ISOLATED"`).
#' @return Promise resolving to a data.table with summary values (repeated) and the asset values:
#'   - summary values (repeated):
#'     - `totalAssetOfQuoteCurrency` (character): Total assets.
#'     - `totalLiabilityOfQuoteCurrency` (character): Total liabilities.
#'     - `timestamp` (numeric): Timestamp in milliseconds.
#'     - `timestamp_datetime` (POSIXct): Converted datetime.
#'   - assets values:
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
#' main_async <- coro::async(function() {
#'   result <- await(get_isolated_margin_account_impl(query = list(symbol = "BTC-USDT", quoteCurrency = "USDT")))
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

        # TODO: verify end point and default return
        if (is.null(data_obj)) {
            return(data.table::data.table(
                # summary
                totalAssetOfQuoteCurrency = character(0),
                totalLiabilityOfQuoteCurrency = character(0),
                timestamp = numeric(0),
                timestamp_datetime = lubridate::as_datetime(character(0)),
                # assets
                symbol = character(0),
                status = character(0),
                debtRatio = character(0),
                base_currency = character(0),
                base_borrowEnabled = logical(0),
                base_transferInEnabled = logical(0),
                base_liability = character(0),
                base_total = character(0),
                base_available = character(0),
                base_hold = character(0),
                base_maxBorrowSize = character(0),
                quote_currency = character(0),
                quote_borrowEnabled = logical(0),
                quote_transferInEnabled = logical(0),
                quote_liability = character(0),
                quote_total = character(0),
                quote_available = character(0),
                quote_hold = character(0),
                quote_maxBorrowSize = character(0)
            ))
        }

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

        result_dt <- data.table::rbindlist(assets_list)

        taoqc <- as.character(data_obj$totalAssetOfQuoteCurrency)
        tloqc <- as.character(data_obj$totalLiabilityOfQuoteCurrency)
        timestamp <- as.numeric(data_obj$timestamp)
        timestamp_datetime <- lubridate::as_datetime(time_convert_from_kucoin(timestamp, "ms"))

        result_dt[, `:=`(
            # summary values
            totalAssetOfQuoteCurrency = taoqc,
            totalLiabilityOfQuoteCurrency = tloqc,
            timestamp = timestamp,
            timestamp_datetime = timestamp_datetime,
            # assets
            symbol = as.character(symbol),
            status = as.character(status),
            debtRatio = as.character(debtRatio),
            base_currency = as.character(base_currency),
            base_borrowEnabled = as.logical(base_borrowEnabled),
            base_transferInEnabled = as.logical(base_transferInEnabled),
            base_liability = as.character(base_liability),
            base_total = as.character(base_total),
            base_available = as.character(base_available),
            base_hold = as.character(base_hold),
            base_maxBorrowSize = as.character(base_maxBorrowSize),
            quote_currency = as.character(quote_currency),
            quote_borrowEnabled = as.logical(quote_borrowEnabled),
            quote_transferInEnabled = as.logical(quote_transferInEnabled),
            quote_liability = as.character(quote_liability),
            quote_total = as.character(quote_total),
            quote_available = as.character(quote_available),
            quote_hold = as.character(quote_hold),
            quote_maxBorrowSize = as.character(quote_maxBorrowSize)
        )]

        return(list(summary = summary_dt, assets = assets_dt))
    }, error = function(e) {
        rlang::abort(paste("Error in get_isolated_margin_account_impl:", conditionMessage(e)))
    })
})

#' Retrieve Spot Ledger Records
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

        # TOOD: updated return signature
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
