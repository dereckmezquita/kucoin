# box::use(./utils[get_base_url])

#' Get Server Time from KuCoin Futures API
#'
#' Retrieves the current API server time (Unix timestamp in milliseconds) from the KuCoin Futures API.
#' This function performs an asynchronous GET request and returns a promise that either resolves to the
#' server timestamp or rejects with an error. The server time is a critical component when making
#' authenticated requests to KuCoin's API. For these requests (e.g., placing orders or fetching account data),
#' the API requires you to include a timestamp header that is within 5 seconds of the actual server time.
#' This helps ensure that requests are timely and protects against replay attacks.
#'
#' The helper function \code{get_base_url()} is used to retrieve the base URL for the Futures domain.
#'
#' For further details, refer to the official KuCoin API documentation:
#' \url{https://www.kucoin.com/docs-new/rest/futures-trading/market-data/get-server-time}
#'
#' @param base_url The base URL for the KuCoin Futures API. Defaults to the result of \code{get_base_url()}.
#' @return A promise that resolves to a numeric Unix timestamp in milliseconds.
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
#' @importFrom httr GET timeout content status_code
#' @importFrom jsonlite fromJSON
#' @importFrom rlang abort
#' @importFrom promises promise
#' @export
get_server_time <- function(base_url = get_base_url()) {
    promises::promise(function(resolve, reject) {
        tryCatch({
            url <- paste0(base_url, "/api/v1/timestamp")
            response <- httr::GET(url, httr::timeout(3))
            if (httr::status_code(response) != 200) {
                reject(rlang::abort(
                    "KuCoin API request failed",
                    error_details = list(
                        status_code = httr::status_code(response),
                        url = url
                    )
                ))
                return(NULL)
            }
            # Extract and parse the response.
            response_text <- httr::content(response, as = "text", encoding = "UTF-8")
            parsed_response <- jsonlite::fromJSON(response_text)
            # Check that the response contains the required fields.
            if (!all(c("code", "data") %in% names(parsed_response))) {
                reject(rlang::abort(
                    "Invalid API response structure",
                    error_details = list(response = parsed_response)
                ))
                return(NULL)
            }
            # Ensure that the API returned a successful code.
            if (parsed_response$code != "200000") {
                reject(rlang::abort(
                    "KuCoin API returned an error",
                    error_details = list(
                        code = parsed_response$code,
                        response = parsed_response
                    )
                ))
                return(NULL)
            }
            resolve(parsed_response$data)
        }, error = function(e) {
            reject(rlang::abort("Error retrieving server time", parent = rlang::as_error(e)))
        })
    })
}

#' @export
build_headers <- coro::async(function(method, endpoint, body, config) {
    tryCatch({
        timestamp <- await(get_server_time(get_base_url(config)))
        prehash <- paste0(timestamp, toupper(method), endpoint, body)
        sig_raw <- digest::hmac(
            key = config$api_secret,
            object = prehash,
            algo = "sha256",
            serialize = FALSE,
            raw = TRUE
        )
        signature <- base64enc::base64encode(sig_raw)
        passphrase_raw <- digest::hmac(
            key = config$api_secret,
            object = config$api_passphrase,
            algo = "sha256",
            serialize = FALSE,
            raw = TRUE
        )
        encrypted_passphrase <- base64enc::base64encode(passphrase_raw)
        httr::add_headers(
            `KC-API-KEY` = config$api_key,
            `KC-API-SIGN` = signature,
            `KC-API-TIMESTAMP` = timestamp,
            `KC-API-PASSPHRASE` = encrypted_passphrase,
            `KC-API-KEY-VERSION` = config$key_version,
            `Content-Type` = "application/json"
        )
    }, error = function(e) {
        if (inherits(e, "kucoin_error")) {
            rlang::abort(e$message, parent = e)
        } else {
            kucoin_error(
                message = "Failed to build request headers",
                class = "kucoin_headers_error",
                parent = e
            )
        }
    })
})