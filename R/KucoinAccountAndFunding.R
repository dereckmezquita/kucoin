# File: ./R/KucoinAccountAndFunding.R

# box::use(
#     ./impl_account_account_and_funding[
#         get_account_summary_info_impl,
#         get_apikey_info_impl,
#         get_spot_account_type_impl,
#         get_spot_account_list_impl,
#         get_spot_account_detail_impl,
#         get_cross_margin_account_impl,
#         get_isolated_margin_account_impl,
#         get_spot_ledger_impl
#     ],
#     ./utils[get_api_keys, get_base_url]
# )

#' KucoinAccountAndFunding Class for KuCoin Account and Funding Management
#'
#' The `KucoinAccountAndFunding` class provides a comprehensive, asynchronous interface for managing account and funding
#' operations on KuCoin. It leverages the `coro` package for non-blocking HTTP requests, returning promises that resolve
#' to `data.table` objects or logical values. This class encompasses a wide range of functionalities, including account
#' summaries, API key details, spot account types, account lists, and ledger records for spot and margin accounts.
#'
#' ### Purpose and Scope
#' This class is designed to manage and monitor KuCoin account details and funding activities, covering:
#' - **Account Overview**: Summaries of VIP levels, sub-accounts, and limits.
#' - **API Key Insights**: Metadata and permissions of the API key.
#' - **Spot Account Management**: Type detection, account lists, and detailed financial metrics.
#' - **Margin Accounts**: Cross and isolated margin account details.
#' - **Transaction History**: Ledger records for tracking funding activities.
#'
#' ### Workflow Overview
#' Not applicable (class definition overview).
#'
#' ### API Endpoint
#' Not applicable (class-level documentation; see individual methods for specific endpoints).
#'
#' ### Usage
#' Utilised by traders and developers to programmatically interact with KuCoin’s Account & Funding endpoints. The class is
#' initialized with API credentials, sourced from `get_api_keys()` if not provided, and a base URL from `get_base_url()`.
#' All methods require authentication. For detailed endpoint information, parameters, and response schemas, refer to the
#' official [KuCoin API Documentation](https://www.kucoin.com/docs-new).
#'
#' ### Official Documentation
#' [KuCoin API Documentation - Account & Funding](https://www.kucoin.com/docs-new/rest/account-info/account-funding/introduction)
#'
#' @section Methods:
#' - **initialize(keys, base_url):** Initialises the object with API credentials and base URL.
#' - **get_account_summary_info():** Retrieves a summary of account status and limits.
#' - **get_apikey_info():** Fetches detailed API key metadata.
#' - **get_spot_account_type():** Determines if the spot account is high-frequency.
#' - **get_spot_account_list(query):** Lists all spot accounts with optional filters.
#' - **get_spot_account_detail(accountId):** Retrieves details for a specific spot account.
#' - **get_cross_margin_account(query):** Fetches cross margin account information.
#' - **get_isolated_margin_account(query):** Retrieves isolated margin account details.
#' - **get_spot_ledger(query, page_size, max_pages):** Fetches paginated ledger records.
#'
#' @return Not applicable (class definition; see individual methods for return values).
#'
#' @examples
#' \dontrun{
#' # Comprehensive example demonstrating key methods
#' main_async <- coro::async(function() {
#'   # Initialise the class
#'   account <- KucoinAccountAndFunding$new()
#'
#'   # Get account summary
#'   summary <- await(account$get_account_summary_info())
#'   print("Account Summary:"); print(summary)
#'
#'   # Check spot account type
#'   is_high_freq <- await(account$get_spot_account_type())
#'   cat("Is High-Frequency Spot Account:", is_high_freq, "\n")
#'
#'   # List USDT trade accounts
#'   spot_accounts <- await(account$get_spot_account_list(list(currency = "USDT", type = "trade")))
#'   print("USDT Trade Accounts:"); print(spot_accounts)
#'
#'   # Get ledger for last 24 hours
#'   ledger <- await(account$get_spot_ledger(
#'     list(currency = "BTC", startAt = as.integer(Sys.time() - 24*3600) * 1000),
#'     page_size = 20,
#'     max_pages = 1
#'   ))
#'   print("Recent BTC Ledger:"); print(ledger)
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
        #' @field keys List containing KuCoin API keys (`api_key`, `api_secret`, `api_passphrase`, `key_version`).
        keys = NULL,
        #' @field base_url Character string representing the base URL for KuCoin API endpoints.
        base_url = NULL,

        #' Initialise a New KucoinAccountAndFunding Object
        #'
        #' ### Description
        #' Initialises a `KucoinAccountAndFunding` object with API credentials and a base URL for managing account and
        #' funding operations asynchronously. All methods require authentication via API keys.
        #'
        #' ### Workflow Overview
        #' 1. **Credential Assignment**: Sets `self$keys` to the provided or default API keys from `get_api_keys()`.
        #' 2. **URL Assignment**: Sets `self$base_url` to the provided or default base URL from `get_base_url()`.
        #'
        #' ### API Endpoint
        #' Not applicable (initialisation method).
        #'
        #' ### Usage
        #' Creates an instance for accessing KuCoin account and funding data, requiring authenticated API access.
        #'
        #' ### Official Documentation
        #' [KuCoin API Authentication](https://www.kucoin.com/docs-new/rest/introduction#authentication)
        #'
        #' ### Automated Trading Usage
        #' - **Account Hub**: Use as the central object for account monitoring in your bot, integrating with trading strategies.
        #' - **Secure Setup**: Provide explicit `keys` or use `get_api_keys()` from a secure source for production safety.
        #' - **Lifecycle Management**: Instantiate once and reuse across sessions, pairing with deposit/withdrawal classes for full financial oversight.
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
        initialize = function(keys = get_api_keys(), base_url = get_base_url()) {
            self$keys <- keys
            self$base_url <- base_url
        },

        #' Get Account Summary Information
        #'
        #' ### Description
        #' Retrieves a comprehensive account summary asynchronously via a GET request to `/api/v2/user-info`.
        #' Calls `get_account_summary_info_impl`.
        #'
        #' ### Workflow Overview
        #' 1. **Request**: Constructs authenticated GET request.
        #' 2. **Response**: Returns a `data.table` with VIP level, sub-account counts, and limits.
        #'
        #' ### API Endpoint
        #' `GET https://api.kucoin.com/api/v2/user-info`
        #'
        #' ### Usage
        #' Utilised to obtain a high-level overview of account status, including sub-account limits and VIP benefits.
        #'
        #' ### Official Documentation
        #' [KuCoin Get Account Summary Info](https://www.kucoin.com/docs-new/rest/account-info/account-funding/get-account-summary-info)
        #'
        #' ### Automated Trading Usage
        #' - **Capacity Check**: Monitor `maxSubQuantity` to manage sub-account creation, scaling bot operations as needed.
        #' - **VIP Benefits**: Adjust trading fees or limits in your bot based on `level`, optimizing cost strategies.
        #' - **Periodic Audit**: Fetch daily to log account health, alerting if sub-account limits are near capacity.
        #'
        #' @return Promise resolving to a `data.table` with:
        #'   - `level` (integer): VIP level.
        #'   - `subQuantity` (integer): Total sub-accounts.
        #'   - `spotSubQuantity` (integer): Spot sub-accounts.
        #'   - `maxSubQuantity` (integer): Max allowed sub-accounts.
        #'   - Full schema in implementation docs.
        #' ### JSON Response Example
        #' ```json
        #' {"code": "200000", "data": {"level": 3, "subQuantity": 5, "maxSubQuantity": 20}}
        #' ```
        get_account_summary_info = function() {
            return(get_account_summary_info_impl(self$keys, self$base_url))
        },

        #' Get API Key Information
        #'
        #' ### Description
        #' Retrieves detailed API key metadata asynchronously via a GET request to `/api/v1/user/api-key`.
        #' Calls `get_apikey_info_impl`.
        #'
        #' ### Workflow Overview
        #' 1. **Request**: Constructs authenticated GET request.
        #' 2. **Response**: Returns a `data.table` with key details and permissions.
        #'
        #' ### API Endpoint
        #' `GET https://api.kucoin.com/api/v1/user/api-key`
        #'
        #' ### Usage
        #' Utilised to inspect API key properties, aiding in security and permission audits.
        #'
        #' ### Official Documentation
        #' [KuCoin Get API Key Info](https://www.kucoin.com/docs-new/rest/account-info/account-funding/get-apikey-info)
        #'
        #' ### Automated Trading Usage
        #' - **Permission Sync**: Verify `permission` includes required scopes (e.g., "Spot") before bot operations, halting if insufficient.
        #' - **Security Audit**: Check `ipWhitelist` and `createdAt` to enforce IP restrictions or key rotation policies.
        #' - **Logging**: Log `uid` and `subName` to map API keys to accounts, ensuring traceability in multi-user systems.
        #'
        #' @return Promise resolving to a `data.table` with:
        #'   - `uid` (integer): Account UID.
        #'   - `apiKey` (character): API key string.
        #'   - `permission` (character): Permissions list.
        #'   - `createdAt` (integer): Creation time (ms).
        #'   - Full schema in implementation docs.
        #' ### JSON Response Example
        #' ```json
        #' {"code": "200000", "data": {"uid": 12345, "apiKey": "abc123", "permission": "General, Spot", "createdAt": 1733049198863}}
        #' ```
        get_apikey_info = function() {
            return(get_apikey_info_impl(self$keys, self$base_url))
        },

        #' Get Spot Account Type
        #'
        #' ### Description
        #' Determines if the spot account is high-frequency asynchronously via a GET request to `/api/v1/hf/accounts/opened`.
        #' Calls `get_spot_account_type_impl`.
        #'
        #' ### Workflow Overview
        #' 1. **Request**: Constructs authenticated GET request.
        #' 2. **Response**: Returns a logical indicating high-frequency status.
        #'
        #' ### API Endpoint
        #' `GET https://api.kucoin.com/api/v1/hf/accounts/opened`
        #'
        #' ### Usage
        #' Utilised to identify spot account type, affecting endpoint usage for trading operations.
        #'
        #' ### Official Documentation
        #' [KuCoin Get Account Type Spot](https://www.kucoin.com/docs-new/rest/account-info/account-funding/get-account-type-spot)
        #'
        #' ### Automated Trading Usage
        #' - **Endpoint Selection**: Use result to choose between high-frequency (HF) or low-frequency endpoints for orders and transfers.
        #' - **Performance Tuning**: Adjust polling frequency in your bot based on account type, optimizing for HF accounts.
        #' - **Initial Check**: Run at bot startup to configure workflows, logging the type for debugging.
        #'
        #' @return Promise resolving to a logical:
        #'   - `TRUE`: High-frequency spot account.
        #'   - `FALSE`: Low-frequency spot account.
        #' ### JSON Response Example
        #' ```json
        #' {"code": "200000", "data": true}
        #' ```
        get_spot_account_type = function() {
            return(get_spot_account_type_impl(self$keys, self$base_url))
        },

        #' Get Spot Account List
        #'
        #' ### Description
        #' Retrieves a list of all spot accounts asynchronously via a GET request to `/api/v1/accounts`.
        #' Calls `get_spot_account_list_impl`.
        #'
        #' ### Workflow Overview
        #' 1. **Query**: Applies optional filters from `query`.
        #' 2. **Request**: Constructs authenticated GET request.
        #' 3. **Response**: Returns a `data.table` of account details.
        #'
        #' ### API Endpoint
        #' `GET https://api.kucoin.com/api/v1/accounts`
        #'
        #' ### Usage
        #' Utilised to list spot accounts, filterable by currency or type, for financial monitoring.
        #'
        #' ### Official Documentation
        #' [KuCoin Get Account List Spot](https://www.kucoin.com/docs-new/rest/account-info/account-funding/get-account-list-spot)
        #'
        #' ### Automated Trading Usage
        #' - **Fund Allocation**: Filter by `type = "trade"` to monitor trading funds, reallocating via transfers if `available` is low.
        #' - **Currency Tracking**: Use `currency` filter to manage specific asset balances, integrating with market data.
        #' - **Real-Time Sync**: Poll periodically to update account states, caching IDs for detailed queries.
        #'
        #' @param query Named list; optional filters:
        #'   - `currency` (character): Currency code (e.g., "USDT").
        #'   - `type` (character): Account type ("main", "trade").
        #' @return Promise resolving to a `data.table` with:
        #'   - `id` (character): Account ID.
        #'   - `currency` (character): Currency code.
        #'   - `type` (character): Account type.
        #'   - `balance` (numeric): Total funds.
        #'   - `available` (numeric): Available funds.
        #'   - `holds` (numeric): Funds on hold.
        #' ### JSON Response Example
        #' ```json
        #' {"code": "200000", "data": [{"id": "123", "currency": "USDT", "type": "trade", "balance": "1000", "available": "900", "holds": "100"}]}
        #' ```
        get_spot_account_list = function(query = list()) {
            return(get_spot_account_list_impl(self$keys, self$base_url, query))
        },

        #' Get Spot Account Detail
        #'
        #' ### Description
        #' Retrieves detailed financial metrics for a specific spot account asynchronously via a GET request to `/api/v1/accounts/{accountId}`.
        #' Calls `get_spot_account_detail_impl`.
        #'
        #' ### Workflow Overview
        #' 1. **Request**: Constructs authenticated GET request with `accountId`.
        #' 2. **Response**: Returns a `data.table` with account metrics.
        #'
        #' ### API Endpoint
        #' `GET https://api.kucoin.com/api/v1/accounts/{accountId}`
        #'
        #' ### Usage
        #' Utilised to inspect a specific spot account’s financial status using an ID from `get_spot_account_list`.
        #'
        #' ### Official Documentation
        #' [KuCoin Get Account Detail Spot](https://www.kucoin.com/docs-new/rest/account-info/account-funding/get-account-detail-spot)
        #'
        #' ### Automated Trading Usage
        #' - **Balance Monitoring**: Check `available` vs. `holds` to manage trading liquidity, triggering transfers if needed.
        #' - **Account Drill-Down**: Use after `get_spot_account_list` to focus on high-value accounts, logging discrepancies.
        #' - **Risk Assessment**: Monitor `holds` to detect pending orders or freezes, adjusting risk parameters.
        #'
        #' @param accountId Character string; unique account ID (e.g., from `get_spot_account_list`). Required.
        #' @return Promise resolving to a `data.table` with:
        #'   - `currency` (character): Currency code.
        #'   - `balance` (numeric): Total funds.
        #'   - `available` (numeric): Available funds.
        #'   - `holds` (numeric): Funds on hold.
        #' ### JSON Response Example
        #' ```json
        #' {"code": "200000", "data": {"currency": "USDT", "balance": "1000", "available": "900", "holds": "100"}}
        #' ```
        get_spot_account_detail = function(accountId) {
            return(get_spot_account_detail_impl(self$keys, self$base_url, accountId))
        },

        #' Get Cross Margin Account
        #'
        #' ### Description
        #' Retrieves cross margin account details asynchronously via a GET request to `/api/v3/margin/accounts`.
        #' Calls `get_cross_margin_account_impl`.
        #'
        #' ### Workflow Overview
        #' 1. **Query**: Applies optional filters from `query`.
        #' 2. **Request**: Constructs authenticated GET request.
        #' 3. **Response**: Returns a list with `summary` and `accounts` `data.table`s.
        #'
        #' ### API Endpoint
        #' `GET https://api.kucoin.com/api/v3/margin/accounts`
        #'
        #' ### Usage
        #' Utilised to monitor cross margin account status, including total assets and per-currency details.
        #'
        #' ### Official Documentation
        #' [KuCoin Get Account Cross Margin](https://www.kucoin.com/docs-new/rest/account-info/account-funding/get-account-cross-margin)
        #'
        #' ### Automated Trading Usage
        #' - **Risk Management**: Track `debtRatio` in `summary` to adjust leverage, halting trades if risk exceeds thresholds.
        #' - **Fund Allocation**: Monitor `available` in `accounts` to optimize margin usage across currencies.
        #' - **Currency Filter**: Use `query$quoteCurrency` to focus on primary trading assets (e.g., "USDT"), syncing with market conditions.
        #'
        #' @param query Named list; optional filters:
        #'   - `quoteCurrency` (character): Quote currency (e.g., "USDT", default "USDT").
        #'   - `queryType` (character): Account type ("MARGIN", "MARGIN_V2", "ALL", default "MARGIN").
        #' @return Promise resolving to a list with:
        #'   - `summary`: `data.table`:
        #'     - `totalAssetOfQuoteCurrency` (character): Total assets.
        #'     - `debtRatio` (character): Debt ratio.
        #'   - `accounts`: `data.table`:
        #'     - `currency` (character): Currency code.
        #'     - `total` (character): Total funds.
        #'     - `available` (character): Available funds.
        #'     - Full schema in implementation docs.
        #' ### JSON Response Example
        #' ```json
        #' {"code": "200000", "data": {"totalAssetOfQuoteCurrency": "1000", "accounts": [{"currency": "USDT", "total": "500"}]}}
        #' ```
        get_cross_margin_account = function(query = list()) {
            return(get_cross_margin_account_impl(self$keys, self$base_url, query))
        },

        #' Get Isolated Margin Account
        #'
        #' ### Description
        #' Retrieves isolated margin account details asynchronously via a GET request to `/api/v3/isolated/accounts`.
        #' Calls `get_isolated_margin_account_impl`.
        #'
        #' ### Workflow Overview
        #' 1. **Query**: Applies optional filters from `query`.
        #' 2. **Request**: Constructs authenticated GET request.
        #' 3. **Response**: Returns a list with `summary` and `assets` `data.table`s.
        #'
        #' ### API Endpoint
        #' `GET https://api.kucoin.com/api/v3/isolated/accounts`
        #'
        #' ### Usage
        #' Utilised to monitor isolated margin accounts per trading pair, detailing assets and liabilities.
        #'
        #' ### Official Documentation
        #' [KuCoin Get Account Isolated Margin](https://www.kucoin.com/docs-new/rest/account-info/account-funding/get-account-isolated-margin)
        #'
        #' ### Automated Trading Usage
        #' - **Pair-Specific Risk**: Monitor `debtRatio` per `symbol` in `assets` to manage isolated leverage, adjusting positions dynamically.
        #' - **Liquidity Check**: Use `base_available` and `quote_available` to ensure sufficient margin, triggering fund transfers if low.
        #' - **Time-Based Sync**: Leverage `datetime` in `summary` to validate data freshness, polling hourly for critical pairs.
        #'
        #' @param query Named list; optional filters:
        #'   - `symbol` (character): Trading pair (e.g., "BTC-USDT").
        #'   - `quoteCurrency` (character): Quote currency (e.g., "USDT", default "USDT").
        #'   - `queryType` (character): Type ("ISOLATED", "ISOLATED_V2", "ALL", default "ISOLATED").
        #' @return Promise resolving to a list with:
        #'   - `summary`: `data.table`:
        #'     - `totalAssetOfQuoteCurrency` (character): Total assets.
        #'     - `datetime` (POSIXct): Snapshot time.
        #'   - `assets`: `data.table`:
        #'     - `symbol` (character): Trading pair.
        #'     - `base_total` (character): Base total funds.
        #'     - `quote_liability` (character): Quote liability.
        #'     - Full schema in implementation docs.
        #' ### JSON Response Example
        #' ```json
        #' {"code": "200000", "data": {"totalAssetOfQuoteCurrency": "1000", "assets": [{"symbol": "BTC-USDT", "base_total": "0.1"}]}}
        #' ```
        get_isolated_margin_account = function(query = list()) {
            return(get_isolated_margin_account_impl(self$keys, self$base_url, query))
        },

        #' Get Spot Ledger
        #'
        #' ### Description
        #' Retrieves paginated ledger records for spot and margin accounts asynchronously via a GET request to `/api/v1/accounts/ledgers`.
        #' Calls `get_spot_ledger_impl`.
        #'
        #' ### Workflow Overview
        #' 1. **Query**: Applies filters and pagination from `query`, `page_size`, and `max_pages`.
        #' 2. **Request**: Constructs authenticated GET request with pagination.
        #' 3. **Response**: Returns a `data.table` of transaction history.
        #'
        #' ### API Endpoint
        #' `GET https://api.kucoin.com/api/v1/accounts/ledgers`
        #'
        #' ### Usage
        #' Utilised to track transaction histories for spot and margin accounts, filterable by various criteria.
        #'
        #' ### Official Documentation
        #' [KuCoin Get Account Ledgers Spot Margin](https://www.kucoin.com/docs-new/rest/account-info/account-funding/get-account-ledgers-spot-margin)
        #'
        #' ### Automated Trading Usage
        #' - **Transaction Audit**: Filter by `bizType = "TRANSFER"` to reconcile internal movements, logging `amount` and `createdAtDatetime`.
        #' - **Fee Analysis**: Sum `fee` over time ranges to optimize trading costs, adjusting strategies accordingly.
        #' - **Event Monitoring**: Use `direction` and `context` to detect deposits/withdrawals, triggering fund allocation or alerts.
        #'
        #' @param query Named list; optional filters:
        #'   - `currency` (character): Currency code (up to 10).
        #'   - `direction` (character): "in" or "out".
        #'   - `bizType` (character): Business type (e.g., "DEPOSIT").
        #'   - `startAt` (integer): Start time (ms).
        #'   - `endAt` (integer): End time (ms).
        #' @param page_size Integer; results per page (10-500, default 50).
        #' @param max_pages Numeric; max pages to fetch (default `Inf`).
        #' @return Promise resolving to a `data.table` with:
        #'   - `id` (character): Ledger ID.
        #'   - `currency` (character): Currency code.
        #'   - `amount` (character): Transaction amount.
        #'   - `createdAtDatetime` (POSIXct): Transaction time.
        #'   - Full schema in implementation docs.
        #' ### JSON Response Example
        #' ```json
        #' {"code": "200000", "data": {"items": [{"id": "xyz", "currency": "BTC", "amount": "0.1", "createdAt": 1733049198863}]}}
        #' ```
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
