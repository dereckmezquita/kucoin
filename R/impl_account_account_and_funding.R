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
#' ### Function Validated
#' - 2025-02-23 15h30
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
#' ### Function Validated
#' - 2025-02-23 18h34
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
#' @details
#' **Raw Response Schema**:
#' - `code` (string): Status code, where `"200000"` indicates success.
#' - `data` (object): see below:
#' ```json
#' {
#'     "code": "200000",
#'     "data": {
#'         "remark": "account1",
#'         "apiKey": "6705f5c311545b000157d3eb",
#'         "apiVersion": 3,
#'         "permission": "General,Futures,Spot,Earn,InnerTransfer,Transfer,Margin",
#'         "ipWhitelist": "203.**.154,103.**.34",
#'         "createdAt": 1728443843000,
#'         "uid": 165111215,
#'         "isMaster": true
#'     }
#' }
#' ```
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
        # saveRDS(response, "../../api-responses/impl_account_account_and_funding/response-get_apikey_info_impl.ignore.Rds")

        parsed_response <- process_kucoin_response(response, url)
        # saveRDS(parsed_response, "../../api-responses/impl_account_account_and_funding/parsed_response-get_apikey_info_impl.Rds")

        data_obj <- parsed_response$data

        expected_cols <- c(
            "uid", "subName", "remark", "apiKey", "apiVersion",
            "permission", "ipWhitelist", "isMaster", "createdAt"
        )

        if (is.null(data_obj)) {
            return(data.table::data.table(
                uid = numeric(0),
                subName = character(0),
                remark = character(0),
                apiKey = character(0),
                apiVersion = numeric(0),
                permission = character(0),
                ipWhitelist = character(0),
                isMaster = logical(0),
                createdAt = numeric(0)
            ))
        }

        result_dt <- data.table::as.data.table(data_obj)

        missing_cols <- setdiff(expected_cols, names(result_dt))
        for (col in missing_cols) {
            result_dt[, (col) := NA_character_]
        }

        result_dt[, `:=`(
            uid = as.numeric(uid),
            subName = as.character(subName),
            remark = as.character(remark),
            apiKey = as.character(apiKey),
            apiVersion = as.numeric(apiVersion),
            permission = as.character(permission),
            ipWhitelist = as.character(ipWhitelist),
            isMaster = as.logical(isMaster),
            createdAt = as.numeric(createdAt),
            createdAt_datetime = time_convert_from_kucoin(createdAt, "ms")
        )]
        data.table::setcolorder(result_dt, expected_cols)
        return(result_dt[])
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
#' ### Function Validated
#' - 2025-02-23 19h45
#'
#' @param keys List containing API configuration parameters from `get_api_keys()`, including:
#'   - `api_key` (character): your KuCoin API key.
#'   - `api_secret` (character): your KuCoin API secret.
#'   - `api_passphrase` (character): your KuCoin API passphrase.
#'   - `key_version` (character): API key version (e.g., `"2"`).
#'   Defaults to `get_api_keys()`.
#' @param base_url Character string representing the base URL for the API. Defaults to `get_base_url()`.
#' @return Promise resolving to a logical value: `TRUE` for high-frequency, `FALSE` for low-frequency.
#' 
#' @details
#' **Raw Response Schema**:
#' - `code` (string): Status code, where `"200000"` indicates success.
#' - `data` (boolean): `true` for high-frequency, `false` for low-frequency.
#' ```json
#' {"code": "200000", "data": false}
#' ```
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
#' ### Function Validated
#' - 2025-02-23 20h15
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
#' @details
#' **Raw Response Schema**:
#' - `code` (string): Status code, where `"200000"` indicates success.
#' - `data` (array): Array of account objects:
#'    - `id` (string): Account ID.
#'    - `currency` (string): Currency code.
#'    - `type` (string): enum (`"main"`, `"trade"`).
#'    - `balance` (string): Total funds; float as string.
#'    - `available` (string): Available funds; float as string.
#'    - `holds` (string): Funds on hold; float as string.
#' ```json
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
#' ```
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
        # saveRDS(response, "../../api-responses/impl_account_account_and_funding/response-get_spot_account_list_impl.ignore.Rds")

        parsed_response <- process_kucoin_response(response, url)
        # saveRDS(parsed_response, "../../api-responses/impl_account_account_and_funding/parsed_response-get_spot_account_list_impl.Rds")

        data_obj <- parsed_response$data

        result_dt <- data.table::rbindlist(data_obj)

        if (nrow(result_dt) == 0) {
            return(data.table::data.table(
                id        = character(0),
                currency  = character(0),
                type      = character(0),
                balance   = numeric(0),
                available = numeric(0),
                holds     = numeric(0)
            ))
        }

        result_dt[, `:=`(
            id        = as.character(id),
            currency  = as.character(currency),
            type      = as.character(type),
            balance   = as.numeric(balance),
            available = as.numeric(available),
            holds     = as.numeric(holds)
        )]

        return(result_dt[])
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
#' ### Function Validated
#' - 2025-02-23 20h20
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
#' @details
#' **Raw Response Schema**:
#' - `code` (string): Status code, where `"200000"` indicates success.
#' - `data` (object): data object:
#'   - `currency` (string): Currency code.
#'   - `balance` (string): Total funds; float as string.
#'   - `available` (string): Available funds; float as string.
#'   - `holds` (string): Funds on hold; float as string.
#' ```json
#' {
#'     "code": "200000",
#'     "data": {
#'         "currency": "USDT",
#'         "balance": "26.66759503",
#'         "available": "26.66759503",
#'         "holds": "0"
#'     }
#' }
#' ```
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
        # saveRDS(response, "../../api-responses/impl_account_account_and_funding/response-get_spot_account_detail_impl.ignore.Rds")
        parsed_response <- process_kucoin_response(response, url)
        # saveRDS(parsed_response, "../../api-responses/impl_account_account_and_funding/parsed_response-get_spot_account_detail_impl.Rds")

        result_dt <- data.table::as.data.table(parsed_response$data)

        if (nrow(result_dt) == 0) {
            return(data.table::data.table(
                currency  = character(0),
                balance   = numeric(0),
                available = numeric(0),
                holds     = numeric(0)
            ))
        }

        result_dt[, `:=`(
            currency  = as.character(currency),
            balance   = as.numeric(balance),
            available = as.numeric(available),
            holds     = as.numeric(holds)
        )]

        return(result_dt[])
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
#' ### Function Validated
#' - 2025-02-23 20h27
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
#'   - Summary Metrics:
#'     - `totalAssetOfQuoteCurrency` (numeric): Total assets in the quote currency across all accounts.
#'     - `totalLiabilityOfQuoteCurrency` (numeric): Total liabilities in the quote currency across all accounts.
#'     - `debtRatio` (numeric): Debt ratio for the cross margin account.
#'     - `status` (character): Position status (e.g., `"EFFECTIVE"`).
#'   - Account Details:
#'     - `currency` (character): Currency code of the individual account.
#'     - `total` (numeric): Total funds in the account.
#'     - `available` (numeric): Available funds in the account.
#'     - `hold` (numeric): Funds on hold in the account.
#'     - `liability` (numeric): Liabilities in the account.
#'     - `maxBorrowSize` (numeric): Maximum borrowable amount for the account.
#'     - `borrowEnabled` (logical): Whether borrowing is enabled for the account.
#'     - `transferInEnabled` (logical): Whether transfer-in is enabled for the account.
#'   If no data is present (e.g., no accounts), returns an empty `data.table` with the same columns.
#'   The function combines summary metrics (e.g., `totalAssetOfQuoteCurrency`) with individual account details into a single table, repeating summary values across each account row if multiple accounts are present.
#' @details
#' **Raw Response Schema**:  
#' - `code` (string): Status code, where `"200000"` indicates success.  
#' - `data` (object):
#'   - `totalAssetOfQuoteCurrency` (string): Total assets in the quote currency across all accounts.
#'   - `totalLiabilityOfQuoteCurrency` (string): Total liabilities in the quote currency across all accounts.
#'   - `debtRatio` (string): Debt ratio for the cross margin account.
#'   - `status` (string): Position status enum (e.g., `"EFFECTIVE", "BANKRUPTCY", "LIQUIDATION", "REPAY", "BORROW"`).
#'   - `accounts` (array): Array of account objects:
#'     - `currency` (string): Currency code of the individual account.
#'     - `total` (string): Total funds in the account; float as string.
#'     - `available` (string): Available funds in the account; float as string.
#'     - `hold` (string): Funds on hold in the account; float as string.
#'     - `liability` (string): Liabilities in the account; float as string.
#'     - `maxBorrowSize` (string): Maximum borrowable amount for the account; float as string.
#'     - `borrowEnabled` (boolean): Whether borrowing is enabled for the account.
#'     - `transferInEnabled` (boolean): Whether transfer-in is enabled for the account.
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

        # accounts to be reformated into a data.table
        result_dt <- data.table::rbindlist(data_obj$accounts)

        result_dt[, `:=`(
            totalAssetOfQuoteCurrency = as.numeric(data_obj$totalAssetOfQuoteCurrency),
            totalLiabilityOfQuoteCurrency = as.numeric(data_obj$totalLiabilityOfQuoteCurrency),
            debtRatio = as.numeric(data_obj$debtRatio),
            status = as.character(data_obj$status),
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
            "totalAssetOfQuoteCurrency", "totalLiabilityOfQuoteCurrency", "debtRatio",
            "status", "currency", "total", "available", "hold", "liability",
            "maxBorrowSize", "borrowEnabled", "transferInEnabled"
        ))

        return(result_dt[])
    }, error = function(e) {
        rlang::abort(paste("Error in get_cross_margin_account_impl:", conditionMessage(e)))
    })
})

#' Retrieve Isolated Margin Account Information
#'
#' Fetches isolated margin account details from the KuCoin API asynchronously for specific trading pairs, combining overall metrics and individual trading pair details into a single `data.table`.
#'
#' ### Workflow Overview
#' 1. **URL Construction**: Combines the base URL (from `get_base_url()` or provided `base_url`) with `/api/v3/isolated/accounts` and a query string from `build_query()`.
#' 2. **Header Preparation**: Constructs authentication headers using `build_headers()`.
#' 3. **API Request**: Sends a GET request with a 3-second timeout via `httr::GET()`.
#' 4. **Response Processing**: Processes the response with `process_kucoin_response()` and transform the `"data"` field into a single `data.table` with both summary metrics and trading pair details.
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
#' ### Function Validated
#' - 2025-02-23 21h44
#'
#' @param keys List containing API configuration parameters from `get_api_keys()`, including:
#'   - `api_key` (character): Your KuCoin API key.
#'   - `api_secret` (character): Your KuCoin API secret.
#'   - `api_passphrase` (character): Your KuCoin API passphrase.
#'   - `key_version` (character): API key version (e.g., `"2"`).
#'   Defaults to `get_api_keys()`.
#' @param base_url Character string representing the base URL for the API. Defaults to `get_base_url()`.
#' @param query Named list of query parameters:
#'   - `symbol` (character, optional): Trading pair (e.g., `"BTC-USDT"`).
#'   - `quoteCurrency` (character, optional): Quote currency (enum `"USDT"`, `"KCS"`, `"BTC"`; default `"USDT"`).
#'   - `queryType` (character, optional): Type (enum `"ISOLATED"`, `"ISOLATED_V2"`, `"ALL"`; default `"ISOLATED"`).
#'
#' @return Promise resolving to a `data.table` containing the following columns:
#'   - **Summary Metrics**:
#'     - `totalAssetOfQuoteCurrency` (numeric): Total assets in the quote currency across all isolated margin accounts; coerced from string.
#'     - `totalLiabilityOfQuoteCurrency` (numeric): Total liabilities in the quote currency across all isolated margin accounts; coerced from string.
#'     - `timestamp` (numeric): Timestamp in milliseconds; kept as numeric from integer.
#'     - `timestamp_datetime` (POSIXct): Converted datetime from `timestamp`, divided by 1000 for seconds, with origin `"1970-01-01"` and UTC timezone.
#'   - **Trading Pair Details**:
#'     - `symbol` (character): Trading pair (e.g., `"BTC-USDT"`); remains character.
#'     - `status` (character): Position status (enum `"EFFECTIVE", "BANKRUPTCY", "LIQUIDATION", "REPAY", "BORROW"`); remains character.
#'     - `debtRatio` (numeric): Debt ratio for the trading pair; coerced from string.
#'     - `base_currency` (character): Base currency code; remains character.
#'     - `base_borrowEnabled` (logical): Whether borrowing is enabled for the base currency; remains logical.
#'     - `base_transferInEnabled` (logical): Whether transfer-in is enabled for the base currency; remains logical.
#'     - `base_liability` (numeric): Liabilities in the base currency; coerced from string.
#'     - `base_total` (numeric): Total funds in the base currency; coerced from string.
#'     - `base_available` (numeric): Available funds in the base currency; coerced from string.
#'     - `base_hold` (numeric): Funds on hold in the base currency; coerced from string.
#'     - `base_maxBorrowSize` (numeric): Maximum borrowable amount for the base currency; coerced from string.
#'     - `quote_currency` (character): Quote currency code; remains character.
#'     - `quote_borrowEnabled` (logical): Whether borrowing is enabled for the quote currency; remains logical.
#'     - `quote_transferInEnabled` (logical): Whether transfer-in is enabled for the quote currency; remains logical.
#'     - `quote_liability` (numeric): Liabilities in the quote currency; coerced from string.
#'     - `quote_total` (numeric): Total funds in the quote currency; coerced from string.
#'     - `quote_available` (numeric): Available funds in the quote currency; coerced from string.
#'     - `quote_hold` (numeric): Funds on hold in the quote currency; coerced from string.
#'     - `quote_maxBorrowSize` (numeric): Maximum borrowable amount for the quote currency; coerced from string.
#' 
#'   If no data is present (e.g., empty `assets` array), returns an empty `data.table` with the same columns and no rows. The function flattens the API response, repeating summary metrics across each trading pair row if multiple trading pairs are present.
#'
#' @details
#' **Raw Response Schema**:  
#' - `code` (string): Status code, where `"200000"` indicates success.
#' - `data` (object):
#'   - `totalAssetOfQuoteCurrency` (string): Total assets in the quote currency across all isolated margin accounts.
#'   - `totalLiabilityOfQuoteCurrency` (string): Total liabilities in the quote currency across all isolated margin accounts.
#'   - `timestamp` (integer <int64>): Timestamp in milliseconds.
#'   - `assets` (array): Array of objects, each representing a trading pair’s isolated margin account:
#'     - `symbol` (string): Trading pair (e.g., `"BTC-USDT"`).
#'     - `status` (string): Position status enum (e.g., `"EFFECTIVE"`, `"BANKRUPTCY"`, `"LIQUIDATION"`, `"REPAY"`, `"BORROW"`).
#'     - `debtRatio` (string): Debt ratio for the trading pair.
#'     - `baseAsset` (object): Details for the base currency:
#'       - `currency` (string): Base currency code.
#'       - `borrowEnabled` (boolean): Whether borrowing is enabled.
#'       - `transferInEnabled` (boolean): Whether transfer-in is enabled.
#'       - `liability` (string): Liabilities in the base currency.
#'       - `total` (string): Total funds in the base currency.
#'       - `available` (string): Available funds in the base currency.
#'       - `hold` (string): Funds on hold in the base currency.
#'       - `maxBorrowSize` (string): Maximum borrowable amount for the base currency.
#'     - `quoteAsset` (object): Details for the quote currency (same structure as `baseAsset`):
#'       - `currency` (string): Quote currency code.
#'       - `borrowEnabled` (boolean): Whether borrowing is enabled.
#'       - `transferInEnabled` (boolean): Whether transfer-in is enabled.
#'       - `liability` (string): Liabilities in the quote currency.
#'       - `total` (string): Total funds in the quote currency.
#'       - `available` (string): Available funds in the quote currency.
#'       - `hold` (string): Funds on hold in the quote currency.
#'       - `maxBorrowSize` (string): Maximum borrowable amount for the quote currency.
#'
#' **Example JSON Response**:  
#' ```json
#' {
#'   "code": "200000",
#'   "data": {
#'     "totalAssetOfQuoteCurrency": "0.01",
#'     "totalLiabilityOfQuoteCurrency": "0",
#'     "timestamp": 1728725465994,
#'     "assets": [
#'       {
#'         "symbol": "BTC-USDT",
#'         "status": "EFFECTIVE",
#'         "debtRatio": "0",
#'         "baseAsset": {
#'           "currency": "BTC",
#'           "borrowEnabled": true,
#'           "transferInEnabled": true,
#'           "liability": "0",
#'           "total": "0",
#'           "available": "0",
#'           "hold": "0",
#'           "maxBorrowSize": "0"
#'         },
#'         "quoteAsset": {
#'           "currency": "USDT",
#'           "borrowEnabled": true,
#'           "transferInEnabled": true,
#'           "liability": "0",
#'           "total": "0.01",
#'           "available": "0.01",
#'           "hold": "0",
#'           "maxBorrowSize": "0"
#'         }
#'       }
#'     ]
#'   }
#' }
#' ```
#' The function processes this response by:
#' - Flattening the `assets` array into rows, one per trading pair.
#' - Prefixing base and quote asset fields with `base_` and `quote_` respectively for clarity.
#' - Coercing string values (e.g., `liability`, `total`) to numeric for R compatibility.
#' - Converting the `timestamp` (milliseconds) to a `POSIXct` datetime in `timestamp_datetime`.
#' - Repeating summary metrics (`totalAssetOfQuoteCurrency`, etc.) across all rows.
#'
#' @examples
#' \dontrun{
#' main_async <- coro::async(function() {
#'   result <- await(get_isolated_margin_account_impl(query = list(symbol = "BTC-USDT", quoteCurrency = "USDT", queryType = "ISOLATED")))
#'   print(result)
#' })
#' main_async()
#' while (!later::loop_empty()) later::run_now()
#' }
#' @importFrom coro async await
#' @importFrom httr GET timeout
#' @importFrom data.table as.data.table rbindlist setcolorder
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
        # saveRDS(response, "../../api-responses/impl_account_account_and_funding/response-get_isolated_margin_account_impl.ignore.Rds")

        parsed_response <- process_kucoin_response(response, url)
        # saveRDS(parsed_response, "../../api-responses/impl_account_account_and_funding/parsed_response-get_isolated_margin_account_impl.Rds")

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

        data.table::setcolorder(result_dt, c(
            "totalAssetOfQuoteCurrency", "totalLiabilityOfQuoteCurrency", "timestamp", "timestamp_datetime",
            "symbol", "status", "debtRatio", "base_currency", "base_borrowEnabled", "base_transferInEnabled",
            "base_liability", "base_total", "base_available", "base_hold", "base_maxBorrowSize", "quote_currency",
            "quote_borrowEnabled", "quote_transferInEnabled", "quote_liability", "quote_total", "quote_available",
            "quote_hold", "quote_maxBorrowSize"
        ))

        return(result_dt[])
    }, error = function(e) {
        rlang::abort(paste("Error in get_isolated_margin_account_impl:", conditionMessage(e)))
    })
})

#' Retrieve Spot Ledger Records
#'
#' Fetches detailed ledger records for spot and margin accounts from the KuCoin API asynchronously with pagination, combining all records into a single `data.table`.
#'
#' ### Workflow Overview
#' 1. **URL Construction**: Combines the base URL (from `get_base_url()` or provided `base_url`) with `/api/v1/accounts/ledgers`, merging query parameters with pagination settings.
#' 2. **Header Preparation**: Constructs authentication headers using `build_headers()` within an inner async function.
#' 3. **API Request**: Utilises `auto_paginate` to fetch all pages asynchronously via an inner `fetch_page` function with a 3-second timeout per request.
#' 4. **Response Processing**: Aggregates `"items"` from each page into a `data.table` with `data.table::rbindlist()`, adding a `createdAt_datetime` column via `time_convert_from_kucoin()`.
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
#' ### Function Validated
#' - NOT VALIDATED: 2025-02-23 22h27
#' 
#' API is returning response with no items array.
#'
#' @param keys List containing API configuration parameters from `get_api_keys()`, including:
#'   - `api_key` (character): Your KuCoin API key.
#'   - `api_secret` (character): Your KuCoin API secret.
#'   - `api_passphrase` (character): Your KuCoin API passphrase.
#'   - `key_version` (character): API key version (e.g., `"2"`).
#'   Defaults to `get_api_keys()`.
#' @param base_url Character string representing the base URL for the API. Defaults to `get_base_url()`.
#' @param query Named list of query parameters (excluding pagination):
#'   - `currency` (character vector, optional): Filter by currency. Supports up to 10 currencies (character vector) (e.g., `c("BTC", "ETH", "USDT")`). If not specified, all currencies are queried.
#'   - `direction` (character, optional): Transaction direction; expected values: `"in"`, `"out"`.
#'   - `bizType` (character, optional): Business type; expected values include `"DEPOSIT"`, `"WITHDRAW"`, `"TRANSFER"`, `"SUB_TRANSFER"`, `"TRADE_EXCHANGE"`, `"MARGIN_EXCHANGE"`, `"KUCOIN_BONUS"`, `"BROKER_TRANSFER"`, etc. (see **BizType Description** in Details).
#'   - `startAt` (integer, optional): Start time in milliseconds (e.g., `1728663338000`). The time range (`startAt` to `endAt`) cannot exceed 24 hours.
#'   - `endAt` (integer, optional): End time in milliseconds (e.g., `1728692138000`). If only one of `startAt` or `endAt` is provided, the other is automatically calculated to cover a 24-hour period.
#' @param page_size Integer; number of results per page (10–500, default 50).
#' @param max_pages Numeric; maximum number of pages to fetch (default `Inf` for all pages).
#'
#' @return Promise resolving to an aggregated (across pages) `data.table` containing the following columns:
#'   - `id` (character): Unique ledger record ID.
#'   - `currency` (character): Currency code (e.g., `"USDT"`).
#'   - `amount` (numeric): The total amount of assets (fees included) involved in asset changes such as transactions, withdrawals, and bonus distributions; coerced from string.
#'   - `fee` (numeric): Fees generated in transaction, withdrawal, etc.; coerced from string.
#'   - `balance` (numeric): Remaining funds after the transaction; coerced from string.
#'   - `accountType` (character): Master user account types; expected values: `"MAIN"`, `"TRADE"`, `"MARGIN"`, `"CONTRACT"`.
#'   - `bizType` (character): Business type leading to changes in funds (e.g., `"SUB_TRANSFER"`); see **BizType Description** in Details.
#'   - `direction` (character): Side of the transaction; expected values: `"in"`, `"out"`.
#'   - `createdAt` (numeric): Time of the event in milliseconds.
#'   - `createdAt_datetime` (POSIXct): Converted datetime from `createdAt`, with origin `"1970-01-01"` and UTC timezone.
#'   - `context` (character): Business-related information such as order ID, serial no., etc. For `bizType = "TRADE_EXCHANGE"`, this includes trade details like order ID and trade ID.
#'   - `currentPage` (numeric): Page number of the record.
#'   - `pageSize` (numeric): Number of records per page.
#'   - `totalNum` (numeric): Total number of records across all pages.
#'   - `totalPage` (numeric): Total number of pages.
#'   
#'   If no records are returned (e.g., empty `items` array across all pages), returns an empty `data.table` with the same columns and no rows.
#'
#' @details
#' **Raw Response Schema**:  
#' - `code` (string): Status code, where `"200000"` indicates success.
#' - `data` (object):
#'   - `currentPage` (integer): Current request page.
#'   - `pageSize` (integer): Number of results per request.
#'   - `totalNum` (integer): Total number of records.
#'   - `totalPage` (integer): Total number of pages.
#'   - `items` (array): Array of ledger record objects:
#'     - `id` (string): Unique identifier for the ledger record.
#'     - `currency` (string): Currency.
#'     - `amount` (string): The total amount of assets (fees included) involved in asset changes.
#'     - `fee` (string): Fees generated in transaction, withdrawal, etc.
#'     - `balance` (string): Remaining funds after the transaction.
#'     - `accountType` (string): Master user account types: `"MAIN"`, `"TRADE"`, `"MARGIN"`, or `"CONTRACT"`.
#'     - `bizType` (string): Business type leading to changes in funds (see **BizType Description**).
#'     - `direction` (string): Side of the transaction: `"in"` or `"out"`.
#'     - `createdAt` (integer <int64>): Time of the event in milliseconds.
#'     - `context` (string): Business-related information such as order ID, serial no., etc. For `bizType = "TRADE_EXCHANGE"`, this includes additional trade info like order ID, trade ID, and trading pair.
#'
#' **BizType Description**:  
#' The `bizType` field indicates the type of business activity that led to the ledger entry. Below is the complete list of possible `bizType` values and their descriptions:
#' - `"Assets Transferred in After Upgrading"`: Assets transferred after V1 to V2 upgrading.
#' - `"Deposit"`: Deposit.
#' - `"Withdrawal"`: Withdrawal.
#' - `"Transfer"`: Transfer.
#' - `"Trade_Exchange"`: Trade.
#' - `"Vote for Coin"`: Vote for a coin.
#' - `"KuCoin Bonus"`: KuCoin Bonus.
#' - `"Referral Bonus"`: Referral Bonus.
#' - `"Rewards"`: Activities Rewards.
#' - `"Distribution"`: Distribution, such as getting GAS by holding NEO.
#' - `"Airdrop/Fork"`: Airdrop or fork.
#' - `"Other rewards"`: Other rewards, except Vote, Airdrop, Fork.
#' - `"Fee Rebate"`: Fee Rebate.
#' - `"Buy Crypto"`: Use credit card to buy crypto.
#' - `"Sell Crypto"`: Use credit card to sell crypto.
#' - `"Public Offering Purchase"`: Public Offering Purchase for Spotlight.
#' - `"Send red envelope"`: Send red envelope.
#' - `"Open red envelope"`: Open red envelope.
#' - `"Staking"`: Staking.
#' - `"LockDrop Vesting"`: LockDrop Vesting.
#' - `"Staking Profits"`: Staking Profits.
#' - `"Redemption"`: Redemption.
#' - `"Refunded Fees"`: Refunded Fees.
#' - `"KCS Pay Fees"`: KCS Pay Fees.
#' - `"Margin Trade"`: Margin Trade.
#' - `"Loans"`: Loans.
#' - `"Borrowings"`: Borrowings.
#' - `"Debt Repayment"`: Debt Repayment.
#' - `"Loans Repaid"`: Loans Repaid.
#' - `"Lendings"`: Lendings.
#' - `"Pool transactions"`: Pool-X transactions.
#' - `"Instant Exchange"`: Instant Exchange.
#' - `"Sub Account Transfer"`: Sub-account transfer.
#' - `"Liquidation Fees"`: Liquidation Fees.
#' - `"Soft Staking Profits"`: Soft Staking Profits.
#' - `"Voting Earnings"`: Voting Earnings on Pool-X.
#' - `"Redemption of Voting"`: Redemption of Voting on Pool-X.
#' - `"Convert to KCS"`: Convert to KCS.
#' - `"BROKER_TRANSFER"`: Broker transfer record.
#'
#' **Example JSON Response**:  
#' ```json
#' {
#'   "code": "200000",
#'   "data": {
#'     "currentPage": 1,
#'     "pageSize": 50,
#'     "totalNum": 1,
#'     "totalPage": 1,
#'     "items": [
#'       {
#'         "id": "265329987780896",
#'         "currency": "USDT",
#'         "amount": "0.01",
#'         "fee": "0",
#'         "balance": "0",
#'         "accountType": "TRADE",
#'         "bizType": "SUB_TRANSFER",
#'         "direction": "out",
#'         "createdAt": 1728658481484,
#'         "context": ""
#'       }
#'     ]
#'   }
#' }
#' ```
#' The function processes this response by:
#' - Aggregating all `items` across pages into a single `data.table`.
#' - Coercing string values (e.g., `amount`, `fee`, `balance`) to numeric for R compatibility.
#' - Converting `createdAt` (milliseconds) to a `POSIXct` datetime in `createdAt_datetime`.
#' - Retaining pagination metadata (`currentPage`, `pageSize`, etc.) for traceability, coerced to numeric.
#'
#' **Notes**:
#' - The API enforces a 24-hour maximum time range between `startAt` and `endAt`. If only one is specified, the other is calculated to cover a 24-hour period. Exceeding 24 hours results in an error.
#' - Supports up to 1 year of historical data; for longer periods, submit a ticket to KuCoin support.
#' - For `bizType = "Trade_Exchange"`, the `context` field includes trade-specific details like order ID, trade ID, and trading pair.
#' - Items are sorted to show the latest first.
#'
#' ### Use Cases
#' - **Accounting and Reconciliation**: Track deposits, withdrawals, and transfers to reconcile account balances over time.
#' - **Trading Activity Analysis**: Filter on `bizType = "Trade_Exchange"` to analyze trading history, using `context` for trade details like order and trade IDs.
#' - **Bonus and Reward Tracking**: Monitor entries with `bizType` such as `"KuCoin Bonus"`, `"Referral Bonus"`, or `"Rewards"` to track incentive distributions.
#' - **Margin and Lending Monitoring**: Use `bizType` values like `"Margin Trade"`, `"Loans"`, or `"Lendings"` to oversee margin and lending activities.
#'
#' ### Advice for Automated Trading Systems
#' - **Pagination Management**: Set `page_size` to balance API call frequency and data volume. For large datasets, consider using a larger `page_size` (up to 500) to reduce the number of requests.
#' - **Time Range Handling**: Since the API limits queries to 24-hour periods, split longer time ranges into multiple requests, each covering 24 hours or less.
#' - **Data Volume Control**: Use `max_pages` to limit data retrieval during testing or when only recent data is needed (e.g., `max_pages = 1` for the latest page).
#' - **Trade Linking**: For trade-related ledger entries (`bizType = "Trade_Exchange"`), parse the `context` field to extract order and trade IDs for linking with order and trade data.
#' - **Error Handling**: Implement retry logic for requests that may fail due to rate limits or temporary issues, especially when fetching multiple pages.
#'
#' @examples
#' \dontrun{
#' query <- list(
#'   currency = c("BTC", "ETH"), # Multiple currencies
#'   direction = "in",
#'   bizType = "TRANSFER",
#'   startAt = 1728663338000L,
#'   endAt = 1728692138000L
#' )
#' main_async <- coro::async(function() {
#'   dt <- await(get_spot_ledger_impl(
#'     query = query,
#'     page_size = 100L,  # Larger page size for fewer requests
#'     max_pages = Inf    # Fetches all pages
#'   ))
#'   print(dt)
#' })
#' main_async()
#' while (!later::loop_empty()) later::run_now()
#' }
#'
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

        if (!is.null(initial_query$currencies)) {
            initial_query$currencies <- paste0(initial_query$currencies, collapse = ",")
        }

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
            # saveRDS(response, paste0("../../api-responses/impl_account_account_and_funding/response-", file_name, ".ignore.Rds"))
            parsed_response <- process_kucoin_response(response, url)
            # saveRDS(parsed_response, paste0("../../api-responses/impl_account_account_and_funding/parsed_response-", file_name, ".Rds"))
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
                        id = character(0),
                        currency = character(0),
                        amount = character(0),
                        fee = character(0),
                        balance = character(0),
                        accountType = character(0),
                        bizType = character(0),
                        direction = character(0),
                        context = character(0),
                        createdAt = numeric(0),
                        createdAt_datetime = lubridate::as_datetime(character(0)) 
                    ))
                }
                result_dt <- data.table::rbindlist(acc)
                result_dt[, `:=`(
                    id = as.character(id),
                    currency = as.character(currency),
                    amount = as.character(amount),
                    fee = as.character(fee),
                    balance = as.character(balance),
                    accountType = as.character(accountType),
                    bizType = as.character(bizType),
                    direction = as.character(direction),
                    context = as.character(context),
                    createdAt = as.numeric(createdAt),
                    createdAt_datetime = time_convert_from_kucoin(as.numeric(createdAt), "ms")
                )]

                return(result_dt)
            },
            max_pages = max_pages
        ))

        return(result)
    }, error = function(e) {
        rlang::abort(paste("Error in get_spot_ledger_impl:", conditionMessage(e)))
    })
})
