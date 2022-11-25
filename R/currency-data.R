
# currency data - for deposits etc ---------------------------------------------------------

#' @title Get a currencies' details
#' 
#' @description Get a currencies' details. This includes what chains are available for depositing; this function is useful for then generating a deposit address by use of `kucoin::get_kucoin_deposit_address()`.
#' 
#' @param currencies A `character` vector to specify the currencies to get details for.
#' 
#' @seealso `kucoin::get_kucoin_deposit_address()`
#' 
#' @return A `data.table` containing currency information
#' 
#' @examples
#' # import library
#' library("kucoin")
#' 
#' # get a currencies' details
#' currencies_details <- get_kucoin_currencies_details(c("BTC", "XMR"))
#' 
#' # quick check
#' currencies_details
#' 
#' @export

get_kucoin_currencies_details <- function(currencies) {
    # get currencies details
    results <- lapply(currencies, get_kucoin_currency_details)

    # combine results
    results <- data.table::rbindlist(results)

    return(results[])
}

# kucoin::get_kucoin_currencies_details(c("BTC", "XMR"))
# results <- lapply(c("BTC", "XMR"), kucoin:::get_kucoin_currency_details)
# results <- data.table::rbindlist(results)

# a helper function to get currency data; used to know what network "chain" to use to generate a deposit address
get_kucoin_currency_details <- function(currency) {
    # https://docs.kucoin.com/#get-currency-detail

    # GET /api/v2/currencies/{currency}
    # GET /api/v2/currencies/BTC

    response <- httr::GET(
        url = get_base_url(),
        path = get_paths("currencies", append = currency)
    )

    # analyze response
    response <- analyze_response(response)

    # parse json result
    parsed <- jsonlite::fromJSON(httr::content(response, "text", encoding = "UTF-8"))

    results <- data.table::as.data.table(parsed$data, check.names = FALSE)

    # clean up column names
    colnames(results) <- gsub("chains\\.", "", colnames(results))

    # to snake case
    colnames(results) <- to_snake_case(colnames(results))

    return(results[])
}

