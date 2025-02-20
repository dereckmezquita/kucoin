# File: ./R/KucoinSubAccount.R

# box::use(
#     impl = ./impl_account_sub_account,
#     ./utils[ get_api_keys, get_base_url ]
# )

#' KucoinSubAccount Class for KuCoin Sub-Account Endpoints
#'
#' The `KucoinSubAccount` class provides an asynchronous interface for managing sub-accounts under a KuCoin master account.
#' It leverages the `coro` package for non-blocking HTTP requests, returning promises that typically resolve to `data.table`
#' objects. This class supports creating new sub-accounts, retrieving summary information for all sub-accounts, and fetching
#' detailed balance data for specific sub-accounts.
#'
#' ### Workflow Overview
#' Not applicable (class definition overview).
#'
#' ### API Endpoint
#' Not applicable (class-level documentation; see individual methods).
#'
#' ### Usage
#' Utilised by users to manage KuCoin sub-accounts programmatically. The class is initialised with API credentials,
#' automatically loaded via `get_api_keys()` if not provided, and a base URL from `get_base_url()`. For detailed endpoint
#' information and response schemas, refer to the official [KuCoin API Documentation](https://www.kucoin.com/docs-new).
#'
#' ### Official Documentation
#' [KuCoin API Documentation](https://www.kucoin.com/docs-new)
#'
#' @section Methods:
#' - **initialize(keys, base_url):** Initialises the object with API credentials and the base URL.
#' - **add_subaccount(password, subName, access, remarks):** Creates a new sub-account under the master account.
#' - **get_subaccount_list_summary(page_size, max_pages):** Retrieves a paginated summary of all sub-accounts.
#' - **get_subaccount_detail_balance(subUserId, includeBaseAmount):** Retrieves detailed balance information for a specific sub-account.
#'
#' @return Not applicable (class definition; see individual methods for return values).
#'
#' @examples
#' \dontrun{
#' # Comprehensive example demonstrating all methods
#' main_async <- coro::async(function() {
#'   # Initialise the class
#'   sub_acc <- KucoinSubAccount$new()
#'
#'   # Add a new sub-account
#'   new_sub <- await(sub_acc$add_subaccount(
#'     password = "TestPass123",
#'     subName = "TestSub123",
#'     access = "Spot",
#'     remarks = "Test sub-account"
#'   ))
#'   print("New Sub-Account:")
#'   print(new_sub)
#'
#'   # Get summary of all sub-accounts
#'   summary <- await(sub_acc$get_subaccount_list_summary(page_size = 50, max_pages = 2))
#'   print("Sub-Account Summary:")
#'   print(summary)
#'
#'   # Get balance details for the first sub-account (if any)
#'   if (nrow(summary) > 0) {
#'     sub_id <- summary[1, uid]
#'     balance <- await(sub_acc$get_subaccount_detail_balance(sub_id, includeBaseAmount = TRUE))
#'     print("Sub-Account Balance:")
#'     print(balance)
#'   }
#' 
#'   # Get Spot sub-account list (V2)
#'   spot_accounts <- await(sub_acc$get_subaccount_spot_v2(page_size = 50, max_pages = 2))
#'   print("Spot Sub-Accounts (V2):")
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
        #' Initialises a `KucoinSubAccount` object with API credentials and a base URL for managing KuCoin sub-accounts asynchronously.
        #' If not provided, credentials are sourced from `get_api_keys()` and the base URL from `get_base_url()`.
        #'
        #' ### Workflow Overview
        #' 1. **Credential Assignment**: Sets `self$keys` to the provided or default API keys.
        #' 2. **URL Assignment**: Sets `self$base_url` to the provided or default base URL.
        #'
        #' ### API Endpoint
        #' Not applicable (initialisation method).
        #'
        #' ### Usage
        #' Utilised to create an instance of the class with authentication details for sub-account management.
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
        #' @return A new instance of the `KucoinSubAccount` class.
        initialize = function(keys = get_api_keys(), base_url = get_base_url()) {
            self$keys <- keys
            self$base_url <- base_url
        },

        #' Add Sub-Account
        #'
        #' ### Description
        #' Creates a new sub-account under the master account asynchronously by sending a POST request to the KuCoin API.
        #' This method constructs a JSON request body, generates authentication headers, and processes the response into a `data.table`.
        #' It calls `add_subaccount_impl`.
        #'
        #' ### Workflow Overview
        #' 1. **URL Construction**: Combines the base URL with `/api/v2/sub/user/created`.
        #' 2. **Request Body Preparation**: Builds a list with `password`, `subName`, `access`, and optional `remarks`, converted to JSON.
        #' 3. **Header Preparation**: Generates authentication headers asynchronously using `build_headers()`.
        #' 4. **API Request**: Sends a POST request with a 3-second timeout via `httr::POST()`.
        #' 5. **Response Processing**: Validates the response and converts the `"data"` field into a `data.table`.
        #'
        #' ### API Endpoint
        #' `POST https://api.kucoin.com/api/v2/sub/user/created`
        #'
        #' ### Usage
        #' Utilised by users to create sub-accounts for managing separate trading permissions within the KuCoin ecosystem.
        #'
        #' ### Official Documentation
        #' [KuCoin Add Sub-Account](https://www.kucoin.com/docs-new/rest/account-info/sub-account/add-subaccount)
        #'
        #' @param password Character string; sub-account password (7–24 characters, must contain letters and numbers).
        #' @param subName Character string; sub-account name (7–32 characters, must include one letter and one number, no spaces).
        #' @param access Character string; permission type (`"Spot"`, `"Futures"`, `"Margin"`).
        #' @param remarks Character string (optional); remarks about the sub-account (1–24 characters if provided).
        #'
        #' @return Promise resolving to a `data.table` containing:
        #'   - `uid` (integer): Unique sub-account identifier.
        #'   - `subName` (character): Sub-account name.
        #'   - `remarks` (character): Provided remarks or notes.
        #'   - `access` (character): Permission type granted.
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

        #' Get Sub-Account List Summary (Paginated)
        #'
        #' ### Description
        #' Retrieves a paginated summary of all sub-accounts associated with the master account asynchronously, aggregating results into a `data.table`.
        #' This method converts `createdAt` timestamps to POSIXct and calls `get_subaccount_list_summary_impl`.
        #'
        #' ### Workflow Overview
        #' 1. **Pagination Initialisation**: Sets an initial query with `currentPage = 1` and specified `page_size`.
        #' 2. **Page Fetching**: Defines an async helper to fetch each page with authentication headers.
        #' 3. **Automatic Pagination**: Uses `auto_paginate` to fetch all pages up to `max_pages`.
        #' 4. **Aggregation**: Combines results into a `data.table`, converting `createdAt` to `createdDatetime`.
        #'
        #' ### API Endpoint
        #' `GET https://api.kucoin.com/api/v2/sub/user`
        #'
        #' ### Usage
        #' Utilised by users to obtain a comprehensive overview of all sub-accounts, including creation details and permissions.
        #'
        #' ### Official Documentation
        #' [KuCoin Get Sub-Account List Summary Info](https://www.kucoin.com/docs-new/rest/account-info/sub-account/get-subaccount-list-summary-info)
        #'
        #' @param page_size Integer; number of results per page (1–100, default 100).
        #' @param max_pages Numeric; maximum number of pages to fetch (default `Inf` for all pages).
        #'
        #' @return Promise resolving to a `data.table` containing:
        #'   - `currentPage` (integer): Current page number.
        #'   - `pageSize` (integer): Results per page.
        #'   - `totalNum` (integer): Total sub-accounts.
        #'   - `totalPage` (integer): Total pages.
        #'   - `userId` (character): Master account identifier.
        #'   - `uid` (integer): Sub-account identifier.
        #'   - `subName` (character): Sub-account name.
        #'   - `status` (integer): Sub-account status.
        #'   - `type` (integer): Sub-account type.
        #'   - `access` (character): Permission type (e.g., `"All"`, `"Spot"`).
        #'   - `createdAt` (integer): Creation timestamp in milliseconds.
        #'   - `createdDatetime` (POSIXct): Converted creation datetime.
        #'   - `remarks` (character): Sub-account remarks.
        get_subaccount_list_summary = function(page_size = 100, max_pages = Inf) {
            return(get_subaccount_list_summary_impl(self$keys, self$base_url, page_size, max_pages))
        },

        #' Get Sub-Account Detail - Balance
        #'
        #' ### Description
        #' Retrieves detailed balance information for a specific sub-account identified by `subUserId` asynchronously.
        #' This method aggregates balances across account types into a `data.table` and calls `get_subaccount_detail_balance_impl`.
        #' Use `get_subaccount_list_summary()` to obtain `subUserId`.
        #'
        #' ### Workflow Overview
        #' 1. **URL Construction**: Combines the base URL with `/api/v1/sub-accounts/{subUserId}` and a query string for `includeBaseAmount`.
        #' 2. **Header Preparation**: Generates authentication headers using `build_headers()`.
        #' 3. **API Request**: Sends a GET request with a 3-second timeout via `httr::GET()`.
        #' 4. **Response Processing**: Aggregates non-empty account type arrays (`mainAccounts`, etc.) into a `data.table`, adding `accountType`, `subUserId`, and `subName`.
        #'
        #' ### API Endpoint
        #' `GET https://api.kucoin.com/api/v1/sub-accounts/{subUserId}?includeBaseAmount={includeBaseAmount}`
        #'
        #' ### Usage
        #' Utilised by users to monitor detailed balances across various account types for a specific sub-account.
        #'
        #' ### Official Documentation
        #' [KuCoin Get Sub-Account Detail Balance](https://www.kucoin.com/docs-new/rest/account-info/sub-account/get-subaccount-detail-balance)
        #'
        #' @param subUserId Character string; sub-account user ID (e.g., from `get_subaccount_list_summary()`).
        #' @param includeBaseAmount Logical; whether to include currencies with zero balance (default `FALSE`).
        #'
        #' @return Promise resolving to a `data.table` containing:
        #'   - `currency` (character): Currency code.
        #'   - `balance` (character): Total balance.
        #'   - `available` (character): Available amount.
        #'   - `holds` (character): Locked amount.
        #'   - `accountType` (character): Source type (e.g., `"mainAccounts"`, `"tradeAccounts"`).
        #'   - `subUserId` (character): Sub-account user ID.
        #'   - `subName` (character): Sub-account name.
        #'   Additional fields like `baseCurrency`, `baseAmount` may be present.
        get_subaccount_detail_balance = function(subUserId, includeBaseAmount = FALSE) {
            return(get_subaccount_detail_balance_impl(self$keys, self$base_url, subUserId, includeBaseAmount))
        },

        #' Get Spot Sub-Account List - Balance Details (V2)
        #'
        #' ### Description
        #' Retrieves paginated Spot sub-account balance information for all sub-accounts associated with the master account asynchronously,
        #' aggregating results into a `data.table`. This method fetches data from the KuCoin API endpoint `/api/v2/sub-accounts`, processes
        #' balance details across account types (`mainAccounts`, `tradeAccounts`, `marginAccounts`, `tradeHFAccounts`), and combines them
        #' into a single table. It calls `get_subaccount_spot_v2_impl`.
        #'
        #' ### Workflow Overview
        #' 1. **Pagination Initialisation**: Sets an initial query with `currentPage = 1` and the specified `page_size`.
        #' 2. **Page Fetching**: Defines an asynchronous helper to fetch each page, constructing the URL with query parameters and authentication headers.
        #' 3. **Automatic Pagination**: Uses `auto_paginate` to fetch all pages up to `max_pages`, flattening items into a single list.
        #' 4. **Balance Aggregation**: Processes each sub-account’s account type arrays, converting non-empty arrays into `data.table`s with an `accountType` column,
        #'    and aggregates them with `subUserId` and `subName`.
        #' 5. **Type Casting**: Converts balance-related fields to numeric types for consistency.
        #'
        #' ### API Endpoint
        #' `GET https://api.kucoin.com/api/v2/sub-accounts`
        #'
        #' ### Usage
        #' Utilised by users to obtain a comprehensive view of Spot sub-account balances across all sub-accounts under the master account. This method is ideal
        #' for monitoring aggregated balance details without needing to query individual sub-accounts separately.
        #'
        #' ### Official Documentation
        #' [KuCoin Get Sub-Account List - Spot Balance (V2)](https://www.kucoin.com/docs-new/rest/account-info/sub-account/get-subaccount-list-spot-balance-v2)
        #'
        #' @param page_size Integer; number of sub-accounts per page (10–100, default 100). The KuCoin API enforces a minimum of 10 and a maximum of 100.
        #' @param max_pages Numeric; maximum number of pages to fetch (default `Inf` for all pages). Use a finite value to limit the number of API requests.
        #'
        #' @return Promise resolving to a `data.table` containing aggregated sub-account balance information, with columns:
        #'   - `subUserId` (character): Sub-account user ID.
        #'   - `subName` (character): Sub-account name.
        #'   - `accountType` (character): Type of account (e.g., `"mainAccounts"`, `"tradeAccounts"`, `"marginAccounts"`, `"tradeHFAccounts"`).
        #'   - `currency` (character): Currency code (e.g., `"USDT"`).
        #'   - `balance` (numeric): Total balance in the currency.
        #'   - `available` (numeric): Amount available for trading or withdrawal.
        #'   - `holds` (numeric): Amount locked or held.
        #'   - `baseCurrency` (character): Base currency code (e.g., `"BTC"`).
        #'   - `baseCurrencyPrice` (numeric): Price of the base currency at the time of the snapshot.
        #'   - `baseAmount` (numeric): Equivalent amount in the base currency.
        #'   - `tag` (character): Tag associated with the account (e.g., `"DEFAULT"`).
        #'   - If no balances are present across all sub-accounts, an empty `data.table` is returned.
        #'
        #' @details
        #' This method leverages the `/api/v2/sub-accounts` endpoint, which provides paginated data including balance details for each sub-account’s account types.
        #' Sub-accounts with no balance entries (i.e., all account type arrays empty) are excluded from the result, focusing only on sub-accounts with active balances.
        #' Pagination is handled automatically, respecting the API’s constraints on `pageSize` (10–100) and using `currentPage` to iterate through results.
        #' Numeric fields are explicitly cast from character strings to ensure proper data types for downstream analysis.
        get_subaccount_spot_v2 = function(page_size = 100, max_pages = Inf) {
            return(impl$get_subaccount_spot_v2_impl(
                keys = self$keys,
                base_url = self$base_url,
                page_size = page_size,
                max_pages = max_pages
            ))
        }
    )
)
