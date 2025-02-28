# File: ./R/impl_account_deposit.R

box::use(
    ./helpers_api[auto_paginate, build_headers, process_kucoin_response],
    ./utils[get_api_keys, get_base_url, build_query],
    ./utils_time_convert_kucoin[time_convert_from_kucoin, time_convert_to_kucoin],
    coro[async, await],
    data.table[as.data.table, rbindlist],
    httr[POST, GET, timeout],
    jsonlite[toJSON],
    rlang[abort, arg_match]
)

#' Add Deposit Address (V3)
#'
#' Creates a new deposit address for a specified currency on KuCoin asynchronously by sending a POST request to the `/api/v3/deposit-address/create` endpoint. This internal function is designed for use within an R6 class and is not intended for direct end-user consumption.
#'
#' ## Workflow Overview
#' 1. **URL Construction**: Combines the base URL with the endpoint `/api/v3/deposit-address/create`.
#' 2. **Request Body Preparation**: Constructs a list with required and optional parameters (`currency`, `chain`, `to`, `amount`), then converts it to JSON.
#' 3. **Header Preparation**: Generates authentication headers asynchronously using `build_headers()`.
#' 4. **API Request**: Sends a POST request via `httr::POST()` with the constructed URL, headers, and JSON body, enforcing a 3-second timeout.
#' 5. **Response Handling**: Processes the JSON response with `process_kucoin_response()`, extracts the `"data"` field, and converts it to a `data.table`.
#'
#' ## API Endpoint
#' `POST https://api.kucoin.com/api/v3/deposit-address/create`
#'
#' ## Usage
#' This function is used internally to generate deposit addresses for various currencies, facilitating deposits to either the funding (`main`) or spot trading (`trade`) account.
#'
#' ## Official Documentation
#' [KuCoin Add Deposit Address (V3)](https://www.kucoin.com/docs-new/rest/account-info/deposit/add-deposit-address-v3)
#'
#' ## Function Validated
#' - Last validated: 2025-02-23 22h56
#'
#' @param keys List containing API configuration parameters from `get_api_keys()`, including:
#'   - `api_key` (character): Your KuCoin API key.
#'   - `api_secret` (character): Your KuCoin API secret.
#'   - `api_passphrase` (character): Your KuCoin API passphrase.
#'   - `key_version` (character): API key version (e.g., `"2"`).
#'   Defaults to `get_api_keys()`.
#' @param base_url Character string representing the base URL for the API. Defaults to `get_base_url()`.
#' @param currency Character string; the currency for which to create the deposit address (e.g., `"BTC"`, `"ETH"`, `"USDT"`). **Required**.
#' @param chain Character string (optional); the chain identifier for multi-chain currencies (e.g., `"eth"`, `"bech32"`, `"trx"`, `"ton"`). If omitted, the API uses the default chain (e.g., `"ERC20"` for USDT, `"Native"` for BTC). Not needed for single-chain currencies.
#' @param to Character string (optional); the account type for the deposit. Allowed values: `"main"` (funding account) or `"trade"` (spot trading account). Defaults to `"main"`.
#' @param amount Character string (optional); the deposit amount, applicable only for Lightning Network invoices. Ignored if not using the Lightning Network.
#'
#' @return A promise resolving to a `data.table` containing the deposit address details with the following columns:
#'   - `address` (character): The generated deposit address.
#'   - `memo` (character): Address remark or tag. Empty if no remark exists. Required for some currencies (e.g., XRP, XLM) to credit deposits.
#'   - `chainId` (character): The chain identifier of the currency (e.g., `"ton"`, `"eth"`, `"trx"`).
#'   - `to` (character): The account type (`"main"` or `"trade"`).
#'   - `expirationDate` (numeric): Expiration time for Lightning Network invoices (0 if not applicable).
#'   - `currency` (character): The currency for which the address was created.
#'   - `chainName` (character): The chain name (e.g., `"TON"`, `"ETH"`).
#'
#'   If the API response lacks data (e.g., due to an error), an empty `data.table` with these columns is returned.
#'
#' ## Details
#'
#' ### Request Body Schema
#' The request body is a JSON object with the following fields:
#' - `currency` (string, **required**): The currency (e.g., `"BTC"`, `"ETH"`, `"USDT"`).
#' - `chain` (string, optional): The chain identifier for multi-chain currencies. Examples:
#'   - USDT: `"OMNI"`, `"ERC20"`, `"TRC20"` (default: `"ERC20"`).
#'   - BTC: `"Native"`, `"Segwit"`, `"TRC20"` (parameters: `"btc"`, `"bech32"`, `"trx"`; default: `"Native"`).
#'   - Single-chain currencies (e.g., `"TON"`): No chain specification needed unless specified (e.g., `"ton"`).
#' - `to` (string, optional): The account type. Allowed values: `"main"` (funding account), `"trade"` (spot trading account). Defaults to `"main"`.
#' - `amount` (string, optional): The deposit amount, only valid for Lightning Network invoices.
#'
#' **Example Request Body**:
#' ```json
#' {
#'   "currency": "TON",
#'   "chain": "ton",
#'   "to": "trade"
#' }
#' ```
#'
#' ### Response Schema
#' - `code` (string): Status code, where `"200000"` indicates success.
#' - `data` (object):
#'   - `address` (string): The deposit address.
#'   - `memo` (string): Address remark or tag (empty if none). Critical for currencies requiring a memo (e.g., XRP, XLM).
#'   - `chainId` (string): The chain identifier (e.g., `"ton"`, `"eth"`, `"trx"`).
#'   - `to` (string): The account type (`"main"` or `"trade"`).
#'   - `expirationDate` (integer): Expiration time for Lightning Network invoices (0 for non-Lightning networks).
#'   - `currency` (string): The currency (e.g., `"TON"`, `"BTC"`).
#'   - `chainName` (string): The chain name (e.g., `"TON"`, `"ETH"`).
#'
#' **Example JSON Response**:
#' ```json
#' {
#'   "code": "200000",
#'   "data": {
#'     "address": "EQCA1BI4QRZ8qYmskSRDzJmkucGodYRTZCf_b9hckjla6dZl",
#'     "memo": "2090821203",
#'     "chainId": "ton",
#'     "to": "TRADE",
#'     "expirationDate": 0,
#'     "currency": "TON",
#'     "chainName": "TON"
#'   }
#' }
#' ```
#'
#' The function processes this response by:
#' - Extracting the `"data"` field.
#' - Converting it to a `data.table`, ensuring proper column types (e.g., `character` for `address`, `numeric` for `expirationDate`).
#'
#' ### Notes
#' - **Multi-Chain Currencies**: Specify `chain` correctly (e.g., `"trx"` for USDT on TRC20) to avoid depositing to the wrong network, which could result in lost funds.
#' - **Memo Requirement**: For currencies like XRP or XLM, the `memo` must be included in deposit instructions to ensure funds are credited.
#' - **Lightning Network**: The `amount` parameter is only relevant for Lightning Network deposits; otherwise, it is ignored.
#' - **Account Types**: The `to` parameter directs deposits to either the funding account (`"main"`) or spot trading account (`"trade"`), affecting fund availability.
#' - **Rate Limit**: This endpoint has a weight of 20 in the API rate limit pool (Management). Plan request frequency accordingly.
#'
#' ## Use Cases
#' - **Automated Address Creation**: Generate deposit addresses programmatically for different currencies and chains, ideal for wallet management or deposit automation.
#' - **Multi-Chain Support**: Create addresses for specific chains (e.g., USDT on TRC20 or ERC20) to control deposit networks.
#' - **Account-Specific Deposits**: Direct funds to the funding account (`"main"`) for storage or the trading account (`"trade"`) for immediate use.
#' - **Lightning Network Deposits**: Generate invoices with a specified `amount` for Lightning Network transactions.
#'
#' ## Advice for Automated Trading Systems
#' - **Chain Validation**: Always specify the `chain` for multi-chain currencies and verify it matches the intended network to prevent deposit errors.
#' - **Memo Management**: Store and provide the `memo` field when instructing deposits, especially for currencies requiring it, to avoid uncredited funds.
#' - **Account Type Strategy**: Use `to` to align deposits with your system’s workflow (e.g., `"trade"` for immediate trading, `"main"` for long-term holding).
#' - **Error Handling**: Check the `code` field in the response (e.g., `"200000"` for success) and handle failures (e.g., invalid currency or chain) gracefully.
#' - **Rate Limit Awareness**: With a weight of 20 per request, monitor and throttle usage in high-frequency systems to stay within KuCoin’s limits.
#'
#' @examples
#' \dontrun{
#' # Example: Generate a deposit address for TON on the TON chain, directed to the trade account
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
#'
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
    if (!is.character(currency) || !nzchar(currency)) {
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
        # saveRDS(response, "../../api-responses/impl_account_deposit/response-add_deposit_address_v3_impl.ignore.Rds")
        parsed_response <- process_kucoin_response(response, url)
        # saveRDS(parsed_response, "../../api-responses/impl_account_deposit/parsed_response-add_deposit_address_v3_impl.Rds")

        data_obj <- parsed_response$data
        if (is.null(data_obj)) {
            return(data.table::data.table(
                address = character(0),
                memo = character(0),
                chainId = character(0),
                to = character(0),
                expirationDate = numeric(0),
                currency = character(0),
                chainName = character(0)
            ))
        }

        result_dt <- data.table::as.data.table(data_obj)
        result_dt[, `:=`(
            address = as.character(address),
            memo = as.character(memo),
            chainId = as.character(chainId),
            to = as.character(to),
            expirationDate = as.numeric(expirationDate),
            currency = as.character(currency),
            chainName = as.character(chainName)
        )]

        return(result_dt[])
    }, error = function(e) {
        rlang::abort(paste("Error in add_deposit_address_v3_impl:", conditionMessage(e)))
    })
})

#' Get Deposit Addresses (V3)
#'
#' Retrieves all deposit addresses for a specified currency on KuCoin asynchronously by sending a GET request to the `/api/v3/deposit-addresses` endpoint. This internal function is designed for use within an R6 class and is not intended for direct end-user consumption.
#'
#' ## API Details
#'
#' - **Domain**: Spot
#' - **API Channel**: Private
#' - **API Permission**: General
#' - **API Rate Limit Pool**: Management
#' - **API Rate Limit Weight**: 5
#' - **SDK Service**: Account
#' - **SDK Sub-Service**: Deposit
#' - **SDK Method Name**: `getDepositAddressV3`
#'
#' ## Description
#' This function retrieves all deposit addresses for the specified currency. If no addresses are returned, you may need to create a deposit address using `add_deposit_address_v3_impl`.
#'
#' ## Workflow Overview
#' 1. **URL Construction**: Combines the base URL with the endpoint `/api/v3/deposit-addresses` and appends query parameters using `build_query()`.
#' 2. **Header Preparation**: Generates authentication headers asynchronously via `build_headers()`.
#' 3. **API Request**: Sends a GET request using `httr::GET()` with the constructed URL and headers, applying a 3-second timeout.
#' 4. **Response Handling**: Processes the JSON response with `process_kucoin_response()`, extracts the `"data"` field (an array of address objects), and converts it to a `data.table` using `rbindlist()`.
#'
#' ## API Endpoint
#' `GET https://api.kucoin.com/api/v3/deposit-addresses`
#'
#' ## Usage
#' This function is used internally by `KucoinDeposit` to retrieve deposit addresses for a specified currency. It is not intended for direct end-user consumption.
#'
#' ## Official Documentation
#' [KuCoin Get Deposit Address (V3)](https://www.kucoin.com/docs-new/rest/account-info/deposit/get-deposit-address-v3)
#'
#' ## Function Validated
#' - Last validated: 2025-02-24 19h02
#'
#' @param keys List containing API configuration parameters from `get_api_keys()`, including:
#'   - `api_key` (character): Your KuCoin API key.
#'   - `api_secret` (character): Your KuCoin API secret.
#'   - `api_passphrase` (character): Your KuCoin API passphrase.
#'   - `key_version` (character): API key version (e.g., `"2"`).
#'   Defaults to `get_api_keys()`.
#' @param base_url Character string representing the base URL for the API. Defaults to `get_base_url()`.
#' @param currency Character string; the currency for which to retrieve deposit addresses (e.g., `"BTC"`, `"ETH"`, `"USDT"`). **Required**.
#' @param amount Character string (optional); the deposit amount, only used for Lightning Network invoices. Ignored if not using the Lightning Network.
#' @param chain Character string (optional); the chain identifier (e.g., `"eth"`, `"bech32"`, `"btc"`, `"kcc"`, `"trx"`, `"bsc"`, `"arbitrum"`, `"ton"`, `"optimism"`). If specified, filters addresses to the given chain.
#'
#' @return A promise resolving to a `data.table` containing deposit address details for the specified currency, with the following columns:
#'   - `address` (character): The deposit address.
#'   - `memo` (character): Address remark or tag (empty if none). Required for some currencies (e.g., XRP, XLM) to credit deposits.
#'   - `chainId` (character): The chain identifier (e.g., `"trx"`, `"eth"`, `"ton"`).
#'   - `to` (character): The account type (`"main"` or `"trade"`).
#'   - `expirationDate` (integer): Expiration time for Lightning Network invoices (0 if not applicable).
#'   - `currency` (character): The currency (e.g., `"USDT"`, `"BTC"`).
#'   - `contractAddress` (character): The token contract address (e.g., for ERC20 tokens).
#'   - `chainName` (character): The chain name (e.g., `"TRC20"`, `"ERC20"`, `"TON"`).
#'
#'   If no addresses are found for the specified currency (and chain, if provided), an empty `data.table` with these columns is returned. In such cases, you may need to create a deposit address using `add_deposit_address_v3_impl`.
#'
#' ## Details
#'
#' ### Query Parameters
#' - `currency` (string, **required**): The currency for which to retrieve deposit addresses (e.g., `"USDT"`, `"BTC"`).
#' - `amount` (string, optional): The deposit amount, only applicable for Lightning Network invoices.
#' - `chain` (string, optional): The chain identifier to filter addresses (e.g., `"trx"` for TRC20, `"eth"` for ERC20). If omitted, addresses for all available chains are returned.
#'
#' **Example Request URL**:
#' ```http
#' GET https://api.kucoin.com/api/v3/deposit-addresses?currency=USDT&chain=trx
#' ```
#'
#' ### Response Schema
#' - `code` (string): Status code, where `"200000"` indicates success.
#' - `data` (array of objects): Each object contains:
#'   - `address` (string): The deposit address.
#'   - `memo` (string): Address remark or tag (may be empty). Critical for currencies requiring a memo (e.g., XRP, XLM).
#'   - `chainId` (string): The chain identifier (e.g., `"trx"`, `"eth"`, `"ton"`).
#'   - `to` (string): The account type (`"main"` or `"trade"`).
#'   - `expirationDate` (integer): Expiration time for Lightning Network invoices (0 for non-Lightning networks).
#'   - `currency` (string): The currency (e.g., `"USDT"`, `"BTC"`).
#'   - `contractAddress` (string): The token contract address (e.g., for ERC20 tokens).
#'   - `chainName` (string): The chain name (e.g., `"TRC20"`, `"ERC20"`, `"TON"`).
#'
#' **Example JSON Response**:
#' ```json
#' {
#'   "code": "200000",
#'   "data": [
#'     {
#'       "address": "TSv3L1fS7yA3SxzKD8c1qdX4nLP6rqNxYz",
#'       "memo": "",
#'       "chainId": "trx",
#'       "to": "TRADE",
#'       "expirationDate": 0,
#'       "currency": "USDT",
#'       "contractAddress": "TR7NHqjeKQxGTCi8q8ZY4pL8otSzgjLj6t",
#'       "chainName": "TRC20"
#'     },
#'     {
#'       "address": "0x551e823a3b36865e8c5dc6e6ac6cc0b00d98533e",
#'       "memo": "",
#'       "chainId": "kcc",
#'       "to": "TRADE",
#'       "expirationDate": 0,
#'       "currency": "USDT",
#'       "contractAddress": "0x0039f574ee5cc39bdd162e9a88e3eb1f111baf48",
#'       "chainName": "KCC"
#'     },
#'     {
#'       "address": "EQCA1BI4QRZ8qYmskSRDzJmkucGodYRTZCf_b9hckjla6dZl",
#'       "memo": "2085202643",
#'       "chainId": "ton",
#'       "to": "TRADE",
#'       "expirationDate": 0,
#'       "currency": "USDT",
#'       "contractAddress": "EQCxE6mUtQJKFnGfaROTKOt1lZbDiiX1kCixRv7Nw2Id_sDs",
#'       "chainName": "TON"
#'     },
#'     {
#'       "address": "0x0a2586d5a901c8e7e68f6b0dc83bfd8bd8600ff5",
#'       "memo": "",
#'       "chainId": "eth",
#'       "to": "MAIN",
#'       "expirationDate": 0,
#'       "currency": "USDT",
#'       "contractAddress": "0xdac17f958d2ee523a2206206994597c13d831ec7",
#'       "chainName": "ERC20"
#'     }
#'   ]
#' }
#' ```
#'
#' The function processes this response by:
#' - Extracting the `"data"` array.
#' - Converting it to a `data.table`, with each object in the array becoming a row.
#' - Ensuring proper column types (e.g., `character` for `address`, `numeric` for `expirationDate`).
#'
#' @examples
#' \dontrun{
#' # Example: Retrieve all deposit addresses for USDT on the TRC20 chain
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
#'
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
        # saveRDS(response, "../../api-responses/impl_account_deposit/response-get_deposit_addresses_v3_impl.ignore.Rds")
        parsed_response <- process_kucoin_response(response, url)
        # saveRDS(parsed_response, "../../api-responses/impl_account_deposit/parsed_response-get_deposit_address_v3_impl.Rds")

        data_array <- parsed_response$data

        if (is.null(data_array) || length(data_array) == 0) {
            return(data.table::data.table(
                address = character(0),
                memo = character(0),
                chainId = character(0),
                to = character(0),
                expirationDate = numeric(0),
                currency = character(0),
                contractAddress = character(0),
                chainName = character(0)
            ))
        }

        result_dt <- data.table::rbindlist(data_array)
        result_dt[, `:=`(
            address = as.character(address),
            memo = as.character(memo),
            chainId = as.character(chainId),
            to = as.character(to),
            expirationDate = as.numeric(expirationDate),
            currency = as.character(currency),
            contractAddress = as.character(contractAddress),
            chainName = as.character(chainName)
        )]

        return(result_dt[])
    }, error = function(e) {
        rlang::abort(paste("Error in get_deposit_address_v3_impl:", conditionMessage(e)))
    })
})

#' Get Deposit History
#'
#' Retrieves a paginated list of deposit records from the KuCoin API asynchronously by sending a GET request to the `/api/v1/deposits` endpoint. This internal function is designed for use within an R6 class and is not intended for direct end-user consumption.
#'
#' ## API Details
#'
#' - **Domain**: Spot
#' - **API Channel**: Private
#' - **API Permission**: General
#' - **API Rate Limit Pool**: Management
#' - **API Rate Limit Weight**: 5
#' - **SDK Service**: Account
#' - **SDK Sub-Service**: Deposit
#' - **SDK Method Name**: `getDepositHistory`
#'
#' ## Description
#' This function retrieves deposit history records for a specified currency, with optional filtering by status and time range. Results are paginated and sorted to show the latest deposits first.
#'
#' ## Workflow Overview
#' 1. **Request Preparation**: Constructs query parameters including currency, status, time range, and pagination settings.
#' 2. **Timestamp Conversion**: Converts datetime objects to millisecond timestamps required by the KuCoin API.
#' 3. **Header Preparation**: Generates authentication headers asynchronously via `build_headers()`.
#' 4. **API Request**: Sends a GET request using `httr::GET()` with the constructed URL and headers, applying a 3-second timeout.
#' 5. **Pagination Handling**: Uses `auto_paginate()` to retrieve multiple pages of results if available.
#' 6. **Response Processing**: Converts the API response items into a structured `data.table` with proper column types.
#' 7. **Datetime Conversion**: Adds a human-readable `createdAtDatetime` column by converting the UNIX timestamp.
#'
#' ## API Endpoint
#' `GET https://api.kucoin.com/api/v1/deposits`
#'
#' ## Usage
#' This function is used internally to retrieve deposit history for specific currencies, optionally filtered by status and time range. It supports pagination to handle large result sets.
#'
#' ## Official Documentation
#' [KuCoin Get Deposit History](https://www.kucoin.com/docs-new/rest/account-info/deposit/get-deposit-history)
#'
#' ## Function Validated
#' - Last validated: 2025-02-24 19h43
#'
#' @param keys List containing API configuration parameters from `get_api_keys()`, including:
#'   - `api_key` (character): Your KuCoin API key.
#'   - `api_secret` (character): Your KuCoin API secret.
#'   - `api_passphrase` (character): Your KuCoin API passphrase.
#'   - `key_version` (character): API key version (e.g., `"2"`).
#'   Defaults to `get_api_keys()`.
#' @param base_url Character string representing the base URL for the API. Defaults to `get_base_url()`.
#' @param currency Character string; the currency for which to retrieve deposit history (e.g., `"BTC"`, `"ETH"`, `"USDT"`). **Required**.
#' @param status Character string (optional); filter deposits by status. Must be one of `"PROCESSING"`, `"SUCCESS"`, or `"FAILURE"`.
#' @param startAt POSIXct/POSIXlt datetime object (optional); the start time for filtering deposits by creation time. Must be a lubridate datetime object.
#' @param endAt POSIXct/POSIXlt datetime object (optional); the end time for filtering deposits by creation time. Must be a lubridate datetime object.
#' @param page_size Numeric; number of results per page (min: 10, max: 500). Defaults to 50.
#' @param max_pages Numeric; maximum number of pages to fetch. Defaults to `Inf` (all available pages).
#'
#' @return A promise resolving to a `data.table` containing deposit records with the following columns:
#'   - `currency` (character): Currency of the deposit (e.g., `"BTC"`, `"USDT"`).
#'   - `chain` (character): Blockchain network used for the deposit (e.g., `"ERC20"`, `"BTC-Segwit"`, `"TRC20"`, `"BEP20"`, `"ARBITRUM"`, `"TON"`, `"OPTIMISM"`).
#'   - `status` (character): Status of the deposit (`"PROCESSING"`, `"SUCCESS"`, or `"FAILURE"`).
#'   - `address` (character): Deposit address.
#'   - `memo` (character): Memo or tag associated with the deposit (if applicable).
#'   - `isInner` (logical): Whether it was an internal transfer.
#'   - `amount` (numeric): Deposit amount.
#'   - `fee` (numeric): Fee charged for the deposit.
#'   - `walletTxId` (character): Transaction ID on the blockchain.
#'   - `createdAt` (numeric): Creation timestamp in milliseconds since epoch.
#'   - `createdAt_Datetime` (POSIXct): Human-readable datetime converted from `createdAt`.
#'   - `updatedAt` (numeric): Last update timestamp in milliseconds since epoch.
#'   - `updatedAt_Datetime` (POSIXct): Human-readable datetime converted from `updatedAt`.
#'   - `remark` (character): Additional remarks.
#'   - `arrears` (logical): Whether there is any debt. A quick rollback will cause the deposit to fail. If the deposit fails, you will need to repay the balance.
#'   - `page_currentPage` (integer): Current page number.
#'   - `page_pageSize` (integer): Number of results per page.
#'   - `page_totalNum` (integer): Total number of records.
#'   - `page_totalPage` (integer): Total number of pages.
#'
#'   If no deposits are found for the specified criteria, an empty `data.table` with these columns is returned.
#'
#' ## Details
#'
#' ### Query Parameters
#' - `currency` (string, **required**): The currency for which to retrieve deposit history (e.g., `"BTC"`, `"USDT"`).
#' - `status` (string, optional): Filter deposits by status. Allowed values: `"PROCESSING"`, `"SUCCESS"`, or `"FAILURE"`.
#' - `startAt` (integer, optional): Start time in milliseconds since epoch.
#' - `endAt` (integer, optional): End time in milliseconds since epoch.
#' - `currentPage` (integer, optional): Current request page.
#' - `pageSize` (integer, optional): Number of results per request (min: 10, max: 500).
#'
#' **Example Request URL**:
#' ```http
#' GET https://api.kucoin.com/api/v1/deposits?currency=BTC&status=SUCCESS&startAt=1645839746000&endAt=1740447746000&currentPage=1&pageSize=50
#' ```
#'
#' ### Response Schema
#' - `code` (string): Status code, where `"200000"` indicates success.
#' - `data` (object): Contains:
#'   - `currentPage` (integer): Current page.
#'   - `pageSize` (integer): Page size.
#'   - `totalNum` (integer): Total number of records.
#'   - `totalPage` (integer): Total number of pages.
#'   - `items` (array of objects): Each object contains:
#'     - `currency` (string): Currency of the deposit.
#'     - `chain` (string): The blockchain network used.
#'     - `status` (string): Status of the deposit.
#'     - `address` (string): Deposit address.
#'     - `memo` (string): Address remark or tag (may be empty).
#'     - `isInner` (boolean): Whether it was an internal transfer.
#'     - `amount` (string): Deposit amount.
#'     - `fee` (string): Fee charged for the deposit.
#'     - `walletTxId` (string): Transaction ID on the blockchain.
#'     - `createdAt` (integer): Creation timestamp in milliseconds.
#'     - `updatedAt` (integer): Last update timestamp in milliseconds.
#'     - `remark` (string): Additional remarks.
#'     - `arrears` (boolean): Whether there is any debt.
#'
#' **Example JSON Response**:
#' ```json
#' {
#'   "code": "200000",
#'   "data": {
#'     "currentPage": 1,
#'     "pageSize": 50,
#'     "totalNum": 2,
#'     "totalPage": 1,
#'     "items": [
#'       {
#'         "currency": "BTC",
#'         "chain": "btc",
#'         "status": "SUCCESS",
#'         "address": "37rbVKjSv4pJhXwSmboTBFL4XfsuMQJAw9",
#'         "memo": "",
#'         "isInner": false,
#'         "amount": "0.02613141",
#'         "fee": "0.00000000",
#'         "walletTxId": "7353c4fe07b1948a77cfd7beae7832e7fe45d42523436dc5c365a60155328320",
#'         "createdAt": 1655593774000,
#'         "updatedAt": 1655594083000,
#'         "remark": "Deposit",
#'         "arrears": false
#'       },
#'       {
#'         "currency": "BTC",
#'         "chain": "btc",
#'         "status": "SUCCESS",
#'         "address": "37rbVKjSv4pJhXwSmboTBFL4XfsuMQJAw9",
#'         "memo": "",
#'         "isInner": false,
#'         "amount": "0.00052079",
#'         "fee": "0.00000000",
#'         "walletTxId": "86ff926d5385a0e5e9c670bebe105d7787e8919867cff7b8ad0bc0b00e0f204e",
#'         "createdAt": 1655592533000,
#'         "updatedAt": 1655593719000,
#'         "remark": "Deposit",
#'         "arrears": false
#'       }
#'     ]
#'   }
#' }
#' ```
#'
#' The function processes this response by:
#' - Extracting the `"items"` array from the `"data"` object.
#' - Converting it to a `data.table`, with each object in the array becoming a row.
#' - Adding a `createdAt_Datetime` column by converting the UNIX timestamp to a human-readable datetime.
#' - Ensuring proper column types for all fields.
#'
#' ## Notes
#' - **Time Range**: Use `startAt` and `endAt` parameters to narrow down the time range of deposits.
#' - **Status Filtering**: Filter by `status` to show only successful deposits or deposits in processing.
#' - **Pagination**: Results are paginated and sorted to show the latest first. Use `max_pages` to limit the number of pages retrieved.
#' - **Integer Overflow**: The function automatically handles large millisecond timestamps by converting them to character strings to prevent integer overflow in R.
#'
#' @examples
#' \dontrun{
#' # Example: Retrieve BTC deposit history from the last 3 months with SUCCESS status
#' keys <- get_api_keys()
#' base_url <- get_base_url()
#' main_async <- coro::async(function() {
#'   three_months_ago <- lubridate::now() - lubridate::months(3)
#'   current_time <- lubridate::now()
#'
#'   history <- await(get_deposit_history_impl(
#'     keys = keys,
#'     base_url = base_url,
#'     currency = "BTC",
#'     status = "SUCCESS",
#'     startAt = three_months_ago,
#'     endAt = current_time,
#'     page_size = 50
#'   ))
#'   print(history)
#' })
#' main_async()
#' while (!later::loop_empty()) later::run_now()
#' }
#'
#' @importFrom coro async await
#' @importFrom httr GET timeout
#' @importFrom data.table rbindlist
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

    # Validate datetime inputs
    if (!is.null(startAt) && !inherits(startAt, c("POSIXct", "POSIXlt", "Date"))) {
        rlang::abort("startAt must be a lubridate datetime object")
    }
    if (!is.null(endAt) && !inherits(endAt, c("POSIXct", "POSIXlt", "Date"))) {
        rlang::abort("endAt must be a lubridate datetime object")
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
            file_name <- paste0("get_deposit_history_impl-", query$currentPage)
            saveRDS(response, paste0("../../api-responses/impl_account_deposit/response-", file_name, ".ignore.Rds"))
            parsed_response <- process_kucoin_response(response, url)
            saveRDS(parsed_response, paste0("../../api-responses/impl_account_deposit/parsed_response-", file_name, ".Rds"))
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

        # Process startAt datetime
        if (!is.null(startAt)) {
            # Convert datetime to millisecond timestamp
            start_ms <- time_convert_to_kucoin(startAt, "ms")
            # Convert to character to avoid integer overflow
            initial_query$startAt <- as.character(round(start_ms))
        }

        # Process endAt datetime
        if (!is.null(endAt)) {
            # Convert datetime to millisecond timestamp
            end_ms <- time_convert_to_kucoin(endAt, "ms")
            # Convert to character to avoid integer overflow
            initial_query$endAt <- as.character(round(end_ms))
        }

        results <- await(auto_paginate(
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
                        createdAt_datetime = lubridate::as_datetime(character(0)),
                        updatedAt = integer(0),
                        updatedAt_datetime = lubridate::as_datetime(character(0)),
                        remark = character(0),
                        arrears = logical(0),
                        # pagination fields
                        page_currentPage = integer(0),
                        page_pageSize = integer(0),
                        page_totalNum = integer(0),
                        page_totalPage = integer(0)
                    ))
                }
                # Pre-process list to convert NULLs to NA or empty values
                acc2 <- lapply(acc, function(item) {
                    # Ensure all possible NULL fields exist, replacing with NA
                    if (is.null(item$subStatus)) item$subStatus <- NA_character_
                    if (is.null(item$url)) item$url <- NA_character_
                    return(item)
                })

                # Create data.table with fill=TRUE to handle any missing columns
                result_dt1 <- data.table::rbindlist(acc2)

                # Add the datetime column
                result_dt1[, createdAt_Datetime := time_convert_from_kucoin(createdAt, "ms")]

                return(result_dt1[])
            },
            max_pages = max_pages
        ))

        agg <- results$aggregate

        agg[, `:=`(
            currency = as.character(currency),
            chain = as.character(chain),
            status = as.character(status),
            address = as.character(address),
            memo = as.character(memo),
            isInner = as.logical(isInner),
            amount = as.numeric(amount),
            fee = as.numeric(fee),
            walletTxId = as.character(walletTxId),
            createdAt = as.numeric(createdAt),
            createdAt_datetime = time_convert_from_kucoin(createdAt, "ms"),
            updatedAt = as.numeric(updatedAt),
            updatedAt_datetime = time_convert_from_kucoin(updatedAt, "ms"),
            remark = as.character(remark),
            arrears = as.logical(arrears),
            # pagination fields
            page_currentPage = as.integer(page_currentPage),
            page_pageSize = as.integer(page_pageSize),
            page_totalNum = as.integer(page_totalNum),
            page_totalPage = as.integer(page_totalPage)
        )]

        return(agg[])
    }, error = function(e) {
        rlang::abort(paste("Error in get_deposit_history_impl:", conditionMessage(e)))
    })
})
