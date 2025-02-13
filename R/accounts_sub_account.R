box::use(
    httr[POST, timeout],
    jsonlite[toJSON],
    rlang[abort],
    coro,
    ./utils[ get_base_url, get_api_keys ],
    ./helpers_api[process_kucoin_response, build_headers]
)

#' Add SubAccount Implementation
#'
#' This asynchronous function creates a new sub‐account on KuCoin by sending a POST request
#' to the `/api/v2/sub/user/created` endpoint.
#'
#' @param config A list containing API configuration parameters.
#' @param password A string representing the sub‐account password (7–24 characters, must contain letters and numbers).
#' @param subName A string representing the sub‐account name (7–32 characters, must contain at least one letter and one number, with no spaces).
#' @param access A string representing the permission type (allowed values: "Spot", "Futures", "Margin").
#' @param remarks An optional string for remarks (1–24 characters).
#'
#' @return A promise that resolves to a list containing sub‐account details (e.g. uid, subName, remarks, access).
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
        data <- process_kucoin_response(response, url)
        return(data)
    }, error = function(e) {
        rlang::abort(paste("Error in add_subaccount_impl:", conditionMessage(e)))
    })
})