
#' @export
# https://docs.kucoin.com/#list-orders
.get_orders_all <- function(
    # all NULL are optional
    symbol = NULL, # expects format "KCS-BTC"
    status = NULL, # expects "active" or "done"
    side = NULL,
    type = NULL,
    tradeType = "TRADE", # TRADE (Spot Trading), MARGIN_TRADE (Cross Margin Trading), MARGIN_ISOLATED_TRADE (Isolated Margin Trading)
    from = NULL, # expects format "2021-01-01 00:00:00 UTC"
    to = NULL,
    retries = 3
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

    # prepare query params
    query_params <- list(
        symbol = prep_symbols(symbol),
        status = status,
        side = side,
        type = type,
        tradeType = tradeType,
        startAt = lubridate::as_datetime(from),
        endAt = lubridate::as_datetime(to),
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
            Sys.sleep(0.1)

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

    return(results)
}