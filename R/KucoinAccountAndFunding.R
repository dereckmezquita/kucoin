# File: ./R/KucoinAccountAndFunding.R

# box::use(
#     impl = ./impl_account_and_funding,
#     ./utils[ get_api_keys, get_base_url ]
# )

#' KucoinAccountAndFunding Class for KuCoin Account & Funding Endpoints
#'
#' The `KucoinAccountAndFunding` class provides a comprehensive, asynchronous interface for interacting with the
#' Account & Funding endpoints of the KuCoin API. It leverages the `coro` package to perform non-blocking HTTP requests
#' and returns promises that often resolve to `data.table` objects. This class covers a wide range of functionalities,
#' including:
#'
#' - Retrieving a complete account summary (VIP level, sub-account counts, and various limits).
#' - Fetching detailed API key information (key details, permissions, IP whitelist, creation time, etc.).
#' - Determining the type of your spot account (high-frequency vs. low-frequency).
#' - Listing all spot accounts, with optional filters for currency and account type.
#' - Obtaining detailed information for a specific spot account.
#' - Retrieving cross margin account information with asset/liability summaries.
#' - Fetching isolated margin account data for specific trading pairs.
#' - Obtaining detailed ledger records (transaction histories) for spot and margin accounts.
#'
#' ### Workflow Overview
#' Not applicable (class definition overview).
#'
#' ### API Endpoint
#' Not applicable (class-level documentation; see individual methods).
#'
#' ### Usage
#' Utilised by users to interact with KuCoin's Account & Funding endpoints. The class is initialised with API credentials,
#' automatically loaded via `get_api_keys()` if not provided, and a base URL from `get_base_url()`. For detailed endpoint
#' information and response schemas, refer to the official [KuCoin API Documentation](https://www.kucoin.com/docs-new).
#'
#' ### Official Documentation
#' [KuCoin API Documentation](https://www.kucoin.com/docs-new)
#'
#' @section Methods:
#' - **initialize(keys, base_url):** Initialises the object with API credentials and the base URL.
#' - **get_account_summary_info():** Retrieves a comprehensive summary of the user's account.
#' - **get_apikey_info():** Retrieves detailed information about the API key.
#' - **get_spot_account_type():** Determines whether the spot account is high-frequency or low-frequency.
#' - **get_spot_account_dt(query):** Retrieves a list of all spot accounts with optional filters.
#' - **get_spot_account_detail(accountId):** Retrieves detailed information for a specific spot account.
#' - **get_cross_margin_account(query):** Retrieves cross margin account information based on specified filters.
#' - **get_isolated_margin_account(query):** Retrieves isolated margin account data for specific trading pairs.
#' - **get_spot_ledger(query, page_size, max_pages):** Retrieves detailed ledger records for spot and margin accounts, including pagination.
#'
#' @return Not applicable (class definition; see individual methods for return values).
#'
#' @examples
#' \dontrun{
#' main_async <- coro::async(function() {
#'   # Initialise the class
#'   account <- KucoinAccountAndFunding$new()
#'
#'   # Get account summary
#'   summary <- await(account$get_account_summary_info())
#'   print("Account Summary:")
#'   print(summary)
#'
#'   # Get API key info
#'   key_info <- await(account$get_apikey_info())
#'   print("API Key Info:")
#'   print(key_info)
#'
#'   # Check spot account type
#'   is_high_freq <- await(account$get_spot_account_type())
#'   cat("Spot Account High-Frequency:", is_high_freq, "\n")
#'
#'   # List spot accounts and filter for USDT main accounts
#'   spot_accounts <- await(account$get_spot_account_dt(list(currency = "USDT", type = "main")))
#'   print("Spot Accounts (USDT Main):")
#'   print(spot_accounts)
#'
#'   # Get details for the first USDT main account (if any)
#'   if (nrow(spot_accounts) > 0) {
#'     account_id <- spot_accounts[1, id]
#'     account_detail <- await(account$get_spot_account_detail(account_id))
#'     print("Spot Account Detail:")
#'     print(account_detail)
#'   }
#'
#'   # Get cross margin account info
#'   cross_margin <- await(account$get_cross_margin_account(list(quoteCurrency = "USDT")))
#'   print("Cross Margin Summary:")
#'   print(cross_margin$summary)
#'   print("Cross Margin Accounts:")
#'   print(cross_margin$accounts)
#'
#'   # Get isolated margin account info for BTC-USDT
#'   isolated_margin <- await(account$get_isolated_margin_account(list(symbol = "BTC-USDT")))
#'   print("Isolated Margin Summary:")
#'   print(isolated_margin$summary)
#'   print("Isolated Margin Assets:")
#'   print(isolated_margin$assets)
#'
#'   # Get spot ledger records for BTC transfers in the last day
#'   query <- list(currency = "BTC", bizType = "TRANSFER", startAt = as.integer(Sys.time() - 86400) * 1000, endAt = as.integer(Sys.time()) * 1000)
#'   ledger <- await(account$get_spot_ledger(query, page_size = 50, max_pages = 2))
#'   print("Spot Ledger Records:")
#'   print(ledger)
#' })
#' main_async()
#' while (!later::loop_empty()) later::run_now()
#' }
#'
#' @importFrom R6 R6Class
#' @export
KucoinAccountAndFunding <- R6::R6Class(
    "KucoinAccountAndFunding",
    public = list(
        #' @field keys List of API configuration parameters from `get_api_keys()`, including `api_key`, `api_secret`, 
        #' `api_passphrase`, and `key_version`.
        keys = NULL,
        #' @field base_url Character string representing the base URL for the KuCoin API, obtained via `get_base_url()`.
        base_url = NULL,

        #' Initialise a New KucoinAccountAndFunding Object
        #'
        #' ### Description
        #' Initialises a `KucoinAccountAndFunding` object with API credentials and a base URL for interacting with KuCoin's Account & Funding endpoints asynchronously. If credentials or the base URL are not provided, they are sourced from `get_api_keys()` and `get_base_url()`, respectively.
        #'
        #' ### Workflow Overview
        #' 1. **Credential Assignment**: Assigns the provided or default API keys to `self$keys`.
        #' 2. **URL Assignment**: Assigns the provided or default base URL to `self$base_url`.
        #'
        #' ### API Endpoint
        #' Not applicable (initialisation method).
        #'
        #' ### Usage
        #' Utilised to create an instance of the class with necessary authentication details for accessing KuCoin API endpoints.
        #'
        #' ### Official Documentation
        #' [KuCoin API Authentication](https://www.kucoin.com/docs-new/rest/introduction)
        #'
        #' @param keys List containing API configuration parameters from `get_api_keys()`, including:
        #'   - `api_key`: Character string; your KuCoin API key.
        #'   - `api_secret`: Character string; your KuCoin API secret.
        #'   - `api_passphrase`: Character string; your KuCoin API passphrase.
        #'   - `key_version`: Character string; API key version (e.g., `"2"`).
        #'   Defaults to `get_api_keys()`.
        #' @param base_url Character string representing the base URL for the API. Defaults to `get_base_url()`.
        #'
        #' @return A new instance of the `KucoinAccountAndFunding` class.
        #'
        #' @examples
        #' \dontrun{
        #' account <- KucoinAccountAndFunding$new()
        #' }
        initialize = function(keys = get_api_keys(), base_url = get_base_url()) {
            self$keys <- keys
            self$base_url <- base_url
        },

        #' Retrieve Account Summary Information
        #'
        #' ### Description
        #' Retrieves a comprehensive summary of the user's account from the KuCoin API asynchronously. This includes the VIP level, total number of sub-accounts, breakdown by trading type (spot, margin, futures, options), and associated limits. This method calls the internal `get_account_summary_info_impl` function.
        #'
        #' ### Workflow Overview
        #' 1. **URL Construction**: Combines the base URL with the endpoint `/api/v2/user-info`.
        #' 2. **Header Preparation**: Constructs authentication headers using `build_headers()` with the HTTP method, endpoint, and an empty request body.
        #' 3. **API Request**: Sends a GET request with a 3-second timeout via `httr::GET()`.
        #' 4. **Response Processing**: Processes the JSON response with `process_kucoin_response()`, converting the `"data"` field into a `data.table`.
        #'
        #' ### API Endpoint
        #' `GET https://api.kucoin.com/api/v2/user-info`
        #'
        #' ### Usage
        #' Utilised by users to obtain a high-level overview of their KuCoin account status, including sub-account limits and VIP tier benefits.
        #'
        #' ### Official Documentation
        #' [KuCoin Get Account Summary Info](https://www.kucoin.com/docs-new/rest/account-info/account-funding/get-account-summary-info)
        #'
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
        #'
        #' @examples
        #' \dontrun{
        #' main_async <- coro::async(function() {
        #'   account <- KucoinAccountAndFunding$new()
        #'   summary <- await(account$get_account_summary_info())
        #'   print(summary)
        #' })
        #' main_async()
        #' while (!later::loop_empty()) later::run_now()
        #' }
        get_account_summary_info = function() {
            return(get_account_summary_info_impl(self$keys, self$base_url))
        },

        #' Retrieve API Key Information
        #'
        #' ### Description
        #' Retrieves detailed metadata about the API key used for authentication from the KuCoin API asynchronously. This includes account UID, sub-account name (if applicable), remarks, permissions, IP whitelist, and creation timestamp. This method calls `get_apikey_info_impl`.
        #'
        #' ### Workflow Overview
        #' 1. **URL Construction**: Combines the base URL with the endpoint `/api/v1/user/api-key`.
        #' 2. **Header Preparation**: Constructs authentication headers using `build_headers()`.
        #' 3. **API Request**: Sends a GET request with a 3-second timeout via `httr::GET()`.
        #' 4. **Response Processing**: Processes the response with `process_kucoin_response()`, converting the `"data"` field into a `data.table`.
        #'
        #' ### API Endpoint
        #' `GET https://api.kucoin.com/api/v1/user/api-key`
        #'
        #' ### Usage
        #' Utilised by users to inspect the properties and permissions of their KuCoin API key, aiding in security and configuration audits.
        #'
        #' ### Official Documentation
        #' [KuCoin Get API Key Info](https://www.kucoin.com/docs-new/rest/account-info/account-funding/get-apikey-info)
        #'
        #' @return Promise resolving to a `data.table` containing:
        #'   - `uid` (integer): Account UID.
        #'   - `subName` (character, optional): Sub-account name (if applicable).
        #'   - `remark` (character): API key remarks.
        #'   - `apiKey` (character): API key string.
        #'   - `apiVersion` (integer): API version.
        #'   - `permission` (character): Comma-separated permissions list (e.g., `"General, Spot"`).
        #'   - `ipWhitelist` (character, optional): IP whitelist.
        #'   - `isMaster` (logical): Master account indicator.
        #'   - `createdAt` (integer): Creation timestamp in milliseconds.
        #'
        #' @examples
        #' \dontrun{
        #' main_async <- coro::async(function() {
        #'   account <- KucoinAccountAndFunding$new()
        #'   key_info <- await(account$get_apikey_info())
        #'   print(key_info)
        #' })
        #' main_async()
        #' while (!later::loop_empty()) later::run_now()
        #' }
        get_apikey_info = function() {
            return(get_apikey_info_impl(self$keys, self$base_url))
        },

        #' Determine Spot Account Type
        #'
        #' ### Description
        #' Determines whether the user's spot account is high-frequency or low-frequency asynchronously. This distinction affects asset transfer and balance query endpoints. This method calls `get_spot_account_type_impl`.
        #'
        #' ### Workflow Overview
        #' 1. **URL Construction**: Combines the base URL with `/api/v1/hf/accounts/opened`.
        #' 2. **Header Preparation**: Constructs authentication headers via `build_headers()`.
        #' 3. **API Request**: Sends a GET request with a 3-second timeout via `httr::GET()`.
        #' 4. **Response Processing**: Extracts the boolean `"data"` field from the response processed by `process_kucoin_response()`.
        #'
        #' ### API Endpoint
        #' `GET https://api.kucoin.com/api/v1/hf/accounts/opened`
        #'
        #' ### Usage
        #' Utilised by users to identify their spot account type, which influences the appropriate endpoints for trading operations.
        #'
        #' ### Official Documentation
        #' [KuCoin Get Account Type Spot](https://www.kucoin.com/docs-new/rest/account-info/account-funding/get-account-type-spot)
        #'
        #' @return Promise resolving to a logical value:
        #'   - `TRUE`: High-frequency spot account.
        #'   - `FALSE`: Low-frequency spot account.
        #'
        #' @examples
        #' \dontrun{
        #' main_async <- coro::async(function() {
        #'   account <- KucoinAccountAndFunding$new()
        #'   is_high_freq <- await(account$get_spot_account_type())
        #'   cat("Spot Account High-Frequency:", is_high_freq, "\n")
        #' })
        #' main_async()
        #' while (!later::loop_empty()) later::run_now()
        #' }
        get_spot_account_type = function() {
            return(get_spot_account_type_impl(self$keys, self$base_url))
        },

        #' Retrieve Spot Account List
        #'
        #' ### Description
        #' Retrieves a list of all spot accounts associated with the KuCoin account asynchronously, with optional filters for currency and account type. This method returns financial metrics in a `data.table` and calls `get_spot_account_dt_impl`.
        #'
        #' ### Workflow Overview
        #' 1. **URL Construction**: Combines the base URL with `/api/v1/accounts` and a query string from `build_query()`.
        #' 2. **Header Preparation**: Constructs authentication headers using `build_headers()`.
        #' 3. **API Request**: Sends a GET request with a 3-second timeout via `httr::GET()`.
        #' 4. **Response Processing**: Converts the `"data"` array into a `data.table`, handling empty responses with a typed empty table.
        #'
        #' ### API Endpoint
        #' `GET https://api.kucoin.com/api/v1/accounts`
        #'
        #' ### Usage
        #' Utilised by users to list all spot accounts, filterable by currency or type, for account management or monitoring.
        #'
        #' ### Official Documentation
        #' [KuCoin Get Account List Spot](https://www.kucoin.com/docs-new/rest/account-info/account-funding/get-account-list-spot)
        #'
        #' @param query Named list of query parameters, e.g., `list(currency = "USDT", type = "main")`. Supported:
        #'   - `currency` (character, optional): Filter by currency (e.g., `"USDT"`).
        #'   - `type` (character, optional): Filter by account type (`"main"`, `"trade"`).
        #'
        #' @return Promise resolving to a `data.table` containing:
        #'   - `id` (character): Account ID.
        #'   - `currency` (character): Currency code.
        #'   - `type` (character): Account type (e.g., `"main"`, `"trade"`).
        #'   - `balance` (numeric): Total funds.
        #'   - `available` (numeric): Available funds.
        #'   - `holds` (numeric): Funds on hold.
        #'
        #' @examples
        #' \dontrun{
        #' main_async <- coro::async(function() {
        #'   account <- KucoinAccountAndFunding$new()
        #'   spot_accounts <- await(account$get_spot_account_dt(list(currency = "USDT", type = "main")))
        #'   print(spot_accounts)
        #' })
        #' main_async()
        #' while (!later::loop_empty()) later::run_now()
        #' }
        get_spot_account_dt = function(query = list()) {
            return(get_spot_account_dt_impl(self$keys, self$base_url, query))
        },

        #' Retrieve Spot Account Details
        #'
        #' ### Description
        #' Retrieves detailed financial metrics for a specific spot account identified by its `accountId` from the KuCoin API asynchronously. This method calls `get_spot_account_detail_impl` and requires an account ID, obtainable via `get_spot_account_dt()`.
        #'
        #' ### Workflow Overview
        #' 1. **URL Construction**: Embeds `accountId` into `/api/v1/accounts/{accountId}` and combines with the base URL.
        #' 2. **Header Preparation**: Constructs authentication headers using `build_headers()`.
        #' 3. **API Request**: Sends a GET request with a 3-second timeout via `httr::GET()`.
        #' 4. **Response Processing**: Converts the `"data"` field into a `data.table`, handling empty responses.
        #'
        #' ### API Endpoint
        #' `GET https://api.kucoin.com/api/v1/accounts/{accountId}`
        #'
        #' ### Usage
        #' Utilised by users to obtain detailed metrics for a specific spot account, such as balance and availability, after identifying the account ID.
        #'
        #' ### Official Documentation
        #' [KuCoin Get Account Detail Spot](https://www.kucoin.com/docs-new/rest/account-info/account-funding/get-account-detail-spot)
        #'
        #' @param accountId Character string; unique account ID (e.g., from `get_spot_account_dt()`).
        #'
        #' @return Promise resolving to a `data.table` containing:
        #'   - `currency` (character): Currency of the account.
        #'   - `balance` (numeric): Total funds.
        #'   - `available` (numeric): Available funds.
        #'   - `holds` (numeric): Funds on hold.
        #'
        #' @examples
        #' \dontrun{
        #' main_async <- coro::async(function() {
        #'   account <- KucoinAccountAndFunding$new()
        #'   spot_accounts <- await(account$get_spot_account_dt(list(currency = "USDT")))
        #'   if (nrow(spot_accounts) > 0) {
        #'     account_id <- spot_accounts[1, id]
        #'     detail <- await(account$get_spot_account_detail(account_id))
        #'     print(detail)
        #'   }
        #' })
        #' main_async()
        #' while (!later::loop_empty()) later::run_now()
        #' }
        get_spot_account_detail = function(accountId) {
            return(get_spot_account_detail_impl(self$keys, self$base_url, accountId))
        },

        #' Retrieve Cross Margin Account Information
        #'
        #' ### Description
        #' Retrieves detailed information about the cross margin account asynchronously, including overall metrics and individual accounts. Cross margin allows collateral use across multiple trading pairs. This method calls `get_cross_margin_account_impl`.
        #'
        #' ### Workflow Overview
        #' 1. **URL Construction**: Combines the base URL with `/api/v3/margin/accounts` and a query string from `build_query()`.
        #' 2. **Header Preparation**: Constructs authentication headers using `build_headers()`.
        #' 3. **API Request**: Sends a GET request with a 3-second timeout via `httr::GET()`.
        #' 4. **Response Processing**: Splits the `"data"` field into `summary` and `accounts` `data.table` objects.
        #'
        #' ### API Endpoint
        #' `GET https://api.kucoin.com/api/v3/margin/accounts`
        #'
        #' ### Usage
        #' Utilised by users to monitor cross margin account status, including total assets, liabilities, and per-currency details.
        #'
        #' ### Official Documentation
        #' [KuCoin Get Account Cross Margin](https://www.kucoin.com/docs-new/rest/account-info/account-funding/get-account-cross-margin)
        #'
        #' @param query Named list of query parameters:
        #'   - `quoteCurrency` (character, optional): Quote currency (e.g., `"USDT"`, `"KCS"`, `"BTC"`; default `"USDT"`).
        #'   - `queryType` (character, optional): Account type (`"MARGIN"`, `"MARGIN_V2"`, `"ALL"`; default `"MARGIN"`).
        #'
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
        #'
        #' @examples
        #' \dontrun{
        #' main_async <- coro::async(function() {
        #'   account <- KucoinAccountAndFunding$new()
        #'   cross_margin <- await(account$get_cross_margin_account(list(quoteCurrency = "USDT")))
        #'   print(cross_margin$summary)
        #'   print(cross_margin$accounts)
        #' })
        #' main_async()
        #' while (!later::loop_empty()) later::run_now()
        #' }
        get_cross_margin_account = function(query = list()) {
            return(get_cross_margin_account_impl(self$keys, self$base_url, query))
        },

        #' Retrieve Isolated Margin Account Information
        #'
        #' ### Description
        #' Retrieves isolated margin account details for specific trading pairs from the KuCoin API asynchronously, segregating collateral by pair. This method calls `get_isolated_margin_account_impl`.
        #'
        #' ### Workflow Overview
        #' 1. **URL Construction**: Combines the base URL with `/api/v3/isolated/accounts` and a query string from `build_query()`.
        #' 2. **Header Preparation**: Constructs authentication headers using `build_headers()`.
        #' 3. **API Request**: Sends a GET request with a 3-second timeout via `httr::GET()`.
        #' 4. **Response Processing**: Converts the `"data"` field into `summary` and flattened `assets` `data.table` objects, adding a `datetime` column.
        #'
        #' ### API Endpoint
        #' `GET https://api.kucoin.com/api/v3/isolated/accounts`
        #'
        #' ### Usage
        #' Utilised by users to monitor isolated margin accounts, providing detailed asset and liability data per trading pair.
        #'
        #' ### Official Documentation
        #' [KuCoin Get Account Isolated Margin](https://www.kucoin.com/docs-new/rest/account-info/account-funding/get-account-isolated-margin)
        #'
        #' @param query Named list of query parameters:
        #'   - `symbol` (character, optional): Trading pair (e.g., `"BTC-USDT"`).
        #'   - `quoteCurrency` (character, optional): Quote currency (e.g., `"USDT"`, `"KCS"`, `"BTC"`; default `"USDT"`).
        #'   - `queryType` (character, optional): Type (`"ISOLATED"`, `"ISOLATED_V2"`, `"ALL"`; default `"ISOLATED"`).
        #'
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
        #'
        #' @examples
        #' \dontrun{
        #' main_async <- coro::async(function() {
        #'   account <- KucoinAccountAndFunding$new()
        #'   isolated_margin <- await(account$get_isolated_margin_account(list(symbol = "BTC-USDT")))
        #'   print(isolated_margin$summary)
        #'   print(isolated_margin$assets)
        #' })
        #' main_async()
        #' while (!later::loop_empty()) later::run_now()
        #' }
        get_isolated_margin_account = function(query = list()) {
            return(get_isolated_margin_account_impl(self$keys, self$base_url, query))
        },

        #' Retrieve Spot Ledger Records
        #'
        #' ### Description
        #' Retrieves detailed ledger records for spot and margin accounts from the KuCoin API asynchronously with pagination, aggregating transaction histories into a `data.table`. This method calls `get_spot_ledger_impl`.
        #'
        #' ### Workflow Overview
        #' 1. **URL Construction**: Combines the base URL with `/api/v1/accounts/ledgers`, merging query parameters with pagination settings.
        #' 2. **Header Preparation**: Constructs authentication headers using `build_headers()` within an inner async function.
        #' 3. **API Request**: Utilises `auto_paginate` to fetch all pages asynchronously via an inner `fetch_page` function.
        #' 4. **Response Processing**: Aggregates `"items"` from each page into a `data.table`, adding a `createdAtDatetime` column.
        #'
        #' ### API Endpoint
        #' `GET https://api.kucoin.com/api/v1/accounts/ledgers`
        #'
        #' ### Usage
        #' Utilised by users to retrieve transaction histories for spot and margin accounts, filterable by currency, direction, and time range.
        #'
        #' ### Official Documentation
        #' [KuCoin Get Account Ledgers Spot Margin](https://www.kucoin.com/docs-new/rest/account-info/account-funding/get-account-ledgers-spot-margin)
        #'
        #' @param query Named list of query parameters (excluding pagination):
        #'   - `currency` (character, optional): Filter by currency (up to 10).
        #'   - `direction` (character, optional): `"in"` or `"out"`.
        #'   - `bizType` (character, optional): Business type (e.g., `"DEPOSIT"`, `"TRANSFER"`).
        #'   - `startAt` (integer, optional): Start time in milliseconds.
        #'   - `endAt` (integer, optional): End time in milliseconds.
        #' @param page_size Integer; number of results per page (10–500, default 50).
        #' @param max_pages Numeric; maximum number of pages to fetch (default `Inf` for all pages).
        #'
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
        #'
        #' @examples
        #' \dontrun{
        #' main_async <- coro::async(function() {
        #'   account <- KucoinAccountAndFunding$new()
        #'   query <- list(currency = "BTC", bizType = "TRANSFER", startAt = as.integer(Sys.time() - 86400) * 1000, endAt = as.integer(Sys.time()) * 1000)
        #'   ledger <- await(account$get_spot_ledger(query, page_size = 50, max_pages = 2))
        #'   print(ledger)
        #' })
        #' main_async()
        #' while (!later::loop_empty()) later::run_now()
        #' }
        get_spot_ledger = function(query = list(), page_size = 50, max_pages = Inf) {
            return(get_spot_ledger_impl(
                keys = self$keys,
                base_url = self$base_url,
                query = query,
                page_size = page_size,
                max_pages = max_pages
            ))
        }
    )
)
