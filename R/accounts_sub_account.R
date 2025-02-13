box::use(
    data.table,
    httr[POST, timeout, content, status_code],
    jsonlite[toJSON, fromJSON],
    rlang[abort],
    coro,
    ./utils[get_base_url],
    ./helpers_api[build_headers]
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
#' This asynchronous function retrieves a paginated list of sub-accounts from KuCoin.
#' It sends a GET request to the `/api/v2/sub/user` endpoint with optional query parameters.
#'
#' @param config A list containing API configuration parameters.
#' @param query A list of query parameters to filter the sub-account list.
#'              Supported parameters include:
#'              - **currentPage** (integer, optional): Current request page. Default is 1.
#'              - **pageSize** (integer, optional): Number of results per request. Default is 10.
#'
#' @return A promise that resolves to a data.table containing the sub-account summary information.
#'
#' @details
#' **Endpoint:** `GET https://api.kucoin.com/api/v2/sub/user`
#'
#' The response data includes fields such as `currentPage`, `pageSize`, `totalNum`, `totalPage`,
#' and `items` (an array of sub-account objects).
#'
#' @examples
#' \dontrun{
#'   query <- list(currentPage = 1, pageSize = 10)
#'   coro::run(function() {
#'       dt <- await(get_subaccount_list_summary_impl(config, query))
#'       print(dt)
#'   })
#' }
#'
#' @export
get_subaccount_list_summary_impl <- coro::async(function(config, query = list()) {
    tryCatch({
        base_url <- get_base_url(config)
        endpoint <- "/api/v2/sub/user"
        method <- "GET"
        body <- ""
        qs <- build_query(query)
        full_endpoint <- paste0(endpoint, qs)
        headers <- await(build_headers(method, full_endpoint, body, config))
        url <- paste0(base_url, full_endpoint)
        
        response <- GET(url, headers, timeout(3))
        data <- process_kucoin_response(response, url)
        dt <- as.data.table(data)
        return(dt)
    }, error = function(e) {
        abort(paste("Error in get_subaccount_list_summary_impl:", conditionMessage(e)))
    })
})