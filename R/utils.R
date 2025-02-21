# File: ./R/utils.R

#' Verify Ticker Symbol Format
#'
#' Checks whether a ticker symbol adheres to the format `"BTC-USDT"`, consisting of uppercase alphanumeric characters separated by a dash.
#'
#' @param ticker Character string representing the ticker symbol to verify.
#' @return Logical; `TRUE` if the symbol is valid, `FALSE` otherwise.
#' @examples
#' \dontrun{
#' verify_symbol("BTC-USDT")  # Returns TRUE
#' verify_symbol("btc-usdt")  # Returns FALSE
#' verify_symbol("BTC_USDT")  # Returns FALSE
#' }
#' @export
verify_symbol <- function(ticker) {
    if (!grepl("^[A-Za-z0-9]+-[A-Za-z0-9]+$", ticker)) {
        return(FALSE)
    }
    return(TRUE)
}

#' Build KuCoin API Query String
#'
#' Constructs a URL query string from a named list of parameters for KuCoin API requests. The process involves:
#'
#' 1. **Filtering NULL Values**: Removes any parameters with `NULL` values from the input list.
#' 2. **Concatenating Parameters**: Combines remaining key-value pairs into a query string, starting with a `?` and formatted as `"key1=value1&key2=value2"`.
#'
#' **Important**: For authenticated requests, pass the complete URL (base endpoint + query string) to the header builder to ensure the signature includes the full path.
#'
#' @param params Named list of query parameters.
#' @return Character string representing the query part of the URL. Returns an empty string (`""`) if no parameters are provided.
#' @examples
#' \dontrun{
#' # Basic usage
#' params <- list(currency = "USDT", type = "main")
#' build_query(params)  # Returns "?currency=USDT&type=main"
#'
#' # Empty list
#' build_query(list())  # Returns ""
#' }
#' @export
build_query <- function(params) {
    params <- params[!sapply(params, is.null)]
    if (length(params) == 0) return("")
    return(paste0("?", paste0(names(params), "=", params, collapse = "&")))
}

#' Retrieve KuCoin API Base URL
#'
#' Returns the base URL for the KuCoin API, determined by the following priority:
#'
#' 1. Uses the explicitly provided `url` parameter if specified.
#' 2. If `url` is `NULL` or empty, checks the `"KC-API-ENDPOINT"` environment variable.
#' 3. Falls back to the default `"https://api.kucoin.com"` if neither above source provides a value.
#'
#' @param url Character string representing the base URL. Defaults to `Sys.getenv("KC-API-ENDPOINT")`.
#' @return Character string containing the determined base URL.
#' @examples
#' \dontrun{
#' # Default behavior (uses environment variable or fallback)
#' get_base_url()  # Might return "https://api.kucoin.com" if KC-API-ENDPOINT is unset
#'
#' # Explicit URL
#' get_base_url("https://testnet.kucoin.com")  # Returns "https://testnet.kucoin.com"
#' }
#' @export
get_base_url <- function(url = Sys.getenv("KC-API-ENDPOINT")) {
    if (is.null(url) || !nzchar(url)) {
        return("https://api.kucoin.com")
    }
    return(url)
}

#' Retrieve KuCoin API Keys from Environment Variables
#'
#' Fetches KuCoin API credentials from environment variables and returns them as a list. Expected environment variables are:
#'
#' - `KC-API-KEY`: The API key.
#' - `KC-API-SECRET`: The API secret.
#' - `KC-API-PASSPHRASE`: The API passphrase.
#' - `KC-API-ENDPOINT`: Optional base URL (handled by `get_base_url()`).
#'
#' Includes a default API key version (`"2"`). These credentials are required for authenticated KuCoin API requests.
#'
#' @param api_key Character string; the KuCoin API key. Defaults to `Sys.getenv("KC-API-KEY")`.
#' @param api_secret Character string; the KuCoin API secret. Defaults to `Sys.getenv("KC-API-SECRET")`.
#' @param api_passphrase Character string; the KuCoin API passphrase. Defaults to `Sys.getenv("KC-API-PASSPHRASE")`.
#' @param key_version Character string; the API key version. Defaults to `"2"`.
#' @return List containing the API credentials: `api_key`, `api_secret`, `api_passphrase`, and `key_version`.
#' @examples
#' \dontrun{
#' # Retrieve credentials from environment variables
#' config <- get_api_keys()
#' print(config)
#'
#' # Specify credentials manually
#' config <- get_api_keys(
#'   api_key = "my_key",
#'   api_secret = "my_secret",
#'   api_passphrase = "my_pass",
#'   key_version = "2"
#' )
#' print(config)
#' }
#' @export
get_api_keys <- function(
    api_key        = Sys.getenv("KC-API-KEY"),
    api_secret     = Sys.getenv("KC-API-SECRET"),
    api_passphrase = Sys.getenv("KC-API-PASSPHRASE"),
    key_version    = "2"
) {
    return(list(
        api_key        = api_key,
        api_secret     = api_secret,
        api_passphrase = api_passphrase,
        key_version    = key_version
    ))
}

#' Retrieve KuCoin Sub-Account Configuration from Environment Variables
#'
#' Fetches sub-account-specific configuration parameters from environment variables. Expected variables are:
#'
#' - `KC-ACCOUNT-SUBACCOUNT-NAME`: The sub-account name.
#' - `KC-ACCOUNT-SUBACCOUNT-PASSWORD`: The sub-account password.
#'
#' These parameters are used for sub-account-related operations in the KuCoin API.
#'
#' @param sub_account_name Character string; the sub-account name. Defaults to `Sys.getenv("KC-ACCOUNT-SUBACCOUNT-NAME")`.
#' @param sub_account_password Character string; the sub-account password. Defaults to `Sys.getenv("KC-ACCOUNT-SUBACCOUNT-PASSWORD")`.
#' @return List containing sub-account configuration: `sub_account_name` and `sub_account_password`.
#' @examples
#' \dontrun{
#' # Retrieve sub-account config from environment variables
#' sub_cfg <- get_subaccount()
#' print(sub_cfg)
#'
#' # Specify sub-account details manually
#' sub_cfg <- get_subaccount(
#'   sub_account_name = "my_subaccount",
#'   sub_account_password = "my_password"
#' )
#' print(sub_cfg)
#' }
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
