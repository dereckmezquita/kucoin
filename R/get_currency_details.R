#' @title Get currencies' details
#' 
#' @description
#' 
#' Get a currencies' details. This includes what chains are available for depositing; this function is useful for then generating a deposit address by use of [kucoin::get_deposit_address()].
#'
#' | currency | name | full_name | precision | is_margin_enabled | is_debit_enabled | chain_name | chain  | withdrawal_min_size | withdrawal_min_fee | is_withdraw_enabled | is_deposit_enabled | confirms | pre_confirms | contract_address                           |
#' |----------|------|-----------|-----------|-------------------|------------------|------------|--------|---------------------|--------------------|---------------------|--------------------|----------|--------------|--------------------------------------------|
#' | BTC      | BTC  | Bitcoin   | 8         | TRUE              | TRUE             | BTC        | btc    | 0.0008              | 0.0005             | TRUE                | TRUE               | 3        | 1            |                                            |
#' | BTC      | BTC  | Bitcoin   | 8         | TRUE              | TRUE             | KCC        | kcc    | 0.0008              | 0.00002            | TRUE                | TRUE               | 20       | 20           | 0xfa93c12cd345c658bc4644d1d4e1b9615952258c |
#' | BTC      | BTC  | Bitcoin   | 8         | TRUE              | TRUE             | BTC-Segwit | bech32 | 0.0008              | 0.0005             | FALSE               | TRUE               | 2        | 2            |                                            |
#' 
#' @param currencies A `character` vector to specify the currencies to get details for (required - default `NULL`).
#' 
#' @seealso `kucoin::get_deposit_address()`
#' 
#' @return A `data.table` with currency information
#' 
#' @details
#' 
#' For more information see documentation: [KuCoin - get-currency-detail](https://docs.kucoin.com/#get-currency-detail-recommend)
#' 
#' Using v2 of the api.
#' 
#' @examples
#' 
#' # get a currencies' details
#' kucoin::get_currency_details(c("BTC", "XMR"))
#' 
#' @export

get_currency_details <- function(currencies = NULL) {
    if (is.null(currencies)) {
        rlang::abort('Argument "currencies" must be provided.')
    }

    # get currencies details
    results <- lapply(currencies, .get_currency_details)

    # combine results
    results <- data.table::rbindlist(results)

    return(results[])
}


# https://docs.kucoin.com/#get-currency-detail-recommend
.get_currency_details <- function(currency = NULL) {
    if (is.null(currency)) {
        rlang::abort('Argument "currency" must be provided.')
    }

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
