
#' @title Get all order(s)
#' 
#' @param symbol A `character` vector of one or more which contain symbol(s) of format "BTC/USDT" (optional - default `NULL`).
#' @param status A `character` vector of one either "done" or "active" (optional - default `NULL`).
#' @param side A `character` vector of one either "buy" or "sell" (optional - default `NULL`).
#' @param type A `character` vector of one either "limit", "market", "limit_stop", "market_stop" (optional - default `NULL`).
#' @param tradeType A `character` vector of one either "TRADE" (spot trading), "MARGIN_TRADE" (cross margin trading), "MARGIN_ISOLATED_TRADE" (isolated margin trading) (required - default `TRADE`).
#' @param from A `character` with valid `date`/`datetime` format, or `date`/`datetime` object as a start of datetime range (optional - default `NULL`).
#' @param to A `character` with valid `date`/`datetime` format, or `date`/`datetime` object as an end of datetime range (optional - default `NULL`).
#' @param delay A `numeric` value to delay data request in milliseconds (optional - default `0.1`).
#' @param retries A `numeric` value to specify the number of retries in case of failure (optional - default `3`).
#'
#' @return A `data.table` containing order details
#' 
#' @details
#' 
#' For more information see documentation: [KuCoin - list-orders](https://docs.kucoin.com/#list-orders)
#'
#' @examples
#'
#' \dontrun{
#'
#' # to run this example, make sure
#' # you already setup the API key
#' # in a proper .Renviron file
#'
#' kucoin::get_orders_all()
#'
#' }
#'
#' @export

get_orders_all <- function(
    # all NULL are optional
    symbol = NULL, # expects format "KCS-BTC"
    status = NULL, # expects "active" or "done"
    side = NULL,
    type = NULL,
    tradeType = "TRADE", # TRADE (Spot Trading), MARGIN_TRADE (Cross Margin Trading), MARGIN_ISOLATED_TRADE (Isolated Margin Trading)
    from = NULL, # expects format "2021-01-01 00:00:00 UTC"
    to = NULL,
    retries = 3,
    delay = 0.1
) {

    if (!is.null(status) && !status %in% c("active", "done")) {
        rlang::abort(stringr::str_interp('Argument status must be one of "active", "done"; received ${status}.'))
    }

    if (!is.null(side) && !side %in% c("buy", "sell")) {
        rlang::abort(stringr::str_interp('Argument side must be one of "buy", "sell"; received ${side}.'))
    }

    if (!tradeType %in% c("TRADE", "MARGIN_TRADE", "MARGIN_ISOLATED_TRADE")) {
        rlang::abort(stringr::str_interp('Argument tradeType must be one of "TRADE", "MARGIN_TRADE", "MARGIN_ISOLATED_TRADE"; received ${tradeType}.'))
    }

    current_timestamp <- as.character(get_kucoin_time(raw = TRUE))

    # example
    # GET /api/v1/orders?status=active
    # GET /api/v1/orders?status=active?tradeType=MARGIN_ISOLATED_TRADE

    # prepare query params; need to return NULL if no params
    query_params <- list(
        symbol = (\() {
            if (!is.null(symbol)) return(prep_symbols(symbol))
            return(NULL)
        })(),
        status = status,
        side = side,
        type = type,
        tradeType = tradeType,
        startAt = (\() {
            if (!is.null(from)) return(lubridate::as_datetime(from))
            return(NULL)
        })(),
        endAt = (\() {
            if (!is.null(to)) return(lubridate::as_datetime(to))
            return(NULL)
        })(),
        currentPage = 1,
        pageSize = 10 # min 10 max 500
    )

    query_params <- query_params[!sapply(query_params, is.null)]

    # prepare query strings
    query_strings <- prep_query_strings(query_params)

    # prepare get request
    sig <- paste0(current_timestamp, "GET", get_paths("orders", type = "endpoint"), query_strings)
    sig <- digest::hmac(object = sig, algo = "sha256", key = Sys.getenv("KC-API-SECRET"), raw = TRUE)
    sig <- jsonlite::base64_enc(input = sig)

    get_header <- c(
        "KC-API-KEY" = Sys.getenv("KC-API-KEY"),
        "KC-API-SIGN" = sig,
        "KC-API-TIMESTAMP" = current_timestamp,
        "KC-API-PASSPHRASE" = Sys.getenv("KC-API-PASSPHRASE")
    )

    # get server response: This API is restricted for each account, the request rate limit is 30 times/3s.
    response <- httr::RETRY(
        verb = "GET",
        url = get_base_url(),
        path = get_paths("orders"),
        query = query_params,
        config = httr::add_headers(.headers = get_header),
        times = retries
    )

    # analyze response
    response <- analyze_response(response)

    # parse json result
    parsed <- jsonlite::fromJSON(httr::content(response, "text", encoding = "UTF-8"))

    results <- data.table::as.data.table(parsed$data$items, check.names = TRUE)

    # to get subsequent pages another get request is necessary
    # GET /api/v1/orders?currentPage=1&pageSize=50

    # if there are more pages, get them
    if (parsed$data$currentPage < parsed$data$totalPage) {
        message(stringr::str_interp('There are ${parsed$data$totalNum} orders in total; getting next page(s)...'))

        # if there are more pages the result for example (initial request was set to 10 items):
        # $code
        # [1] "200000"
        # $data
        # $data$currentPage
        # [1] 1
        # $data$pageSize
        # [1] 10
        # $data$totalNum
        # [1] 38
        # $data$totalPage
        # [1] 4
        # $data$items

        # get subsequent pages start from 2 (1 is already retrieved)
        for (i in (parsed$data$currentPage + 1):parsed$data$totalPage) {
            message(stringr::str_interp('Getting page ${i} of ${parsed$data$totalPage}.'))

            current_timestamp <- as.character(get_kucoin_time(raw = TRUE))

            # set current page
            query_params$currentPage <- i

            # prepare query strings - example: "?tradeType=TRADE&currentPage=2&pageSize=10"
            query_strings <- prep_query_strings(query_params)

            # prepare get request
            sig <- paste0(current_timestamp, "GET", get_paths("orders", type = "endpoint"), query_strings)
            sig <- digest::hmac(object = sig, algo = "sha256", key = Sys.getenv("KC-API-SECRET"), raw = TRUE)
            sig <- jsonlite::base64_enc(input = sig)

            get_header <- c(
                "KC-API-KEY" = Sys.getenv("KC-API-KEY"),
                "KC-API-SIGN" = sig,
                "KC-API-TIMESTAMP" = current_timestamp,
                "KC-API-PASSPHRASE" = Sys.getenv("KC-API-PASSPHRASE")
            )

            # get server response: This API is restricted for each account, the request rate limit is 30 times/3s.
            # sleep to meet rate limit of 10 requests per second
            Sys.sleep(delay)

            response <- httr::RETRY(
                verb = "GET",
                url = get_base_url(),
                path = get_paths("orders"),
                query = query_params,
                config = httr::add_headers(.headers = get_header),
                times = retries
            )

            # analyze response
            response <- analyze_response(response)

            # parse json result
            parsed <- jsonlite::fromJSON(httr::content(response, "text", encoding = "UTF-8"))

            results <- rbind(results, data.table::as.data.table(parsed$data$items, check.names = TRUE))
        }
    }

    colnames(results) <- to_snake_case(colnames(results))

    numeric_cols <- c("price", "size", "funds", "deal_funds", "deal_size", "fee", "stop_price", "visible_size", "cancel_after", "created_at")

    numeric_missing_cols <- setdiff(numeric_cols, colnames(results))

    if (length(numeric_missing_cols) > 0) {
        rlang::warn(stringr::str_interp('The following columns are missing: ${collapse(numeric_missing_cols)}'))

        # keep only columns that are in results
        numeric_cols <- numeric_cols[!numeric_cols %in% numeric_missing_cols]
    }

    logical_cols <- c("stop_triggered", "post_only", "hidden", "iceberg", "is_active", "cancel_exist")

    logical_missing_cols <- setdiff(logical_cols, colnames(results))

    if (length(logical_missing_cols) > 0) {
        rlang::warn(stringr::str_interp('The following columns are missing: ${collapse(logical_missing_cols)}'))

        # keep only columns that are in results
        logical_cols <- logical_cols[!logical_cols %in% logical_missing_cols]
    }

    ## -----------------
    results[, (numeric_cols) := lapply(.SD, as.numeric), .SDcols = numeric_cols]

    results[, (logical_cols) := lapply(.SD, as.logical), .SDcols = logical_cols]

    return(results)
}
