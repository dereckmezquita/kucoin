# File: ./R/KucoinDeposit.R

# box::use(
#     ./impl_account_deposit[
#         add_deposit_address_v3_impl,
#         get_deposit_addresses_v3_impl,
#         get_deposit_history_impl
#     ],
#     ./utils[get_api_keys, get_base_url]
# )

#' KucoinDeposit Class for KuCoin Deposit Management
#'
#' The `KucoinDeposit` class provides an asynchronous interface for managing deposit operations on KuCoin.
#' It leverages the `coro` package for non-blocking HTTP requests, returning promises that resolve to `data.table` objects.
#' This class supports creating new deposit addresses, retrieving existing deposit addresses, and fetching deposit history,
#' all requiring authentication via API keys.
#'
#' ### Purpose and Scope
#' This class is designed to handle deposit-related tasks in the KuCoin ecosystem, including:
#' - **Address Creation**: Generating new deposit addresses for various currencies and chains.
#' - **Address Retrieval**: Listing all deposit addresses for a currency.
#' - **History Tracking**: Querying deposit records with filtering and pagination.
#'
#' ### Usage
#' Utilised by traders and developers to programmatically manage deposits on KuCoin. The class is initialized with API credentials,
#' automatically sourced from `get_api_keys()` if not provided, and a base URL from `get_base_url()`. All methods require authentication.
#' For detailed endpoint information, parameters, and response schemas, refer to the official [KuCoin API Documentation](https://www.kucoin.com/docs-new).
#'
#' ### Official Documentation
#' [KuCoin API Documentation - Deposit](https://www.kucoin.com/docs-new/rest/account-info/deposit/introduction)
#'
#' @section Methods:
#' - **initialize(keys, base_url):** Initialises the object with API credentials and base URL.
#' - **add_deposit_address(currency, chain, to, amount):** Creates a new deposit address for a currency.
#' - **get_deposit_addresses(currency, chain, amount):** Retrieves all deposit addresses for a currency.
#' - **get_deposit_history(currency, status, startAt, endAt, page_size, max_pages):** Fetches paginated deposit history.
#'
#' @examples
#' \dontrun{
#' # Comprehensive example demonstrating key methods
#' main_async <- coro::async(function() {
#'   # Initialise the class
#'   deposit <- KucoinDeposit$new()
#'
#'   # Add a new deposit address for USDT on TRON
#'   new_address <- await(deposit$add_deposit_address(
#'     currency = "USDT",
#'     chain = "trx",
#'     to = "trade"
#'   ))
#'   print("New Deposit Address:"); print(new_address)
#'
#'   # Get all deposit addresses for USDT
#'   addresses <- await(deposit$get_deposit_addresses(currency = "USDT"))
#'   print("USDT Deposit Addresses:"); print(addresses)
#'
#'   # Get deposit history for USDT over a specific period
#'   history <- await(deposit$get_deposit_history(
#'     currency = "USDT",
#'     status = "SUCCESS",
#'     startAt = as.integer(Sys.time() - 24*3600) * 1000,
#'     endAt = as.integer(Sys.time()) * 1000,
#'     page_size = 10,
#'     max_pages = 2
#'   ))
#'   print("USDT Deposit History:"); print(history)
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
        #' Initialises a `KucoinDeposit` object with API credentials and a base URL for managing deposit operations
        #' asynchronously. All methods require authentication, so valid credentials are essential.
        #'
        #' ### Workflow Overview
        #' 1. **Credential Assignment**: Sets `self$keys` to the provided or default API keys from `get_api_keys()`.
        #' 2. **URL Assignment**: Sets `self$base_url` to the provided or default base URL from `get_base_url()`.
        #'
        #' ### API Endpoint
        #' Not applicable (initialisation method).
        #'
        #' ### Usage
        #' Creates an instance for managing KuCoin deposits, requiring authenticated API access for all operations.
        #'
        #' ### Official Documentation
        #' [KuCoin API Authentication](https://www.kucoin.com/docs-new/rest/introduction#authentication)
        #'
        #' ### Automated Trading Usage
        #' - **Deposit Automation**: Use as the core object for deposit workflows in your bot, integrating with wallet management systems.
        #' - **Secure Setup**: Provide explicit `keys` or use `get_api_keys()` from a secure vault for production-grade security.
        #' - **Scalability**: Instantiate once and reuse across deposit cycles, pairing with withdrawal classes for full fund management.
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
        #' Creates a new deposit address for a specified currency asynchronously via a POST request to `/api/v3/deposit-address/create`.
        #' Calls `add_deposit_address_v3_impl`.
        #'
        #' ### Workflow Overview
        #' 1. **Validation**: Ensures `currency` is valid within the implementation.
        #' 2. **Request Body**: Constructs JSON with `currency`, `chain`, `to`, and optional `amount`.
        #' 3. **Authentication**: Generates headers with API keys.
        #' 4. **API Call**: Sends POST request.
        #' 5. **Response**: Returns address details as a `data.table`.
        #'
        #' ### API Endpoint
        #' `POST https://api.kucoin.com/api/v3/deposit-address/create`
        #'
        #' ### Usage
        #' Utilised to generate new deposit addresses for funding KuCoin accounts, supporting various chains and account types.
        #'
        #' ### Official Documentation
        #' [KuCoin Add Deposit Address (V3)](https://www.kucoin.com/docs-new/rest/account-info/deposit/add-deposit-address-v3)
        #'
        #' ### Automated Trading Usage
        #' - **Fund Allocation**: Generate addresses for `to = "trade"` to direct funds to trading accounts, automating wallet-to-exchange transfers.
        #' - **Chain Selection**: Specify `chain` (e.g., "trx" for USDT) to optimize fees, integrating with fee analysis from market data.
        #' - **Address Rotation**: Create new addresses periodically for security, tracking via `chainId` and auditing with `get_deposit_addresses`.
        #'
        #' @param currency Character string; currency code (e.g., "BTC", "USDT"). Required.
        #' @param chain Character string; chain identifier (e.g., "trx", "erc20"). Optional.
        #' @param to Character string; account type ("main" or "trade"). Optional, defaults to "main".
        #' @param amount Character string; amount for Lightning Network invoices. Optional.
        #' @return Promise resolving to a `data.table` with:
        #'   - `address` (character): Deposit address.
        #'   - `memo` (character): Address remark (if any).
        #'   - `chainId` (character): Chain identifier.
        #'   - `to` (character): Account type.
        #'   - `expirationDate` (integer): Expiration (Lightning Network).
        #'   - `currency` (character): Currency code.
        #'   - `chainName` (character): Chain name.
        #' ### JSON Response Example
        #' ```json
        #' {"code": "200000", "data": {"address": "T...x", "memo": "", "chainId": "trx", "to": "trade", "currency": "USDT", "chainName": "TRON"}}
        #' ```
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
        #' Retrieves all deposit addresses for a specified currency asynchronously via a GET request to `/api/v3/deposit-addresses`.
        #' Calls `get_deposit_addresses_v3_impl`.
        #'
        #' ### Workflow Overview
        #' 1. **Validation**: Ensures `currency` is valid within the implementation.
        #' 2. **Query**: Builds query with `currency`, optional `chain`, and `amount`.
        #' 3. **Authentication**: Generates headers with API keys.
        #' 4. **API Call**: Sends GET request.
        #' 5. **Response**: Returns a `data.table` of all addresses, empty if none exist.
        #'
        #' ### API Endpoint
        #' `GET https://api.kucoin.com/api/v3/deposit-addresses`
        #'
        #' ### Usage
        #' Utilised to list all existing deposit addresses for a currency, aiding in deposit management.
        #'
        #' ### Official Documentation
        #' [KuCoin Get Deposit Address (V3)](https://www.kucoin.com/docs-new/rest/account-info/deposit/get-deposit-address-v3)
        #'
        #' ### Automated Trading Usage
        #' - **Address Inventory**: Fetch all addresses for a currency to manage multiple deposit points, selecting based on `to` or `chainName`.
        #' - **Verification**: Confirm address availability before initiating deposits, retrying `add_deposit_address` if none exist.
        #' - **Chain Preference**: Filter by `chain` to use low-fee networks, integrating with deposit history to track usage.
        #'
        #' @param currency Character string; currency code (e.g., "BTC", "USDT"). Required.
        #' @param chain Character string; chain identifier (e.g., "trx"). Optional.
        #' @param amount Character string; amount for Lightning Network invoices. Optional.
        #' @return Promise resolving to a `data.table` with:
        #'   - `address` (character): Deposit address.
        #'   - `memo` (character): Address remark (if any).
        #'   - `chainId` (character): Chain identifier.
        #'   - `to` (character): Account type.
        #'   - `expirationDate` (integer): Expiration (Lightning Network).
        #'   - `currency` (character): Currency code.
        #'   - `contractAddress` (character): Token contract address.
        #'   - `chainName` (character): Chain name.
        #' ### JSON Response Example
        #' ```json
        #' {"code": "200000", "data": [{"address": "T...x", "memo": "", "chainId": "trx", "to": "trade", "currency": "USDT", "chainName": "TRON"}]}
        #' ```
        get_deposit_addresses = function(currency, chain = NULL, amount = NULL) {
            return(get_deposit_addresses_v3_impl(
                keys = self$keys,
                base_url = self$base_url,
                currency = currency,
                chain = chain,
                amount = amount
            ))
        },

        #' Get Deposit History
        #'
        #' ### Description
        #' Retrieves paginated deposit history asynchronously via a GET request to `/api/v1/deposits`.
        #' Calls `get_deposit_history_impl`.
        #'
        #' ### Workflow Overview
        #' 1. **Validation**: Ensures parameters meet API constraints (e.g., `page_size` 10-500).
        #' 2. **Query**: Constructs query with filters and pagination settings.
        #' 3. **Authentication**: Generates headers with API keys.
        #' 4. **API Call**: Fetches pages up to `max_pages`.
        #' 5. **Response**: Aggregates history into a `data.table` with datetime conversion.
        #'
        #' ### API Endpoint
        #' `GET https://api.kucoin.com/api/v1/deposits`
        #'
        #' ### Usage
        #' Utilised to track deposit transactions, with filtering by currency, status, and time range.
        #'
        #' ### Official Documentation
        #' [KuCoin Get Deposit History](https://www.kucoin.com/docs-new/rest/account-info/deposit/get-deposit-history)
        #'
        #' ### Automated Trading Usage
        #' - **Fund Tracking**: Monitor `status = "SUCCESS"` deposits to confirm fund availability, triggering trading actions.
        #' - **Reconciliation**: Use `createdAtDatetime` and `amount` to reconcile with external wallet records, polling daily with time filters.
        #' - **Error Handling**: Filter `status = "FAILURE"` to investigate issues, alerting users or retrying deposits automatically.
        #'
        #' @param currency Character string; currency code (e.g., "BTC", "USDT"). Required.
        #' @param status Character string; status filter ("PROCESSING", "SUCCESS", "FAILURE"). Optional.
        #' @param startAt Integer; start time (ms). Optional.
        #' @param endAt Integer; end time (ms). Optional.
        #' @param page_size Integer; results per page (10-500, default 50).
        #' @param max_pages Numeric; max pages to fetch (default `Inf`).
        #' @return Promise resolving to a `data.table` with:
        #'   - `currency` (character): Currency code.
        #'   - `chain` (character): Chain identifier.
        #'   - `status` (character): Deposit status.
        #'   - `address` (character): Deposit address.
        #'   - `amount` (character): Deposit amount.
        #'   - `createdAtDatetime` (POSIXct): Creation time.
        #'   - Full schema in implementation docs.
        #' ### JSON Response Example
        #' ```json
        #' {"code": "200000", "data": {"items": [{"currency": "USDT", "status": "SUCCESS", "amount": "100", "createdAt": 1733049198863}]}}
        #' ```
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
