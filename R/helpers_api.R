# File: ./R/helpers_api.R

box::use(
    ./utils[get_base_url],
    httr[GET, timeout, content, status_code, add_headers],
    jsonlite[fromJSON],
    rlang[error_cnd, abort],
    promises[promise],
    digest[hmac],
    base64enc[base64encode],
    coro[async, await]
)

#' Retrieve Server Time from KuCoin Futures API
#'
#' Retrieves the current server time as a Unix timestamp in milliseconds from the KuCoin Futures API asynchronously. This helper function is essential for authenticated requests, ensuring timestamps align with server time within a 5-second window.
#'
#' ### Workflow Overview
#' 1. **URL Construction**: Combines the base URL (default from `get_base_url()`) with the endpoint `/api/v1/timestamp`.
#' 2. **API Request**: Sends an asynchronous GET request with a 3-second timeout using `httr::GET()`.
#' 3. **Status Check**: Validates the HTTP status code is 200, rejecting the promise if not.
#' 4. **Response Parsing**: Extracts the response text and parses it as JSON with `jsonlite::fromJSON()`.
#' 5. **Structure Validation**: Ensures `"code"` and `"data"` fields exist, rejecting if missing.
#' 6. **Success Check**: Confirms the API code is `"200000"`, rejecting if not.
#' 7. **Result Resolution**: Resolves the promise with the timestamp from the `"data"` field.
#'
#' ### API Endpoint
#' `GET https://api.kucoin.com/api/v1/timestamp`
#'
#' ### Usage
#' Utilised to synchronise request timestamps for signature generation and to prevent replay attacks in authenticated API calls.
#'
#' ### Official Documentation
#' [KuCoin Futures Get Server Time](https://www.kucoin.com/docs-new/rest/futures-trading/market-data/get-server-time)
#'
#' @param base_url Character string specifying the base URL for the KuCoin Futures API. Defaults to `get_base_url()`.
#' @return Promise resolving to a numeric Unix timestamp in milliseconds or rejecting with an error if the request fails.
#' @examples
#' \dontrun{
#' get_server_time()$
#'   then(function(timestamp) {
#'     cat("KuCoin Server Time:", timestamp, "\n")
#'   })$
#'   catch(function(e) {
#'     message("Error retrieving server time:", conditionMessage(e))
#'   })
#' while (!later::loop_empty()) later::run_now(timeoutSecs = Inf, all = TRUE)
#' }
#' @importFrom promises promise
#' @importFrom httr GET timeout content status_code
#' @importFrom jsonlite fromJSON
#' @importFrom rlang error_cnd
#' @export
get_server_time <- function(base_url = get_base_url()) {
    promises::promise(function(resolve, reject) {
        tryCatch({
            url <- paste0(base_url, "/api/v1/timestamp")
            response <- httr::GET(url, httr::timeout(3))
            if (httr::status_code(response) != 200) {
                reject(rlang::error_cnd(
                    "rlang_error",
                    reason = paste("KuCoin API request failed with status code", httr::status_code(response))
                ))
                return()
            }
            response_text <- httr::content(response, as = "text", encoding = "UTF-8")
            parsed_response <- jsonlite::fromJSON(response_text)
            if (!all(c("code", "data") %in% names(parsed_response))) {
                reject(rlang::error_cnd(
                    "rlang_error",
                    reason = "Invalid API response structure: missing 'code' or 'data' field"
                ))
                return()
            }
            if (parsed_response$code != "200000") {
                reject(rlang::error_cnd("rlang_error", message = "KuCoin API returned an error"))
                return()
            }
            resolve(parsed_response$data)
        }, error = function(e) {
            reject(rlang::error_cnd("rlang_error", message = paste("Error retrieving server time:", conditionMessage(e))))
        })
    })
}

#' Construct Request Headers for KuCoin API
#'
#' Generates HTTP request headers asynchronously for authenticated KuCoin API requests, incorporating the API key, HMAC-SHA256 signature, timestamp, encrypted passphrase, key version, and content type to ensure request security.
#'
#' ### Workflow Overview
#' 1. **Retrieve Server Time**: Obtains the current server timestamp in milliseconds by calling `get_server_time()` with the base URL from `get_base_url()`.
#' 2. **Construct Prehash String**: Concatenates the timestamp, uppercase HTTP method, endpoint, and request body.
#' 3. **Generate Signature**: Computes an HMAC-SHA256 signature over the prehash string using the API secret, then base64-encodes it.
#' 4. **Encrypt Passphrase**: Signs the API passphrase with the API secret using HMAC-SHA256 and base64-encodes the result.
#' 5. **Assemble Headers**: Constructs headers with `httr::add_headers()`, including `KC-API-KEY`, `KC-API-SIGN`, `KC-API-TIMESTAMP`, `KC-API-PASSPHRASE`, `KC-API-KEY-VERSION`, and `Content-Type`.
#'
#' ### API Endpoint
#' Not applicable (helper function for request construction).
#'
#' ### Usage
#' Employed to authenticate and secure API requests to KuCoin endpoints requiring authorisation.
#'
#' ### Official Documentation
#' Not directly tied to a specific endpoint; see KuCoin API authentication guidelines.
#'
#' @param method Character string specifying the HTTP method (e.g., `"GET"`, `"POST"`).
#' @param endpoint Character string representing the API endpoint (e.g., `"/api/v1/orders"`).
#' @param body Character string containing the JSON-formatted request body; use `""` if no payload is required.
#' @param keys List of API credentials including:
#'   - `api_key`: Character string; your KuCoin API key.
#'   - `api_secret`: Character string; your KuCoin API secret.
#'   - `api_passphrase`: Character string; your KuCoin API passphrase.
#'   - `key_version`: Character string; the API key version (e.g., `"2"`).
#' @return Promise resolving to a list of HTTP headers created with `httr::add_headers()`.
#' @examples
#' \dontrun{
#' keys <- list(
#'   api_key = "your_api_key",
#'   api_secret = "your_api_secret",
#'   api_passphrase = "your_api_passphrase",
#'   key_version = "2"
#' )
#' main_async <- coro::async(function() {
#'   headers <- await(build_headers("POST", "/api/v1/orders", '{"size": 1}', keys))
#'   print(headers)
#'   headers <- await(build_headers("GET", "/api/v1/orders", "", keys))
#'   print(headers)
#' })
#' main_async()
#' while (!later::loop_empty()) later::run_now()
#' }
#' @importFrom coro async await
#' @importFrom digest hmac
#' @importFrom base64enc base64encode
#' @importFrom httr add_headers
#' @importFrom rlang abort
#' @export
build_headers <- coro::async(function(method, endpoint, body, keys) {
    tryCatch({
        # Retrieve the current server time using the base URL.
        timestamp <- await(get_server_time(get_base_url()))
        # Construct the prehash string from timestamp, method, endpoint, and body.
        prehash <- paste0(timestamp, toupper(method), endpoint, body)
        # Compute the HMAC-SHA256 signature.
        sig_raw <- digest::hmac(
            key = keys$api_secret,
            object = prehash,
            algo = "sha256",
            serialize = FALSE,
            raw = TRUE
        )
        # Base64-encode the signature.
        signature <- base64enc::base64encode(sig_raw)
        # Encrypt the API passphrase.
        passphrase_raw <- digest::hmac(
            key = keys$api_secret,
            object = keys$api_passphrase,
            algo = "sha256",
            serialize = FALSE,
            raw = TRUE
        )
        encrypted_passphrase <- base64enc::base64encode(passphrase_raw)
        # Build and return the headers.
        httr::add_headers(
            `KC-API-KEY` = keys$api_key,
            `KC-API-SIGN` = signature,
            `KC-API-TIMESTAMP` = timestamp,
            `KC-API-PASSPHRASE` = encrypted_passphrase,
            `KC-API-KEY-VERSION` = keys$key_version,
            `Content-Type` = "application/json"
        )
    }, error = function(e) {
        rlang::abort(
            paste("Failed to build request headers:", conditionMessage(e)),
            parent = e
        )
    })
})

#' Process and Validate KuCoin API Response
#'
#' Processes an HTTP response from a KuCoin API request, validating its HTTP status and API-specific response code, returning the parsed JSON object if successful or aborting with an error otherwise.
#'
#' ### Workflow Overview
#' 1. **Check HTTP Status**: Confirms the status code is 200, aborting if not.
#' 2. **Parse JSON**: Extracts the response content as text and parses it into a JSON object using `jsonlite::fromJSON()`.
#' 3. **Validate Structure**: Verifies the `"code"` field exists, aborting if absent.
#' 4. **Check Success**: Ensures the `"code"` is `"200000"`, retrieving an error message from `"msg"` and aborting if not successful.
#'
#' ### API Endpoint
#' Not applicable (helper function for response processing).
#'
#' ### Usage
#' Utilised to validate and extract data from KuCoin API responses, typically accessing the `$data` or `$data$items` field for results.
#'
#' ### Official Documentation
#' Not directly tied to a specific endpoint; see KuCoin API response handling guidelines.
#'
#' @param response HTTP response object (e.g., from `httr::GET()`).
#' @param url Character string representing the requested URL, used for error messages.
#' @return List representing the parsed JSON response; users should extract fields like `"data"` as required.
#' @examples
#' \dontrun{
#' response <- httr::GET("https://api.kucoin.com/api/v1/timestamp", httr::timeout(3))
#' parsed <- process_kucoin_response(response, "https://api.kucoin.com/api/v1/timestamp")
#' print(parsed$data)
#' }
#' @importFrom httr status_code content
#' @importFrom jsonlite fromJSON
#' @importFrom rlang abort
#' @export
process_kucoin_response <- function(response, url = "") {
    status_code <- httr::status_code(response)
    if (status_code != 200) {
        rlang::abort(paste("HTTP request failed with status code", status_code, "for URL:", url))
    }

    response_text <- httr::content(response, as = "text", encoding = "UTF-8")
    parsed_response <- jsonlite::fromJSON(
        response_text,
        simplifyVector = TRUE,
        simplifyDataFrame = FALSE,
        simplifyMatrix = FALSE
    )

    if (!"code" %in% names(parsed_response)) {
        rlang::abort("Invalid API response structure: missing 'code' field.")
    }

    if (as.character(parsed_response$code) != "200000") {
        error_msg <- "No error message provided."
        if ("msg" %in% names(parsed_response)) {
            error_msg <- parsed_response$msg
        }
        rlang::abort(paste("KuCoin API returned an error:", parsed_response$code, "-", error_msg))
    }

    return(parsed_response)
}

#' Facilitate Automatic Pagination for KuCoin API Endpoints
#'
#' Handles pagination for KuCoin API endpoints asynchronously by iteratively fetching pages with a user-supplied function and aggregating results using a provided aggregation function.
#'
#' ### Workflow Overview
#' 1. **Fetch Page**: Calls `fetch_page` with current query parameters to retrieve a page.
#' 2. **Accumulate Results**: Adds items from the page (via `items_field`) to an accumulator list.
#' 3. **Determine Continuation**: Continues if the current page is less than the total pages and `max_pages` hasn’t been reached.
#' 4. **Aggregate Results**: Applies `aggregate_fn` to the accumulator once all pages are fetched.
#'
#' ### API Endpoint
#' Not applicable (helper function for paginated endpoints).
#'
#' ### Usage
#' Utilised to simplify retrieval of multi-page data from KuCoin API responses, aggregating results into a user-defined format.
#'
#' ### Official Documentation
#' Not directly tied to a specific endpoint; see KuCoin API pagination guidelines.
#'
#' @param fetch_page Function fetching a page of results, returning a promise resolving to the response.
#' @param query Named list of query parameters for the first page. Defaults to `list(currentPage = 1, pageSize = 50)`.
#' @param items_field Character string; field in the response containing items to aggregate. Defaults to `"items"`.
#' @param paginate_fields Named list specifying response fields for pagination:
#'   - `currentPage`: Field with the current page number.
#'   - `totalPage`: Field with the total number of pages.
#'   Defaults to `list(currentPage = "currentPage", totalPage = "totalPage")`.
#' @param aggregate_fn Function combining accumulated results into the final output. Defaults to returning the accumulator list unchanged.
#' @param max_pages Numeric; maximum number of pages to fetch. Defaults to `Inf` (all available pages).
#' @return Promise resolving to the aggregated result as defined by `aggregate_fn`.
#' @examples
#' \dontrun{
#' fetch_page <- coro::async(function(query) {
#'   url <- paste0(get_base_url(), "/api/v1/example", build_query(query))
#'   response <- httr::GET(url, httr::timeout(3))
#'   process_kucoin_response(response, url)
#' })
#' aggregate <- function(acc) data.table::rbindlist(acc)
#' main_async <- coro::async(function() {
#'   result <- await(auto_paginate(
#'     fetch_page = fetch_page,
#'     query = list(currentPage = 1, pageSize = 10),
#'     max_pages = 3,
#'     aggregate_fn = aggregate
#'   ))
#'   print(result)
#' })
#' main_async()
#' while (!later::loop_empty()) later::run_now()
#' }
#' @importFrom coro async await
#' @export
auto_paginate <- coro::async(function(
    fetch_page,
    query = list(currentPage = 1, pageSize = 50),
    items_field = "items",
    paginate_fields = list(
        currentPage = "currentPage",
        totalPage   = "totalPage"
    ),
    aggregate_fn = function(acc) { acc },
    max_pages = Inf
) {
    tryCatch({
        accumulator <- list()
        repeat {
            # Fetch the current page asynchronously.
            response <- await(fetch_page(query))
            if (!is.null(response[[items_field]])) {
                page_items <- response[[items_field]]
            } else {
                page_items <- response
            }
            # Append page_items to accumulator, flattening as we go
            # Flatten by concatenating directly
            accumulator <- c(accumulator, page_items)
            currentPage <- response[[paginate_fields$currentPage]]
            totalPage   <- response[[paginate_fields$totalPage]]
            # If we've reached max_pages, or there is no next page, break.
            if (is.finite(max_pages) && currentPage >= max_pages) break
            if (is.null(currentPage) || is.null(totalPage) || (currentPage >= totalPage)) break
            # Prepare query for next page.
            query$currentPage <- currentPage + 1
        }
        aggregate_fn(accumulator)
    }, error = function(e) {
        stop("Error in auto_paginate: ", conditionMessage(e))
    })
})

#' Facilitate Automatic Pagination for KuCoin API Endpoints (Legacy Version)
#'
#' Manages pagination for KuCoin API endpoints asynchronously using a recursive approach, fetching pages with a user-supplied function and aggregating results via a provided function. This is an older version of `auto_paginate`.
#'
#' ### Workflow Overview
#' 1. **Fetch Page**: Calls `fetch_page` to retrieve the current page.
#' 2. **Accumulate Results**: Adds items from the page (via `items_field`) to the `accumulator`.
#' 3. **Recursive Continuation**: Recursively fetches the next page if the current page is less than the total pages and `max_pages` allows, updating the query.
#' 4. **Aggregate Results**: Applies `aggregate_fn` to the accumulator when pagination completes.
#'
#' ### API Endpoint
#' Not applicable (helper function for paginated endpoints).
#'
#' ### Usage
#' Utilised as a legacy alternative to `auto_paginate` for retrieving multi-page data from KuCoin API responses.
#'
#' ### Official Documentation
#' Not directly tied to a specific endpoint; see KuCoin API pagination guidelines.
#'
#' @param fetch_page Function fetching a page of results, returning a promise resolving to the response.
#' @param query Named list of query parameters for the first page. Defaults to `list(currentPage = 1, pageSize = 50)`.
#' @param items_field Character string; field in the response containing items to aggregate. Defaults to `"items"`.
#' @param paginate_fields Named list specifying response fields for pagination:
#'   - `currentPage`: Field with the current page number.
#'   - `totalPage`: Field with the total number of pages.
#'   Defaults to `list(currentPage = "currentPage", totalPage = "totalPage")`.
#' @param aggregate_fn Function combining accumulated results into the final output. Defaults to returning the accumulator list unchanged.
#' @param max_pages Numeric; maximum number of pages to fetch. Defaults to `Inf` (all available pages).
#' @param accumulator List; internal accumulator for recursive aggregation. Defaults to an empty list.
#' @return Promise resolving to the aggregated result as defined by `aggregate_fn`.
#' @examples
#' \dontrun{
#' fetch_page <- coro::async(function(query) {
#'   url <- paste0(get_base_url(), "/api/v1/example", build_query(query))
#'   response <- httr::GET(url, httr::timeout(3))
#'   process_kucoin_response(response, url)
#' })
#' aggregate <- function(acc) data.table::rbindlist(acc)
#' main_async <- coro::async(function() {
#'   result <- await(auto_paginate_old(
#'     fetch_page = fetch_page,
#'     query = list(currentPage = 1, pageSize = 10),
#'     max_pages = 3,
#'     aggregate_fn = aggregate
#'   ))
#'   print(result)
#' })
#' main_async()
#' while (!later::loop_empty()) later::run_now()
#' }
#' @importFrom coro async await
#' @export
auto_paginate_old <- coro::async(function(
    fetch_page,
    query = list(currentPage = 1, pageSize = 50),
    items_field = "items",
    paginate_fields = list(
        currentPage = "currentPage",
        totalPage = "totalPage"
    ),
    aggregate_fn = function(acc) { acc },
    max_pages = Inf,
    accumulator = list()
) {
    tryCatch({
        response <- await(fetch_page(query))
        if (!is.null(response[[items_field]])) {
            page_items <- response[[items_field]]
        } else {
            page_items <- response
        }
        accumulator[[length(accumulator) + 1]] <- page_items
        currentPage <- response[[paginate_fields$currentPage]]
        totalPage   <- response[[paginate_fields$totalPage]]
        if (is.finite(max_pages) && currentPage >= max_pages) {
            return(aggregate_fn(accumulator))
        } else if (!is.null(currentPage) && !is.null(totalPage) && (currentPage < totalPage)) {
            query$currentPage <- currentPage + 1
            return(await(auto_paginate(
                fetch_page      = fetch_page,
                query           = query,
                items_field     = items_field,
                paginate_fields = paginate_fields,
                aggregate_fn    = aggregate_fn,
                max_pages       = max_pages,
                accumulator     = accumulator
            )))
        } else {
            return(aggregate_fn(accumulator))
        }
    }, error = function(e) {
        rlang::abort(paste("Error in auto_paginate:", conditionMessage(e)))
    })
})
