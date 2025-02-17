# File: ./R/utils2.R

#' Convert Kucoin's server time; UNIX timestamp to POSIXct
#' @param ms A numeric value representing the time in milliseconds.
#' @return A POSIXct object representing the time in the UTC timezone.
#' @export
time_convert_from_kucoin_ms <- function(ms) {
    if (!is.numeric(ms)) {
        rlang::abort("Input must be a numeric value.")
    }

    return(lubridate::as_datetime(ms / 1000))
}

#' Convert POSIXct to Kucoin's server time; UNIX timestamp
#' @param datetime A POSIXct object representing the time.
#' @return A numeric value representing the time in milliseconds.
#' @export
time_convert_to_kucoin_ms <- function(datetime) {
    if (!inherits(datetime, "POSIXct")) {
        rlang::abort("Input must be a POSIXct object.")
    }
    return(as.numeric(lubridate::as_datetime(datetime)) * 1000)
}
