# File: utils.R

#' @export
build_query <- function(params) {
    params <- params[!sapply(params, is.null)]
    if (length(params) == 0) return("")
    return(httr::modify_url(url = "", query = params))
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
