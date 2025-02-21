# File: ./R/KucoinDeposit.R

# box::use(
#     ./impl_account_deposit[
#         add_deposit_address_v3_impl,
#         get_deposit_addresses_v3_impl,
#         get_deposit_history_impl
#     ],
#     ./utils[get_api_keys, get_base_url]
# )

#' KucoinDeposit Class for KuCoin Deposit Endpoints
#'
#' The `KucoinDeposit` class provides an asynchronous interface for managing deposits on KuCoin.
#' It leverages the `coro` package for non-blocking HTTP requests, returning promises that typically resolve to `data.table`
#' objects. This class supports creating new deposit addresses, retrieving existing deposit addresses, and fetching deposit history.
#'
#' ### Workflow Overview
#' Not applicable (class definition overview).
#'
#' ### API Endpoint
#' Not applicable (class-level documentation; see individual methods).
#'
#' ### Usage
#' Utilised by users to manage KuCoin deposits programmatically. The class is initialised with API credentials,
#' automatically loaded via `get_api_keys()` if not provided, and a base URL from `get_base_url()`. For detailed endpoint
#' information and response schemas, refer to the official [KuCoin API Documentation](https://www.kucoin.com/docs-new).
#'
#' ### Official Documentation
#' [KuCoin API Documentation](https://www.kucoin.com/docs-new)
#'
#' @section Methods:
#' - **initialize(keys, base_url):** Initialises the object with API credentials and the base URL.
#' - **add_deposit_address(currency, chain, to, amount):** Creates a new deposit address for a specified currency.
#' - **get_deposit_addresses(currency, amount, chain):** Retrieves all deposit addresses for a specified currency.
#' - **get_deposit_history(currency, status, startAt, endAt, page_size, max_pages):** Retrieves the deposit history for a specified currency.
#'
#' @return Not applicable (class definition; see individual methods for return values).
#'
#' @examples
#' \dontrun{
#' # Comprehensive example demonstrating all methods
#' main_async <- coro::async(function() {
#'   # Initialise the class
#'   deposit <- KucoinDeposit$new()
#'
#'   # Add a new deposit address
#'   new_address <- await(deposit$add_deposit_address(
#'     currency = "USDT",
#'     chain = "trx",
#'     to = "trade"
#'   ))
#'   print("New Deposit Address:")
#'   print(new_address)
#'
#'   # Get all deposit addresses for a currency
#'   addresses <- await(deposit$get_deposit_addresses(currency = "USDT"))
#'   print("Deposit Addresses:")
#'   print(addresses)
#'
#'   # Get deposit history
#'   history <- await(deposit$get_deposit_history(
#'     currency = "USDT",
#'     status = "SUCCESS",
#'     startAt = 1728663338000,
#'     endAt = 1728692138000,
#'     page_size = 50,
#'     max_pages = 2
#'   ))
#'   print("Deposit History:")
#'   print(history)
#' })
#' main_async()
#' while (!later::loop_empty()) later::run_now()
#' }
#'
#' @importFrom R6 R6Class
#' @export
KucoinDeposit <- R6::R6Class(
    "KucoinDeposit",
    public = list(
        #' @field keys List containing KuCoin API keys (`api_key`, `api_secret`, `api_passphrase`, `key_version`).
        keys = NULL,
        #' @field base_url Character string representing the base URL for KuCoin API endpoints.
        base_url = NULL,
        
        #' Initialise a New KucoinDeposit Object
        #'
        #' ### Description
        #' Initialises a `KucoinDeposit` object with API credentials and a base URL for managing KuCoin deposits asynchronously.
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
        #' Utilised to create an instance of the class with authentication details for deposit management.
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
        #' @return A new instance of the `KucoinDeposit` class.
        initialize = function(keys = get_api_keys(), base_url = get_base_url()) {
            self$keys <- keys
            self$base_url <- base_url
        },
        
        #' Add Deposit Address
        #'
        #' ### Description
        #' Creates a new deposit address for a specified currency on KuCoin asynchronously by sending a POST request to the `/api/v3/deposit-address/create` endpoint.
        #' This method constructs a JSON request body, generates authentication headers, and processes the response into a `data.table`.
        #' It calls `add_deposit_address_v3_impl`.
        #'
        #' ### Workflow Overview
        #' 1. **URL Construction**: Combines the base URL with `/api/v3/deposit-address/create`.
        #' 2. **Request Body Preparation**: Builds a list with `currency`, `chain`, `to`, and optional `amount`, converted to JSON.
        #' 3. **Header Preparation**: Generates authentication headers asynchronously using `build_headers()`.
        #' 4. **API Request**: Sends a POST request with a 3-second timeout via `httr::POST()`.
        #' 5. **Response Processing**: Validates the response and converts the `"data"` field into a `data.table`.
        #'
        #' ### API Endpoint
        #' `POST https://api.kucoin.com/api/v3/deposit-address/create`
        #'
        #' ### Usage
        #' Utilised by users to create deposit addresses for various currencies, enabling deposits to the specified account type.
        #'
        #' ### Official Documentation
        #' [KuCoin Add Deposit Address (V3)](https://www.kucoin.com/docs-new/rest/account-info/deposit/add-deposit-address-v3)
        #'
        #' @param currency Character string; the currency for which to create the deposit address (e.g., "BTC", "ETH", "USDT").
        #' @param chain Character string (optional); the chain identifier (e.g., "eth", "bech32", "btc").
        #' @param to Character string (optional); the account type to deposit to ("main" or "trade").
        #' @param amount Character string (optional); the deposit amount, only used for Lightning Network invoices.
        #'
        #' @return Promise resolving to a `data.table` containing:
        #'   - `address` (character): The deposit address.
        #'   - `memo` (character): Address remark (may be empty).
        #'   - `chainId` (character): The chain identifier.
        #'   - `to` (character): The account type.
        #'   - `expirationDate` (integer): Expiration time (for Lightning Network).
        #'   - `currency` (character): The currency.
        #'   - `chainName` (character): The chain name.
        add_deposit_address = function(currency, chain = NULL, to = NULL, amount = NULL) {
            return(add_deposit_address_v3_impl(
                keys = self$keys,
                base_url = self$base_url,
                currency = currency,
                chain = chain,
                to = to,
                amount = amount
            ))
        },
        
        #' Get Deposit Addresses
        #'
        #' ### Description
        #' Retrieves all deposit addresses for a specified currency on KuCoin asynchronously by sending a GET request to the `/api/v3/deposit-addresses` endpoint.
        #' This method constructs the query string, generates authentication headers, and processes the response into a `data.table`.
        #' It calls `get_deposit_addresses_v3_impl`.
        #'
        #' ### Workflow Overview
        #' 1. **URL Construction**: Combines the base URL with `/api/v3/deposit-addresses` and appends query parameters.
        #' 2. **Header Preparation**: Generates authentication headers asynchronously using `build_headers()`.
        #' 3. **API Request**: Sends a GET request with a 3-second timeout via `httr::GET()`.
        #' 4. **Response Processing**: Validates the response and converts the `"data"` array into a `data.table`.
        #'
        #' ### API Endpoint
        #' `GET https://api.kucoin.com/api/v3/deposit-addresses`
        #'
        #' ### Usage
        #' Utilised by users to retrieve all existing deposit addresses for a given currency.
        #'
        #' ### Official Documentation
        #' [KuCoin Get Deposit Address (V3)](https://www.kucoin.com/docs-new/rest/account-info/deposit/get-deposit-address-v3)
        #'
        #' @param currency Character string; the currency for which to retrieve deposit addresses (e.g., "BTC", "ETH", "USDT").
        #' @param amount Character string (optional); the deposit amount, only used for Lightning Network invoices.
        #' @param chain Character string (optional); the chain identifier (e.g., "eth", "bech32", "btc").
        #'
        #' @return Promise resolving to a `data.table` containing:
        #'   - `address` (character): The deposit address.
        #'   - `memo` (character): Address remark (may be empty).
        #'   - `chainId` (character): The chain identifier.
        #'   - `to` (character): The account type ("main" or "trade").
        #'   - `expirationDate` (integer): Expiration time (for Lightning Network).
        #'   - `currency` (character): The currency.
        #'   - `contractAddress` (character): The token contract address.
        #'   - `chainName` (character): The chain name.
        get_deposit_addresses = function(currency, amount = NULL, chain = NULL) {
            return(get_deposit_addresses_v3_impl(
                keys = self$keys,
                base_url = self$base_url,
                currency = currency,
                amount = amount,
                chain = chain
            ))
        },
        
        #' Get Deposit History
        #'
        #' ### Description
        #' Retrieves a paginated list of deposit history entries for a specified currency on KuCoin asynchronously by sending a GET request to the `/api/v1/deposits` endpoint.
        #' This method handles pagination, constructs the query string, generates authentication headers, and processes the response into a `data.table` with a `createdAtDatetime` column.
        #' It calls `get_deposit_history_impl`.
        #'
        #' ### Workflow Overview
        #' 1. **URL Construction**: Combines the base URL with `/api/v1/deposits` and appends query parameters for filters and pagination.
        #' 2. **Pagination Initialisation**: Sets an initial query with `currentPage = 1` and the specified `page_size`.
        #' 3. **Page Fetching**: Defines an async helper to fetch each page with authentication headers.
        #' 4. **Automatic Pagination**: Uses `auto_paginate` to fetch all pages up to `max_pages`.
        #' 5. **Response Processing**: Combines `"items"` from each page into a `data.table`, adding `createdAtDatetime`.
        #'
        #' ### API Endpoint
        #' `GET https://api.kucoin.com/api/v1/deposits`
        #'
        #' ### Usage
        #' Utilised by users to fetch a comprehensive history of deposits for a KuCoin account, with optional filters for status and time range.
        #'
        #' ### Official Documentation
        #' [KuCoin Get Deposit History](https://www.kucoin.com/docs-new/rest/account-info/deposit/get-deposit-history)
        #'
        #' @param currency Character string; the currency to filter deposits by (e.g., "BTC", "ETH", "USDT").
        #' @param status Character string (optional); the status to filter by ("PROCESSING", "SUCCESS", "FAILURE").
        #' @param startAt Integer (optional); start time in milliseconds to filter deposits (e.g., 1728663338000).
        #' @param endAt Integer (optional); end time in milliseconds to filter deposits (e.g., 1728692138000).
        #' @param page_size Integer; number of results per page (10–500, default 50).
        #' @param max_pages Numeric; maximum number of pages to fetch (default `Inf` for all pages).
        #'
        #' @return Promise resolving to a `data.table` containing:
        #'   - `currency` (character): The currency of the deposit.
        #'   - `chain` (character): The chain identifier.
        #'   - `status` (character): Deposit status.
        #'   - `address` (character): Deposit address.
        #'   - `memo` (character): Address remark.
        #'   - `isInner` (logical): Whether the deposit is internal.
        #'   - `amount` (character): Deposit amount.
        #'   - `fee` (character): Fee charged.
        #'   - `walletTxId` (character or NULL): Wallet transaction ID.
        #'   - `createdAt` (integer): Creation timestamp in milliseconds.
        #'   - `createdAtDatetime` (POSIXct): Converted creation datetime.
        #'   - `updatedAt` (integer): Last updated timestamp in milliseconds.
        #'   - `remark` (character): Additional remarks.
        #'   - `arrears` (logical): Whether the deposit is in arrears.
        get_deposit_history = function(currency, status = NULL, startAt = NULL, endAt = NULL, page_size = 50, max_pages = Inf) {
            return(get_deposit_history_impl(
                keys = self$keys,
                base_url = self$base_url,
                currency = currency,
                status = status,
                startAt = startAt,
                endAt = endAt,
                page_size = page_size,
                max_pages = max_pages
            ))
        }
    )
)
