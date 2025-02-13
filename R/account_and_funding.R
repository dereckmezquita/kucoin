# File: account_and_funding.R

box::use(
    httr[GET, status_code, content, timeout, add_headers],
    jsonlite[fromJSON],
    rlang[abort],
    coro,
    promises,
    data.table[as.data.table],
    ./helpers_api[build_headers, process_kucoin_response],
    ./utils[convert_datetime_range_to_ms, build_query, get_base_url]
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
        base_url <- get_base_url(config)
        endpoint <- "/api/v2/user-info"
        method <- "GET"
        body <- ""
        headers <- await(build_headers(method, endpoint, body, config))
        url <- paste0(base_url, endpoint)

        response <- GET(url, headers, timeout(3))

        # Use the helper to check the response and extract the data.
        data <- process_kucoin_response(response, url)

        dt <- as.data.table(data)
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
        data <- process_kucoin_response(response, url)
        dt <- as.data.table(data)
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
        base_url <- get_base_url(config)
        endpoint <- "/api/v1/hf/accounts/opened"
        method <- "GET"
        body <- ""
        headers <- await(build_headers(method, endpoint, body, config))
        url <- paste0(base_url, endpoint)

        response <- GET(url, headers, timeout(3))
        data <- process_kucoin_response(response, url)
        # data is expected to be a boolean value.
        return(data)
    }, error = function(e) {
        abort(paste("Error in get_spot_account_type_impl:", conditionMessage(e)))
    })
})


#' Get Spot Account DT Implementation
#'
#' This asynchronous function retrieves a list of spot accounts from the KuCoin API.
#' It sends a GET request to the `/api/v1/accounts` endpoint with optional query parameters,
#' and returns the account list as a data.table.
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
#'     - **holds** (string): Funds on hold.
#'
#' The returned JSON array is converted to a data.table.
#'
#' @examples
#' \dontrun{
#'   query <- list(currency = "USDT", type = "main")
#'   coro::run(function() {
#'       dt <- await(get_spot_account_dt_impl(config, query))
#'       print(dt)
#'   })
#' }
#'
#' @export
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

        response <- GET(url, headers, timeout(3))
        data <- process_kucoin_response(response, url)
        dt <- as.data.table(data)
        return(dt)
    }, error = function(e) {
        abort(paste("Error in get_spot_account_dt_impl:", conditionMessage(e)))
    })
})

#' Get Spot Account Detail Implementation
#'
#' This asynchronous function retrieves detailed information for a single spot account
#' from the KuCoin API. It requires the account ID as a path parameter. The function
#' constructs the full URL by embedding the provided `accountId` into the endpoint, builds
#' the authentication headers, sends the GET request, and returns the parsed response data
#' as a data.table.
#'
#' @param config A list containing API configuration parameters.
#' @param accountId A string representing the account ID for which details are requested.
#'
#' @return A promise that resolves to a data.table containing the spot account detail.
#'
#' @details
#' **Endpoint:** `GET https://api.kucoin.com/api/v1/accounts/{accountId}`
#'
#' **Response Schema:**
#' - **code** (string): `"200000"` indicates success.
#' - **data** (object): Contains the following fields:
#'     - **currency** (string): The currency of the account.
#'     - **balance** (string): Total funds in the account.
#'     - **available** (string): Funds available for withdrawal or trading.
#'     - **holds** (string): Funds on hold (not available for use).
#'
#' For further details, refer to the [KuCoin API Documentation](https://www.kucoin.com/docs-new/rest/account-info/account-funding/get-account-detail-spot).
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
#'   # Suppose you want to retrieve details for account "548674591753":
#'   coro::run(function() {
#'       dt <- await(get_spot_account_detail_impl(config, "548674591753"))
#'       print(dt)
#'   })
#' }
#'
#' @export
get_spot_account_detail_impl <- coro::async(function(config, accountId) {
    tryCatch({
        base_url <- get_base_url(config)
        endpoint <- paste0("/api/v1/accounts/", accountId)
        method <- "GET"
        body <- ""
        headers <- await(build_headers(method, endpoint, body, config))
        url <- paste0(base_url, endpoint)

        response <- GET(url, headers, timeout(3))
        data <- process_kucoin_response(response, url)
        dt <- as.data.table(data)
        return(dt)
    }, error = function(e) {
        abort(paste("Error in get_spot_account_detail_impl:", conditionMessage(e)))
    })
})

#' Get Cross Margin Account Implementation
#'
#' This asynchronous function retrieves information about the cross margin account from the KuCoin API.
#' It sends a GET request to the `/api/v3/margin/accounts` endpoint with optional query parameters and returns
#' the parsed response data as a data.table.
#'
#' @param config A list containing API configuration parameters.
#' @param query A list of query parameters to filter the account information. Supported parameters include:
#'   - **quoteCurrency** (string, optional): The quote currency. Allowed values: `"USDT"`, `"KCS"`, `"BTC"`.
#'     If not provided, the default is `"USDT"`.
#'   - **queryType** (string, optional): The type of account query. Allowed values:
#'     `"MARGIN"` (only query low-frequency cross margin account),
#'     `"MARGIN_V2"` (only query high-frequency cross margin account),
#'     `"ALL"` (aggregate query, as seen on the website). The default is `"MARGIN"`.
#'
#' @return A promise that resolves to a data.table containing the cross margin account information. The
#' data.table includes the following fields:
#'   - **totalAssetOfQuoteCurrency** (string): Total assets in the quote currency.
#'   - **totalLiabilityOfQuoteCurrency** (string): Total liabilities in the quote currency.
#'   - **debtRatio** (string): The debt ratio.
#'   - **status** (string): The position status (e.g., `"EFFECTIVE"`, `"BANKRUPTCY"`, `"LIQUIDATION"`,
#'     `"REPAY"`, or `"BORROW"`).
#'   - **accounts** (list): A list of margin account details. Each element is an object containing:
#'       - **currency** (string): Currency code.
#'       - **total** (string): Total funds in the account.
#'       - **available** (string): Funds available for withdrawal or trading.
#'       - **hold** (string): Funds on hold.
#'       - **liability** (string): Current liabilities.
#'       - **maxBorrowSize** (string): Maximum borrowable amount.
#'       - **borrowEnabled** (boolean): Whether borrowing is enabled.
#'       - **transferInEnabled** (boolean): Whether transfers into the account are enabled.
#'
#' @details
#' **Endpoint:** `GET https://api.kucoin.com/api/v3/margin/accounts`
#'
#' For further details, see the [KuCoin API Documentation](https://www.kucoin.com/docs-new/rest/account-info/account-funding/get-account-cross-margin).
#'
#' @examples
#' \dontrun{
#'   query <- list(quoteCurrency = "USDT", queryType = "MARGIN")
#'   coro::run(function() {
#'       dt <- await(get_cross_margin_account_impl(config, query))
#'       print(dt)
#'   })
#' }
#'
#' @export
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

        response <- GET(url, headers, timeout(3))
        data <- process_kucoin_response(response, url)
        dt <- as.data.table(data)
        return(dt)
    }, error = function(e) {
        abort(paste("Error in get_cross_margin_account_impl:", conditionMessage(e)))
    })
})
#' Get Isolated Margin Account Implementation
#'
#' This asynchronous function retrieves information about the isolated margin account from the KuCoin API.
#' It sends a GET request to the `/api/v3/isolated/accounts` endpoint with optional query parameters and
#' returns the parsed response data as a data.table.
#'
#' @param config A list containing API configuration parameters.
#' @param query A list of query parameters to filter the isolated margin account information.
#'        Supported parameters include:
#'         - **symbol** (string, optional): For isolated trading pairs; if omitted, queries all pairs.
#'         - **quoteCurrency** (string, optional): The quote currency. Allowed values: `"USDT"`, `"KCS"`, `"BTC"`. Default is `"USDT"`.
#'         - **queryType** (string, optional): The type of account query. Allowed values: `"ISOLATED"`, `"ISOLATED_V2"`, `"ALL"`. Default is `"ISOLATED"`.
#'
#' @return A promise that resolves to a data.table containing the isolated margin account information.
#'
#' @details
#' **Endpoint:** `GET https://api.kucoin.com/api/v3/isolated/accounts`
#'
#' **Response Schema:**
#' - **code** (string): `"200000"` indicates success.
#' - **data** (object): Contains:
#'     - **totalAssetOfQuoteCurrency** (string): Total assets in the quote currency.
#'     - **totalLiabilityOfQuoteCurrency** (string): Total liabilities in the quote currency.
#'     - **timestamp** (integer): The timestamp.
#'     - **assets** (array of objects): Each object represents a margin account detail with fields such as:
#'           - **symbol** (string): Trading pair symbol (e.g., "BTC-USDT").
#'           - **status** (string): Position status.
#'           - **debtRatio** (string): Debt ratio.
#'           - **baseAsset** (object): Details of the base asset.
#'           - **quoteAsset** (object): Details of the quote asset.
#'
#' For more details, refer to the [KuCoin API Documentation](https://www.kucoin.com/docs-new/rest/account-info/account-funding/get-account-isolated-margin).
#'
#' @examples
#' \dontrun{
#'     query <- list(quoteCurrency = "USDT", queryType = "ISOLATED")
#'     coro::run(function() {
#'         dt <- await(get_isolated_margin_account_impl(config, query))
#'         print(dt)
#'     })
#' }
#'
#' @export
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

        response <- GET(url, headers, timeout(3))
        data <- process_kucoin_response(response, url)
        dt <- as.data.table(data)
        return(dt)
    }, error = function(e) {
        abort(paste("Error in get_isolated_margin_account_impl:", conditionMessage(e)))
    })
})

#' Get Futures Account Implementation
#'
#' This asynchronous function retrieves the futures account information from the KuCoin Futures API.
#' It sends a GET request to the `/api/v1/account-overview` endpoint with optional query parameters.
#'
#' @param config A list containing API configuration parameters.
#' @param query A list of query parameters to filter the account information. Supported parameter:
#'        - **currency** (string, optional): The account currency. The default is "XBT", but you may specify others (e.g., "USDT", "ETH").
#'
#' @return A promise that resolves to a data.table containing the futures account information.
#'
#' @details
#' **Endpoint:** `GET https://api-futures.kucoin.com/api/v1/account-overview`
#'
#' For further details, please refer to the
#' [KuCoin API Documentation](https://www.kucoin.com/docs-new/rest/account-info/account-funding/get-account-futures).
#'
#' @examples
#' \dontrun{
#'     query <- list(currency = "USDT")
#'     coro::run(function() {
#'         dt <- await(get_futures_account_impl(config, query))
#'         print(dt)
#'     })
#' }
#'
#' @export
get_futures_account_impl <- coro::async(function(config, query = list()) {
    tryCatch({
        # Use the futures base URL if provided in config; otherwise, use the default.
        if (!is.null(config$futures_base_url)) {
            base_url <- config$futures_base_url
        } else {
            base_url <- "https://api-futures.kucoin.com"
        }
        endpoint <- "/api/v1/account-overview"
        method <- "GET"
        body <- ""
        qs <- build_query(query)
        full_endpoint <- paste0(endpoint, qs)
        # Build authentication headers using the full endpoint (including query string)
        headers <- await(build_headers(method, full_endpoint, body, config))
        url <- paste0(base_url, full_endpoint)
        response <- GET(url, headers, timeout(3))
        data <- process_kucoin_response(response, url)
        dt <- as.data.table(data)
        return(dt)
    }, error = function(e) {
        abort(paste("Error in get_futures_account_impl:", conditionMessage(e)))
    })
})

#' Get Spot Ledger Implementation
#'
#' This asynchronous function retrieves transaction records (ledgers) for spot/margin accounts from the KuCoin API.
#' It sends a GET request to the `/api/v1/accounts/ledgers` endpoint with optional query parameters.
#'
#' @param config A list containing API configuration parameters.
#' @param query A list of query parameters to filter the ledger records. Supported parameters include:
#'   - **currency** (string, optional): One or more currencies (up to 10) to filter by; if omitted, all currencies are returned.
#'   - **direction** (string, optional): "in" or "out".
#'   - **bizType** (string, optional): e.g., "DEPOSIT", "WITHDRAW", "TRANSFER", "SUB_TRANSFER", "TRADE_EXCHANGE", etc.
#'   - **startAt** (integer, optional): Start time in milliseconds.
#'   - **endAt** (integer, optional): End time in milliseconds.
#'   - **currentPage** (integer, optional): The page number (default is 1).
#'   - **pageSize** (integer, optional): Number of results per page (minimum 10, maximum 500; default is 50).
#'
#' @return A promise that resolves to a data.table containing the ledger information. The returned object includes:
#'         - currentPage, pageSize, totalNum, totalPage, and items (an array of ledger records).
#'
#' @details
#' **Endpoint:** `GET https://api.kucoin.com/api/v1/accounts/ledgers`
#'
#' For further details, refer to the
#' [KuCoin API Documentation](https://www.kucoin.com/docs-new/rest/account-info/account-funding/get-account-ledgers-spot-margin).
#'
#' @examples
#' \dontrun{
#'     query <- list(currency = "BTC", direction = "in", bizType = "TRANSFER", currentPage = 1, pageSize = 50)
#'     coro::run(function() {
#'         dt <- await(get_spot_ledger_impl(config, query))
#'         print(dt)
#'     })
#' }
#'
#' @export
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
        response <- GET(url, headers, timeout(3))
        data <- process_kucoin_response(response, url)
        dt <- as.data.table(data)
        return(dt)
    }, error = function(e) {
        abort(paste("Error in get_spot_ledger_impl:", conditionMessage(e)))
    })
})

