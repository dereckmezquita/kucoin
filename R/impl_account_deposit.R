# File: ./R/impl_account_deposit.R

# box::use(
#     ./helpers_api[auto_paginate, build_headers, process_kucoin_response],
#     ./utils[get_api_keys, get_base_url, build_query],
#     ./utils_time_convert_kucoin[time_convert_from_kucoin],
#     coro[async, await],
#     data.table[as.data.table, rbindlist],
#     httr[POST, GET, timeout],
#     jsonlite[toJSON],
#     rlang[abort, arg_match]
# )

#' Add Deposit Address (V3) (Implementation)
#'
#' Creates a new deposit address for a specified currency on KuCoin asynchronously by sending a POST request to the `/api/v3/deposit-address/create` endpoint. This internal function is designed for use within an R6 class and is not intended for direct end-user consumption.
#'
#' ### Workflow Overview
#' 1. **URL Construction**: Combines the base URL with the endpoint `/api/v3/deposit-address/create`.
#' 2. **Request Body Preparation**: Creates a list with required and optional parameters (`currency`, `chain`, `to`, `amount`), converted to JSON.
#' 3. **Header Preparation**: Generates authentication headers asynchronously via `build_headers()`.
#' 4. **API Request**: Sends a POST request using `httr::POST()` with the constructed URL, headers, and JSON body, applying a 3-second timeout.
#' 5. **Response Handling**: Processes the JSON response with `process_kucoin_response()`, extracting the `"data"` field and converting it to a `data.table`.
#'
#' ### API Endpoint
#' `POST https://api.kucoin.com/api/v3/deposit-address/create`
#'
#' ### Usage
#' Utilised internally to create deposit addresses for various currencies, enabling deposits to the specified account type.
#'
#' ### Official Documentation
#' [KuCoin Add Deposit Address (V3)](https://www.kucoin.com/docs-new/rest/account-info/deposit/add-deposit-address-v3)
#'
#' @param keys List containing API configuration parameters from `get_api_keys()`, including:
#'   - `api_key`: Character string; your KuCoin API key.
#'   - `api_secret`: Character string; your KuCoin API secret.
#'   - `api_passphrase`: Character string; your KuCoin API passphrase.
#'   - `key_version`: Character string; API key version (e.g., `"2"`).
#'   Defaults to `get_api_keys()`.
#' @param base_url Character string representing the base URL for the API. Defaults to `get_base_url()`.
#' @param currency Character string; the currency for which to create the deposit address (e.g., "BTC", "ETH", "USDT").
#' @param chain Character string (optional); the chain identifier (e.g., "eth", "bech32", "btc"). If not provided, the API uses the default chain for the currency.
#' @param to Character string (optional); the account type to deposit to ("main" or "trade"). If not provided, defaults to "main".
#' @param amount Character string (optional); the deposit amount, only used for Lightning Network invoices.
#' @return Promise resolving to a `data.table` containing the deposit address details, including:
#'   - `address` (character): The deposit address.
#'   - `memo` (character): Address remark (may be empty).
#'   - `chainId` (character): The chain identifier.
#'   - `to` (character): The account type.
#'   - `expirationDate` (integer): Expiration time (for Lightning Network).
#'   - `currency` (character): The currency.
#'   - `chainName` (character): The chain name.
#' @examples
#' \dontrun{
#' keys <- get_api_keys()
#' base_url <- "https://api.kucoin.com"
#' main_async <- coro::async(function() {
#'   dt <- await(add_deposit_address_v3_impl(
#'     keys = keys,
#'     base_url = base_url,
#'     currency = "TON",
#'     chain = "ton",
#'     to = "trade"
#'   ))
#'   print(dt)
#' })
#' main_async()
#' while (!later::loop_empty()) later::run_now()
#' }
#' @importFrom coro async await
#' @importFrom httr POST timeout
#' @importFrom jsonlite toJSON
#' @importFrom data.table as.data.table
#' @importFrom rlang abort
#' @export
add_deposit_address_v3_impl <- coro::async(function(
    keys = get_api_keys(),
    base_url = get_base_url(),
    currency,
    chain = NULL,
    to = NULL,
    amount = NULL
) {
    if (!is.character(currency) && !nzchar(currency)) {
        rlang::abort("currency must be a non-empty character string")
    }

    tryCatch({
        endpoint <- "/api/v3/deposit-address/create"
        method <- "POST"
        body_list <- list(currency = currency)
        if (!is.null(chain)) {
            body_list$chain <- chain
        }
        if (!is.null(to)) {
            body_list$to <- to
        }
        if (!is.null(amount)) {
            body_list$amount <- amount
        }

        body_json <- jsonlite::toJSON(body_list, auto_unbox = TRUE)
        headers <- await(build_headers(method, endpoint, body_json, keys))
        url <- paste0(base_url, endpoint)

        response <- httr::POST(
            url,
            headers,
            body = body_json,
            encode = "raw",
            httr::timeout(3)
        )
        parsed_response <- process_kucoin_response(response, url)
        # TODO: verify this might need rbindlist instead
        return(data.table::as.data.table(parsed_response$data))
    }, error = function(e) {
        rlang::abort(paste("Error in add_deposit_address_v3_impl:", conditionMessage(e)))
    })
})

#' Get Deposit Addresses (V3) (Implementation)
#'
#' Retrieves all deposit addresses for a specified currency on KuCoin asynchronously by sending a GET request to the `/api/v3/deposit-addresses` endpoint. This internal function is designed for use within an R6 class and is not intended for direct end-user consumption.
#'
#' ### Workflow Overview
#' 1. **URL Construction**: Combines the base URL with the endpoint `/api/v3/deposit-addresses` and appends query parameters using `build_query()`.
#' 2. **Header Preparation**: Generates authentication headers asynchronously via `build_headers()`.
#' 3. **API Request**: Sends a GET request using `httr::GET()` with the constructed URL and headers, applying a 3-second timeout.
#' 4. **Response Handling**: Processes the JSON response with `process_kucoin_response()`, extracting the `"data"` field and converting it to a `data.table` using `rbindlist()` for the array of addresses.
#'
#' ### API Endpoint
#' `GET https://api.kucoin.com/api/v3/deposit-addresses`
#'
#' ### Usage
#' Utilised internally to retrieve all existing deposit addresses for a given currency, which can be used for depositing funds to the specified account type.
#'
#' ### Official Documentation
#' [KuCoin Get Deposit Address (V3)](https://www.kucoin.com/docs-new/rest/account-info/deposit/get-deposit-address-v3)
#'
#' @param keys List containing API configuration parameters from `get_api_keys()`, including:
#'   - `api_key`: Character string; your KuCoin API key.
#'   - `api_secret`: Character string; your KuCoin API secret.
#'   - `api_passphrase`: Character string; your KuCoin API passphrase.
#'   - `key_version`: Character string; API key version (e.g., `"2"`).
#'   Defaults to `get_api_keys()`.
#' @param base_url Character string representing the base URL for the API. Defaults to `get_base_url()`.
#' @param currency Character string; the currency for which to retrieve deposit addresses (e.g., "BTC", "ETH", "USDT").
#' @param amount Character string (optional); the deposit amount, only used for Lightning Network invoices.
#' @param chain Character string (optional); the chain identifier (e.g., "eth", "bech32", "btc").
#' @return Promise resolving to a `data.table` containing the deposit address details, with columns including:
#'   - `address` (character): The deposit address.
#'   - `memo` (character): Address remark (may be empty).
#'   - `chainId` (character): The chain identifier.
#'   - `to` (character): The account type ("main" or "trade").
#'   - `expirationDate` (integer): Expiration time (for Lightning Network).
#'   - `currency` (character): The currency.
#'   - `contractAddress` (character): The token contract address.
#'   - `chainName` (character): The chain name.
#'   If no addresses are found, an empty `data.table` is returned.
#' @examples
#' \dontrun{
#' keys <- get_api_keys()
#' base_url <- "https://api.kucoin.com"
#' main_async <- coro::async(function() {
#'   dt <- await(get_deposit_address_v3_impl(
#'     keys = keys,
#'     base_url = base_url,
#'     currency = "USDT",
#'     chain = "trx"
#'   ))
#'   print(dt)
#' })
#' main_async()
#' while (!later::loop_empty()) later::run_now()
#' }
#' @importFrom coro async await
#' @importFrom httr GET timeout
#' @importFrom data.table rbindlist
#' @importFrom rlang abort
#' @export
get_deposit_addresses_v3_impl <- coro::async(function(
    keys = get_api_keys(),
    base_url = get_base_url(),
    currency,
    amount = NULL,
    chain = NULL
) {
    if (!is.character(currency) || !nzchar(currency)) {
        rlang::abort("currency must be a non-empty character string")
    }

    tryCatch({
        endpoint <- "/api/v3/deposit-addresses"
        method <- "GET"
        body <- ""

        # Build query parameters
        query_list <- list(currency = currency)
        if (!is.null(amount)) {
            query_list$amount <- amount
        }
        if (!is.null(chain)) {
            query_list$chain <- chain
        }
        qs <- build_query(query_list)
        full_endpoint <- paste0(endpoint, qs)

        headers <- await(build_headers(method, full_endpoint, body, keys))
        url <- paste0(base_url, full_endpoint)

        response <- httr::GET(url, headers, httr::timeout(3))
        parsed_response <- process_kucoin_response(response, url)

        # The response data is an array of objects, so use rbindlist
        if (length(parsed_response$data) > 0) {
            deposit_addresses_dt <- data.table::rbindlist(parsed_response$data)
        } else {
            # Return an empty data.table with the expected columns
            deposit_addresses_dt <- data.table::data.table(
                address = character(0),
                memo = character(0),
                chainId = character(0),
                to = character(0),
                expirationDate = integer(0),
                currency = character(0),
                contractAddress = character(0),
                chainName = character(0)
            )
        }

        return(deposit_addresses_dt)
    }, error = function(e) {
        rlang::abort(paste("Error in get_deposit_address_v3_impl:", conditionMessage(e)))
    })
})

#' Get Deposit History (Implementation)
#'
#' Retrieves a paginated list of deposit history entries from KuCoin asynchronously by sending a GET request to the `/api/v1/deposits` endpoint. This internal function is designed for use within an R6 class and is not intended for direct end-user consumption. Deposits are sorted to show the latest first, with pagination handled automatically.
#'
#' ### Workflow Overview
#' 1. **URL Construction**: Combines the base URL with the endpoint `/api/v1/deposits` and constructs query parameters using `build_query()`.
#' 2. **Pagination Initialisation**: Sets an initial query with `currentPage = 1` and the specified `page_size`, merging with additional filters.
#' 3. **Page Fetching**: Defines an asynchronous helper function (`fetch_page`) to send GET requests for each page, including authentication headers.
#' 4. **Automatic Pagination**: Leverages `auto_paginate` to fetch all pages up to `max_pages`, aggregating results into a single list.
#' 5. **Response Handling**: Processes responses with `process_kucoin_response()`, combines items into a `data.table` using `rbindlist()`, and adds a `createdAtDatetime` column for human-readable timestamps.
#'
#' ### API Endpoint
#' `GET https://api.kucoin.com/api/v1/deposits`
#'
#' ### Usage
#' Utilised internally to fetch a comprehensive history of deposits for a KuCoin account, allowing filtering by currency, status, and time range.
#'
#' ### Official Documentation
#' [KuCoin Get Deposit History](https://www.kucoin.com/docs-new/rest/account-info/deposit/get-deposit-history)
#'
#' @param keys List containing API configuration parameters from `get_api_keys()`, including:
#'   - `api_key`: Character string; your KuCoin API key.
#'   - `api_secret`: Character string; your KuCoin API secret.
#'   - `api_passphrase`: Character string; your KuCoin API passphrase.
#'   - `key_version`: Character string; API key version (e.g., `"2"`).
#'   Defaults to `get_api_keys()`.
#' @param base_url Character string representing the base URL for the API. Defaults to `get_base_url()`.
#' @param currency Character string; the currency to filter deposits by (e.g., "BTC", "ETH", "USDT").
#' @param status Character string (optional); the status to filter by ("PROCESSING", "SUCCESS", "FAILURE"). If not provided, all statuses are included.
#' @param startAt Integer (optional); start time in milliseconds to filter deposits (e.g., 1728663338000).
#' @param endAt Integer (optional); end time in milliseconds to filter deposits (e.g., 1728692138000).
#' @param page_size Integer; number of results per page (minimum 10, maximum 500). Defaults to 50.
#' @param max_pages Numeric; maximum number of pages to fetch (defaults to `Inf`, fetching all available pages).
#' @return Promise resolving to a `data.table` containing the deposit history, with columns including:
#'   - `currency` (character): The currency of the deposit (e.g., "USDT").
#'   - `chain` (character): The chain identifier (may be empty).
#'   - `status` (character): Deposit status ("PROCESSING", "SUCCESS", "FAILURE").
#'   - `address` (character): Deposit address or identifier.
#'   - `memo` (character): Address remark (may be empty).
#'   - `isInner` (logical): Whether the deposit is internal to KuCoin.
#'   - `amount` (character): Deposit amount.
#'   - `fee` (character): Fee charged for the deposit.
#'   - `walletTxId` (character or NULL): Wallet transaction ID (if applicable).
#'   - `createdAt` (integer): Creation timestamp in milliseconds.
#'   - `createdAtDatetime` (POSIXct): Converted creation datetime.
#'   - `updatedAt` (integer): Last updated timestamp in milliseconds.
#'   - `remark` (character): Additional remarks (may be empty).
#'   - `arrears` (logical): Whether the deposit is in arrears.
#'   If no deposits are found, an empty `data.table` with these columns is returned.
#' @examples
#' \dontrun{
#' keys <- get_api_keys()
#' base_url <- "https://api.kucoin.com"
#' main_async <- coro::async(function() {
#'   dt <- await(get_deposit_history_impl(
#'     keys = keys,
#'     base_url = base_url,
#'     currency = "USDT",
#'     status = "SUCCESS",
#'     startAt = 1728663338000,
#'     endAt = 1728692138000,
#'     page_size = 50,
#'     max_pages = 2
#'   ))
#'   print(dt)
#' })
#' main_async()
#' while (!later::loop_empty()) later::run_now()
#' }
#' @importFrom coro async await
#' @importFrom httr GET timeout
#' @importFrom data.table rbindlist data.table
#' @importFrom rlang abort
#' @export
get_deposit_history_impl <- coro::async(function(
    keys = get_api_keys(),
    base_url = get_base_url(),
    currency,
    status = NULL,
    startAt = NULL,
    endAt = NULL,
    page_size = 50,
    max_pages = Inf
) {
    if (!is.character(currency) || !nzchar(currency)) {
        rlang::abort("currency must be a non-empty character string")
    }
    if (!is.null(status) && !status %in% c("PROCESSING", "SUCCESS", "FAILURE")) {
        rlang::abort("status must be one of 'PROCESSING', 'SUCCESS', or 'FAILURE'")
    }
    if (!is.numeric(page_size) || page_size < 10 || page_size > 500) {
        rlang::abort("page_size must be an integer between 10 and 500")
    }

    tryCatch({
        # Define the fetch_page function for pagination
        fetch_page <- coro::async(function(query) {
            endpoint <- "/api/v1/deposits"
            method <- "GET"
            body <- ""
            qs <- build_query(query)
            full_endpoint <- paste0(endpoint, qs)
            headers <- await(build_headers(method, full_endpoint, body, keys))
            url <- paste0(base_url, full_endpoint)
            response <- httr::GET(url, headers, httr::timeout(3))
            parsed_response <- process_kucoin_response(response, url)
            return(parsed_response$data)
        })

        # Build initial query with filters and pagination
        initial_query <- list(
            currency = currency,
            currentPage = 1,
            pageSize = page_size
        )
        if (!is.null(status)) {
            initial_query$status <- status
        }
        if (!is.null(startAt)) {
            initial_query$startAt <- as.integer(startAt)
        }
        if (!is.null(endAt)) {
            initial_query$endAt <- as.integer(endAt)
        }

        # TOOD: updated return signature
        deposit_history_dt <- await(auto_paginate(
            fetch_page = fetch_page,
            query = initial_query,
            items_field = "items",
            paginate_fields = list(
                currentPage = "currentPage",
                totalPage = "totalPage"
            ),
            aggregate_fn = function(acc) {
                if (length(acc) == 0 || all(sapply(acc, length) == 0)) {
                    return(data.table::data.table(
                        currency = character(0),
                        chain = character(0),
                        status = character(0),
                        address = character(0),
                        memo = character(0),
                        isInner = logical(0),
                        amount = character(0),
                        fee = character(0),
                        walletTxId = character(0),
                        createdAt = integer(0),
                        updatedAt = integer(0),
                        remark = character(0),
                        arrears = logical(0),
                        createdAtDatetime = as.POSIXct(character(0))
                    ))
                }
                dt <- data.table::rbindlist(acc, fill = TRUE)
                dt[, createdAtDatetime := time_convert_from_kucoin(createdAt, "ms")]
                return(dt)
            },
            max_pages = max_pages
        ))

        return(deposit_history_dt)
    }, error = function(e) {
        rlang::abort(paste("Error in get_deposit_history_impl:", conditionMessage(e)))
    })
})
