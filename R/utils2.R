# File: ./R/utils2.R

#' @export
verify_ticker <- function(ticker) {
    # has to be of format "BTC-USDT"
    if (!grepl("^[A-Z|0-9]+-[A-Z|0-9]+$", ticker)) {
        return(FALSE)
    }
    return(TRUE)
}

#' Convert Kucoin's server time; UNIX timestamp to POSIXct from milliseconds
#' @param ms A numeric value representing the time in milliseconds.
#' @return A POSIXct object representing the time in the UTC timezone.
#' @export
time_convert_from_kucoin_ms <- function(ms) {
    if (!is.numeric(ms)) {
        rlang::abort("Input must be a numeric value.")
    }

    return(lubridate::as_datetime(ms / 1000))
}

#' Convert POSIXct to Kucoin's server time; UNIX timestamp in milliseconds
#' @param datetime A POSIXct object representing the time.
#' @return A numeric value representing the time in milliseconds.
#' @export
time_convert_to_kucoin_ms <- function(datetime) {
    if (!inherits(datetime, "POSIXct")) {
        rlang::abort("Input must be a POSIXct object.")
    }
    return(as.numeric(lubridate::as_datetime(datetime)) * 1000)
}

#' Convert Kucoin's server time; UNIX timestamp to POSIXct from seconds
#' @param s A numeric value representing the time in seconds.
#' @return A POSIXct object representing the time in the UTC timezone.
#' @export
time_convert_from_kucoin_s <- function(s) {
    if (!is.numeric(s)) {
        rlang::abort("Input must be a numeric value.")
    }
    return(lubridate::as_datetime(s))
}

#' Convert POSIXct to Kucoin's server time; UNIX timestamp in seconds
#' @param datetime A POSIXct object representing the time.
#' @return A numeric value representing the time in seconds.
#' @export
time_convert_to_kucoin_s <- function(datetime) {
    if (!inherits(datetime, "POSIXct")) {
        rlang::abort("Input must be a POSIXct object.")
    }
    return(as.numeric(lubridate::as_datetime(datetime)))
}
