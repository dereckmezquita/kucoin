# File: ./R/impl_account_sub_account.R

box::use(
    ./helpers_api[ auto_paginate, build_headers, process_kucoin_response ],
    ./utils[ build_query, get_base_url ],
    ./utils_time_convert_kucoin[ time_convert_from_kucoin ]
)

#' Add Sub-Account (Implementation)
#'
#' Creates a new sub-account on KuCoin asynchronously by sending a POST request to the `/api/v2/sub/user/created` endpoint. This internal function is designed for use within an R6 class and is not intended for direct end-user consumption.
#'
#' ## API Details
#' 
#' - **Domain**: Spot
#' - **API Channel**: Private
#' - **API Permission**: General
#' - **API Rate Limit Pool**: Management
#' - **API Rate Limit Weight**: 15
#' - **SDK Service**: Account
#' - **SDK Sub-Service**: SubAccount
#' - **SDK Method Name**: `addSubAccount`
#'
#' ## Description
#' This function creates a new sub-account with specified permissions and credentials, facilitating segmented account management within a master KuCoin account structure.
#'
#' ## Workflow Overview
#' 1. **Request Validation**: Validates the `access` parameter against allowed values (`"Spot"`, `"Futures"`, `"Margin"`).
#' 2. **URL Construction**: Combines the base URL with the endpoint `/api/v2/sub/user/created`.
#' 3. **Request Body Preparation**: Creates a JSON payload with required parameters (`password`, `subName`, `access`) and optional `remarks`.
#' 4. **Header Preparation**: Generates authentication headers asynchronously via `build_headers()`, incorporating the signature, timestamp, encrypted passphrase, and API key details.
#' 5. **API Request**: Sends a POST request using `httr::POST()` with the constructed URL, headers, and JSON body, applying a 3-second timeout.
#' 6. **Response Handling**: Processes the JSON response with `process_kucoin_response()`, raising an error if the HTTP status is not 200 or the API code is not `"200000"`.
#' 7. **Result Conversion**: Extracts and converts the `data` field of the successful response into a `data.table` for structured access.
#'
#' ## API Endpoint
#' `POST https://api.kucoin.com/api/v2/sub/user/created`
#'
#' ## Usage
#' This function is used internally to establish sub-accounts for managing separate trading permissions within the KuCoin ecosystem, enabling segregated trading activities under a single master account.
#'
#' ## Official Documentation
#' [KuCoin Add Sub-Account](https://www.kucoin.com/docs-new/rest/account-info/sub-account/add-subaccount)
#' 
#' ## Function Validated
#' - Last validated: 2025-02-25 22h26
#'
#' @param keys List containing API configuration parameters from `get_api_keys()`, including:
#'   - `api_key` (character): Your KuCoin API key.
#'   - `api_secret` (character): Your KuCoin API secret.
#'   - `api_passphrase` (character): Your KuCoin API passphrase.
#'   - `key_version` (character): API key version (e.g., `"2"`).
#'   Defaults to `get_api_keys()`.
#' @param base_url Character string representing the base URL for the API. Defaults to `get_base_url()`.
#' @param password Character string; sub-account password (7–24 characters, must contain both letters and numbers, cannot only contain numbers or include special characters).
#' @param subName Character string; desired sub-account name (7–32 characters, must include at least one letter and one number, no spaces).
#' @param access Character string; permission type for the sub-account. One of: `"Spot"`, `"Futures"`, `"Margin"`. Defaults to `"Spot"` if not specified.
#' @param remarks Character string (optional); remarks or notes about the sub-account (1–24 characters if provided).
#'
#' @return Promise resolving to a `data.table` containing sub-account details, including:
#'   - `uid` (numeric): Unique identifier for the sub-account.
#'   - `subName` (character): Name of the sub-account.
#'   - `remarks` (character): Remarks or notes associated with the sub-account.
#'   - `access` (character): Permission type granted to the sub-account.
#'
#' ## Details
#'
#' ### Request Body Schema
#' The request body is a JSON object with the following fields:
#' - `password` (string, **required**): Password (7–24 characters, must contain letters and numbers, cannot only contain numbers or include special characters).
#' - `subName` (string, **required**): Sub-account name (must contain 7–32 characters, at least one number and one letter, no spaces).
#' - `access` (string, **required**): Permission type. One of: `"Spot"`, `"Futures"`, `"Margin"`.
#' - `remarks` (string, optional): Remarks or notes (1–24 characters).
#'
#' **Example Request Body**:
#' ```json
#' {
#'   "password": "1234567",
#'   "remarks": "TheRemark",
#'   "subName": "Name1234567",
#'   "access": "Spot"
#' }
#' ```
#'
#' ### Response Schema
#' - `code` (string): Status code, where `"200000"` indicates success.
#' - `data` (object): Contains pagination metadata and an `items` array with the sub-account details.
#'   - `uid` (integer): Unique identifier for the sub-account.
#'   - `subName` (string): Name of the sub-account.
#'   - `remarks` (string): Remarks or notes associated with the sub-account.
#'   - `access` (string): Permission type granted to the sub-account.
#'
#' **Example JSON Response**:
#' ```json
#' {
#'     "code": "200000",
#'     "data": {
#'         "currentPage": 1,
#'         "pageSize": 10,
#'         "totalNum": 1,
#'         "totalPage": 1,
#'         "items": [
#'             {
#'                 "userId": "63743f07e0c5230001761d08",
#'                 "uid": 169579801,
#'                 "subName": "testapi6",
#'                 "status": 2,
#'                 "type": 0,
#'                 "access": "All",
#'                 "createdAt": 1668562696000,
#'                 "remarks": "remarks",
#'                 "tradeTypes": [
#'                     "Spot",
#'                     "Futures",
#'                     "Margin"
#'                 ],
#'                 "openedTradeTypes": [
#'                     "Spot"
#'                 ],
#'                 "hostedStatus": null
#'             }
#'         ]
#'     }
#' }
#' ```
#'
#' The function processes this response by extracting the `"data"` field and converting it to a structured `data.table`.
#'
#' ## Notes
#' - **Password Requirements**: The sub-account password must be 7-24 characters long, containing both letters and numbers. It cannot consist solely of numbers or include special characters.
#' - **Sub-Account Name Requirements**: The name must be 7-32 characters, containing at least one letter and one number, with no spaces.
#' - **Access Types**: The `access` parameter determines which trading features the sub-account can use (`"Spot"`, `"Futures"`, `"Margin"`).
#' - **Rate Limit**: This endpoint has a weight of 15 in the API rate limit pool (Management). Plan request frequency accordingly.
#'
#' @examples
#' \dontrun{
#' # Example: Create a new sub-account with Spot trading permission
#' keys <- get_api_keys()
#' base_url <- "https://api.kucoin.com"
#' main_async <- coro::async(function() {
#'   result <- await(add_subaccount_impl(
#'     keys = keys,
#'     base_url = base_url,
#'     password = "SecurePass123",
#'     subName = "TradingBot2025",
#'     access = "Spot",
#'     remarks = "Automated trading account"
#'   ))
#'   print(result)
#' })
#' main_async()
#' while (!later::loop_empty()) later::run_now()
#' }
#'
#' @importFrom coro async await
#' @importFrom jsonlite toJSON
#' @importFrom httr POST timeout
#' @importFrom data.table as.data.table
#' @importFrom rlang abort
#' @export
add_subaccount_impl <- coro::async(function(
    keys = get_api_keys(),
    base_url = get_base_url(),
    password,
    subName,
    access = c("Spot", "Futures", "Margin"),
    remarks = NULL
) {
    access <- rlang::arg_match0(access, values = c("Spot", "Futures", "Margin"))
    tryCatch({
        endpoint <- "/api/v2/sub/user/created"
        method <- "POST"
        body_list <- list(
            password = password,
            subName = subName,
            access = access
        )
        if (!is.null(remarks)) {
            body_list$remarks <- remarks
        }
        body <- jsonlite::toJSON(body_list, auto_unbox = TRUE)
        headers <- await(build_headers(method, endpoint, body, keys))
        url <- paste0(base_url, endpoint)
        response <- httr::POST(url, headers, body = body, encode = "raw", httr::timeout(3))
        # saveRDS(response, "../../api-responses/impl_account_sub_account/response-add_subaccount_impl.ignore.Rds")
        parsed_response <- process_kucoin_response(response, url)
        # saveRDS(parsed_response, "../../api-responses/impl_account_sub_account/parsed_response-add_subaccount_impl.Rds")
        return(data.table::as.data.table(parsed_response$data))
    }, error = function(e) {
        rlang::abort(paste("Error in add_subaccount_impl:", conditionMessage(e)))
    })
})

#' Retrieve Sub-Account Summary Information (Implementation)
#'
#' Retrieves a paginated summary of sub-accounts from KuCoin asynchronously and aggregates the results into a single `data.table`. This internal function is designed for use within an R6 class and is not intended for direct end-user consumption. It converts millisecond timestamps in the `createdAt` column to human-readable POSIXct datetime objects where present.
#'
#' ### Workflow Overview
#' 1. **Pagination Initialisation**: Begins by setting an initial query with `currentPage = 1` and the specified `page_size`.
#' 2. **Page Fetching**: Defines an asynchronous helper function (`fetch_page`) to send a GET request for a given page, constructing the URL with current query parameters and authentication headers.
#' 3. **Automatic Pagination**: Leverages `auto_paginate` to repeatedly call `fetch_page`, aggregating results until all pages are retrieved or `max_pages` is reached.
#' 4. **Aggregation and Datetime Conversion**: Combines responses into a `data.table` using `data.table::rbindlist()`, converting `createdAt` timestamps to POSIXct in a new `createdDatetime` column if present.
#'
#' ### API Endpoint
#' `GET https://api.kucoin.com/api/v2/sub/user`
#'
#' ### Usage
#' Utilised internally to provide a comprehensive summary of all sub-accounts associated with a KuCoin master account.
#'
#' ### Official Documentation
#' [KuCoin Get Sub-Account List Summary Info](https://www.kucoin.com/docs-new/rest/account-info/sub-account/get-subaccount-list-summary-info)
#'
#' @param keys List containing API configuration parameters from `get_api_keys()`, including:
#'   - `api_key`: Character string; your KuCoin API key.
#'   - `api_secret`: Character string; your KuCoin API secret.
#'   - `api_passphrase`: Character string; your KuCoin API passphrase.
#'   - `key_version`: Character string; API key version (e.g., `"2"`).
#'   Defaults to `get_api_keys()`.
#' @param base_url Character string representing the base URL for the API. Defaults to `get_base_url()`.
#' @param page_size Integer specifying the number of results per page (minimum 1, maximum 100). Defaults to 100.
#' @param max_pages Numeric specifying the maximum number of pages to fetch (defaults to `Inf`, fetching all available pages).
#' @return Promise resolving to a `data.table` containing aggregated sub-account summary information, including:
#'   - `userId` (character): Unique identifier of the master account.
#'   - `uid` (integer): Unique identifier of the sub-account.
#'   - `subName` (character): Sub-account name.
#'   - `status` (integer): Current status of the sub-account.
#'   - `type` (integer): Type of sub-account.
#'   - `access` (character): Permission type granted (e.g., `"All"`, `"Spot"`, `"Futures"`, `"Margin"`).
#'   - `createdAt` (integer): Timestamp of creation in milliseconds.
#'   - `createdDatetime` (POSIXct): Converted human-readable datetime.
#'   - `remarks` (character): Remarks or notes associated with the sub-account.
#'   - `tradeTypes` (character): Separated by `;`, the trade types available to the sub-account (e.g. `"Spot;Futures;Margin"`).
#'   - `openedTradeTypes` (character): Separated by `;`, the trade types currently open to the sub-account.
#'   - `hostedStatus` (character): Hosted status of the sub-account.
#'
#' @details
#' **Raw Response Schema**:  
#' - `code` (string): Status code, where `"200000"` indicates success.  
#' - `data` (object): Contains pagination metadata and an `items` array with sub-account summary details.  
#' 
#' Example JSON response:  
#' ```
#' {
#'     "code": "200000",
#'     "data": {
#'         "currentPage": 1,
#'         "pageSize": 10,
#'         "totalNum": 1,
#'         "totalPage": 1,
#'         "items": [
#'             {
#'                 "userId": "63743f07e0c5230001761d08",
#'                 "uid": 169579801,
#'                 "subName": "testapi6",
#'                 "status": 2,
#'                 "type": 0,
#'                 "access": "All",
#'                 "createdAt": 1668562696000,
#'                 "remarks": "remarks",
#'                 "tradeTypes": ["Spot", "Futures", "Margin"],
#'                 "openedTradeTypes": ["Spot"],
#'                 "hostedStatus": null
#'             }
#'         ]
#'     }
#' }
#' ```
#' @examples
#' \dontrun{
#' keys <- get_api_keys()
#' base_url <- "https://api.kucoin.com"
#' main_async <- coro::async(function() {
#'   dt_all <- await(get_subaccount_list_summary_impl(
#'     keys = keys,
#'     base_url = base_url
#'   ))
#'   print(dt_all)
#'   dt_partial <- await(get_subaccount_list_summary_impl(
#'     keys = keys,
#'     base_url = base_url,
#'     page_size = 50,
#'     max_pages = 3
#'   ))
#'   print(dt_partial)
#' })
#' main_async()
#' while (!later::loop_empty()) later::run_now(timeoutSecs = Inf, all = TRUE)
#' }
#' @importFrom coro async await
#' @importFrom httr GET timeout
#' @importFrom data.table rbindlist as.data.table
#' @importFrom rlang abort
#' @export
get_subaccount_list_summary_impl <- coro::async(function(
    keys = get_api_keys(),
    base_url = get_base_url(),
    page_size = 100,
    max_pages = Inf
) {
    tryCatch({
        fetch_page <- coro::async(function(query) {
            endpoint <- "/api/v2/sub/user"
            method <- "GET"
            body <- ""
            qs <- build_query(query)
            full_endpoint <- paste0(endpoint, qs)
            headers <- await(build_headers(method, full_endpoint, body, keys))
            url <- paste0(base_url, full_endpoint)
            response <- httr::GET(url, headers, httr::timeout(3))
            file_name <- paste0("get_subaccount_list_summary_impl_", query$currentPage)
            # saveRDS(response, "./api-responses/impl_account_sub_account/response-get_subaccount_list_summary_impl.ignore.Rds")
            parsed_response <- process_kucoin_response(response, url)
            # saveRDS(parsed_response, "./api-responses/impl_account_sub_account/parsed_response-get_subaccount_list_summary_impl.Rds")
            return(parsed_response$data)
        })

        # Initialize the query with the first page.
        initial_query <- list(currentPage = 1, pageSize = page_size)

        # TOOD: updated return signature
        subaccount_summary_dt <- await(auto_paginate(
            fetch_page = fetch_page,
            query = initial_query,
            items_field = "items",
            paginate_fields = list(
                currentPage = "currentPage",
                totalPage = "totalPage"
            ),
            aggregate_fn = function(acc) {
                els <- lapply(acc, function(el) {
                    # collapse certain fields into a single string
                    el$tradeTypes <- paste(el$tradeTypes, collapse = ";")
                    el$openTradeTypes <- paste(el$openTradeTypes, collapse = ";")
                    if (is.null(el$remarks)) {
                        el$remarks <- NA_character_
                    }
                    return(el)
                })
                # rbindlist can convert list of lists to data.table
                return(data.table::rbindlist(els))
            },
            max_pages = max_pages
        ))

        subaccount_summary_dt[, createdDatetime := time_convert_from_kucoin(createdAt, "ms")]

        return(subaccount_summary_dt)
    }, error = function(e) {
        rlang::abort(paste("Error in get_subaccount_list_summary_impl:", conditionMessage(e)))
    })
})

#' Retrieve Sub-Account Balance Details (Implementation)
#'
#' Retrieves balance details for a specific sub-account from KuCoin asynchronously, aggregating account types into a single `data.table`. This internal function is designed for use within an R6 class and is not intended for direct end-user consumption.
#'
#' ### Workflow Overview
#' 1. **URL and Query String Construction**: Constructs the endpoint URL by appending `subUserId` to `/api/v1/sub-accounts/` and adding the `includeBaseAmount` query parameter (defaulting to `FALSE`).
#' 2. **Header Generation**: Generates authentication headers asynchronously via `build_headers()`.
#' 3. **HTTP Request**: Sends a GET request to the constructed URL with a 3-second timeout using `httr::GET()`.
#' 4. **Response Processing**: Parses the JSON response with `process_kucoin_response()`, converting each non-empty account type array (`mainAccounts`, `tradeAccounts`, `marginAccounts`, `tradeHFAccounts`) into a `data.table` with an added `accountType` column.
#' 5. **Aggregation and Metadata Addition**: Aggregates all non-empty `data.table`s into a single `data.table` using `data.table::rbindlist()`, appending `subUserId` and `subName` to each row.
#'
#' ### API Endpoint
#' `GET https://api.kucoin.com/api/v1/sub-accounts/{subUserId}?includeBaseAmount={includeBaseAmount}`
#'
#' ### Usage
#' Utilised internally to provide detailed balance information across various account categories for a specified sub-account.
#'
#' ### Official Documentation
#' [KuCoin Get Sub-Account Detail Balance](https://www.kucoin.com/docs-new/rest/account-info/sub-account/get-subaccount-detail-balance)
#'
#' @param keys List containing API configuration parameters from `get_api_keys()`, including:
#'   - `api_key`: Character string; your KuCoin API key.
#'   - `api_secret`: Character string; your KuCoin API secret.
#'   - `api_passphrase`: Character string; your KuCoin API passphrase.
#'   - `key_version`: Character string; API key version (e.g., `"2"`).
#'   Defaults to `get_api_keys()`.
#' @param base_url Character string representing the base URL for the API. Defaults to `get_base_url()`.
#' @param subUserId Character string representing the sub-account user ID for which balance details are retrieved.
#' @param includeBaseAmount Logical flag indicating whether to include currencies with a zero balance in the response. Defaults to `FALSE`.
#' @return Promise resolving to a `data.table` containing detailed balance information for the specified sub-account, with columns including:
#'   - `subUserId` (character): Sub-account user ID.
#'   - `subName` (character): Sub-account name.
#'   - `currency` (character): Currency code.
#'   - `balance` (numeric): Total balance.
#'   - `available` (numeric): Amount available for trading or withdrawal.
#'   - `holds` (numeric): Amount locked or held.
#'   - `baseCurrency` (character): Base currency code.
#'   - `baseCurrencyPrice` (numeric): Price of the base currency.
#'   - `baseAmount` (numeric): Amount in the base currency.
#'   - `tag` (character): Tag associated with the account.
#'   - `accountType` (character): Source account type (e.g., `"mainAccounts"`, `"tradeAccounts"`, `"marginAccounts"`, `"tradeHFAccounts"`).
#' @details
#' **Raw Response Schema**:  
#' - `code` (string): Status code, where `"200000"` indicates success.  
#' - `data` (object): Contains `subUserId`, `subName`, and arrays for `mainAccounts`, `tradeAccounts`, `marginAccounts`, and `tradeHFAccounts`.  
#' 
#' KuCoin's API docs list this as the return data schema:
#' ```
#' {
#'     "code": "200000",
#'     "data": {
#'         "subUserId": "63743f07e0c5230001761d08",
#'         "subName": "testapi6",
#'         "mainAccounts": [
#'             {
#'                 "currency": "USDT",
#'                 "balance": "0.01",
#'                 "available": "0.01",
#'                 "holds": "0",
#'                 "baseCurrency": "BTC",
#'                 "baseCurrencyPrice": "62384.3",
#'                 "baseAmount": "0.00000016",
#'                 "tag": "DEFAULT"
#'             }
#'         ],
#'         "tradeAccounts": [
#'             {
#'                 "currency": "USDT",
#'                 "balance": "0.01",
#'                 "available": "0.01",
#'                 "holds": "0",
#'                 "baseCurrency": "BTC",
#'                 "baseCurrencyPrice": "62384.3",
#'                 "baseAmount": "0.00000016",
#'                 "tag": "DEFAULT"
#'             }
#'         ],
#'         "marginAccounts": [
#'             {
#'                 "currency": "USDT",
#'                 "balance": "0.01",
#'                 "available": "0.01",
#'                 "holds": "0",
#'                 "baseCurrency": "BTC",
#'                 "baseCurrencyPrice": "62384.3",
#'                 "baseAmount": "0.00000016",
#'                 "tag": "DEFAULT"
#'             }
#'         ],
#'         "tradeHFAccounts": []
#'     }
#' }
#' ```
#' @examples
#' \dontrun{
#' keys <- get_api_keys()
#' base_url <- "https://api.kucoin.com"
#' subUserId <- "63743f07e0c5230001761d08"
#' main_async <- coro::async(function() {
#'   dt <- await(get_subaccount_detail_balance_impl(
#'     keys = keys,
#'     base_url = base_url,
#'     subUserId = subUserId,
#'     includeBaseAmount = TRUE
#'   ))
#'   print(dt)
#' })
#' main_async()
#' while (!later::loop_empty()) later::run_now()
#' }
#' @importFrom coro async await
#' @importFrom httr GET timeout
#' @importFrom data.table as.data.table rbindlist
#' @importFrom rlang abort
#' @export
get_subaccount_detail_balance_impl <- coro::async(function(
    keys = get_api_keys(),
    base_url = get_base_url(),
    subUserId,
    includeBaseAmount = FALSE
) {
    if (is.null(subUserId) || !is.character(subUserId)) {
        if (length(subUserId) != 1) {
            rlang::abort("subUserId must be a scalar character string")
        }
    }
    tryCatch({
        # Construct the endpoint URL with the query parameter.
        endpoint <- paste0("/api/v1/sub-accounts/", subUserId)
        query <- list(includeBaseAmount = includeBaseAmount)
        qs <- build_query(query)
        full_endpoint <- paste0(endpoint, qs)

        # Set method and empty body.
        method <- "GET"
        body <- ""

        # Generate authentication headers.
        headers <- await(build_headers(method, full_endpoint, body, keys))
        url <- paste0(base_url, full_endpoint)

        # Send the GET request.
        response <- httr::GET(url, headers, httr::timeout(3))
        # saveRDS(response, "./api-responses/impl_account_sub_account/response-get_subaccount_detail_balance_impl.ignore.Rds")
        parsed_response <- process_kucoin_response(response, url)
        # saveRDS(parsed_response, "./api-responses/impl_account_sub_account/parsed_response-get_subaccount_detail_balance_impl.Rds")

        data <- parsed_response$data

        # Initialize a list to collect data.tables for each account type.
        result_list <- list()

        # Process each account type array if present and non-empty.
        if (!is.null(data$mainAccounts) && length(data$mainAccounts) > 0) {
            dt_main <- data.table::rbindlist(data$mainAccounts)
            dt_main[, accountType := "mainAccounts"]
            result_list[[length(result_list) + 1]] <- dt_main
        }
        if (!is.null(data$tradeAccounts) && length(data$tradeAccounts) > 0) {
            dt_trade <- data.table::rbindlist(data$tradeAccounts)
            dt_trade[, accountType := "tradeAccounts"]
            result_list[[length(result_list) + 1]] <- dt_trade
        }
        if (!is.null(data$marginAccounts) && length(data$marginAccounts) > 0) {
            dt_margin <- data.table::rbindlist(data$marginAccounts)
            dt_margin[, accountType := "marginAccounts"]
            result_list[[length(result_list) + 1]] <- dt_margin
        }
        if (!is.null(data$tradeHFAccounts) && length(data$tradeHFAccounts) > 0) {
            dt_tradeHF <- data.table::rbindlist(data$tradeHFAccounts)
            dt_tradeHF[, accountType := "tradeHFAccounts"]
            result_list[[length(result_list) + 1]] <- dt_tradeHF
        }

        # Combine the results; if no data is available, return an empty data.table.
        if (length(result_list) == 0) {
            # TODO: update default empty data.table
            result_dt <- data.table::data.table(
                subUserId = character(0),
                subName = character(0),
                currency = character(0),
                balance = numeric(0),
                available = numeric(0),
                holds = numeric(0),
                baseCurrency = character(0),
                baseCurrencyPrice = numeric(0),
                baseAmount = numeric(0),
                tag = character(0),
                accountType = character(0)
            )
        } else {
            result_dt <- data.table::rbindlist(result_list)
        }

        # Append metadata (subUserId and subName) from the parent response.
        result_dt[, subUserId := parsed_response$data$subUserId]
        result_dt[, subName := parsed_response$data$subName]

        data.table::setcolorder(result_dt, c("subUserId", "subName", setdiff(names(result_dt), c("subUserId", "subName"))))

        # cast numeric types
        result_dt[, `:=`(
            balance = as.numeric(balance),
            available = as.numeric(available),
            holds = as.numeric(holds),
            baseCurrencyPrice = as.numeric(baseCurrencyPrice),
            baseAmount = as.numeric(baseAmount)
        )]

        return(result_dt)
    }, error = function(e) {
        rlang::abort(paste("Error in get_subaccount_detail_balance_impl:", conditionMessage(e)))
    })
})

#' Retrieve Spot Sub-Account List - Balance Details (V2) (Implementation)
#'
#' Retrieves paginated Spot sub-account information from KuCoin asynchronously, aggregating balance details into a single `data.table`. This internal function is designed for use within an R6 class and is not intended for direct end-user consumption.
#'
#' ### Workflow Overview
#' 1. **Pagination Initialisation**: Sets an initial query with `currentPage = 1` and the specified `page_size`.
#' 2. **Page Fetching**: Defines an asynchronous helper function (`fetch_page`) to send a GET request for a given page, constructing the URL with current query parameters and authentication headers.
#' 3. **Automatic Pagination**: Leverages `auto_paginate` to repeatedly call `fetch_page`, aggregating results until all pages are retrieved or `max_pages` is reached.
#' 4. **Aggregation**: Processes each sub-account's account type arrays, converting them into `data.table`s with an added `accountType` column, and combines them into a single `data.table` with `subUserId` and `subName`.
#'
#' ### API Endpoint
#' `GET https://api.kucoin.com/api/v2/sub-accounts`
#'
#' ### Usage
#' Utilised internally to provide detailed balance information for all sub-accounts associated with a KuCoin master account.
#'
#' ### Official Documentation
#' [KuCoin Get Sub-Account List - Spot Balance (V2)](https://www.kucoin.com/docs-new/rest/account-info/sub-account/get-subaccount-list-spot-balance-v2)
#'
#' @param keys List containing API configuration parameters from `get_api_keys()`, including:
#'   - `api_key`: Character string; your KuCoin API key.
#'   - `api_secret`: Character string; your KuCoin API secret.
#'   - `api_passphrase`: Character string; your KuCoin API passphrase.
#'   - `key_version`: Character string; API key version (e.g., `"2"`).
#'   Defaults to `get_api_keys()`.
#' @param base_url Character string representing the base URL for the API. Defaults to `get_base_url()`.
#' @param page_size Integer specifying the number of results per page (minimum 10, maximum 100). Defaults to 100.
#' @param max_pages Numeric specifying the maximum number of pages to fetch (defaults to `Inf`, fetching all available pages).
#' @return Promise resolving to a `data.table` containing aggregated sub-account balance information, with columns including:
#'   - `subUserId` (character): Sub-account user ID.
#'   - `subName` (character): Sub-account name.
#'   - `accountType` (character): Type of account (e.g., `"mainAccounts"`, `"tradeAccounts"`, `"marginAccounts"`, `"tradeHFAccounts"`).
#'   - `currency` (character): Currency code.
#'   - `balance` (numeric): Total balance.
#'   - `available` (numeric): Amount available for trading or withdrawal.
#'   - `holds` (numeric): Amount locked or held.
#'   - `baseCurrency` (character): Base currency code.
#'   - `baseCurrencyPrice` (numeric): Price of the base currency.
#'   - `baseAmount` (numeric): Amount in the base currency.
#'   - `tag` (character): Tag associated with the account.
#' @details
#' **Raw Response Schema**:  
#' - `code` (string): Status code, where `"200000"` indicates success.  
#' - `data` (object): Contains pagination metadata and an `items` array with sub-account details.  
#' 
#' Example JSON response:  
#' ```json
#' {
#'     "code": "200000",
#'     "data": {
#'         "currentPage": 1,
#'         "pageSize": 10,
#'         "totalNum": 3,
#'         "totalPage": 1,
#'         "items": [
#'             {
#'                 "subUserId": "63743f07e0c5230001761d08",
#'                 "subName": "testapi6",
#'                 "mainAccounts": [
#'                     {
#'                         "currency": "USDT",
#'                         "balance": "0.01",
#'                         "available": "0.01",
#'                         "holds": "0",
#'                         "baseCurrency": "BTC",
#'                         "baseCurrencyPrice": "62514.5",
#'                         "baseAmount": "0.00000015",
#'                         "tag": "DEFAULT"
#'                     }
#'                 ],
#'                 "tradeAccounts": [
#'                     {
#'                         "currency": "USDT",
#'                         "balance": "0.01",
#'                         "available": "0.01",
#'                         "holds": "0",
#'                         "baseCurrency": "BTC",
#'                         "baseCurrencyPrice": "62514.5",
#'                         "baseAmount": "0.00000015",
#'                         "tag": "DEFAULT"
#'                     }
#'                 ],
#'                 "marginAccounts": [
#'                     {
#'                         "currency": "USDT",
#'                         "balance": "0.01",
#'                         "available": "0.01",
#'                         "holds": "0",
#'                         "baseCurrency": "BTC",
#'                         "baseCurrencyPrice": "62514.5",
#'                         "baseAmount": "0.00000015",
#'                         "tag": "DEFAULT"
#'                     }
#'                 ],
#'                 "tradeHFAccounts": []
#'             },
#'             {
#'                 "subUserId": "670538a31037eb000115b076",
#'                 "subName": "Name1234567",
#'                 "mainAccounts": [],
#'                 "tradeAccounts": [],
#'                 "marginAccounts": [],
#'                 "tradeHFAccounts": []
#'             },
#'             {
#'                 "subUserId": "66b0c0905fc1480001c14c36",
#'                 "subName": "LTkucoin1491",
#'                 "mainAccounts": [],
#'                 "tradeAccounts": [],
#'                 "marginAccounts": [],
#'                 "tradeHFAccounts": []
#'             }
#'         ]
#'     }
#' }
#' ```
#' - The function handles pagination automatically, fetching all pages up to `max_pages`.
#' - Balance fields are converted from character to numeric types.
#' - Sub-accounts with no balance entries are not included in the resulting `data.table`.
#' @examples
#' \dontrun{
#' keys <- get_api_keys()
#' base_url <- "https://api.kucoin.com"
#' main_async <- coro::async(function() {
#'   dt <- await(get_spot_subaccount_list_v2_impl(
#'     keys = keys,
#'     base_url = base_url,
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
#' @importFrom data.table rbindlist as.data.table
#' @importFrom rlang abort
#' @export
get_subaccount_spot_v2_impl <- coro::async(function(
    keys = get_api_keys(),
    base_url = get_base_url(),
    page_size = 100,
    max_pages = Inf
) {
    tryCatch({
        # Define the fetch_page function to retrieve a specific page of sub-account data.
        fetch_page <- coro::async(function(query) {
            endpoint <- "/api/v2/sub-accounts"
            method <- "GET"
            body <- ""
            qs <- build_query(query)
            full_endpoint <- paste0(endpoint, "?", qs)
            headers <- await(build_headers(method, full_endpoint, body, keys))
            url <- paste0(base_url, full_endpoint)
            response <- httr::GET(url, headers, httr::timeout(3))
            parsed_response <- process_kucoin_response(response, url)
            return(parsed_response$data)
        })

        # Initialize the query with the first page.
        initial_query <- list(currentPage = 1, pageSize = page_size)

        # TOOD: updated return signature
        spot_subaccount_list_dt <- await(auto_paginate(
            fetch_page = fetch_page,
            query = initial_query,
            items_field = "items",
            paginate_fields = list(
                currentPage = "currentPage",
                totalPage = "totalPage"
            ),
            aggregate_fn = function(acc) {
                result_list <- list()
                for (sub in acc) {
                    sub_result_list <- list()
                    # Process mainAccounts if not empty.
                    if (!is.null(sub$mainAccounts) && length(sub$mainAccounts) > 0) {
                        dt_main <- data.table::rbindlist(sub$mainAccounts)
                        dt_main[, accountType := "mainAccounts"]
                        sub_result_list[[length(sub_result_list) + 1]] <- dt_main
                    }
                    # Process tradeAccounts if not empty.
                    if (!is.null(sub$tradeAccounts) && length(sub$tradeAccounts) > 0) {
                        dt_trade <- data.table::rbindlist(sub$tradeAccounts)
                        dt_trade[, accountType := "tradeAccounts"]
                        sub_result_list[[length(sub_result_list) + 1]] <- dt_trade
                    }
                    # Process marginAccounts if not empty.
                    if (!is.null(sub$marginAccounts) && length(sub$marginAccounts) > 0) {
                        dt_margin <- data.table::rbindlist(sub$marginAccounts)
                        dt_margin[, accountType := "marginAccounts"]
                        sub_result_list[[length(sub_result_list) + 1]] <- dt_margin
                    }
                    # Process tradeHFAccounts if not empty.
                    if (!is.null(sub$tradeHFAccounts) && length(sub$tradeHFAccounts) > 0) {
                        dt_tradeHF <- data.table::rbindlist(sub$tradeHFAccounts)
                        dt_tradeHF[, accountType := "tradeHFAccounts"]
                        sub_result_list[[length(sub_result_list) + 1]] <- dt_tradeHF
                    }
                    # Combine results for this sub-account if there are any balances.
                    if (length(sub_result_list) > 0) {
                        sub_dt <- data.table::rbindlist(sub_result_list, fill = TRUE)
                        sub_dt[, subUserId := sub$subUserId]
                        sub_dt[, subName := sub$subName]
                        result_list[[length(result_list) + 1]] <- sub_dt
                    }
                }
                # Combine all sub-account results; if empty, return an empty data.table.
                if (length(result_list) > 0) {
                    final_dt <- data.table::rbindlist(result_list, fill = TRUE)
                } else {
                    final_dt <- data.table::data.table(
                        subUserId = character(0),
                        subName = character(0),
                        accountType = character(0),
                        currency = character(0),
                        balance = numeric(0),
                        available = numeric(0),
                        holds = numeric(0),
                        baseCurrency = character(0),
                        baseCurrencyPrice = numeric(0),
                        baseAmount = numeric(0),
                        tag = character(0)
                    )
                }
                # Cast numeric columns.
                if (nrow(final_dt) > 0) {
                    final_dt[, `:=`(
                        balance = as.numeric(balance),
                        available = as.numeric(available),
                        holds = as.numeric(holds),
                        baseCurrencyPrice = as.numeric(baseCurrencyPrice),
                        baseAmount = as.numeric(baseAmount)
                    )]
                }
                # Set column order.
                data.table::setcolorder(final_dt, c(
                    "subUserId", "subName", "accountType", "currency",
                    "balance", "available", "holds", "baseCurrency",
                    "baseCurrencyPrice", "baseAmount", "tag"
                ))
                return(final_dt)
            },
            max_pages = max_pages
        ))

        return(spot_subaccount_list_dt)
    }, error = function(e) {
        rlang::abort(paste("Error in get_spot_subaccount_list_v2_impl:", conditionMessage(e)))
    })
})
