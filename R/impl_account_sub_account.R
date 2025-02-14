# File: ./R/impl_account_sub_account.R

box::use(
    ./helpers_api[ auto_paginate, build_headers, process_kucoin_response ],
    ./utils[ build_query, get_base_url ]
)

#' Add SubAccount Implementation
#'
#' This asynchronous function creates a new sub‐account on KuCoin by sending a POST request
#' to the `/api/v2/sub/user/created` endpoint. On success, it returns a data.table with the sub‐account details.
#'
#' @param config A list containing API configuration parameters.
#' @param password A string representing the sub‐account password (7–24 characters; must contain letters and numbers).
#' @param subName A string representing the sub‐account name (7–32 characters; must contain at least one letter and one number; no spaces).
#' @param access A string representing the permission type (allowed values: "Spot", "Futures", "Margin").
#' @param remarks An optional string for remarks (1–24 characters).
#'
#' @return A promise that resolves to a data.table containing the sub‐account details. The returned table
#'         includes at least the following columns: uid, subName, remarks, and access.
#'
#' @details
#' **Endpoint:** POST `https://api.kucoin.com/api/v2/sub/user/created`
#'
#' The expected response on success is similar to:
#'
#'     data.table(
#'         uid = 237231855,
#'         subName = "Name12345678",
#'         remarks = "Test sub-account",
#'         access = "Spot"
#'     )
#'
#' @examples
#' \dontrun{
#'   coro::run(function() {
#'       result <- await(add_subaccount_impl(
#'           config,
#'           password = "1234567",
#'           subName = "Name1234567",
#'           access = "Spot",
#'           remarks = "Test sub-account"
#'       ))
#'       print(result)
#'   })
#' }
#'
#' @export
add_subaccount_impl <- coro::async(function(config, password, subName, access, remarks = NULL) {
    tryCatch({
        base_url <- get_base_url(config)
        endpoint <- "/api/v2/sub/user/created"
        method <- "POST"
        body_list <- list(
            password = password,
            subName = subName,
            access = access
        )
        if (!is.null(remarks)) {
            body_list$remarks <- remarks
        }
        body <- jsonlite::toJSON(body_list, auto_unbox = TRUE)
        headers <- await(build_headers(method, endpoint, body, config))
        url <- paste0(base_url, endpoint)
        response <- POST(url, headers, body = body, encode = "raw", timeout(3))
        response_text <- httr::content(response, as = "text", encoding = "UTF-8")
        parsed_response <- jsonlite::fromJSON(response_text)
        if (httr::status_code(response) != 200) {
            rlang::abort(paste("HTTP request failed with status code", httr::status_code(response), "for URL:", url))
        }
        if (as.character(parsed_response$code) != "200000") {
            error_msg <- "No error message provided."
            if ("msg" %in% names(parsed_response)) {
                error_msg <- parsed_response$msg
            }
            rlang::abort(paste("KuCoin API returned an error:", parsed_response$code, "-", error_msg))
        }
        result <- NULL
        if ("data" %in% names(parsed_response)) {
            result <- data.table::as.data.table(parsed_response$data)
        } else {
            result <- parsed_response
        }
        return(result)
    }, error = function(e) {
        abort(paste("Error in add_subaccount_impl:", conditionMessage(e)))
    })
})

#' Get SubAccount List - Summary Info Implementation
#'
#' This asynchronous function retrieves a paginated list of sub-accounts from KuCoin using the generic pagination helper.
#' Users can specify the page size and the maximum number of pages to fetch. By default, it fetches all pages with a page size of 100.
#' After aggregation, if a "createdAt" column is present, its values (in milliseconds) are converted to POSIXct datetime objects.
#'
#' @param config A list containing API configuration parameters.
#' @param page_size An integer specifying the number of results per page (default is 100).
#' @param max_pages The maximum number of pages to fetch. Use Inf to fetch all pages (default is Inf).
#'
#' @return A promise that resolves to a data.table containing the aggregated sub-account summary information,
#'         with the "createdAt" column converted to datetime (if present).
#'
#' @examples
#' \dontrun{
#'   # Fetch all sub-account summaries with page size 100:
#'   dt <- await(get_subaccount_list_summary_impl(config))
#'
#'   # Fetch only 3 pages with a page size of 50:
#'   dt <- await(get_subaccount_list_summary_impl(config, page_size = 50, max_pages = 3))
#' }
#'
#' @export
get_subaccount_list_summary_impl <- coro::async(function(config, page_size = 100, max_pages = Inf) {
    tryCatch({
        fetch_page <- coro::async(function(query) {
            base_url <- get_base_url(config)
            endpoint <- "/api/v2/sub/user"
            method <- "GET"
            body <- ""
            qs <- build_query(query)
            full_endpoint <- paste0(endpoint, qs)
            headers <- await(build_headers(method, full_endpoint, body, config))
            url <- paste0(base_url, full_endpoint)
            response <- httr::GET(url, headers, timeout(3))
            data <- process_kucoin_response(response, url)
            return(data)
        })
        initial_query <- list(currentPage = 1, pageSize = page_size)
        dt <- await(auto_paginate(
            fetch_page = fetch_page,
            query = initial_query,
            items_field = "items",
            aggregate_fn = function(acc) {
                data.table::rbindlist(acc, fill = TRUE)
            },
            max_pages = max_pages
        ))
        # Convert "createdAt" from milliseconds to POSIXct datetime if the column exists.
        if ("createdAt" %in% colnames(dt)) {
            dt[, createdDatetime := lubridate::as_datetime(createdAt / 1000, origin = "1970-01-01", tz = "UTC")]
        }
        return(dt)
    }, error = function(e) {
        rlang::abort(paste("Error in get_subaccount_list_summary_impl:", conditionMessage(e)))
    })
})

#' Get SubAccount Detail - Balance Implementation
#'
#' This asynchronous function retrieves the balance details for a sub-account specified by its user ID.
#' It sends a GET request to the endpoint `/api/v1/sub-accounts/{subUserId}` with a query parameter
#' `includeBaseAmount` (set to FALSE by default) and processes the returned object. The response contains
#' separate arrays for each account type (mainAccounts, tradeAccounts, marginAccounts, tradeHFAccounts).
#' This function converts each non-empty array to a data.table, adds an "accountType" column, and then
#' combines them. It also adds the subUserId and subName to every row.
#'
#' @param config A list containing API configuration parameters.
#' @param subUserId A string representing the sub-account user ID.
# TODO: confusing name of argument. Should be something like include null values or something.
#' @param includeBaseAmount A boolean indicating whether to include currencies with zero balance (default is FALSE).
#'
#' @return A promise that resolves to a data.table containing the sub-account detail.
#'
#' @examples
#' \dontrun{
#'   dt <- await(get_subaccount_detail_balance_impl(config, "63743f07e0c5230001761d08", includeBaseAmount = FALSE))
#'   print(dt)
#' }
#'
#' @export
get_subaccount_detail_balance_impl <- coro::async(function(config, subUserId, includeBaseAmount = FALSE) {
    tryCatch({
        base_url <- get_base_url(config)
        endpoint <- paste0("/api/v1/sub-accounts/", subUserId)
        query <- list(includeBaseAmount = includeBaseAmount)
        qs <- build_query(query)
        full_endpoint <- paste0(endpoint, qs)
        method <- "GET"
        body <- ""
        headers <- coro::await(build_headers("GET", full_endpoint, body, config))
        url <- paste0(base_url, full_endpoint)
        response <- httr::GET(url, headers, httr::timeout(3))
        data <- process_kucoin_response(response, url)

        # Process each account type into a data.table and add an accountType column.
        result_list <- list()
        if (!is.null(data$mainAccounts) && length(data$mainAccounts) > 0) {
            dt_main <- data.table::as.data.table(data$mainAccounts)
            dt_main[, accountType := "mainAccounts"]
            result_list[[length(result_list) + 1]] <- dt_main
        }
        if (!is.null(data$tradeAccounts) && length(data$tradeAccounts) > 0) {
            dt_trade <- data.table::as.data.table(data$tradeAccounts)
            dt_trade[, accountType := "tradeAccounts"]
            result_list[[length(result_list) + 1]] <- dt_trade
        }
        if (!is.null(data$marginAccounts) && length(data$marginAccounts) > 0) {
            dt_margin <- data.table::as.data.table(data$marginAccounts)
            dt_margin[, accountType := "marginAccounts"]
            result_list[[length(result_list) + 1]] <- dt_margin
        }
        if (!is.null(data$tradeHFAccounts) && length(data$tradeHFAccounts) > 0) {
            dt_tradeHF <- data.table::as.data.table(data$tradeHFAccounts)
            dt_tradeHF[, accountType := "tradeHFAccounts"]
            result_list[[length(result_list) + 1]] <- dt_tradeHF
        }
        if (length(result_list) == 0) {
            dt <- data.table::data.table()
        } else {
            dt <- data.table::rbindlist(result_list, fill = TRUE)
        }
        # Add subUserId and subName from the parent object.
        dt[, subUserId := data$subUserId]
        dt[, subName := data$subName]
        return(dt)
    }, error = function(e) {
        rlang::abort(paste("Error in get_subaccount_detail_balance_impl:", conditionMessage(e)))
    })
})