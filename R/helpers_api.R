# File: ./R/helpers_api.R

box::use(./utils[ get_base_url ])

#' Get Server Time from KuCoin Futures API
#'
#' Retrieves the current server time (Unix timestamp in milliseconds) from the KuCoin Futures API.
#' The server time is critical for authenticated requests to KuCoin, as the API requires that the
#' timestamp header in each request is within 5 seconds of the actual server time. This function sends
#' an asynchronous GET request and returns a promise that resolves to the timestamp. If the request fails,
#' the promise is rejected with an error.
#'
#' **API Endpoint:**  
#' `GET https://api.kucoin.com/api/v1/timestamp`
#'
#' **Usage:**  
#' The server time is used to generate signatures and validate request freshness, helping prevent replay attacks.
#'
#' **Official Documentation:**  
#' [KuCoin Futures Get Server Time](https://www.kucoin.com/docs-new/rest/futures-trading/market-data/get-server-time)
#'
#' @param base_url The base URL for the KuCoin Futures API. Defaults to the result of \code{get_base_url()}.
#' @return A promise that resolves to a numeric Unix timestamp in milliseconds or rejects with an error.
#'
#' @examples
#' \dontrun{
#'     # Asynchronously retrieve the server time.
#'     get_server_time()$
#'         then(function(timestamp) {
#'             cat("KuCoin Server Time:", timestamp, "\n")
#'         })$
#'         catch(function(e) {
#'             message("Error retrieving server time: ", conditionMessage(e))
#'         })
#'
#'     # Run the event loop until all asynchronous tasks are processed.
#'     while (!later::loop_empty()) {
#'         later::run_now(timeoutSecs = Inf, all = TRUE)
#'     }
#' }
#'
#' @md
#'
#' @importFrom httr GET timeout content status_code
#' @importFrom jsonlite fromJSON
#' @importFrom rlang error_cnd abort
#' @importFrom promises promise
#' @export
get_server_time <- function(base_url = get_base_url()) {
    promises::promise(function(resolve, reject) {
        tryCatch({
            url <- paste0(base_url, "/api/v1/timestamp")
            response <- httr::GET(url, httr::timeout(3))
            if (httr::status_code(response) != 200) {
                reject(
                    rlang::error_cnd("rlang_error",
                    reason = paste("KuCoin API request failed with status code", httr::status_code(response)))
                )
                return()
            }
            response_text <- httr::content(response, as = "text", encoding = "UTF-8")
            parsed_response <- jsonlite::fromJSON(response_text)
            if (!all(c("code", "data") %in% names(parsed_response))) {
                reject(
                    rlang::error_cnd("rlang_error",
                    reason = "Invalid API response structure: missing 'code' or 'data' field")
                )
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

#' Build Request Headers for KuCoin API
#'
#' Asynchronously constructs the HTTP request headers required for making authenticated requests to the KuCoin API.
#' These headers include your API key, an HMAC-SHA256 signature computed over a prehash string, a timestamp,
#' an encrypted passphrase, the API key version, and the content type. The headers ensure both the security and
#' integrity of API requests.
#'
#' ## Workflow Overview:
#'
#' 1. **Retrieve Server Time:**  
#'    Calls \code{get_server_time()} with the base URL (obtained via \code{get_base_url()}) to fetch the current
#'    server timestamp in milliseconds.
#'
#' 2. **Construct the Prehash String:**  
#'    Concatenates the timestamp, the uppercase HTTP method, the API endpoint, and the request body to form a string
#'    that will be used for signing.
#'
#' 3. **Generate the Signature:**  
#'    Computes an HMAC-SHA256 signature using your API secret and the prehash string. The raw signature is then
#'    encoded in base64.
#'
#' 4. **Encrypt the Passphrase:**  
#'    Signs your API passphrase with the API secret (also via HMAC-SHA256) and encodes the result in base64.
#'
#' 5. **Assemble the Headers:**  
#'    Returns a list of headers (using \code{httr::add_headers()}) that includes:
#'    - \code{KC-API-KEY}
#'    - \code{KC-API-SIGN}
#'    - \code{KC-API-TIMESTAMP}
#'    - \code{KC-API-PASSPHRASE}
#'    - \code{KC-API-KEY-VERSION}
#'    - \code{Content-Type}
#'
#' **Parameters:**
#' - **method:** A character string specifying the HTTP method (e.g., "GET", "POST").
#' - **endpoint:** A character string representing the API endpoint (e.g., "/api/v1/orders").
#' - **body:** A character string containing the JSON-formatted request body; use an empty string (`""`) if no payload is required.
#' - **keys:** A list of API credentials and configuration parameters. It must include:
#'    - \code{api_key}: Your KuCoin API key.
#'    - \code{api_secret}: Your KuCoin API secret.
#'    - \code{api_passphrase}: Your KuCoin API passphrase.
#'    - \code{key_version}: The API key version (e.g., "2").
#'    Optionally, a \code{base_url} may be provided, though this function relies on \code{get_base_url()} to determine the base URL.
#'
#' **Return Value:**  
#' Returns a list of HTTP headers created using \code{httr::add_headers()}.
#'
#' **Usage Example:**
#' ```r
#' \dontrun{
#'   keys <- list(
#'       api_key = "your_api_key",
#'       api_secret = "your_api_secret",
#'       api_passphrase = "your_api_passphrase",
#'       key_version = "2"
#'       # Optionally, base_url can be provided; however, build_headers() uses get_base_url() internally.
#'   )
#'
#'   # Build headers for a POST request with a JSON payload.
#'   headers <- coro::await(build_headers("POST", "/api/v1/orders", '{"size": 1}', keys))
#'   print(headers)
#'
#'   # Build headers for a GET request with no payload:
#'   headers <- coro::await(build_headers("GET", "/api/v1/orders", "", keys))
#'   print(headers)
#' }
#' ```
#'
#' @md
#'
#' @importFrom httr add_headers
#' @importFrom digest hmac
#' @importFrom base64enc base64encode
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
#' This function processes an HTTP response from a KuCoin API request. It validates that the response
#' has a successful HTTP status and that the API-specific response code indicates success. If the response is
#' valid, it returns the parsed JSON object.
#' The actual data is often in the `$data` field or `$data$items` etc. especially if the end point is paginated.
#' as needed.
#'
#' **Response Validation Workflow:**  
#' 1. Checks if the HTTP status code is 200.
#' 2. Parses the JSON response.
#' 3. Validates that the response contains the `"code"` field.
#' 4. Ensures the `"code"` is `"200000"` (success); if not, retrieves the error message from the `"msg"` field if available.
#'
#' @param response An HTTP response object (e.g., from \code{httr::GET()}).
#' @param url A character string representing the requested URL (used for error messages).
#'
#' @return A list representing the parsed JSON response. Users are responsible for extracting specific fields (e.g., the `"data"` field) as needed.
#'
#' @md
#' @export
process_kucoin_response <- function(response, url = "") {
    status_code <- httr::status_code(response)
    if (status_code != 200) {
        rlang::abort(paste("HTTP request failed with status code", status_code, "for URL:", url))
    }

    response_text <- httr::content(response, as = "text", encoding = "UTF-8")
    parsed_response <- jsonlite::fromJSON(response_text)

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

#' Generic Pagination Helper for KuCoin API Endpoints
#'
#' This asynchronous helper function facilitates automatic pagination for KuCoin API endpoints that return paginated
#' responses. It repeatedly calls a user-supplied function to fetch each page and aggregates the results using an 
#' aggregation function provided by the user.
#'
#' ## Detailed Workflow:
#' 1. **Fetch a Page:**  
#'    The function calls the user-supplied \code{fetch_page} function with the current query parameters.
#' 2. **Accumulate Results:**  
#'    The items from the current page (extracted via the \code{items_field} parameter) are added to an accumulator.
#' 3. **Determine Continuation:**  
#'    If the current page number is less than the total number of pages (or less than \code{max_pages} if specified),
#'    the function increments the page number and recursively calls itself.
#' 4. **Aggregate and Return:**  
#'    Once all pages have been fetched, the accumulator is passed to the \code{aggregate_fn} to produce the final result.
#'
#' **Parameters:**
#' - **fetch_page:** A function that takes a query list and returns a promise resolving to the page's response.
#' - **query:** A named list of query parameters for the first page (default is \code{list(currentPage = 1, pageSize = 50)}).
#' - **items_field:** The field in the response that contains the items to be aggregated (default is "items").
#' - **accumulator:** An internal accumulator for recursive calls (do not supply this parameter).
#' - **aggregate_fn:** A function to combine the accumulated results into the final output (default returns the accumulator list as is).
#' - **max_pages:** The maximum number of pages to fetch (default is \code{Inf} to fetch all available pages).
#'
#' **Return Value:**  
#' Returns a promise that resolves to the aggregated result as defined by the \code{aggregate_fn}.
#'
#' @md
#'
#' @export
auto_paginate <- coro::async(function(
    fetch_page,
    query = list(currentPage = 1, pageSize = 50),
    items_field = "items",
    accumulator = list(),
    aggregate_fn = function(acc) { acc },
    max_pages = Inf
) {
    tryCatch({
        response <- await(fetch_page(query))
        if (!is.null(response[[items_field]])) {
            page_items <- response[[items_field]]
        } else {
            page_items <- response
        }
        accumulator[[length(accumulator) + 1]] <- page_items
        currentPage <- response$currentPage
        totalPage   <- response$totalPage
        if (is.finite(max_pages) && currentPage >= max_pages) {
            return(aggregate_fn(accumulator))
        } else if (!is.null(currentPage) && !is.null(totalPage) && (currentPage < totalPage)) {
            query$currentPage <- currentPage + 1
            return(await(auto_paginate(fetch_page, query, items_field, accumulator, aggregate_fn, max_pages)))
        } else {
            return(aggregate_fn(accumulator))
        }
    }, error = function(e) {
        rlang::abort(paste("Error in auto_paginate:", conditionMessage(e)))
    })
})
