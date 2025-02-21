# File: ./R/utils_time_convert_kucoin.R

# box::use(
#   lubridate[as_datetime],
#   rlang[abort]
# )

#' Convert KuCoin Server Time to POSIXct
#'
#' Converts a UNIX timestamp from KuCoin's server into a POSIXct object in UTC, based on the specified time unit.
#'
#' ### Workflow Overview
#' 1. **Input Validation**: Ensures `time_value` is numeric, aborting if not.
#' 2. **Unit Matching**: Validates `unit` against allowed options (`"ms"`, `"ns"`, `"s"`) using `match.arg()`.
#' 3. **Time Conversion**: Converts the timestamp to seconds based on the unit and then to POSIXct using `lubridate::as_datetime()`.
#'
#' ### API Endpoint
#' Not applicable (helper function for timestamp conversion).
#'
#' ### Usage
#' Utilised to transform KuCoin API timestamps into R's POSIXct format for analysis or visualisation.
#'
#' ### Official Documentation
#' Not directly tied to a specific endpoint; see KuCoin API timestamp usage guidelines.
#'
#' @param time_value Numeric value representing the UNIX timestamp.
#' @param unit Character string specifying the input time unit: `"ms"` for milliseconds (default), `"ns"` for nanoseconds, or `"s"` for seconds.
#' @return POSIXct object representing the timestamp in UTC.
#' @examples
#' \dontrun{
#' # Convert a millisecond timestamp
#' time_convert_from_kucoin(time_value = 1698777600000, unit = "ms")
#' # Returns POSIXct equivalent of 2023-10-31 16:00:00 UTC
#'
#' # Convert a nanosecond timestamp
#' time_convert_from_kucoin(time_value = 1698777600000000000, unit = "ns")
#' # Returns POSIXct equivalent of 2023-10-31 16:00:00 UTC
#' }
#' @importFrom lubridate as_datetime
#' @importFrom rlang abort
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

#' Convert POSIXct to KuCoin Server Time
#'
#' Converts a POSIXct object into a UNIX timestamp in the specified unit, compatible with KuCoin's server time requirements.
#'
#' ### Workflow Overview
#' 1. **Input Validation**: Ensures `datetime` is a POSIXct object, aborting if not.
#' 2. **Unit Matching**: Validates `unit` against allowed options (`"ms"`, `"ns"`, `"s"`) using `match.arg()`.
#' 3. **Time Conversion**: Converts the POSIXct to seconds and scales to the desired unit (milliseconds, nanoseconds, or seconds).
#'
#' ### API Endpoint
#' Not applicable (helper function for timestamp conversion).
#'
#' ### Usage
#' Utilised to prepare timestamps in the appropriate UNIX format for KuCoin API requests.
#'
#' ### Official Documentation
#' Not directly tied to a specific endpoint; see KuCoin API timestamp usage guidelines.
#'
#' @param datetime POSIXct object representing the timestamp to convert.
#' @param unit Character string specifying the output time unit: `"ms"` for milliseconds (default), `"ns"` for nanoseconds, or `"s"` for seconds.
#' @return Numeric value representing the UNIX timestamp in the specified unit.
#' @examples
#' \dontrun{
#' # Convert to milliseconds
#' dt <- as.POSIXct("2023-10-31 16:00:00", tz = "UTC")
#' time_convert_to_kucoin(datetime = dt, unit = "ms")
#' # Returns 1698777600000
#'
#' # Convert to nanoseconds
#' time_convert_to_kucoin(datetime = dt, unit = "ns")
#' # Returns 1698777600000000000
#' }
#' @importFrom lubridate as_datetime
#' @importFrom rlang abort
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
