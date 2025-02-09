#' KucoinBasicInfo R6 Class for KuCoin Account Basic Info Endpoints
#'
#' This class implements the Basic Info endpoints for the KuCoin Spot Account API.
#' All methods are asynchronous (using coro) and return a promise that resolves to a data.table.
#'
#' @import R6
#' @import coro
#' @import data.table
#' @export
KucoinBasicInfo <- R6::R6Class("KucoinBasicInfo",
    public = list(
        #' @field config A list containing API credentials and settings.
        config = NULL,

        #' Initialize a new KucoinBasicInfo instance.
        #'
        #' @param config A named list with required API credentials and settings.
        #'   Required keys: `api_key`, `api_secret`, `api_passphrase`.
        #'   Optional keys: `key_version` (default "2"), `base_url` (default "https://api.kucoin.com").
        initialize = function(config) {
            required <- c("api_key", "api_secret", "api_passphrase")
            missing <- setdiff(required, names(config))
            if (length(missing) > 0) {
                rlang::abort(sprintf("Missing required config fields: %s", paste(missing, collapse = ", ")))
            }
            if (is.null(config$key_version)) config$key_version <- "2"
            if (is.null(config$base_url)) config$base_url <- "https://api.kucoin.com"
            self$config <- config
        },

        #' Get Account Summary Info.
        #'
        #' Retrieves account summary information using the endpoint `GET /api/v2/user-info`.
        #'
        #' @return A promise that resolves to a data.table with account summary information.
        getAccountSummaryInfo = coro::async(function() {
            tryCatch({
                method <- "GET"
                endpoint <- "/api/v2/user-info"
                body <- ""
                url <- paste0(get_base_url(self$config), endpoint)
                headers <- await(build_headers(method, endpoint, body, self$config))

                res <- httr::GET(url, headers)
                if (httr::status_code(res) != 200) {
                    err_msg <- tryCatch({
                        httr::content(res, as = "text", encoding = "UTF-8")
                    }, error = function(e) {
                        return("NO CONTENT")
                    })
                    rlang::abort(sprintf("HTTP error %s: %s", httr::status_code(res), err_msg))
                }

                result <- httr::content(res, as = "parsed", simplifyVector = TRUE)
                if (!is.null(result$code) && result$code != "200000") {
                    rlang::abort(sprintf("API error %s: %s", result$code, result$msg))
                }
                data.table::as.data.table(result$data)
            }, error = function(e) {
                rlang::abort("Failed to get account summary info", parent = e)
            })
        }),

        #' Get Account List.
        #'
        #' Retrieves a list of accounts using the endpoint `GET /api/v1/accounts`.
        #'
        #' @param currency (optional) Filter by currency.
        #' @param type (optional) Filter by account type (e.g., "main", "trade").
        #' @return A promise that resolves to a data.table of accounts.
        getAccountList = coro::async(function(currency = NULL, type = NULL) {
            tryCatch({
                method <- "GET"
                endpoint <- "/api/v1/accounts"
                params <- list(currency = currency, type = type)
                query <- build_query(params)
                url <- paste0(get_base_url(self$config), endpoint, query)
                headers <- await(build_headers(method, endpoint, "", self$config))

                res <- httr::GET(url, headers)
                if (httr::status_code(res) != 200) {
                    err_msg <- tryCatch({
                        httr::content(res, as = "text", encoding = "UTF-8")
                    }, error = function(e) "NO CONTENT")
                    rlang::abort(sprintf("HTTP error %s: %s", httr::status_code(res), err_msg))
                }

                result <- httr::content(res, as = "parsed", simplifyVector = TRUE)
                data.table::as.data.table(result$data)
            }, error = function(e) {
                rlang::abort("Failed to get account list", parent = e)
            })
        }),

        #' Get Account Detail.
        #'
        #' Retrieves detailed information for a specific account using the endpoint `GET /api/v1/accounts/{accountId}`.
        #'
        #' @param accountId A string representing the account ID.
        #' @return A promise that resolves to a data.table with account details.
        getAccountDetail = coro::async(function(accountId) {
            tryCatch({
                method <- "GET"
                endpoint <- paste0("/api/v1/accounts/", accountId)
                url <- paste0(get_base_url(self$config), endpoint)
                headers <- await(build_headers(method, endpoint, "", self$config))

                res <- httr::GET(url, headers)
                if (httr::status_code(res) != 200) {
                    err_msg <- tryCatch({
                        httr::content(res, as = "text", encoding = "UTF-8")
                    }, error = function(e) "NO CONTENT")
                    rlang::abort(sprintf("HTTP error %s: %s", httr::status_code(res), err_msg))
                }

                result <- httr::content(res, as = "parsed", simplifyVector = TRUE)
                data.table::as.data.table(result)
            }, error = function(e) {
                rlang::abort("Failed to get account detail", parent = e)
            })
        }),

        #' Get Account Ledgers.
        #'
        #' Retrieves ledger (transaction) records for Spot/Margin accounts using the endpoint `GET /api/v1/accounts/ledgers`.
        #'
        #' @param currency (optional) Filter by currency.
        #' @param direction (optional) "in" or "out".
        #' @param bizType (optional) Filter by business type.
        #' @param startAt (optional) Start time (milliseconds).
        #' @param endAt (optional) End time (milliseconds).
        #' @return A promise that resolves to a data.table of ledger records.
        getAccountLedgers = coro::async(function(currency = NULL, direction = NULL, bizType = NULL, startAt = NULL, endAt = NULL) {
            tryCatch({
                method <- "GET"
                endpoint <- "/api/v1/accounts/ledgers"
                params <- list(
                    currency = currency,
                    direction = direction,
                    bizType = bizType,
                    startAt = startAt,
                    endAt = endAt
                )
                query <- build_query(params)
                url <- paste0(get_base_url(self$config), endpoint, query)
                headers <- await(build_headers(method, endpoint, "", self$config))

                res <- httr::GET(url, headers)
                if (httr::status_code(res) != 200) {
                    err_msg <- tryCatch({
                        httr::content(res, as = "text", encoding = "UTF-8")
                    }, error = function(e) "NO CONTENT")
                    rlang::abort(sprintf("HTTP error %s: %s", httr::status_code(res), err_msg))
                }
                result <- httr::content(res, as = "parsed", simplifyVector = TRUE)
                data.table::as.data.table(result$items)
            }, error = function(e) {
                rlang::abort("Failed to get account ledgers", parent = e)
            })
        }),

        #' Get Trade HF Account Ledgers.
        #'
        #' Retrieves ledger records for high-frequency trading accounts using the endpoint `GET /api/v1/hf/accounts/ledgers`.
        #'
        #' @param currency (optional) Filter by currency.
        #' @param direction (optional) "in" or "out".
        #' @param bizType (optional) Filter by business type.
        #' @param lastId (optional) Last ledger ID from a previous page.
        #' @param limit (optional) Maximum number of records.
        #' @param startAt (optional) Start time (milliseconds).
        #' @param endAt (optional) End time (milliseconds).
        #' @return A promise that resolves to a data.table of ledger records.
        getAccountLedgersTradeHF = coro::async(function(
            currency = NULL,
            direction = NULL,
            bizType = NULL,
            lastId = NULL,
            limit = NULL,
            startAt = NULL,
            endAt = NULL
        ) {
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
                url <- paste0(get_base_url(self$config), endpoint, query)
                headers <- await(build_headers(method, endpoint, "", self$config))

                res <- httr::GET(url, headers)
                if (httr::status_code(res) != 200) {
                    err_msg <- tryCatch({
                        httr::content(res, as = "text", encoding = "UTF-8")
                    }, error = function(e) "NO CONTENT")
                    rlang::abort(sprintf("HTTP error %s: %s", httr::status_code(res), err_msg))
                }

                result <- httr::content(res, as = "parsed", simplifyVector = TRUE)
                data.table::as.data.table(result$data)
            }, error = function(e) {
                rlang::abort("Failed to get trade HF account ledgers", parent = e)
            })
        }),

        #' Get Margin HF Account Ledgers.
        #'
        #' Retrieves ledger records for high-frequency margin trading accounts using the endpoint `GET /api/v3/hf/margin/account/ledgers`.
        #'
        #' @param currency (optional) Filter by currency.
        #' @param direction (optional) "in" or "out".
        #' @param bizType (optional) Filter by business type.
        #' @param lastId (optional) Last ledger ID for pagination.
        #' @param limit (optional) Maximum number of records.
        #' @param startAt (optional) Start time (milliseconds).
        #' @param endAt (optional) End time (milliseconds).
        #' @return A promise that resolves to a data.table of ledger records.
        getAccountLedgersMarginHF = coro::async(function(
            currency = NULL,
            direction = NULL,
            bizType = NULL,
            lastId = NULL,
            limit = NULL,
            startAt = NULL,
            endAt = NULL
        ) {
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
                url <- paste0(get_base_url(self$config), endpoint, query)
                headers <- await(build_headers(method, endpoint, "", self$config))

                res <- httr::GET(url, headers)
                if (httr::status_code(res) != 200) {
                    err_msg <- tryCatch({
                        httr::content(res, as = "text", encoding = "UTF-8")
                    }, error = function(e) "NO CONTENT")
                    rlang::abort(sprintf("HTTP error %s: %s", httr::status_code(res), err_msg))
                }

                result <- httr::content(res, as = "parsed", simplifyVector = TRUE)
                data.table::as.data.table(result$data)
            }, error = function(e) {
                rlang::abort("Failed to get margin HF account ledgers", parent = e)
            })
        }),

        #' Get Futures Account Ledgers.
        #'
        #' Retrieves ledger records for futures accounts using the endpoint `GET /api/v1/transaction-history`.
        #'
        #' @param offset (optional) Starting offset.
        #' @param forward (optional) Lookup direction (TRUE for forward; default is TRUE).
        #' @param maxCount (optional) Maximum number of records.
        #' @param startAt (optional) Start time (milliseconds).
        #' @param endAt (optional) End time (milliseconds).
        #' @param type (optional) Transaction type (e.g., "RealisedPNL", "Deposit").
        #' @param currency (optional) Filter by currency.
        #' @return A promise that resolves to a data.table of futures ledger records.
        getAccountLedgersFutures = coro::async(function(
            offset = NULL,
            forward = TRUE,
            maxCount = NULL,
            startAt = NULL,
            endAt = NULL,
            type = NULL,
            currency = NULL
        ) {
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
                url <- paste0(get_base_url(self$config), endpoint, query)
                headers <- await(build_headers(method, endpoint, "", self$config))

                res <- httr::GET(url, headers)
                if (httr::status_code(res) != 200) {
                    err_msg <- tryCatch({
                        httr::content(res, as = "text", encoding = "UTF-8")
                    }, error = function(e) "NO CONTENT")
                    rlang::abort(sprintf("HTTP error %s: %s", httr::status_code(res), err_msg))
                }

                result <- httr::content(res, as = "parsed", simplifyVector = TRUE)
                # For futures, ledger records are in result$data$dataList.
                data.table::as.data.table(result$data$dataList)
            }, error = function(e) {
                rlang::abort("Failed to get futures account ledgers", parent = e)
            })
        })
    )
)