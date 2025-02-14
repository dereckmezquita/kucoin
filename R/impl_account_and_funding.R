# File: ./R/impl_account_and_funding.R

box::use(
    ./helpers_api[ build_headers, process_kucoin_response ],
    ./utils[ build_query, convert_datetime_range_to_ms, get_base_url ]
)

#' Get Account Summary Information (Implementation)
#'
#' This asynchronous function implements the retrieval of account summary information from the KuCoin API. It is designed for internal use as a method in an R6 class and is **not** intended for direct consumption by end-users. The function performs the following operations:
#'
#' 1. **URL Construction:** Constructs the full API URL using the `base_url` provided in the configuration.
#' 2. **Header Preparation:** Builds the authentication headers based on the HTTP method, endpoint, and request body.
#' 3. **API Request:** Sends a `GET` request to the KuCoin API endpoint for account summary information.
#' 4. **Response Processing:** Processes the API response using a helper function and converts the result to a `data.table`.
#'
#' **Parameters**
#'
#' - `config`: A list containing API configuration parameters. The list must include:
#'   - `api_key`: Your KuCoin API key.
#'   - `api_secret`: Your KuCoin API secret.
#'   - `api_passphrase`: Your KuCoin API passphrase.
#'   - `base_url`: The base URL for the API (e.g., `"https://api.kucoin.com"`).
#'   - `key_version`: The version of the API key (e.g., `"2"`).
#'
#' **Returns**
#'
#' A promise that resolves to a `data.table` containing the account summary data.
#'
#' **Details**
#'
#' - **Endpoint:** `GET https://api.kucoin.com/api/v2/user-info`
#'
#' - **Response Schema:**
#'   - `code` (string): Status code, where `"200000"` indicates success.
#'   - `data` (object): Contains the account summary details, including:
#'     - `level` (integer): The user's VIP level.
#'     - `subQuantity` (integer): Total number of sub-accounts.
#'     - `spotSubQuantity` (integer): Number of sub-accounts with spot trading permissions.
#'     - `marginSubQuantity` (integer): Number of sub-accounts with margin trading permissions.
#'     - `futuresSubQuantity` (integer): Number of sub-accounts with futures trading permissions.
#'     - `optionSubQuantity` (integer): Number of sub-accounts with option trading permissions.
#'     - `maxSubQuantity` (integer): Maximum allowed sub-accounts, calculated as the sum of `maxDefaultSubQuantity` and `maxSpotSubQuantity`.
#'     - `maxDefaultSubQuantity` (integer): Maximum default open sub-accounts based on VIP level.
#'     - `maxSpotSubQuantity` (integer): Maximum additional sub-accounts with spot trading permissions.
#'     - `maxMarginSubQuantity` (integer): Maximum additional sub-accounts with margin trading permissions.
#'     - `maxFuturesSubQuantity` (integer): Maximum additional sub-accounts with futures trading permissions.
#'     - `maxOptionSubQuantity` (integer): Maximum additional sub-accounts with option trading permissions.
#'
#' For more detailed information, please see the [KuCoin API Documentation](https://www.kucoin.com/docs-new/rest/account-info/account-funding/get-account-summary-info).
#'
#' **Example**
#'
#' ```r
#' config <- list(
#'   api_key = "your_api_key",
#'   api_secret = "your_api_secret",
#'   api_passphrase = "your_api_passphrase",
#'   base_url = "https://api.kucoin.com",
#'   key_version = "2"
#' )
#'
#' # Execute the asynchronous request using coro::run:
#' coro::run(function() {
#'   dt <- await(get_account_summary_info_impl(config))
#'   print(dt)
#' })
#' ```
#'
#' @export
#' @md
get_account_summary_info_impl <- coro::async(function(config) {
    tryCatch({
        base_url <- get_base_url(config)
        endpoint <- "/api/v2/user-info"
        method <- "GET"
        body <- ""
        headers <- await(build_headers(method, endpoint, body, config))
        url <- paste0(base_url, endpoint)

        response <- httr::GET(url, headers, timeout(3))

        # Use the helper to check the response and extract the data.
        data <- process_kucoin_response(response, url)

        dt <- data.table::as.data.table(data)
        return(dt)
    }, error = function(e) {
        rlang::abort(paste("Error in get_account_summary_info_impl:", conditionMessage(e)))
    })
})

#' Get API Key Information (Implementation)
#'
#' This asynchronous function implements the logic for retrieving API key information from the KuCoin API.
#' It is designed for internal use as a method in an R6 class and is **not** intended for direct consumption by end-users.
#' The function constructs the full URL, builds the authentication headers, sends the `GET` request, and processes the response,
#' converting the result into a `data.table`.
#'
#' **Parameters**
#'
#' - `config`: A list containing API configuration parameters. The list must include:
#'   - `api_key`: Your KuCoin API key.
#'   - `api_secret`: Your KuCoin API secret.
#'   - `api_passphrase`: Your KuCoin API passphrase.
#'   - `base_url`: The base URL for the API (e.g., `"https://api.kucoin.com"`).
#'   - `key_version`: The version of the API key (e.g., `"2"`).
#'
#' **Returns**
#'
#' A promise that resolves to a `data.table` containing the API key information.
#'
#' **Details**
#'
#' - **Endpoint:** `GET https://api.kucoin.com/api/v1/user/api-key`
#'
#' - **Response Schema:**
#'   - `code` (string): Status code, where `"200000"` indicates success.
#'   - `data` (object): Contains API key details, including:
#'     - `uid` (integer): Account UID.
#'     - `subName` (string, optional): Sub account name (if applicable; not provided for master accounts).
#'     - `remark` (string): Remarks associated with the API key.
#'     - `apiKey` (string): The API key.
#'     - `apiVersion` (integer): API version.
#'     - `permission` (string): A comma-separated list of permissions (e.g., `General, Spot, Margin, Futures, InnerTransfer, Transfer, Earn`).
#'     - `ipWhitelist` (string, optional): IP whitelist, if applicable.
#'     - `isMaster` (boolean): Indicates whether the API key belongs to the master account.
#'     - `createdAt` (integer): API key creation time in milliseconds.
#'
#' For additional details, please refer to the [KuCoin API Documentation](https://www.kucoin.com/docs-new/rest/account-info/account-funding/get-apikey-info).
#'
#' **Example**
#'
#' ```r
#' config <- list(
#'   api_key = "your_api_key",
#'   api_secret = "your_api_secret",
#'   api_passphrase = "your_api_passphrase",
#'   base_url = "https://api.kucoin.com",
#'   key_version = "2"
#' )
#'
#' # Execute the asynchronous request using coro::run:
#' coro::run(function() {
#'   dt <- await(get_apikey_info_impl(config))
#'   print(dt)
#' })
#' ```
#'
#' @export
#' @md
get_apikey_info_impl <- coro::async(function(config) {
    tryCatch({
        base_url <- get_base_url(config)
        endpoint <- "/api/v1/user/api-key"
        method <- "GET"
        body <- ""
        headers <- await(build_headers(method, endpoint, body, config))
        url <- paste0(base_url, endpoint)

        response <- httr::GET(url, headers, timeout(3))
        data <- process_kucoin_response(response, url)
        dt <- data.table::as.data.table(data)
        return(dt)
    }, error = function(e) {
        rlang::abort(paste("Error in get_apikey_info_impl:", conditionMessage(e)))
    })
})

#' Get Spot Account Type Implementation
#'
#' This asynchronous function retrieves spot account type information from the KuCoin API. It is designed for internal use as a method in an R6 class and is **not** intended for direct consumption by end-users.
#'
#' The function performs the following operations:
#'
#' 1. **URL Construction:** Constructs the full API URL using the `base_url` provided in the configuration.
#' 2. **Header Preparation:** Builds the authentication headers based on the HTTP method, endpoint, and request body.
#' 3. **API Request:** Sends a `GET` request to the `/api/v1/hf/accounts/opened` endpoint.
#' 4. **Response Processing:** Processes the API response using a helper function, returning a boolean that indicates whether the current user is a high-frequency spot user (`TRUE`) or a low-frequency spot user (`FALSE`).
#'
#' **Parameters**
#'
#' - `config`: A list containing API configuration parameters. This list should include:
#'   - `api_key`: Your KuCoin API key.
#'   - `api_secret`: Your KuCoin API secret.
#'   - `api_passphrase`: Your KuCoin API passphrase.
#'   - `base_url`: The base URL for the API (e.g., `"https://api.kucoin.com"`).
#'   - `key_version`: The version of the API key (e.g., `"2"`).
#'
#' **Returns**
#'
#' A promise that resolves to a boolean value:
#'
#' - `TRUE` indicates that the current user is a high-frequency spot user.
#' - `FALSE` indicates that the current user is a low-frequency spot user.
#'
#' **Details**
#'
#' - **Endpoint:** `GET https://api.kucoin.com/api/v1/hf/accounts/opened`
#'
#' - **Response Schema:**
#'   - `code` (string): Status code, where `"200000"` indicates success.
#'   - `data` (boolean): Indicates the spot account type.
#'
#' For more information, please refer to the [KuCoin API Documentation](https://www.kucoin.com/docs-new/rest/account-info/account-funding/get-account-type-spot).
#'
#' **Example**
#'
#' ```r
#' config <- list(
#'   api_key = "your_api_key",
#'   api_secret = "your_api_secret",
#'   api_passphrase = "your_api_passphrase",
#'   base_url = "https://api.kucoin.com",
#'   key_version = "2"
#' )
#'
#' # Execute the asynchronous request using coro::run:
#' coro::run(function() {
#'   is_high_freq <- await(get_spot_account_type_impl(config))
#'   print(is_high_freq)
#' })
#' ```
#'
#' @export
#' @md
get_spot_account_type_impl <- coro::async(function(config) {
    tryCatch({
        base_url <- get_base_url(config)
        endpoint <- "/api/v1/hf/accounts/opened"
        method <- "GET"
        body <- ""
        headers <- await(build_headers(method, endpoint, body, config))
        url <- paste0(base_url, endpoint)

        response <- httr::GET(url, headers, timeout(3))
        # Process the response using a helper function; the returned data is expected to be a boolean.
        data <- process_kucoin_response(response, url)
        # data is expected to be a boolean value.
        return(data)
    }, error = function(e) {
        rlang::abort(paste("Error in get_spot_account_type_impl:", conditionMessage(e)))
    })
})

#' Get Spot Account DT Implementation
#'
#' This asynchronous function retrieves a list of spot accounts from the KuCoin API. It sends a 
#' `GET` request to the `/api/v1/accounts` endpoint with optional query parameters and returns the 
#' account list as a `data.table`. This function is intended for internal use within an R6 class and 
#' is **not** meant for direct end-user consumption.
#'
#' **Parameters**
#'
#' - `config`: A list containing API configuration parameters. It should include:
#'   - `api_key`: Your KuCoin API key.
#'   - `api_secret`: Your KuCoin API secret.
#'   - `api_passphrase`: Your KuCoin API passphrase.
#'   - `base_url`: The base URL for the API (e.g., `"https://api.kucoin.com"`).
#'   - `key_version`: The version of the API key (e.g., `"2"`).
#'
#' - `query`: A list of query parameters to filter the account list. Supported parameters include:
#'   - `currency` (string, optional): e.g., `"USDT"`.
#'   - `type` (string, optional): Allowed values include `"main"` or `"trade"`.
#'
#' **Returns**
#'
#' A promise that resolves to a `data.table` containing the list of spot accounts.
#'
#' **Details**
#'
#' - **Endpoint:** `GET https://api.kucoin.com/api/v1/accounts`
#'
#' - **Response Schema:**
#'   - `code` (string): Status code, where `"200000"` indicates success.
#'   - `data` (array of objects): Each object represents an account and contains:
#'     - `id` (string): Account ID.
#'     - `currency` (string): Currency code.
#'     - `type` (string): Account type (e.g., `"main"`, `"trade"`, or `"balance"`).
#'     - `balance` (string): Total funds in the account.
#'     - `available` (string): Funds available for withdrawal or trading.
#'     - `holds` (string): Funds on hold.
#'
#' The JSON array returned from the API is converted into a `data.table`.
#'
#' For more detailed information, please refer to the [KuCoin API Documentation](https://www.kucoin.com/docs-new/rest/account-info/account-funding/get-account-list-spot).
#'
#' **Example**
#'
#' ```r
#' query <- list(currency = "USDT", type = "main")
#' coro::run(function() {
#'   dt <- await(get_spot_account_dt_impl(config, query))
#'   print(dt)
#' })
#' ```
#'
#' @export
#' @md
get_spot_account_dt_impl <- coro::async(function(config, query = list()) {
    tryCatch({
        base_url <- get_base_url(config)
        endpoint <- "/api/v1/accounts"
        method <- "GET"
        body <- ""
        qs <- build_query(query)
        full_endpoint <- paste0(endpoint, qs)
        headers <- await(build_headers(method, full_endpoint, body, config))
        url <- paste0(base_url, full_endpoint)

        response <- httr::GET(url, headers, timeout(3))
        data <- process_kucoin_response(response, url)
        dt <- data.table::as.data.table(data)
        return(dt)
    }, error = function(e) {
        rlang::abort(paste("Error in get_spot_account_dt_impl:", conditionMessage(e)))
    })
})

#' Get Spot Account Detail Implementation
#'
#' This asynchronous function retrieves detailed information for a single spot account from the KuCoin API.
#' It is designed for internal use as a method in an R6 class and is **not** intended for direct end-user consumption.
#'
#' The function performs the following steps:
#'
#' 1. **URL Construction:**  
#'    Embeds the provided `accountId` into the endpoint to create the full API URL.
#'
#' 2. **Header Preparation:**  
#'    Builds the authentication headers using the HTTP method, endpoint, and an empty request body.
#'
#' 3. **API Request:**  
#'    Sends a `GET` request to the `/api/v1/accounts/{accountId}` endpoint.
#'
#' 4. **Response Processing:**  
#'    Processes the API response using a helper function and converts the parsed JSON into a `data.table`.
#'
#' **Parameters**
#'
#' - `config`: A list containing API configuration parameters. This list must include:
#'   - `api_key`: Your KuCoin API key.
#'   - `api_secret`: Your KuCoin API secret.
#'   - `api_passphrase`: Your KuCoin API passphrase.
#'   - `base_url`: The base URL for the API (e.g., `"https://api.kucoin.com"`).
#'   - `key_version`: The version of the API key (e.g., `"2"`).
#'
#' - `accountId`: A string representing the account ID for which the spot account details are requested.
#'
#' **Returns**
#'
#' A promise that resolves to a `data.table` containing detailed information for the specified spot account.
#'
#' **Details**
#'
#' - **Endpoint:** `GET https://api.kucoin.com/api/v1/accounts/{accountId}`
#'
#' - **Response Schema:**
#'   - `code` (string): Status code, where `"200000"` indicates success.
#'   - `data` (object): Contains the following fields:
#'     - `currency` (string): The currency of the account.
#'     - `balance` (string): Total funds in the account.
#'     - `available` (string): Funds available for withdrawal or trading.
#'     - `holds` (string): Funds on hold (not available for use).
#'
#' For more details, please refer to the [KuCoin API Documentation](https://www.kucoin.com/docs-new/rest/account-info/account-funding/get-account-detail-spot).
#'
#' **Example**
#'
#' ```r
#' config <- list(
#'   api_key = "your_api_key",
#'   api_secret = "your_api_secret",
#'   api_passphrase = "your_api_passphrase",
#'   base_url = "https://api.kucoin.com",
#'   key_version = "2"
#' )
#'
#' # Retrieve details for a specific account, e.g., "548674591753":
#' coro::run(function() {
#'   dt <- await(get_spot_account_detail_impl(config, "548674591753"))
#'   print(dt)
#' })
#' ```
#'
#' @export
#' @md
get_spot_account_detail_impl <- coro::async(function(config, accountId) {
    tryCatch({
        base_url <- get_base_url(config)
        endpoint <- paste0("/api/v1/accounts/", accountId)
        method <- "GET"
        body <- ""
        headers <- await(build_headers(method, endpoint, body, config))
        url <- paste0(base_url, endpoint)

        response <- httr::GET(url, headers, timeout(3))
        data <- process_kucoin_response(response, url)
        return(data.table::as.data.table(data))
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
#' **Parameters**
#'
#' - `config`: A list containing API configuration parameters. This list must include:
#'   - `api_key`: Your KuCoin API key.
#'   - `api_secret`: Your KuCoin API secret.
#'   - `api_passphrase`: Your KuCoin API passphrase.
#'   - `base_url`: The base URL for the API (e.g., `"https://api.kucoin.com"`).
#'   - `key_version`: The version of the API key (e.g., `"2"`).
#'
#' - `query`: A list of query parameters to filter the account information. Supported parameters include:
#'   - `quoteCurrency` (string, optional): The quote currency. Allowed values are `"USDT"`, `"KCS"`, or `"BTC"`.
#'     Defaults to `"USDT"` if not provided.
#'   - `queryType` (string, optional): The type of account query. Allowed values are:
#'       - `"MARGIN"`: Only query low-frequency cross margin accounts.
#'       - `"MARGIN_V2"`: Only query high-frequency cross margin accounts.
#'       - `"ALL"`: Aggregate query, as seen on the website.
#'     Defaults to `"MARGIN"`.
#'
#' **Returns**
#'
#' A promise that resolves to a `data.table` containing the cross margin account information. The returned
#' `data.table` includes the following fields:
#'
#' - `totalAssetOfQuoteCurrency` (string): Total assets in the quote currency.
#' - `totalLiabilityOfQuoteCurrency` (string): Total liabilities in the quote currency.
#' - `debtRatio` (string): The debt ratio.
#' - `status` (string): The position status. Possible values include `"EFFECTIVE"`, `"BANKRUPTCY"`, `"LIQUIDATION"`, `"REPAY"`, or `"BORROW"`.
#' - `accounts` (list): A list of margin account details. Each element is an object containing:
#'     - `currency` (string): Currency code.
#'     - `total` (string): Total funds in the account.
#'     - `available` (string): Funds available for withdrawal or trading.
#'     - `hold` (string): Funds on hold.
#'     - `liability` (string): Current liabilities.
#'     - `maxBorrowSize` (string): Maximum borrowable amount.
#'     - `borrowEnabled` (boolean): Whether borrowing is enabled.
#'     - `transferInEnabled` (boolean): Whether transfers into the account are enabled.
#'
#' **Details**
#'
#' - **Endpoint:** `GET https://api.kucoin.com/api/v3/margin/accounts`
#'
#' For further details, please refer to the [KuCoin API Documentation](https://www.kucoin.com/docs-new/rest/account-info/account-funding/get-account-cross-margin).
#'
#' **Example**
#'
#' ```r
#' query <- list(quoteCurrency = "USDT", queryType = "MARGIN")
#' coro::run(function() {
#'   dt <- await(get_cross_margin_account_impl(config, query))
#'   print(dt)
#' })
#' ```
#'
#' @export
#' @md
get_cross_margin_account_impl <- coro::async(function(config, query = list()) {
    tryCatch({
        base_url <- get_base_url(config)
        endpoint <- "/api/v3/margin/accounts"
        method <- "GET"
        body <- ""
        qs <- build_query(query)
        full_endpoint <- paste0(endpoint, qs)
        headers <- await(build_headers(method, full_endpoint, body, config))
        url <- paste0(base_url, full_endpoint)

        response <- httr::GET(url, headers, timeout(3))
        data <- process_kucoin_response(response, url)
        dt <- data.table::as.data.table(data)
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
#' **Parameters**
#'
#' - `config`: A list containing API configuration parameters. This list must include:
#'   - `api_key`: Your KuCoin API key.
#'   - `api_secret`: Your KuCoin API secret.
#'   - `api_passphrase`: Your KuCoin API passphrase.
#'   - `base_url`: The base URL for the API (e.g., `"https://api.kucoin.com"`).
#'   - `key_version`: The version of the API key (e.g., `"2"`).
#'
#' - `query`: A list of query parameters to filter the isolated margin account information. Supported parameters include:
#'   - `symbol` (string, optional): For isolated trading pairs; if omitted, queries all pairs.
#'   - `quoteCurrency` (string, optional): The quote currency. Allowed values: `"USDT"`, `"KCS"`, `"BTC"`. Defaults to `"USDT"`.
#'   - `queryType` (string, optional): The type of account query. Allowed values: `"ISOLATED"`, `"ISOLATED_V2"`, `"ALL"`. Defaults to `"ISOLATED"`.
#'
#' **Returns**
#'
#' A promise that resolves to a `data.table` containing the isolated margin account information.
#'
#' **Details**
#'
#' - **Endpoint:** `GET https://api.kucoin.com/api/v3/isolated/accounts`
#'
#' - **Response Schema:**
#'   - `code` (string): Status code, where `"200000"` indicates success.
#'   - `data` (object): Contains:
#'     - `totalAssetOfQuoteCurrency` (string): Total assets in the quote currency.
#'     - `totalLiabilityOfQuoteCurrency` (string): Total liabilities in the quote currency.
#'     - `timestamp` (integer): The timestamp.
#'     - `assets` (array of objects): Each object represents a margin account detail with fields such as:
#'         - `symbol` (string): Trading pair symbol (e.g., `"BTC-USDT"`).
#'         - `status` (string): Position status.
#'         - `debtRatio` (string): Debt ratio.
#'         - `baseAsset` (object): Details of the base asset.
#'         - `quoteAsset` (object): Details of the quote asset.
#'
#' For more details, please refer to the [KuCoin API Documentation](https://www.kucoin.com/docs-new/rest/account-info/account-funding/get-account-isolated-margin).
#'
#' **Example**
#'
#' ```r
#' query <- list(quoteCurrency = "USDT", queryType = "ISOLATED")
#' coro::run(function() {
#'   dt <- await(get_isolated_margin_account_impl(config, query))
#'   print(dt)
#' })
#' ```
#'
#' @export
#' @md
get_isolated_margin_account_impl <- coro::async(function(config, query = list()) {
    tryCatch({
        base_url <- get_base_url(config)
        endpoint <- "/api/v3/isolated/accounts"
        method <- "GET"
        body <- ""
        qs <- build_query(query)
        full_endpoint <- paste0(endpoint, qs)
        headers <- await(build_headers(method, full_endpoint, body, config))
        url <- paste0(base_url, full_endpoint)

        response <- httr::GET(url, headers, timeout(3))
        data <- process_kucoin_response(response, url)
        dt <- data.table::as.data.table(data)
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
#' **Parameters**
#'
#' - `config`: A list containing API configuration parameters. This list should include:
#'   - `api_key`: Your KuCoin API key.
#'   - `api_secret`: Your KuCoin API secret.
#'   - `api_passphrase`: Your KuCoin API passphrase.
#'   - `base_url`: The base URL for the API (e.g., `"https://api.kucoin.com"`).
#'   - `key_version`: The version of the API key (e.g., `"2"`).
#'
#' - `query`: A list of query parameters to filter the ledger records. Supported parameters include:
#'   - `currency` (string, optional): One or more currencies (up to 10) to filter by; if omitted, all currencies are returned.
#'   - `direction` (string, optional): The direction of the transaction, either `"in"` or `"out"`.
#'   - `bizType` (string, optional): The business type of the transaction, e.g., `"DEPOSIT"`, `"WITHDRAW"`, `"TRANSFER"`, `"SUB_TRANSFER"`, `"TRADE_EXCHANGE"`, etc.
#'   - `startAt` (integer, optional): Start time in milliseconds.
#'   - `endAt` (integer, optional): End time in milliseconds.
#'   - `currentPage` (integer, optional): The page number (default is 1).
#'   - `pageSize` (integer, optional): Number of results per page (minimum 10, maximum 500; default is 50).
#'
#' **Returns**
#'
#' A promise that resolves to a `data.table` containing the ledger information, which includes:
#' - `currentPage`: The current page number.
#' - `pageSize`: The number of results per page.
#' - `totalNum`: The total number of records.
#' - `totalPage`: The total number of pages.
#' - `items`: An array of ledger records.
#'
#' **Details**
#'
#' - **Endpoint:** `GET https://api.kucoin.com/api/v1/accounts/ledgers`
#'
#' For further details, refer to the [KuCoin API Documentation](https://www.kucoin.com/docs-new/rest/account-info/account-funding/get-account-ledgers-spot-margin).
#'
#' **Example**
#'
#' ```r
#' query <- list(currency = "BTC", direction = "in", bizType = "TRANSFER", currentPage = 1, pageSize = 50)
#' coro::run(function() {
#'   dt <- await(get_spot_ledger_impl(config, query))
#'   print(dt)
#' })
#' ```
#'
#' @export
#' @md
get_spot_ledger_impl <- coro::async(function(config, query = list()) {
    tryCatch({
        base_url <- get_base_url(config)
        endpoint <- "/api/v1/accounts/ledgers"
        method <- "GET"
        body <- ""
        qs <- build_query(query)
        full_endpoint <- paste0(endpoint, qs)
        # Build authentication headers using the full endpoint (including query string)
        headers <- await(build_headers(method, full_endpoint, body, config))
        url <- paste0(base_url, full_endpoint)
        response <- httr::GET(url, headers, timeout(3))
        data <- process_kucoin_response(response, url)
        dt <- data.table::as.data.table(data)
        return(dt)
    }, error = function(e) {
        rlang::abort(paste("Error in get_spot_ledger_impl:", conditionMessage(e)))
    })
})
