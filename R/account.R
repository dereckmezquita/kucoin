box::use(
    ./utils[get_base_url, build_query],
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
            rlang::abort(http_error(status = httr::status_code(res), content = err_msg))
        }
        result <- httr::content(res, as = "parsed", simplifyVector = TRUE)
        if (!is.null(result$code) && result$code != "200000") {
            rlang::abort(api_error(code = result$code, msg = result$msg))
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

#' @export
getAccountList <- coro::async(function(config, currency = NULL, type = NULL) {
    tryCatch({
        method <- "GET"
        endpoint <- "/api/v1/accounts"
        params <- list(currency = currency, type = type)
        query <- build_query(params)
        url <- paste0(get_base_url(config), endpoint, query)
        headers <- await(build_headers(method, endpoint, "", config))
        res <- httr::GET(url, headers)
        if (httr::status_code(res) != 200) {
            err_msg <- tryCatch({
                httr::content(res, as = "text", encoding = "UTF-8")
            }, error = function(e) "NO CONTENT")
            rlang::abort(http_error(status = httr::status_code(res), content = err_msg))
        }
        result <- httr::content(res, as = "parsed", simplifyVector = TRUE)
        data.table::as.data.table(result$data)
    }, error = function(e) {
        if (inherits(e, "kucoin_error")) {
            rlang::abort(e$message, parent = e)
        } else {
            kucoin_error(
                message = "Failed to get account list",
                class = "kucoin_account_list_error",
                parent = e
            )
        }
    })
})

#' @export
getAccountDetail <- coro::async(function(config, accountId) {
    tryCatch({
        method <- "GET"
        endpoint <- paste0("/api/v1/accounts/", accountId)
        url <- paste0(get_base_url(config), endpoint)
        headers <- await(build_headers(method, endpoint, "", config))
        res <- httr::GET(url, headers)
        if (httr::status_code(res) != 200) {
            err_msg <- tryCatch({
                httr::content(res, as = "text", encoding = "UTF-8")
            }, error = function(e) "NO CONTENT")
            rlang::abort(http_error(status = httr::status_code(res), content = err_msg))
        }
        result <- httr::content(res, as = "parsed", simplifyVector = TRUE)
        data.table::as.data.table(result)
    }, error = function(e) {
        if (inherits(e, "kucoin_error")) {
            rlang::abort(e$message, parent = e)
        } else {
            kucoin_error(
                message = "Failed to get account detail",
                class = "kucoin_account_detail_error",
                parent = e
            )
        }
    })
})

#' @export
getAccountLedgers <- coro::async(function(config, currency = NULL, direction = NULL, bizType = NULL, startAt = NULL, endAt = NULL) {
    tryCatch({
        method <- "GET"
        endpoint <- "/api/v1/accounts/ledgers"
        params <- list(currency = currency, direction = direction, bizType = bizType, startAt = startAt, endAt = endAt)
        query <- build_query(params)
        url <- paste0(get_base_url(config), endpoint, query)
        headers <- await(build_headers(method, endpoint, "", config))
        res <- httr::GET(url, headers)
        if (httr::status_code(res) != 200) {
            err_msg <- tryCatch({
                httr::content(res, as = "text", encoding = "UTF-8")
            }, error = function(e) "NO CONTENT")
            rlang::abort(http_error(status = httr::status_code(res), content = err_msg))
        }
        result <- httr::content(res, as = "parsed", simplifyVector = TRUE)
        data.table::as.data.table(result$data)
    }, error = function(e) {
        if (inherits(e, "kucoin_error")) {
            rlang::abort(e$message, parent = e)
        } else {
            kucoin_error(
                message = "Failed to get account ledgers",
                class = "kucoin_account_ledgers_error",
                parent = e
            )
        }
    })
})

#' @export
getAccountLedgersTradeHF <- coro::async(function(config, currency = NULL, direction = NULL, bizType = NULL, lastId = NULL, limit = NULL, startAt = NULL, endAt = NULL) {
    tryCatch({
        method <- "GET"
        endpoint <- "/api/v1/hf/accounts/ledgers"
        params <- list(
            currency = currency,
            direction = direction,
            bizType = bizType,
            lastId = lastId,
            limit = limit,
            startAt = startAt,
            endAt = endAt
        )
        query <- build_query(params)
        url <- paste0(get_base_url(config), endpoint, query)
        headers <- await(build_headers(method, endpoint, "", config))
        res <- httr::GET(url, headers)
        if (httr::status_code(res) != 200) {
            err_msg <- tryCatch({
                httr::content(res, as = "text", encoding = "UTF-8")
            }, error = function(e) "NO CONTENT")
            rlang::abort(http_error(status = httr::status_code(res), content = err_msg))
        }
        result <- httr::content(res, as = "parsed", simplifyVector = TRUE)
        data.table::as.data.table(result$data)
    }, error = function(e) {
        if (inherits(e, "kucoin_error")) {
            rlang::abort(e$message, parent = e)
        } else {
            kucoin_error(
                message = "Failed to get trade HF account ledgers",
                class = "kucoin_account_ledgers_trade_hf_error",
                parent = e
            )
        }
    })
})

#' @export
getAccountLedgersMarginHF <- coro::async(function(config, currency = NULL, direction = NULL, bizType = NULL, lastId = NULL, limit = NULL, startAt = NULL, endAt = NULL) {
    tryCatch({
        method <- "GET"
        endpoint <- "/api/v3/hf/margin/account/ledgers"
        params <- list(
            currency = currency,
            direction = direction,
            bizType = bizType,
            lastId = lastId,
            limit = limit,
            startAt = startAt,
            endAt = endAt
        )
        query <- build_query(params)
        url <- paste0(get_base_url(config), endpoint, query)
        headers <- await(build_headers(method, endpoint, "", config))
        res <- httr::GET(url, headers)
        if (httr::status_code(res) != 200) {
            err_msg <- tryCatch({
                httr::content(res, as = "text", encoding = "UTF-8")
            }, error = function(e) "NO CONTENT")
            rlang::abort(http_error(status = httr::status_code(res), content = err_msg))
        }
        result <- httr::content(res, as = "parsed", simplifyVector = TRUE)
        data.table::as.data.table(result$data)
    }, error = function(e) {
        if (inherits(e, "kucoin_error")) {
            rlang::abort(e$message, parent = e)
        } else {
            kucoin_error(
                message = "Failed to get margin HF account ledgers",
                class = "kucoin_account_ledgers_margin_hf_error",
                parent = e
            )
        }
    })
})

#' @export
getAccountLedgersFutures <- coro::async(function(config, offset = NULL, forward = TRUE, maxCount = NULL, startAt = NULL, endAt = NULL, type = NULL, currency = NULL) {
    tryCatch({
        method <- "GET"
        endpoint <- "/api/v1/transaction-history"
        params <- list(
            offset = offset,
            forward = forward,
            maxCount = maxCount,
            startAt = startAt,
            endAt = endAt,
            type = type,
            currency = currency
        )
        query <- build_query(params)
        url <- paste0(get_base_url(config), endpoint, query)
        headers <- await(build_headers(method, endpoint, "", config))
        res <- httr::GET(url, headers)
        if (httr::status_code(res) != 200) {
            err_msg <- tryCatch({
                httr::content(res, as = "text", encoding = "UTF-8")
            }, error = function(e) "NO CONTENT")
            rlang::abort(http_error(status = httr::status_code(res), content = err_msg))
        }
        result <- httr::content(res, as = "parsed", simplifyVector = TRUE)
        data.table::as.data.table(result$data$dataList)
    }, error = function(e) {
        if (inherits(e, "kucoin_error")) {
            rlang::abort(e$message, parent = e)
        } else {
            kucoin_error(
                message = "Failed to get futures account ledgers",
                class = "kucoin_account_ledgers_futures_error",
                parent = e
            )
        }
    })
})