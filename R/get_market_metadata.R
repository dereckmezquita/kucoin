#' @title Get all market symbols' metadata
#' 
#' @param retries A `numeric` value to specify the number of retries in case of failure (optional - default `3`).
#'
#' @return A `data.table` with metadata
#' 
#' @details
#' 
#' # ---------------
#' For more information see documentation: [KuCoin - get-symbols-list-deprecated](https://docs.kucoin.com/#get-symbols-list-deprecated)
#'
#' @examples
#'
#' # get all symbols' most recent metadata
#' kucoin::get_market_metadata()
#'
#' @export

get_market_metadata <- function(retries = 3) {
    # get server response
    response <- httr::RETRY(
        verb = "GET",
        url = get_base_url(),
        path = get_paths("symbols"),
        times = retries
    )

    # analyze response
    response <- analyze_response(response)

    # parse json result
    parsed <- jsonlite::fromJSON(httr::content(response, "text", encoding = "UTF-8"))

    results <- data.table::as.data.table(parsed$data, check.names = FALSE)
    
    colnames(results) <- to_snake_case(colnames(results))

    numeric_cols <- c(
        "base_min_size", "quote_min_size", "base_max_size",
        "quote_max_size", "base_increment", "quote_increment",
        "price_increment", "price_limit_rate", "min_funds"
    )

    # sandbox api does not have "min_funds" column
    # filter out columns that are not in the data; warn user that they are not in the data
    numeric_missing_cols <- setdiff(numeric_cols, colnames(results))

    if (length(numeric_missing_cols) > 0) {
        rlang::warn(stringr::str_interp("The following columns are not in the data: ${collapse(numeric_missing_cols)}"))

        # keep only columns that are in the data
        numeric_cols <- numeric_cols[!numeric_cols %in% numeric_missing_cols]
    }

    logical_cols <- c("is_margin_enabled", "enable_trading")

    logical_missing_cols <- setdiff(logical_cols, colnames(results))

    if (length(logical_missing_cols) > 0) {
        rlang::warn(stringr::str_interp("The following columns are not in the data: ${collapse(logical_missing_cols)}"))

        # keep only columns that are in the data
        logical_cols <- logical_cols[!logical_cols %in% logical_missing_cols]
    }

    ## -----------------
    results[, (numeric_cols) := lapply(.SD, as.numeric), .SDcols = numeric_cols]

    results[, c("symbol", "name") := lapply(.SD, prep_symbols, revert = TRUE), .SDcols = c("symbol", "name")]

    results[, (logical_cols) := lapply(.SD, as.logical), .SDcols = logical_cols]

    data.table::setorder(results, symbol, fee_currency)

    # return the result
    return(results[])
}
