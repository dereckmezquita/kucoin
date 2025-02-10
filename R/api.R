box::use(./utils[get_base_url])

#' Get Server Time from KuCoin Futures API
#'
#' Retrieves the current API server time (Unix timestamp in milliseconds) from the KuCoin Futures API.
#' This function performs an asynchronous GET request using a future promise and returns a promise
#' that resolves to the server timestamp.
#'
#' The helper function \code{get_base_url()} is used to retrieve the base URL for the Futures domain.
#'
#' @return A promise that resolves to a numeric timestamp.
#' @import httr jsonlite promises future rlang
#' @export
get_server_time <- function(base_url = get_base_url()) {
    promises::future_promise({
        tryCatch({
            url <- paste0(base_url, "/api/v1/timestamp")
            # Execute the GET request with a 10-second timeout.
            response <- httr::GET(url, httr::timeout(10))
            # Validate the HTTP response status.
            if (httr::status_code(response) != 200) {
                rlang::abort(
                    "KuCoin API request failed",
                    error_details = list(
                        status_code = httr::status_code(response),
                        url = url
                    )
                )
            }
            # Extract and parse the response.
            response_text <- httr::content(response, as = "text", encoding = "UTF-8")
            parsed_response <- jsonlite::fromJSON(response_text)
            # Check that the response contains the required fields.
            if (!all(c("code", "data") %in% names(parsed_response))) {
                rlang::abort(
                    "Invalid API response structure",
                    error_details = list(response = parsed_response)
                )
            }
            # Ensure that the API returned a successful code.
            if (parsed_response$code != "200000") {
                rlang::abort(
                    "KuCoin API returned an error",
                    error_details = list(
                        code = parsed_response$code,
                        response = parsed_response
                    )
                )
            }
            return(parsed_response$data)
        }, error = function(e) {
            rlang::abort("Error retrieving server time", parent = e)
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