# File: ./R/impl_account_sub_account.R

# box::use(
#     ./helpers_api[ auto_paginate, build_headers, process_kucoin_response ],
#     ./utils[ build_query, get_base_url ],
#     ./utils_time_convert_kucoin[ time_convert_from_kucoin ]
# )

#' Add SubAccount Implementation
#'
#' @importFrom coro async await
#' @importFrom jsonlite toJSON
#' @importFrom httr POST timeout
#' @importFrom data.table as.data.table
#' @importFrom rlang abort
#'
#' This asynchronous function creates a new sub‐account on KuCoin by sending a POST request to the
#' `/api/v2/sub/user/created` endpoint. It is designed for internal use as a method in an R6 class and is
#' not intended for direct consumption by end-users. The function performs the following steps:
#'
#' 1. **URL Construction:**  
#'    Retrieves the base URL using `get_base_url()` (or the user-supplied `base_url`) and appends the endpoint.
#'
#' 2. **Request Body Preparation:**  
#'    Creates a list with the required parameters:
#'    - `password`: The sub‐account password (7–24 characters; must contain both letters and numbers).
#'    - `subName`: The desired sub‐account name (7–32 characters; must include at least one letter and one number; no spaces).
#'    - `access`: The permission type for the sub‐account (allowed values: `"Spot"`, `"Futures"`, `"Margin"`).
#'    - `remarks` (optional): Remarks or notes about the sub‐account (if provided, 1–24 characters).
#'
#'    This list is converted to JSON format using `jsonlite::toJSON()` with `auto_unbox = TRUE`.
#'
#' 3. **Header Preparation:**  
#'    Generates authentication headers asynchronously by calling `build_headers()`, which includes the necessary
#'    signature, timestamp, encrypted passphrase, and API key details.
#'
#' 4. **API Request:**  
#'    Sends a POST request using `httr::POST()` with the constructed URL, headers and JSON body. A timeout of 3
#'    seconds is applied.
#'
#' 5. **Response Handling:**  
#'    Processes the JSON response using `process_kucoin_response()`. If the HTTP status is not 200 or the API returns
#'    a code other than `"200000"`, an error is raised.
#'
#' 6. **Result Conversion:**  
#'    On success, converts the `data` field of the response into a `data.table` and returns it.
#'
#' @param keys A list containing API configuration parameters, as returned by `get_api_keys()`. The list must include:
#'   - `api_key`: Your KuCoin API key.
#'   - `api_secret`: Your KuCoin API secret.
#'   - `api_passphrase`: Your KuCoin API passphrase.
#'   - `key_version`: The version of the API key (e.g. `"2"`).
#' @param base_url A character string representing the base URL for the API. If not provided, the function uses
#'                 `get_base_url()` to determine the base URL.
#' @param password A string representing the sub‐account password.
#'   - **Requirements:** Must be between 7 and 24 characters and contain both letters and numbers.
#' @param subName A string representing the desired sub‐account name.
#'   - **Requirements:** Must be between 7 and 32 characters, include at least one letter and one number, and not contain spaces.
#' @param access A string representing the permission type for the sub‐account.
#'   - **Allowed Values:** `"Spot"`, `"Futures"`, `"Margin"`.
#' @param remarks (Optional) A string containing remarks or notes about the sub‐account.
#'   - **Requirements:** If provided, must be between 1 and 24 characters.
#'
#' @return A promise that resolves to a `data.table` containing the sub‐account details. The resulting table includes at least:
#'   - **uid** (integer): The unique identifier for the sub‐account.
#'   - **subName** (string): The name of the sub‐account.
#'   - **remarks** (string): Any remarks or notes provided.
#'   - **access** (string): The permission type granted to the sub‐account.
#'
#' @details
#' **Endpoint:** `POST https://api.kucoin.com/api/v2/sub/user/created`  
#'
#' **Raw Response Schema:**  
#' - `code` (string): Status code, where `"200000"` indicates success.
#' - `data` (object): Contains the sub‐account details as described above.
#'
#' The JSON response looks like:
#' \preformatted{
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
#' }
#'
#' For more information, please refer to the
#' [Add SubAccount API Documentation](https://www.kucoin.com/docs-new/rest/account-info/sub-account/add-subaccount).
#'
#' @examples
#' \dontrun{
#'   # Retrieve API keys from the environment using get_api_keys()
#'   keys <- get_api_keys()
#'
#'   # Optionally, specify a base URL; if not provided, defaults to the value from get_base_url()
#'   base_url <- "https://api.kucoin.com"
#'
#'   # Execute the asynchronous request using coro::async:
#'   main_async <- coro::async(function() {
#'     result <- await(add_subaccount_impl(keys, base_url,
#'         password = "1234567",
#'         subName = "Name1234567",
#'         access = "Spot",
#'         remarks = "Test sub-account"
#'     ))
#'     print(result)
#'   })
#'
#'   main_async()
#'   while (!later::loop_empty()) {
#'     later::run_now()
#'   }
#' }
#'
#' @md
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

#' Get SubAccount Summary Information Implementation
#'
#' @importFrom coro async await
#' @importFrom httr GET timeout
#' @importFrom data.table rbindlist as.data.table
#' @importFrom rlang abort
#'
#' This asynchronous function retrieves a paginated summary of sub‐accounts from KuCoin and aggregates
#' the results into a single `data.table`. It sends HTTP GET requests to the KuCoin sub‐account summary
#' endpoint and automatically handles pagination. In the final aggregated `data.table`, each row represents
#' the summary information for one sub‐account. Additionally, if the response contains a `createdAt` column
#' (with timestamps in milliseconds), these values are converted into human‐readable POSIXct datetime objects.
#'
#' ## Endpoint Overview
#'
#' **API Endpoint:**  
#' `GET https://api.kucoin.com/api/v2/sub/user`
#'
#' **Purpose:**  
#' This endpoint is used to retrieve a summary of all sub‐accounts associated with your KuCoin account.
#' The response is paginated and includes metadata such as the current page number, page size, total number
#' of sub‐accounts, and total pages.
#'
#' **Response Schema:**  
#' The API returns a JSON object with the following structure:
#' - **code**: A string status code; `"200000"` indicates success.
#' - **data**: An object containing:
#'   - `currentPage` (integer): The current page number.
#'   - `pageSize` (integer): The number of results per page.
#'   - `totalNum` (integer): The total number of sub‐accounts.
#'   - `totalPage` (integer): The total number of pages.
#'   - `items`: An array where each element corresponds to a sub‐account summary with fields such as:
#'       - `userId`: The unique identifier of the master account.
#'       - `uid`: The unique identifier of the sub‐account.
#'       - `subName`: The sub‐account name.
#'       - `status`: The current status of the sub‐account.
#'       - `type`: The type of sub‐account.
#'       - `access`: The permission type granted (e.g. `"All"`, `"Spot"`, `"Futures"`, `"Margin"`).
#'       - `createdAt`: The timestamp (in milliseconds) when the sub‐account was created.
#'       - `remarks`: Remarks or notes associated with the sub‐account.
#'
#' For more details, please refer to the
#' [KuCoin Sub‐Account Summary Documentation](https://www.kucoin.com/docs-new/rest/account-info/sub-account/get-subaccount-list-summary-info).
#'
#' ## Function Workflow
#'
#' 1. **Pagination Initialisation:**  
#'    The function begins by setting an initial query with `currentPage = 1` and the specified `page_size`.
#'
#' 2. **Page Fetching:**  
#'    An asynchronous helper function (`fetch_page`) is defined to send a GET request for a given page.
#'    It constructs the URL with the current query parameters and sends the request with the required authentication headers.
#'
#' 3. **Automatic Pagination:**  
#'    The function leverages the `auto_paginate` utility to repeatedly call `fetch_page`.
#'    Results from each page are aggregated until all pages have been retrieved or the specified maximum number of pages (`max_pages`) is reached.
#'
#' 4. **Aggregation and Datetime Conversion:**  
#'    The responses from all pages are combined into a single `data.table` using `data.table::rbindlist()`.
#'    If the resulting table contains a `createdAt` column, its millisecond timestamps are converted to POSIXct datetime
#'    objects (stored in a new column named `createdDatetime`).
#'
#' @param keys A list containing API configuration parameters, as returned by `get_api_keys()`. This list must include:
#'   - `api_key`: Your KuCoin API key.
#'   - `api_secret`: Your KuCoin API secret.
#'   - `api_passphrase`: Your KuCoin API passphrase.
#'   - `key_version`: The version of the API key (e.g. `"2"`).
#' @param base_url A character string representing the base URL for the API. Defaults to the value returned by `get_base_url()`.
#' @param page_size An integer specifying the number of results per page. Default is 100 (minimum 1, maximum 100).
#' @param max_pages An integer specifying the maximum number of pages to fetch. Default is `Inf` (fetch all available pages).
#'
#' @return A promise that resolves to a single `data.table` containing the aggregated sub‐account summary information.
#' The resulting table includes:
#'   - **currentPage** (integer): The current page number.
#'   - **pageSize** (integer): The number of results per page.
#'   - **totalNum** (integer): The total number of sub‐accounts.
#'   - **totalPage** (integer): The total number of pages.
#'   - **items**: An array of sub‐account summary objects, where each row includes fields such as:
#'       `userId`, `uid`, `subName`, `status`, `type`, `access`, `createdAt` and `remarks`.
#'   If a `createdAt` column is present, a new column `createdDatetime` is added with human‐readable POSIXct datetime values.
#'
#' @details
#' **Endpoint:** `GET https://api.kucoin.com/api/v2/sub/user`  
#'
#' **Raw Response Schema:**  
#' - `code` (string): Status code, where `"200000"` indicates success.
#' - `data` (object): Contains the pagination metadata and an `items` array with sub‐account summary details.
#' 
#' The JSON response looks like:
#' \preformatted{
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
#' }
#'
#' For further details, please see the
#' [KuCoin Sub‐Account Summary API Documentation](https://www.kucoin.com/docs-new/rest/account-info/sub-account/get-subaccount-list-summary-info).
#'
#' @examples
#' \dontrun{
#'   # Retrieve API keys from the environment using get_api_keys()
#'   keys <- get_api_keys()
#'   base_url <- get_base_url()
#'
#'   # Execute the asynchronous request using coro::async:
#'   main_async <- coro::async(function() {
#'     # Fetch all sub‐account summaries using the default page size (100)
#'     dt_all <- await(get_subaccount_list_summary_impl(keys, base_url))
#'     print(dt_all)
#'
#'     # Fetch only 3 pages of results with a page size of 50
#'     dt_partial <- await(get_subaccount_list_summary_impl(keys, page_size = 50, max_pages = 3))
#'     print(dt_partial)
#'   })
#'
#'   main_async()
#'   while (!later::loop_empty()) {
#'     later::run_now(timeoutSecs = Inf, all = TRUE)
#'   }
#' }
#'
#' @md
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

#' Get SubAccount Detail – Balance Implementation
#'
#' @importFrom coro async await
#' @importFrom httr GET timeout
#' @importFrom data.table as.data.table rbindlist
#' @importFrom rlang abort
#'
#' This asynchronous function retrieves the balance details for a specific sub‐account from KuCoin.
#' It sends a GET request to the KuCoin API endpoint for sub‐account details and processes the returned JSON response.
#' The endpoint provides separate arrays for each account type under the sub‐account (typically including
#' `mainAccounts`, `tradeAccounts`, `marginAccounts` and `tradeHFAccounts`). For each non‐empty array, the function converts
#' the data into a `data.table`, adds an `accountType` column to indicate the type, and then aggregates all the tables into a
#' single `data.table`. Finally, it appends the sub‐account's user ID and name to every row.
#'
#' ## Endpoint Overview
#'
#' **API Endpoint:**  
#' `GET https://api.kucoin.com/api/v1/sub-accounts/{subUserId}?includeBaseAmount={includeBaseAmount}`
#'
#' **Purpose:**  
#' This endpoint retrieves detailed balance information for a specific sub‐account. The response is structured to provide
#' separate balance details for various account categories (e.g. funding, spot, margin, and high‐frequency trading accounts).
#'
#' **Query Parameter:**  
#' - `includeBaseAmount` (boolean): Indicates whether to include currencies with a zero balance in the response.
#'   - **Default:** `FALSE` (only non‐zero balances are returned)
#'
#' **Response Schema:**  
#' On success, the API returns a JSON object with:
#' - **code** (string): Status code, where `"200000"` indicates success.
#' - **data** (object): Contains:
#'   - `subUserId`: The sub‐account's user ID.
#'   - `subName`: The sub‐account name.
#'   - `mainAccounts`: An array of objects detailing funding account balances.
#'   - `tradeAccounts`: An array of objects detailing spot account balances.
#'   - `marginAccounts`: An array of objects detailing margin account balances.
#'   - `tradeHFAccounts`: An array (often deprecated) for high‐frequency trading accounts.
#'
#' Each account object typically includes fields such as:
#' - `currency`: The currency code.
#' - `balance`: Total balance.
#' - `available`: Amount available for trading or withdrawal.
#' - `holds`: Amount locked or held.
#' - Additional fields such as `baseCurrency`, `baseCurrencyPrice`, `baseAmount`, and `tag`.
#' 
#' The JSON response looks like:
#' \preformatted{
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
#' }
#'
#' For more detailed information, please refer to the
#' [KuCoin Sub‐Account Detail Balance Documentation](https://www.kucoin.com/docs-new/rest/account-info/sub-account/get-subaccount-detail-balance).
#'
#' ## Function Workflow
#'
#' 1. **URL and Query String Construction:**  
#'    Constructs the endpoint URL by appending the `subUserId` to `/api/v1/sub-accounts/` and adding the query parameter
#'    `includeBaseAmount` (which defaults to `FALSE` if not specified).
#'
#' 2. **Header Generation:**  
#'    Asynchronously generates the necessary authentication headers by calling `build_headers()`.
#'
#' 3. **HTTP Request:**  
#'    Sends a GET request to the constructed URL using `httr::GET()` with a 3-second timeout.
#'
#' 4. **Response Processing:**  
#'    Parses the JSON response using `process_kucoin_response()` and, for each account type array
#'    (`mainAccounts`, `tradeAccounts`, `marginAccounts`, `tradeHFAccounts`), converts the array into a `data.table`
#'    and adds an `accountType` column.
#'
#' 5. **Aggregation and Metadata Addition:**  
#'    Aggregates all non‐empty `data.table`s into a single `data.table` using `data.table::rbindlist()` and appends the
#'    sub‐account's user ID and name as new columns.
#'
#' @param keys A list containing API configuration parameters, as returned by `get_api_keys()`. It must include:
#'   - `api_key`: Your KuCoin API key.
#'   - `api_secret`: Your KuCoin API secret.
#'   - `api_passphrase`: Your KuCoin API passphrase.
#'   - `key_version`: The version of the API key (e.g. `"2"`).
#' @param base_url A character string representing the base URL for the API. If not provided, the function uses
#'                 `get_base_url()`.
#' @param subUserId A string representing the sub‐account user ID for which the balance details are to be retrieved.
#' @param includeBaseAmount A boolean flag indicating whether to include currencies with a zero balance in the response.
#'   - **Default:** `FALSE`
#'
#' @return A promise that resolves to a `data.table` containing the detailed balance information for the specified sub‐account.
#' Each row represents a currency in one of the account types, with an additional column `accountType` indicating the source
#' array, as well as columns for `subUserId` and `subName` extracted from the parent response.
#'
#' @md
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
