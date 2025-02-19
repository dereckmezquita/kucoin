# File: errors.R
#' @export
kucoin_error <- function(message, class = NULL, ..., call = rlang::caller_env(), parent = NULL) {
    rlang::abort(
        message = message,
        class = c(class, "kucoin_error"),
        ...,
        call = call,
        parent = parent
    )
}

#' @export
http_error <- function(status, content, call = rlang::caller_env()) {
    kucoin_error(
        message = sprintf("HTTP error %s: %s", status, content),
        class = "kucoin_http_error",
        status = status,
        content = content,
        call = call
    )
}

#' @export
api_error <- function(code, msg, call = rlang::caller_env()) {
    kucoin_error(
        message = sprintf("API error %s: %s", code, msg),
        class = "kucoin_api_error",
        code = code,
        msg = msg,
        call = call
    )
}