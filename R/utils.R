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

#' Convert a POSIXct DateTime to Milliseconds
#'
#' This function converts a POSIXct datetime into milliseconds since the Unix epoch.
#'
#' @param datetime A POSIXct object.
#' @return A numeric value (milliseconds).
#' @export
convert_datetime_to_ms <- function(datetime) {
    if (!inherits(datetime, "POSIXt")) {
        rlang::abort("Input must be a POSIXct object.")
    }
    return(as.numeric(datetime) * 1000)
}

#' Convert a Datetime Range to Milliseconds
#'
#' This function accepts a start time and an end time as separate inputs (each should be a POSIXct object).
#' If one is missing, it defaults to a 24‐hour window (end_time defaults to now() if both are missing,
#' or start_time defaults to end_time minus 24 hours, etc.). It returns a list with elements
#' `startAt` and `endAt` in milliseconds.
#'
#' @param start_time A POSIXct object for the start time. If NULL, defaults to end_time minus 24 hours.
#' @param end_time A POSIXct object for the end time. If NULL, defaults to start_time plus 24 hours.
#'
#' @return A list with two elements: startAt and endAt (in milliseconds).
#'
#' @examples
#' \dontrun{
#'   library(lubridate)
#'   times <- convert_datetime_range_to_ms(>
#'     as_datetime("2023-02-01 00:00:00", tz = "UTC"),
#'     as_datetime("2023-02-02 00:00:00", tz = "UTC")
#'   )
#'   # times$startAt and times$endAt are now in milliseconds.
#' }
#' @export
convert_datetime_range_to_ms <- function(start_time, end_time) {
    local_now <- lubridate::now(tzone = "UTC")

    if (is.null(start_time) && is.null(end_time)) {
        end_time <- local_now
        start_time <- end_time - lubridate::dhours(24)
    } else if (is.null(start_time)) {
        start_time <- lubridate::as_datetime(end_time) - lubridate::dhours(24)
    } else if (is.null(end_time)) {
        end_time <- lubridate::as_datetime(start_time) + lubridate::dhours(24)
    }

    if (start_time > end_time) {
        rlang::abort("start_time must be before end_time.")
    }

    return(list(
        startAt = convert_datetime_to_ms(start_time),
        endAt   = convert_datetime_to_ms(end_time)
    ))
}