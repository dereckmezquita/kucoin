# File: ./R/impl_account_sub_account.R

# box::use(
#     ./helpers_api[ auto_paginate, build_headers, process_kucoin_response ],
#     ./utils[ build_query, get_base_url ],
#     ./utils_time_convert_kucoin[ time_convert_from_kucoin ]
# )

#' Add Sub-Account (Implementation)
#'
#' Creates a new sub-account on KuCoin asynchronously by sending a POST request to the `/api/v2/sub/user/created` endpoint. This internal function is designed for use within an R6 class and is not intended for direct end-user consumption.
#'
#' ### Workflow Overview
#' 1. **URL Construction**: Retrieves the base URL using `get_base_url()` (or the user-supplied `base_url`) and appends the endpoint.
#' 2. **Request Body Preparation**: Creates a list with required parameters (`password`, `subName`, `access`, and optional `remarks`), converted to JSON format using `jsonlite::toJSON()` with `auto_unbox = TRUE`.
#' 3. **Header Preparation**: Generates authentication headers asynchronously via `build_headers()`, incorporating the signature, timestamp, encrypted passphrase, and API key details.
#' 4. **API Request**: Sends a POST request using `httr::POST()` with the constructed URL, headers, and JSON body, applying a 3-second timeout.
#' 5. **Response Handling**: Processes the JSON response with `process_kucoin_response()`, raising an error if the HTTP status is not 200 or the API code is not `"200000"`.
#' 6. **Result Conversion**: Converts the `data` field of the successful response into a `data.table`.
#'
#' ### API Endpoint
#' `POST https://api.kucoin.com/api/v2/sub/user/created`
#'
#' ### Usage
#' Utilised internally to establish sub-accounts for managing separate trading permissions within the KuCoin ecosystem.
#'
#' ### Official Documentation
#' [KuCoin Add Sub-Account](https://www.kucoin.com/docs-new/rest/account-info/sub-account/add-subaccount)
#'
#' @param keys List containing API configuration parameters from `get_api_keys()`, including:
#'   - `api_key`: Character string; your KuCoin API key.
#'   - `api_secret`: Character string; your KuCoin API secret.
#'   - `api_passphrase`: Character string; your KuCoin API passphrase.
#'   - `key_version`: Character string; API key version (e.g., `"2"`).
#'   Defaults to `get_api_keys()`.
#' @param base_url Character string representing the base URL for the API. Defaults to `get_base_url()`.
#' @param password Character string; sub-account password (7–24 characters, must contain both letters and numbers).
#' @param subName Character string; desired sub-account name (7–32 characters, must include at least one letter and one number, no spaces).
#' @param access Character string; permission type for the sub-account (allowed values: `"Spot"`, `"Futures"`, `"Margin"`).
#' @param remarks Character string (optional); remarks or notes about the sub-account (1–24 characters if provided).
#' @return Promise resolving to a `data.table` containing sub-account details, including at least:
#'   - `uid` (integer): Unique identifier for the sub-account.
#'   - `subName` (character): Name of the sub-account.
#'   - `remarks` (character): Any provided remarks or notes.
#'   - `access` (character): Permission type granted to the sub-account.
#' @details
#' **Raw Response Schema**:  
#' - `code` (string): Status code, where `"200000"` indicates success.  
#' - `data` (object): Contains the sub-account details as described above.  
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
#'   result <- await(add_subaccount_impl(
#'     keys = keys,
#'     base_url = base_url,
#'     password = "1234567",
#'     subName = "Name1234567",
#'     access = "Spot",
#'     remarks = "Test sub-account"
#'   ))
#'   print(result)
#' })
#' main_async()
#' while (!later::loop_empty()) later::run_now()
#' }
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
    access,
    remarks = NULL
) {
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
        parsed_response <- process_kucoin_response(response, url)
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
#'   - `currentPage` (integer): Current page number.
#'   - `pageSize` (integer): Number of results per page.
#'   - `totalNum` (integer): Total number of sub-accounts.
#'   - `totalPage` (integer): Total number of pages.
#'   - `userId` (character): Unique identifier of the master account.
#'   - `uid` (integer): Unique identifier of the sub-account.
#'   - `subName` (character): Sub-account name.
#'   - `status` (integer): Current status of the sub-account.
#'   - `type` (integer): Type of sub-account.
#'   - `access` (character): Permission type granted (e.g., `"All"`, `"Spot"`, `"Futures"`, `"Margin"`).
#'   - `createdAt` (integer): Timestamp of creation in milliseconds.
#'   - `createdDatetime` (POSIXct): Converted human-readable datetime (if `createdAt` is present).
#'   - `remarks` (character): Remarks or notes associated with the sub-account.
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
            parsed_response <- process_kucoin_response(response, url)
            return(parsed_response$data)
        })

        # Initialize the query with the first page.
        initial_query <- list(currentPage = 1, pageSize = page_size)

        # Automatically paginate through all pages using the auto_paginate helper.
        dt <- await(auto_paginate(
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
                    return(el)
                })
                # rbindlist can convert list of lists to data.table
                return(data.table::rbindlist(els, fill = TRUE))
            },
            max_pages = max_pages
        ))

        dt[, createdDatetime := time_convert_from_kucoin(createdAt, "ms")]

        return(dt)
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
#'   - `currency` (character): Currency code.
#'   - `balance` (character): Total balance.
#'   - `available` (character): Amount available for trading or withdrawal.
#'   - `holds` (character): Amount locked or held.
#'   - `accountType` (character): Source account type (e.g., `"mainAccounts"`, `"tradeAccounts"`, `"marginAccounts"`, `"tradeHFAccounts"`).
#'   - `subUserId` (character): Sub-account user ID.
#'   - `subName` (character): Sub-account name.
#'   Additional fields such as `baseCurrency`, `baseCurrencyPrice`, `baseAmount`, and `tag` may be present depending on the response.
#' @details
#' **Raw Response Schema**:  
#' - `code` (string): Status code, where `"200000"` indicates success.  
#' - `data` (object): Contains `subUserId`, `subName`, and arrays for `mainAccounts`, `tradeAccounts`, `marginAccounts`, and `tradeHFAccounts`.  
#' 
#' Example JSON response:  
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
        data <- process_kucoin_response(response, url)

        # Initialize a list to collect data.tables for each account type.
        result_list <- list()

        # Process each account type array if present and non-empty.
        if (!is.null(data$mainAccounts) && length(data$mainAccounts) > 0) {
            dt_main <- data.table::as.data.table(data$mainAccounts)
            dt_main[, accountType := "mainAccounts"]
            result_list[[length(result_list) + 1]] <- dt_main
        }
        if (!is.null(data$tradeAccounts) && length(data$tradeAccounts) > 0) {
            dt_trade <- data.table::as.data.table(data$tradeAccounts)
            dt_trade[, accountType := "tradeAccounts"]
            result_list[[length(result_list) + 1]] <- dt_trade
        }
        if (!is.null(data$marginAccounts) && length(data$marginAccounts) > 0) {
            dt_margin <- data.table::as.data.table(data$marginAccounts)
            dt_margin[, accountType := "marginAccounts"]
            result_list[[length(result_list) + 1]] <- dt_margin
        }
        if (!is.null(data$tradeHFAccounts) && length(data$tradeHFAccounts) > 0) {
            dt_tradeHF <- data.table::as.data.table(data$tradeHFAccounts)
            dt_tradeHF[, accountType := "tradeHFAccounts"]
            result_list[[length(result_list) + 1]] <- dt_tradeHF
        }

        # Combine the results; if no data is available, return an empty data.table.
        if (length(result_list) == 0) {
            dt <- data.table::data.table()
        } else {
            dt <- data.table::rbindlist(result_list, fill = TRUE)
        }

        # Append metadata (subUserId and subName) from the parent response.
        dt[, subUserId := data$subUserId]
        dt[, subName := data$subName]

        return(dt)
    }, error = function(e) {
        rlang::abort(paste("Error in get_subaccount_detail_balance_impl:", conditionMessage(e)))
    })
})
