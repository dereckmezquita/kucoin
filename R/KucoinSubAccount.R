# File: ./R/KucoinSubAccount.R

# box::use(
#     ./impl_account_sub_account[
#         add_subaccount_impl,
#         get_subaccount_list_summary_impl,
#         get_subaccount_detail_balance_impl,
#         get_subaccount_spot_v2_impl
#     ],
#     ./utils[get_api_keys, get_base_url]
# )

#' KucoinSubAccount Class for KuCoin Sub-Account Management
#'
#' The `KucoinSubAccount` class provides an asynchronous interface for managing sub-accounts under a KuCoin master account.
#' It leverages the `coro` package for non-blocking HTTP requests, returning promises that resolve to `data.table` objects.
#' This class supports creating sub-accounts, retrieving summaries and detailed balance information for all sub-accounts,
#' and fetching comprehensive Spot sub-account balance details across account types.
#'
#' ### Purpose and Scope
#' This class is designed to facilitate sub-account administration within the KuCoin ecosystem, including:
#' - **Sub-Account Creation**: Adding new sub-accounts with specific permissions.
#' - **Summary Overview**: Listing all sub-accounts with basic details.
#' - **Balance Details**: Retrieving financial metrics for individual or all sub-accounts.
#'
#' ### Usage
#' Utilised by traders and developers to programmatically manage KuCoin sub-accounts. The class is initialized with API
#' credentials, sourced from `get_api_keys()` if not provided, and a base URL from `get_base_url()`. All methods require
#' authentication as they operate under the master account’s privileges. For detailed endpoint information, parameters,
#' and response schemas, refer to the official [KuCoin API Documentation](https://www.kucoin.com/docs-new).
#'
#' ### Official Documentation
#' [KuCoin API Documentation - Sub-Account](https://www.kucoin.com/docs-new/rest/account-info/sub-account/introduction)
#'
#' @section Methods:
#' - **initialize(keys, base_url):** Initialises the object with API credentials and base URL.
#' - **add_subaccount(password, subName, access, remarks):** Creates a new sub-account.
#' - **get_subaccount_list_summary(page_size, max_pages):** Retrieves a paginated summary of all sub-accounts.
#' - **get_subaccount_detail_balance(subUserId, includeBaseAmount):** Fetches detailed balance for a specific sub-account.
#' - **get_subaccount_spot_v2(page_size, max_pages):** Retrieves Spot sub-account balance details for all sub-accounts.
#'
#' @examples
#' \dontrun{
#' # Comprehensive example demonstrating key methods
#' main_async <- coro::async(function() {
#'   # Initialise the class
#'   sub_acc <- KucoinSubAccount$new()
#'
#'   # Add a new sub-account
#'   new_sub <- await(sub_acc$add_subaccount(
#'     password = "SecurePass123",
#'     subName = "TradingSub1",
#'     access = "Spot",
#'     remarks = "Spot trading sub-account"
#'   ))
#'   print("New Sub-Account:"); print(new_sub)
#'
#'   # Get sub-account summary
#'   summary <- await(sub_acc$get_subaccount_list_summary(page_size = 10, max_pages = 1))
#'   print("Sub-Account Summary:"); print(summary)
#'
#'   # Get balance for the new sub-account (if created)
#'   if (nrow(summary) > 0) {
#'     sub_id <- summary[1, uid]
#'     balance <- await(sub_acc$get_subaccount_detail_balance(sub_id, includeBaseAmount = TRUE))
#'     print("Sub-Account Balance:"); print(balance)
#'   }
#'
#'   # Get Spot sub-account balances
#'   spot_balances <- await(sub_acc$get_subaccount_spot_v2(page_size = 20, max_pages = 2))
#'   print("Spot Sub-Account Balances:"); print(spot_balances)
#' })
#' main_async()
#' while (!later::loop_empty()) later::run_now()
#' }
#'
#' @importFrom R6 R6Class
#' @export
KucoinSubAccount <- R6::R6Class(
    "KucoinSubAccount",
    public = list(
        #' @field keys List containing KuCoin API keys (`api_key`, `api_secret`, `api_passphrase`, `key_version`).
        keys = NULL,
        #' @field base_url Character string representing the base URL for KuCoin API endpoints.
        base_url = NULL,

        #' Initialise a New KucoinSubAccount Object
        #'
        #' ### Description
        #' Initialises a `KucoinSubAccount` object with API credentials and a base URL for managing sub-accounts
        #' asynchronously. All operations require authentication under the master account’s privileges.
        #'
        #' ### Workflow Overview
        #' 1. **Credential Assignment**: Sets `self$keys` to the provided or default API keys from `get_api_keys()`.
        #' 2. **URL Assignment**: Sets `self$base_url` to the provided or default base URL from `get_base_url()`.
        #'
        #' ### API Endpoint
        #' Not applicable (initialisation method).
        #'
        #' ### Usage
        #' Creates an instance for sub-account management, enabling creation, summary retrieval, and balance queries.
        #'
        #' ### Official Documentation
        #' [KuCoin API Authentication](https://www.kucoin.com/docs-new/rest/introduction#authentication)
        #'
        #' ### Automated Trading Usage
        #' - **Sub-Account Hub**: Use as the central object for sub-account operations in your bot, managing trading silos.
        #' - **Secure Setup**: Provide explicit `keys` or use `get_api_keys()` from a secure vault for production-grade security.
        #' - **Scalability**: Instantiate once and reuse across sessions, integrating with account and funding classes for comprehensive oversight.
        #'
        #' @param keys List containing API configuration parameters from `get_api_keys()`, including:
        #'   - `api_key`: Character string; your KuCoin API key.
        #'   - `api_secret`: Character string; your KuCoin API secret.
        #'   - `api_passphrase`: Character string; your KuCoin API passphrase.
        #'   - `key_version`: Character string; API key version (e.g., `"2"`).
        #'   Defaults to `get_api_keys()`.
        #' @param base_url Character string representing the base URL for the API. Defaults to `get_base_url()`.
        #'
        #' @return A new instance of the `KucoinSubAccount` class.
        initialize = function(keys = get_api_keys(), base_url = get_base_url()) {
            self$keys <- keys
            self$base_url <- base_url
        },

        #' Add Sub-Account
        #'
        #' ### Description
        #' Creates a new sub-account under the master account asynchronously via a POST request to `/api/v2/sub/user/created`.
        #' Calls `add_subaccount_impl`.
        #'
        #' ### Workflow Overview
        #' 1. **Validation**: Ensures parameters meet API constraints within the implementation.
        #' 2. **Request Body**: Constructs JSON with `password`, `subName`, `access`, and optional `remarks`.
        #' 3. **Authentication**: Generates headers with API keys.
        #' 4. **API Call**: Sends POST request.
        #' 5. **Response**: Returns sub-account details as a `data.table`.
        #'
        #' ### API Endpoint
        #' `POST https://api.kucoin.com/api/v2/sub/user/created`
        #'
        #' ### Usage
        #' Utilised to create sub-accounts with specific permissions for segregated trading or management purposes.
        #'
        #' ### Official Documentation
        #' [KuCoin Add Sub-Account](https://www.kucoin.com/docs-new/rest/account-info/sub-account/add-subaccount)
        #'
        #' ### Automated Trading Usage
        #' - **Account Segregation**: Create sub-accounts with `access = "Spot"` for isolated trading strategies, assigning unique `subName`s for tracking.
        #' - **Security**: Use strong, unique `password`s generated programmatically, storing securely with `remarks` for audit trails.
        #' - **Post-Creation**: Follow with `get_subaccount_list_summary` to verify creation and retrieve `uid` for further operations.
        #'
        #' @param password Character string; sub-account password (7-24 characters, must include letters and numbers). Required.
        #' @param subName Character string; sub-account name (7-32 characters, must include a letter and number, no spaces). Required.
        #' @param access Character string; permission type ("Spot", "Futures", "Margin"). Required.
        #' @param remarks Character string; optional remarks (1-24 characters if provided).
        #' @return Promise resolving to a `data.table` with:
        #'   - `uid` (integer): Sub-account ID.
        #'   - `subName` (character): Sub-account name.
        #'   - `remarks` (character): Remarks (if provided).
        #'   - `access` (character): Permission type.
        #' ### JSON Response Example
        #' ```json
        #' {"code": "200000", "data": {"uid": 169579801, "subName": "TestSub123", "remarks": "Test", "access": "Spot"}}
        #' ```
        add_subaccount = function(password, subName, access, remarks = NULL) {
            return(add_subaccount_impl(
                keys = self$keys,
                base_url = self$base_url,
                password = password,
                subName = subName,
                access = access,
                remarks = remarks
            ))
        },

        #' Get Sub-Account List Summary
        #'
        #' ### Description
        #' Retrieves a paginated summary of all sub-accounts asynchronously via a GET request to `/api/v2/sub/user`.
        #' Calls `get_subaccount_list_summary_impl`.
        #'
        #' ### Workflow Overview
        #' 1. **Pagination**: Fetches pages with `page_size` up to `max_pages`.
        #' 2. **Request**: Constructs authenticated GET request.
        #' 3. **Response**: Aggregates results into a `data.table` with datetime conversion.
        #'
        #' ### API Endpoint
        #' `GET https://api.kucoin.com/api/v2/sub/user`
        #'
        #' ### Usage
        #' Utilised to obtain an overview of all sub-accounts, including creation details and permissions.
        #'
        #' ### Official Documentation
        #' [KuCoin Get Sub-Account List Summary Info](https://www.kucoin.com/docs-new/rest/account-info/sub-account/get-subaccount-list-summary-info)
        #'
        #' ### Automated Trading Usage
        #' - **Inventory Management**: Fetch periodically to maintain an updated sub-account list, using `uid` for balance queries.
        #' - **Permission Audit**: Check `access` to ensure sub-accounts align with intended trading scopes, alerting on mismatches.
        #' - **Creation Tracking**: Use `createdDatetime` to monitor sub-account age, flagging old accounts for review or cleanup.
        #'
        #' @param page_size Integer; results per page (1-100, default 100).
        #' @param max_pages Numeric; max pages to fetch (default `Inf`).
        #' @return Promise resolving to a `data.table` with:
        #'   - `uid` (integer): Sub-account ID.
        #'   - `subName` (character): Sub-account name.
        #'   - `access` (character): Permission type.
        #'   - `createdDatetime` (POSIXct): Creation time.
        #'   - Full schema in implementation docs.
        #' ### JSON Response Example
        #' ```json
        #' {"code": "200000", "data": {"items": [{"uid": 169579801, "subName": "TestSub123", "access": "Spot", "createdAt": 1668562696000}]}}
        #' ```
        get_subaccount_list_summary = function(page_size = 100, max_pages = Inf) {
            return(get_subaccount_list_summary_impl(self$keys, self$base_url, page_size, max_pages))
        },

        #' Get Sub-Account Detail Balance
        #'
        #' ### Description
        #' Retrieves detailed balance information for a specific sub-account asynchronously via a GET request to `/api/v1/sub-accounts/{subUserId}`.
        #' Calls `get_subaccount_detail_balance_impl`.
        #'
        #' ### Workflow Overview
        #' 1. **Request**: Constructs authenticated GET request with `subUserId` and `includeBaseAmount`.
        #' 2. **Response**: Aggregates balances across account types into a `data.table`.
        #'
        #' ### API Endpoint
        #' `GET https://api.kucoin.com/api/v1/sub-accounts/{subUserId}?includeBaseAmount={includeBaseAmount}`
        #'
        #' ### Usage
        #' Utilised to monitor financial details for a specific sub-account across various account types.
        #'
        #' ### Official Documentation
        #' [KuCoin Get Sub-Account Detail Balance](https://www.kucoin.com/docs-new/rest/account-info/sub-account/get-subaccount-detail-balance)
        #'
        #' ### Automated Trading Usage
        #' - **Fund Monitoring**: Check `available` per `accountType` to manage sub-account liquidity, triggering transfers if low.
        #' - **Zero Balance Inclusion**: Set `includeBaseAmount = TRUE` to audit unused currencies, initializing them as needed.
        #' - **Sub-Account Focus**: Use `subUserId` from `get_subaccount_list_summary` to drill down into critical accounts, logging balances.
        #'
        #' @param subUserId Character string; sub-account user ID (e.g., from `get_subaccount_list_summary`). Required.
        #' @param includeBaseAmount Logical; include zero-balance currencies (default `FALSE`).
        #' @return Promise resolving to a `data.table` with:
        #'   - `subUserId` (character): Sub-account ID.
        #'   - `subName` (character): Sub-account name.
        #'   - `accountType` (character): Account type (e.g., "mainAccounts").
        #'   - `currency` (character): Currency code.
        #'   - `balance` (numeric): Total balance.
        #'   - Full schema in implementation docs.
        #' ### JSON Response Example
        #' ```json
        #' {"code": "200000", "data": {"subUserId": "123", "subName": "TestSub", "mainAccounts": [{"currency": "USDT", "balance": "0.01"}]}}
        #' ```
        get_subaccount_detail_balance = function(subUserId, includeBaseAmount = FALSE) {
            return(get_subaccount_detail_balance_impl(self$keys, self$base_url, subUserId, includeBaseAmount))
        },

        #' Get Spot Sub-Account List (V2)
        #'
        #' ### Description
        #' Retrieves paginated Spot sub-account balance details for all sub-accounts asynchronously via a GET request to `/api/v2/sub-accounts`.
        #' Calls `get_subaccount_spot_v2_impl`.
        #'
        #' ### Workflow Overview
        #' 1. **Pagination**: Fetches pages with `page_size` up to `max_pages`.
        #' 2. **Request**: Constructs authenticated GET request.
        #' 3. **Response**: Aggregates balances across account types into a `data.table`.
        #'
        #' ### API Endpoint
        #' `GET https://api.kucoin.com/api/v2/sub-accounts`
        #'
        #' ### Usage
        #' Utilised to obtain a comprehensive view of Spot sub-account balances across all sub-accounts.
        #'
        #' ### Official Documentation
        #' [KuCoin Get Sub-Account List - Spot Balance (V2)](https://www.kucoin.com/docs-new/rest/account-info/sub-account/get-subaccount-list-spot-balance-v2)
        #'
        #' ### Automated Trading Usage
        #' - **Portfolio Overview**: Aggregate `balance` across `subUserId` and `accountType` to monitor total sub-account funds, reallocating as needed.
        #' - **Risk Assessment**: Filter by `holds` to identify locked funds, adjusting trading limits per sub-account.
        #' - **Batch Processing**: Use with small `page_size` for frequent updates, caching results to reduce API load.
        #'
        #' @param page_size Integer; results per page (10-100, default 100).
        #' @param max_pages Numeric; max pages to fetch (default `Inf`).
        #' @return Promise resolving to a `data.table` with:
        #'   - `subUserId` (character): Sub-account ID.
        #'   - `subName` (character): Sub-account name.
        #'   - `accountType` (character): Account type (e.g., "tradeAccounts").
        #'   - `currency` (character): Currency code.
        #'   - `balance` (numeric): Total balance.
        #'   - Full schema in implementation docs.
        #' ### JSON Response Example
        #' ```json
        #' {"code": "200000", "data": {"items": [{"subUserId": "123", "subName": "TestSub", "tradeAccounts": [{"currency": "USDT", "balance": "0.01"}]}]}}
        #' ```
        get_subaccount_spot_v2 = function(page_size = 100, max_pages = Inf) {
            return(get_subaccount_spot_v2_impl(self$keys, self$base_url, page_size, max_pages))
        }
    )
)
