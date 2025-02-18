# File: ./R/helpers_api_get_server_time.R

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
