#' KucoinBasicInfo R6 Class for Account Basic Info Endpoints
#'
#' This class implements the Basic Info endpoints (under Account > Basic Info)
#' from the KuCoin API. In particular, it implements the "Get Account Summary Info"
#' endpoint (\code{GET /api/v2/user-info}). This module is designed so that it can be
#' used independently or composed into a master KuCoin client that aggregates multiple
#' submodules.
#'
#' @section Expected Inputs:
#' The class expects a configuration list with the following keys:
#' \describe{
#'   \item{api_key}{(string) Your KuCoin API key.}
#'   \item{api_secret}{(string) Your KuCoin API secret.}
#'   \item{api_passphrase}{(string) Your KuCoin API passphrase.}
#'   \item{key_version}{(string) API key version (default is "2").}
#'   \item{base_url}{(string) The base URL for API calls (default is "https://api.kucoin.com").}
#' }
#'
#' @section Expected Output:
#' The method \code{getAccountSummaryInfo()} returns a promise that resolves with a list
#' containing the following fields:
#' \describe{
#'   \item{level}{User level (integer).}
#'   \item{subQuantity}{Number of sub-accounts (integer).}
#'   \item{maxDefaultSubQuantity}{Maximum number of default sub-accounts (integer).}
#'   \item{maxSubQuantity}{Maximum total sub-accounts (integer).}
#'   \item{spotSubQuantity}{Number of sub-accounts with spot trading enabled (integer).}
#'   \item{marginSubQuantity}{Number of sub-accounts with margin trading enabled (integer).}
#'   \item{futuresSubQuantity}{Number of sub-accounts with futures trading enabled (integer).}
#'   \item{maxSpotSubQuantity}{Max number of additional spot sub-accounts (integer).}
#'   \item{maxMarginSubQuantity}{Max number of additional margin sub-accounts (integer).}
#'   \item{maxFuturesSubQuantity}{Max number of additional futures sub-accounts (integer).}
#' }
#'
#' @import R6
#' @import promises
#' @import later
#' @export
KucoinBasicInfo <- R6::R6Class("KucoinBasicInfo",
  public = list(
    #' @field config A list containing the API configuration.
    config = NULL,
    
    #' Initialize a new KucoinBasicInfo instance.
    #'
    #' @param config A named list containing the required API credentials and settings.
    #'   Expected keys: \code{api_key}, \code{api_secret}, \code{api_passphrase}.
    #'   Optional keys: \code{key_version} (default "2"), \code{base_url} (default "https://api.kucoin.com").
    #' @return A new \code{KucoinBasicInfo} object.
    #' @examples
    #' \dontrun{
    #'   config <- list(api_key = "your_key", api_secret = "your_secret",
    #'                  api_passphrase = "your_pass", key_version = "2",
    #'                  base_url = "https://api.kucoin.com")
    #'   basic_info <- KucoinBasicInfo$new(config)
    #' }
    initialize = function(config) {
      required <- c("api_key", "api_secret", "api_passphrase")
      missing <- setdiff(required, names(config))
      if (length(missing) > 0) {
        rlang::abort(sprintf("Missing required config fields: %s",
                             paste(missing, collapse = ", ")))
      }
      if (is.null(config$key_version)) {
        config$key_version <- "2"
      }
      if (is.null(config$base_url)) {
        config$base_url <- "https://api.kucoin.com"
      }
      self$config <- config
    },
    
    #' Get Account Summary Info
    #'
    #' Retrieves the account summary information using the KuCoin endpoint \code{GET /api/v2/user-info}.
    #'
    #' @return A promise that resolves to a list containing the account summary details.
    #' @examples
    #' \dontrun{
    #'   basic_info$getAccountSummaryInfo()$
    #'     then(function(data) {
    #'       # data is a list with fields: level, subQuantity, etc.
    #'       print(data)
    #'     })$
    #'     catch(function(error) {
    #'       message("Error: ", error$message)
    #'     })
    #' }
    getAccountSummaryInfo = function() {
      promises::promise(function(resolve, reject) {
        later::later(function() {
          tryCatch({
            method <- "GET"
            endpoint <- "/api/v2/user-info"
            body <- ""  # For GET requests, body is an empty string.
            base_url <- get_base_url(self$config)  # from helpers.R
            url <- paste0(base_url, endpoint)
            
            # Call the generic build_headers() helper (from helpers.R)
            headers <- build_headers(method, endpoint, body, self$config)
            
            # Perform the HTTP GET call.
            res <- httr::GET(url, headers)
            if (httr::status_code(res) != 200) {
              err_msg <- tryCatch(httr::content(res, as = "text", encoding = "UTF-8"),
                                  error = function(e) "No content")
              rlang::abort(sprintf("HTTP error %s: %s", httr::status_code(res), err_msg))
            }
            result <- httr::content(res, as = "parsed", simplifyVector = TRUE)
            if (!is.null(result$code) && result$code != "200000") {
              rlang::abort(sprintf("API error %s: %s", result$code, result$msg))
            }
            resolve(result$data)
          }, error = function(e) {
            reject(rlang::abort("Failed to retrieve account summary info", parent = e))
          })
        }, delay = 0.001)
      })
    }
  )
)