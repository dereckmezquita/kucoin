# File: get_api_keys.R
#' @export
get_api_keys <- function(
    api_key = Sys.getenv("KC-API-KEY"),
    api_secret = Sys.getenv("KC-API-SECRET"),
    api_passphrase = Sys.getenv("KC-API-PASSPHRASE"),
    base_url = Sys.getenv("KC-API-ENDPOINT"),
    key_version = "2"
) {
    list(
        api_key = api_key,
        api_secret = api_secret,
        api_passphrase = api_passphrase,
        base_url = base_url,
        key_version = key_version
    )
}