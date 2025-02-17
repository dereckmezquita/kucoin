# File: ./R/impl_market_data_new.R

box::use(
    ./helpers_api[ process_kucoin_response ],
    ./utils[ build_query, get_base_url ],
    ./utils2
)

#' Get Klines market data allowed frequencies
#' @export
freq_to_second_map <- list(
    "1min"    = 60,
    "3min"    = 180,
    "5min"    = 300,
    "15min"   = 900,
    "30min"   = 1800,
    "1hour"   = 3600,
    "2hour"   = 7200,
    "4hour"   = 14400,
    "6hour"   = 21600,
    "8hour"   = 28800,
    "12hour"  = 43200,
    "1day"    = 86400,
    "1week"   = 604800,
    "1month"  = 2592000
)

#' Check Allowed Frequency String
#' @param freq A character string representing the frequency (e.g. "1min", "3min", etc.).
#' @export
check_allowed_frequency_str <- function(freq_str) {
    if (!freq_str %in% names(freq_to_second_map)) {
        rlang::abort(paste("Invalid frequency. Allowed values are:", paste(names(freq_to_second_map), collapse = ", ")))
    }
}

#' Check Allowed Frequency in Seconds
#' @param freq A numeric value representing the frequency in seconds.
#' @export
check_allowed_frequency_s <- function(freq_s) {
    if (!freq_s %in% unlist(freq_to_second_map)) {
        rlang::abort(paste("Invalid frequency in seconds. Allowed values are:", paste(unlist(freq_to_second_map), collapse = ", ")))
    }
}

#' Convert Frequency String to Seconds
#'
#' Given a frequency string (e.g. "1min", "3min", "1hour", etc.), this function returns
#' the corresponding duration in seconds.
#'
#' @param freq A character string representing the frequency. Allowed values are:
#'   "1min", "3min", "5min", "15min", "30min", "1hour", "2hour", "4hour", "6hour", "8hour",
#'   "12hour", "1day", "1week", "1month".
#'
#' @return A numeric value representing the duration in seconds.
#'
#' @examples
#' frequency_to_seconds("1min")  # returns 60
#'
#' @export
frequency_to_seconds <- function(freq) {
    check_allowed_frequency_str(freq)
    return(freq_to_second_map[[freq]])
}

#' Split a Time Range into Segments by Maximum Candle Count
#'
#' Given a start and end time (POSIXct) and the duration of a single candle (in seconds),
#' this function splits the overall time range into segments such that each segment covers at most
#' `max_candles` candles.
#'
#' @param from A POSIXct object representing the start time.
#' @param to A POSIXct object representing the end time.
#' @param candle_duration_s A numeric value; the duration of one candle in seconds.
#' @param max_candles Maximum number of candles per segment (default is 1500).
#'
#' @return A data.table with two columns, `from` and `to`, where each row defines a segment.
#'
#' @examples
#' # For a 1min candle, a segment covers 1500 minutes.
#' # minus 2 hours and convert to seconds
#' from <- lubridate::now() - 2 * 3600
#' to <- lubridate::now()
#' candle_duration_s <- 60
#' split_time_range_by_candles(from, to, candle_duration_s)
#'
#' @export
split_time_range_by_candles <- function(from, to, candle_duration_s, max_candles = 1500) {
    if (from >= to) {
        rlang::abort('"from" must be earlier than "to".')
    }
    check_allowed_frequency_s(candle_duration_s)

    from_s <- utils2$time_convert_to_kucoin_s(from)
    to_s <- utils2$time_convert_to_kucoin_s(to)
    total_seconds <- to_s - from_s

    time_interval <- lubridate::interval(from, to)

    segment_seconds <- max_candles * candle_duration_s
    # if the whole segement can be covered by 1500 data points
    if (total_seconds <= segment_seconds) {
        return(data.table::data.table(from = from, to = to))
    }
    seg_starts <- seq(from, to, by = segment_seconds)
    seg_ends <- pmin(seg_starts + segment_seconds, to)
    return(data.table::data.table(from = seg_starts, to = seg_ends))
}

#' @export
fetch_klines_segment <- coro::async(function(
    base_url = get_base_url(),
    symbol,
    freq = "15min",
    from = lubridate::now() - 1 * 3600,
    to = lubridate::now(),
    retries = 3,
    delay_ms = 0
) {
    if (delay_ms > 0) Sys.sleep(delay_ms / 1000)

    endpoint <- "/api/v1/market/candles"
    method <- "GET"
    query <- list(
        symbol = symbol,
        type = freq,
        startAt = utils2$time_convert_to_kucoin_s(from),
        endAt   = utils2$time_convert_to_kucoin_s(to)
    )
    qs <- build_query(query)

    url <- paste0(base_url, endpoint, qs)

    # Since this is a public endpoint, we use a simple GET with retries.
    response <- httr::RETRY(
        "GET",
        url = url,
        times = retries,
        httr::timeout(10)
    )
    response <- process_kucoin_response(response, url)
    data <- data.table::as.data.table(response$data)

    if (nrow(data) > 0) {
        old_cnames <- names(data)
        new_cnames <- c("timestamp", "open", "close", "high", "low", "volume", "turnover")
        data.table::setnames(data, old_cnames, new_cnames)
        data[, (1:7) := lapply(.SD, as.numeric), .SDcols = 1:7]
        data[, datetime := lubridate::as_datetime(timestamp)]
        data.table::setcolorderv(data, c("datetime", new_cnames))
        data.table::setorder(data, datetime)
    }
    return(data)
})

################################################################################
# Main Implementation: get_klines_impl
################################################################################
#' @export
get_klines_impl <- coro::async(function(
    base_url = get_base_url(),
    symbol = "BTC-USDT",
    freq = "15min",
    from = lubridate::now() - 24 * 3600,
    to = lubridate::now(),
    concurrent = TRUE,
    delay_ms = 0,
    retries = 3
) {
    from <- lubridate::as_datetime(startAt)
    to <- lubridate::as_datetime(endAt)
    if (from >= to) {
        rlang::abort('"from" must be earlier than "to".')
    }

    # Convert frequency string to seconds.
    candle_duration_s <- frequency_to_seconds(freq)

    # Split the overall time range into segments that return at most 1500 candles.
    segments_dt <- split_time_range_by_candles(from, to, candle_duration_s, max_candles = 1500)

    # Create a list of promises (one for each segment)
    fetch_promises <- lapply(1:nrow(segments_dt), function(idx) {
        curr_seg <- segments[idx]
        return(fetch_klines_segment(symbol, freq, curr_seg$from, curr_seg$to, base_url, retries, delay_ms))
    })

    if (concurrent) {
        # Execute all segment requests concurrently.
        result <- promises::promise_all(.list = fetch_promises)
            $then(function(datas) {
                combined <- data.table::rbindlist(datas, fill = TRUE)
                data.table::setorder(combined, datetime)
                return(combined)
            })
    } else {
        # Execute requests sequentially.
        combined <- data.table::data.table()
        for (p in fetch_promises) {
            dt_seg <- await(p)
            combined <- data.table::rbindlist(list(combined, dt_seg), fill = TRUE)
        }
        data.table::setorder(combined, datetime)
        result <- combined
    }

    return(result)
})