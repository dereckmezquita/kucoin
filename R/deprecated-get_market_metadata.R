#' @title Get all market symbols' metadata --deprecated--
#' 
#' @param retries A `numeric` value to specify the number of retries in case of failure (optional - default `3`).
#'
#' @return A `data.table` with metadata
#' 
#' @details
#' 
#' TODO: this function needs to be updated to v2 of the API.
#' 
#' # ---------------
#' For more information see documentation: [KuCoin - get-symbols-list-deprecated](https://docs.kucoin.com/#get-symbols-list-deprecated)
#'
#' @examples
#' # import library
#' library("kucoin")
#'
#' # get all symbols' most recent metadata
#' metadata <- kucoin::get_market_metadata()
#'
#' # quick check
#' metadata
#'
#' @export

get_market_metadata.deprecated <- function(retries = 3) {
    # get server response
    response <- httr::RETRY(
        verb = "GET",
        url = get_base_url(),
        path = get_paths("symbols-deprecated"),
        times = retries
    )

    # analyze response
    response <- analyze_response(response)

    # parse json result
    parsed <- jsonlite::fromJSON(httr::content(response, "text", encoding = "UTF-8"))

    # tidy the parsed data
    results <- data.table::data.table(parsed$data, check.names = FALSE)

    # seems that the only thing that changes in colnames is they are made to snake_case
    # https://github.com/dereckdemezquita/kucoin/issues/1
    # Error in setnames(x, value) : 
    # Can't assign 14 names to a 17 column data.table
    # colnames(results) <- c(
    #     "symbol", "quote_max_size", "enable_trading", "price_increment",
    #     "fee_currency", "base_max_size", "base_currency", "quote_currency",
    #     "market", "quote_increment", "base_min_size", "quote_min_size",
    #     "name", "base_increment"
    # )
    
    colnames(results) <- to_snake_case(colnames(results))

    # since we are not sure to get the same data from the api forever
    # I will programmatically modify what we receive rather than set colnames manually

    # will no longer re-order the table
    # common_cols <- c(
    #     "symbol", "name", "enable_trading",
    #     "base_currency", "quote_currency",
    #     "market", # TOOD: added market column; might remove later
    #     "base_min_size", "quote_min_size",
    #     "base_max_size", "quote_max_size",
    #     "base_increment", "quote_increment",
    #     "price_increment", "fee_currency"
    # )
    # data.table::setcolorder(results, c(common_cols, setdiff(colnames(results), common_cols)))

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
    # results[, colnames(results)[6:12] := lapply(.SD, as.numeric), .SDcols = 6:12]

    results[, c("symbol", "name") := lapply(.SD, prep_symbols, revert = TRUE), .SDcols = c("symbol", "name")]
    # results[, colnames(results)[1:2] := lapply(.SD, prep_symbols, revert = TRUE), .SDcols = 1:2]

    results[, (logical_cols) := lapply(.SD, as.logical), .SDcols = logical_cols]

    # data.table::setorder(results, base_currency, quote_currency)
    data.table::setorder(results, symbol, fee_currency)

    # return the result
    return(results[])
}
