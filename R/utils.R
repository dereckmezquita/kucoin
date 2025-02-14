# File: utils.R

#' Build Query String for KuCoin API Request
#'
#' This function constructs a URL query string from a named list of parameters. It performs the following steps:
#'
#' 1. **Filter NULL Values:**  
#'    It removes any parameters whose value is \code{NULL} from the input list.
#'
#' 2. **Concatenate Parameters:**  
#'    It concatenates the remaining key-value pairs into a properly formatted query string. The resulting string 
#'    starts with a question mark and uses the format \code{"?key1=value1&key2=value2"}.
#'
#' **Important:**  
#' When building an authenticated request, the complete URL (base endpoint plus query string) must be passed to the 
#' header builder to ensure that the signature is computed over the full path.
#'
#' @param params A named list of query parameters.
#'
#' @return A string representing the query part of the URL. If no parameters are provided, an empty string is returned.
#'
#' @examples
#' \dontrun{
#'   # Example usage:
#'   query <- list(currency = "USDT", type = "main")
#'   qs <- build_query(query)
#'   # qs will be "?currency=USDT&type=main"
#' }
#'
#' @export
build_query <- function(params) {
    params <- params[!sapply(params, is.null)]
    if (length(params) == 0) return("")
    return(paste0("?", paste0(names(params), "=", params, collapse = "&")))
}

#' Get Base URL for KuCoin API
#'
#' This function returns the base URL for the KuCoin API. It checks if a configuration list is provided
#' and contains a \code{base_url} field; if so, it returns that value. Otherwise, it defaults to 
#' \code{"https://api.kucoin.com"}.
#'
#' @param config (Optional) A list containing API configuration parameters.
#'
#' @return A character string representing the base URL.
#'
#' @examples
#' \dontrun{
#'   config <- list(base_url = "https://api.kucoin.com")
#'   url <- get_base_url(config)  # Returns "https://api.kucoin.com"
#'
#'   url <- get_base_url()  # Returns the default "https://api.kucoin.com"
#' }
#'
#' @export
get_base_url <- function(config = NULL) {
    if (!is.null(config$base_url)) {
        return(config$base_url)
    }
    return("https://api.kucoin.com")
}

#' Retrieve KuCoin API Keys from Environment Variables
#'
#' This function retrieves the KuCoin API credentials from environment variables and returns them as a list.
#' It expects the following environment variables to be set:
#' - \code{KC-API-KEY}
#' - \code{KC-API-SECRET}
#' - \code{KC-API-PASSPHRASE}
#' - \code{KC-API-ENDPOINT} (optional)
#'
#' It also sets the API key version (default is "2"). These credentials are essential for making authenticated
#' requests to the KuCoin API.
#'
#' @param api_key        (Optional) The KuCoin API key. Defaults to \code{Sys.getenv("KC-API-KEY")}.
#' @param api_secret     (Optional) The KuCoin API secret. Defaults to \code{Sys.getenv("KC-API-SECRET")}.
#' @param api_passphrase (Optional) The KuCoin API passphrase. Defaults to \code{Sys.getenv("KC-API-PASSPHRASE")}.
#' @param base_url       (Optional) The base URL for the API. Defaults to \code{Sys.getenv("KC-API-ENDPOINT")}.
#' @param key_version    (Optional) The API key version. Defaults to "2".
#'
#' @return A list containing the API credentials and configuration parameters.
#'
#' @examples
#' \dontrun{
#'   config <- get_api_keys()
#'   print(config)
#' }
#'
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

#' Retrieve SubAccount Configuration from Environment Variables
#'
#' This function retrieves sub-account–specific configuration parameters from environment variables.
#' It expects the following environment variables to be set:
#' - \code{KC-ACCOUNT-SUBACCOUNT-NAME}: The sub-account name.
#' - \code{KC-ACCOUNT-SUBACCOUNT-PASSWORD}: The sub-account password.
#'
#' These parameters are used for sub-account related operations.
#'
#' @param sub_account_name (Optional) The sub-account name. Defaults to \code{Sys.getenv("KC-ACCOUNT-SUBACCOUNT-NAME")}.
#' @param sub_account_password (Optional) The sub-account password. Defaults to \code{Sys.getenv("KC-ACCOUNT-SUBACCOUNT-PASSWORD")}.
#'
#' @return A list containing sub-account configuration parameters.
#'
#' @examples
#' \dontrun{
#'   sub_cfg <- get_subaccount()
#'   print(sub_cfg)
#' }
#'
#' @export
get_subaccount <- function(
    sub_account_name     = Sys.getenv("KC-ACCOUNT-SUBACCOUNT-NAME"),
    sub_account_password = Sys.getenv("KC-ACCOUNT-SUBACCOUNT-PASSWORD")
) {
    return(list(
        sub_account_name = sub_account_name,
        sub_account_password = sub_account_password
    ))
}
