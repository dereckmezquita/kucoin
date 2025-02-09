box::use(
    ./utils[get_base_url],
    ./api[build_headers],
    ./errors[kucoin_error, http_error, api_error]
)


# File: account.R
#' @export
getAccountSummaryInfo <- coro::async(function(config) {
    tryCatch({
        method <- "GET"
        endpoint <- "/api/v2/user-info"
        body <- ""
        url <- paste0(get_base_url(config), endpoint)
        headers <- await(build_headers(method, endpoint, body, config))
        res <- httr::GET(url, headers)
        
        if (httr::status_code(res) != 200) {
            err_msg <- tryCatch({
                httr::content(res, as = "text", encoding = "UTF-8")
            }, error = function(e) "NO CONTENT")
            
            rlang::abort(
                http_error(
                    status = httr::status_code(res),
                    content = err_msg
                )
            )
        }
        
        result <- httr::content(res, as = "parsed", simplifyVector = TRUE)
        
        if (!is.null(result$code) && result$code != "200000") {
            rlang::abort(
                api_error(
                    code = result$code,
                    msg = result$msg
                )
            )
        }
        
        data.table::as.data.table(result$data)
        
    }, error = function(e) {
        if (inherits(e, "kucoin_error")) {
            rlang::abort(e$message, parent = e)
        } else {
            kucoin_error(
                message = "Failed to get account summary info",
                class = "kucoin_account_error",
                parent = e
            )
        }
    })
})