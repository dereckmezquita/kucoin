box::use(
    rlang,
    lubridate
)

# File: utils.R

#' Build Query String for KuCoin API Request
#'
#' This function constructs a query string from a named list of parameters.
#' It removes any parameters with \code{NULL} values and concatenates the remaining
#' key-value pairs into a properly formatted query string.
#'
#' **Usage:**
#'
#' 1. Provide a named list of query parameters (e.g., \code{list(currency = "USDT", type = "main")}).
#' 2. The function removes any parameters whose value is \code{NULL}.
#' 3. It then concatenates the names and values into a query string that starts with a question mark
#'    (e.g., \code{"?currency=USDT&type=main"}).
#'
#' **Important:** This function should be called before generating the authentication headers.
#' The complete endpoint (i.e., base endpoint plus the query string) must be passed to the header builder
#' so that the signature is computed over the full path.
#'
#' @param params A named list of query parameters to be appended to the URL.
#'
#' @return A string representing the query part of the URL, beginning with \code{"?"}.
#'
#' @examples
#' \dontrun{
#'     # Example usage:
#'     query <- list(currency = "USDT", type = "main")
#'     qs <- build_query(query)
#'     # qs will be "?currency=USDT&type=main"
#' }
#' @export
build_query <- function(params) {
    params <- params[!sapply(params, is.null)]
    if (length(params) == 0) return("")
    return(paste0("?", paste0(names(params), "=", params, collapse = "&")))
}

#' @export
get_base_url <- function(config = NULL) {
    if (!is.null(config$base_url)) {
        return(config$base_url)
    }
    return("https://api.kucoin.com")
}

#' @export
get_api_keys <- function(
    api_key        = Sys.getenv("KC-API-KEY"),
    api_secret     = Sys.getenv("KC-API-SECRET"),
    api_passphrase = Sys.getenv("KC-API-PASSPHRASE"),
    base_url       = Sys.getenv("KC-API-ENDPOINT"),
    key_version    = "2"
) {
    return(list(
        api_key        = api_key,
        api_secret     = api_secret,
        api_passphrase = api_passphrase,
        base_url       = base_url,
        key_version    = key_version
    ))
}

#' @export
get_subaccount <- function(
    sub_account_name = Sys.getenv("KC-ACCOUNT-SUBACCOUNT-NAME"),
    sub_account_password = Sys.getenv("KC-ACCOUNT-SUBACCOUNT-PASSWORD")
) {
    return(list(
        sub_account_name = sub_account_name,
        sub_account_password = sub_account_password
    ))
}
