#' Build Query String
#'
#' Constructs a URL query string from a named list of parameters, omitting any NULL values.
#'
#' @param params A named list of query parameters.
#'
#' @return A character string beginning with "?" if parameters exist; otherwise an empty string.
#'
#' @examples
#' \dontrun{
#'   qs <- build_query(list(currency = "BTC", type = "trade"))
#'   # qs: "?currency=BTC&type=trade"
#' }
build_query <- function(params) {
    params <- params[!sapply(params, is.null)]
    if (length(params) == 0) return("")
    # Use httr::modify_url with an empty base URL to generate a query string.
    return(httr::modify_url(url = "", query = params))
}

#' Get KuCoin Server Time
#'
#' Asynchronously retrieves the current server time from KuCoin API.
#'
#' @param base_url A character string. The base URL for KuCoin API (default: "https://api.kucoin.com").
#'
#' @return A promise that resolves to a numeric value representing the server timestamp in milliseconds.
#'
#' @examples
#' \dontrun{
#'   get_server_time()$then(function(timestamp) {
#'     cat("Server time:", timestamp, "\n")
#'   })
#' }
get_server_time <- function(base_url = "https://api.kucoin.com") {
    promises$promise(function(resolve, reject) {
        tryCatch({
            res <- httr::GET(paste0(base_url, "/api/v1/timestamp"))
            if (httr::status_code(res) != 200) {
                err_msg <- tryCatch({
                    httr::content(res, as = "text", encoding = "UTF-8")
                }, error = function(e) {
                    return("NO CONTENT")
                })
                reject(rlang::abort(sprintf("HTTP error %s: %s", httr::status_code(res), err_msg)))
            }
            result <- httr::content(res, as = "parsed", simplifyVector = TRUE)
            resolve(result$data)
        }, error = function(e) {
            reject(rlang::abort("Failed to get server time", parent = e))
        })
    })
}

#' Build KuCoin API Headers
#'
#' Asynchronously constructs the HTTP headers required for authenticated KuCoin API requests.
#'
#' @param method A character string. The HTTP method (e.g., "GET", "POST").
#' @param endpoint A character string. The API endpoint path (e.g., "/api/v2/user-info").
#' @param body A character string. The JSON body (or "" for GET requests).
#' @param config A named list with the following required elements:
#'   \describe{
#'     \item{api_key}{Your KuCoin API key.}
#'     \item{api_secret}{Your KuCoin API secret.}
#'     \item{api_passphrase}{Your KuCoin API passphrase.}
#'     \item{key_version}{The API key version (default is "2").}
#'   }
#'
#' @return A promise that resolves to an httr::add_headers object.
#'
#' @examples
#' \dontrun{
#'   config <- list(api_key = "your_key", api_secret = "your_secret",
#'                  api_passphrase = "your_pass", key_version = "2")
#'   build_headers("GET", "/api/v2/user-info", "", config)$
#'     then(function(headers) {
#'       # Use headers in your request
#'     })
#' }
build_headers <- coro::async(function(method, endpoint, body, config) {
    # Get server timestamp
    timestamp <- await(get_server_time(get_base_url(config)))
    
    # Create the prehash string: timestamp + HTTP_METHOD + endpoint + body
    prehash <- paste0(timestamp, toupper(method), endpoint, body)
    
    # Generate the signature using HMAC SHA256 and then Base64-encode it
    sig_raw <- digest::hmac(key = config$api_secret, object = prehash,
                           algo = "sha256", serialize = FALSE, raw = TRUE)
    signature <- base64enc::base64encode(sig_raw)
    
    # Encrypt the API passphrase
    passphrase_raw <- digest::hmac(key = config$api_secret,
                                  object = config$api_passphrase,
                                  algo = "sha256", serialize = FALSE, raw = TRUE)
    encrypted_passphrase <- base64enc::base64encode(passphrase_raw)
    
    httr::add_headers(
        `KC-API-KEY` = config$api_key,
        `KC-API-SIGN` = signature,
        `KC-API-TIMESTAMP` = timestamp,
        `KC-API-PASSPHRASE` = encrypted_passphrase,
        `KC-API-KEY-VERSION` = config$key_version,
        `Content-Type` = "application/json"
    )
})

#' Get Base URL for KuCoin API
#'
#' Returns the base URL for KuCoin REST API calls based on the provided configuration.
#'
#' @param config A named list that may contain the field \code{base_url}.
#'
#' @return A character string representing the base URL.
#'
#' @examples
#' \dontrun{
#'   config <- list(base_url = "https://api.kucoin.com")
#'   url <- get_base_url(config)
#' }
get_base_url <- function(config) {
    if (!is.null(config$base_url)) {
        return(config$base_url)
    }
    return("https://api.kucoin.com")
}
