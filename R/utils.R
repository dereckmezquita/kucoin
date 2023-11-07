# time utilities ----------------------------------------------------------

#' @title Get current KuCoin API server time
#'
#' @param raw A `logical` vector to specify whether to return a raw results or not. The default is `FALSE`.
#'
#' @return A `datetime` object
#'
#' @examples
#' # import library
#' library("kucoin")
#'
#' # get current server time
#' get_kucoin_time()
#'
#' @export

get_kucoin_time <- function(raw = FALSE) {
    # get server response
    response <- httr::GET(
        url = get_base_url(),
        path = get_paths("time")
    )

    # analyze response
    response <- analyze_response(response)

    # parse json result
    parsed <- jsonlite::fromJSON(httr::content(response, "text", encoding = "UTF-8"))

    # get timestamp
    results <- as.numeric(parsed$data)

    # parse datetime if raw == FALSE
    if (!raw) {
        # readjust result
        results <- floor(parsed$data / 1000)

        # convert to proper datetime
        results <- lubridate::as_datetime(results)
    }

    # return the results
    return(results)
}

#' @title Convert raw Kucoin time to a `datetime` object
#'
#' @param time A `numeric` vector of time returned from KuCoin API (milliseconds) to be converted to a `datetime` object.
#'
#' @return A `datetime` object
#'
#' @examples
#' # import library
#' library("kucoin")
#'
#' # get current server time
#' kucoin_time_to_datetime(1.669401e+12)
#'
#' @export
#' 
# https://docs.kucoin.com/#server-time

kucoin_time_to_datetime <- function(time) {
    # readjust result
    results <- floor(time / 1000)

    # convert to proper datetime
    results <- lubridate::as_datetime(results)

    # return the results
    return(results)
}
