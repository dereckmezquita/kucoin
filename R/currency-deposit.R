
# currency deposits ---------------------------------------------------------

#' @title Get a deposit address for a currency
#' 
#' @description Get a deposit address for a currency. This function is useful for generating a deposit address for a currency. Note you must provide the chain (network) to use for the deposit address. This can be obtained by use of `kucoin::get_kucoin_currencies_details()`.
#' 
#' @param currencies A `character` vector length 1 to specify the currencies to get deposit addresses for.
#' @param chain A `character` vector length 1 to specify the chain (network) to use for the deposit address.
#' 
#' @seealso `kucoin::get_kucoin_currencies_details()`
#' 
#' @return A `data.table` containing deposit address information
#' 
#' @examples
#' # import library
#' library("kucoin")
#' 
#' # get a deposit address for a currency
#' deposit_address <- get_kucoin_deposit_address("BTC", "btc")
#' 
#' # quick check
#' deposit_address
#' 
#' @export

get_kucoin_deposit_address <- function(currency, chain = NULL) {
    # https://docs.kucoin.com/#get-deposit-addresses-v2

    # GET /api/v2/deposit-addresses
    # Example
    # GET /api/v2/deposit-addresses?currency=BTC

    # get current timestamp
    current_timestamp <- as.character(kucoin:::get_kucoin_time(raw = TRUE))

    if (is.null(chain)) {
        rlang::abort('Argument "chain" must be provided.')
    }

    # prepare query params
    query_params <- list(
        currency = currency,
        chain = chain
    )

    query_params <- query_params[!sapply(query_params, is.null)]

    # prepare query strings
    query_strings <- kucoin:::prep_query_strings(query_params)

    # prepare get headers
    sig <- paste0(current_timestamp, "GET", kucoin:::get_paths("deposit-addresses", type = "endpoint"), query_strings)
    sig <- digest::hmac(object = sig, algo = "sha256", key = Sys.getenv("KC-API-SECRET"), raw = TRUE)
    sig <- jsonlite::base64_enc(input = sig)

    get_header <- c(
        "KC-API-KEY" = Sys.getenv("KC-API-KEY"),
        "KC-API-SIGN" = sig,
        "KC-API-TIMESTAMP" = current_timestamp,
        "KC-API-PASSPHRASE" = Sys.getenv("KC-API-PASSPHRASE")
    )

    # get server response
    response <- httr::GET(
        url = kucoin:::get_base_url(),
        path = kucoin:::get_paths("deposit-addresses"),
        query = query_params,
        config = httr::add_headers(.headers = get_header)
    )

    # analyze response
    response <- kucoin:::analyze_response(response)

    # parse json result
    parsed <- jsonlite::fromJSON(httr::content(response, "text", encoding = "UTF-8"))
    
    results <- data.table::as.data.table(parsed$data, check.names = FALSE)

    colnames(results) <- to_snake_case(colnames(results))

    results[, currency := currency]

    data.table::setcolorder(results, c("currency", "address", "memo", "chain", "contract_address"))

    return(results[])
}
