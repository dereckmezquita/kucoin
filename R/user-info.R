# user information --------------------------------------------------------

#' @title Get user's balance(s) list
#'
#' @param currency A `character` vector of one currency symbol (optional).
#' @param type A `character` vector of one indicating the `"main"` or `"trade"` account type (optional).
#'
#' @return A `tibble` containing balance details
#'
#' @examples
#'
#' \dontrun{
#'
#' # to run this example, make sure
#' # you already setup the API key
#' # in a proper .Renviron file
#'
#' # import library
#' library("kucoin")
#'
#' # get user's balance details
#' balances <- get_kucoin_balances()
#'
#' # quick check
#' balances
#'
#' # get user's balance details for BTC only
#' balances <- get_kucoin_balances(
#'   currency = "BTC"
#' )
#'
#' # quick check
#' balances
#'
#' # get user's balance details for trade account only
#' balances <- get_kucoin_balances(
#'   type = "trade"
#' )
#'
#' # quick check
#' balances
#'
#' }
#'
#' @export

get_kucoin_balances <- function(currency = NULL, type = NULL) {
    # get current timestamp
    current_timestamp <- as.character(get_kucoin_time(raw = TRUE))

    # prepare query params
    query_params <- list(
        currency = currency,
        type = type
    )

    query_params <- query_params[!sapply(query_params, is.null)]

    # prepare query strings
    query_strings <- prep_query_strings(query_params)

    # prepare get headers
    sig <- paste0(current_timestamp, "GET", get_paths("accounts", type = "endpoint"), query_strings)
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
        url = get_base_url(),
        path = get_paths("accounts"),
        query = query_params,
        config = httr::add_headers(.headers = get_header)
    )

    # analyze response
    response <- analyze_response(response)

    # parse json result
    parsed <- jsonlite::fromJSON(content(response, "text"))

    # tidy the parsed data
    # results <- as_tibble(parsed$data)
    results <- data.table::data.table(parsed$data, check.names = FALSE)

    results <- results[, c("type", "id", "currency", "balance", "available", "holds")]

    # results[, 4:6] <- lapply(results[, 4:6], as.numeric)
    results[, colnames(results)[4:6] := lapply(.SD, as.numeric), .SDcols = 4:6]

    # results <- results[order(results$type, results$currency), ]
    data.table::setorder(results, type, currency)

    # return the result
    return(results)
}
