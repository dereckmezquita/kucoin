# File: ./R/utils2.R

#' Verify Symbol Format
#'
#' Checks whether the ticker symbol is of the format "BTC-USDT" (uppercase alphanumeric separated by a dash).
#'
#' @param ticker A character string representing the symbol.
#' @return A logical value; TRUE if the symbol is valid, FALSE otherwise.
#' @export
verify_symbol <- function(ticker) {
    # has to be of format "BTC-USDT"
    if (!grepl("^[A-Z|0-9]+-[A-Z|0-9]+$", ticker)) {
        return(FALSE)
    }
    return(TRUE)
}

#' Convert KuCoin's Server Time to POSIXct
#'
#' Converts a UNIX timestamp (in the specified unit) from KuCoin's server to a POSIXct object (UTC).
#'
#' @param time_value A numeric value representing the time.
#' @param unit A character string specifying the time unit: "ms" for milliseconds (default) or "s" for seconds.
#' @return A POSIXct object representing the time in UTC.
#' @export
time_convert_from_kucoin <- function(time_value, unit = c("ms", "ns", "s")) {
    unit <- match.arg(unit)
    if (!is.numeric(time_value)) {
        rlang::abort("Input must be a numeric value.")
    }
    switch(unit,
        ms = {
            # Convert milliseconds to seconds and then to POSIXct.
            lubridate::as_datetime(time_value / 1000)
        },
        ns = {
            # Convert nanoseconds to seconds and then to POSIXct.
            lubridate::as_datetime(time_value / 1e9)
        },
        s = {
            # Use the value as seconds.
            lubridate::as_datetime(time_value)
        }
    )
}

#' Convert POSIXct to KuCoin's Server Time
#'
#' Converts a POSIXct object to a UNIX timestamp in the specified unit for KuCoin's server.
#'
#' @param datetime A POSIXct object representing the time.
#' @param unit A character string specifying the output time unit: "ms" for milliseconds (default) or "s" for seconds.
#' @return A numeric value representing the time in the specified unit.
#' @export
time_convert_to_kucoin <- function(datetime, unit = c("ms", "ns", "s")) {
    unit <- match.arg(unit)
    if (!inherits(datetime, "POSIXct")) {
        rlang::abort("Input must be a POSIXct object.")
    }
    switch(unit,
        ms = {
            # Convert POSIXct to numeric (seconds) then multiply by 1000.
            as.numeric(lubridate::as_datetime(datetime)) * 1000
        },
        ns = {
            # Convert POSIXct to numeric (seconds) then multiply by 1e9.
            as.numeric(lubridate::as_datetime(datetime)) * 1e9
        },
        s = {
            # Convert POSIXct to numeric and then to integer.
            as.integer(as.numeric(lubridate::as_datetime(datetime)))
        }
    )
}
