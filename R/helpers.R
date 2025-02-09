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
  httr::modify_url(url = "", query = params)
}

#' Build KuCoin API Headers
#'
#' Constructs the HTTP headers required for authenticated KuCoin API requests.
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
#' @return An object (of class \code{request}) returned by \code{httr::add_headers()}.
#'
#' @examples
#' \dontrun{
#'   config <- list(api_key = "your_key", api_secret = "your_secret",
#'                  api_passphrase = "your_pass", key_version = "2")
#'   headers <- build_headers("GET", "/api/v2/user-info", "", config)
#' }
build_headers <- function(method, endpoint, body, config) {
  # Get current timestamp in milliseconds as a character string.
  timestamp <- sprintf("%.0f", as.numeric(Sys.time()) * 1000)
  
  # Create the prehash string: timestamp + HTTP_METHOD + endpoint + body.
  prehash <- paste0(timestamp, toupper(method), endpoint, body)
  
  # Generate the signature using HMAC SHA256 and then Base64-encode it.
  sig_raw <- digest::hmac(key = config$api_secret, object = prehash,
                            algo = "sha256", serialize = FALSE, raw = TRUE)
  signature <- base64enc::base64encode(sig_raw)
  
  # Encrypt the API passphrase (using the same process as for the signature).
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
}

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