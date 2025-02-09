#' KucoinBasicInfo R6 Class for KuCoin Account Basic Info Endpoints
#'
#' This class implements the Basic Info endpoints for the KuCoin Spot Account API.
#' It provides methods for:
#' \itemize{
#'   \item \strong{Get Account Summary Info} (\code{GET /api/v2/user-info})
#'   \item \strong{Get Account List} (\code{GET /api/v1/accounts})
#'   \item \strong{Get Account Detail} (\code{GET /api/v1/accounts/{accountId}})
#'   \item \strong{Get Account Ledgers} (\code{GET /api/v1/accounts/ledgers})
#'   \item \strong{Get Account Ledgers – trade\_hf} (\code{GET /api/v1/hf/accounts/ledgers})
#'   \item \strong{Get Account Ledgers – margin\_hf} (\code{GET /api/v3/hf/margin/account/ledgers})
#'   \item \strong{Get Account Ledgers – Futures} (\code{GET /api/v1/transaction-history})
#' }
#'
#' All methods return a promise that resolves to a \code{data.table} containing the requested data.
#'
#' @section Expected Inputs:
#' The \code{config} list passed to \code{initialize()} must include:
#' \describe{
#'   \item{api_key}{(string) Your KuCoin API key.}
#'   \item{api_secret}{(string) Your KuCoin API secret.}
#'   \item{api_passphrase}{(string) Your KuCoin API passphrase.}
#'   \item{key_version}{(string, optional) API key version (default: "2").}
#'   \item{base_url}{(string, optional) Base URL for API calls (default: "https://api.kucoin.com").}
#' }
#'
#' @section Expected Outputs:
#' Each method returns a promise that, when resolved, yields a \code{data.table} with columns
#' corresponding to the fields specified in the API documentation. For example, 
#' \code{getAccountSummaryInfo()} returns a table with columns such as \code{level},
#' \code{subQuantity}, \code{maxDefaultSubQuantity}, etc.
#'
#' @import R6
#' @import promises
#' @import data.table
#' @export
KucoinBasicInfo <- R6::R6Class("KucoinBasicInfo",
    public = list(
        #' @field config A list containing API credentials and settings.
        config = NULL,

        #' Initialize a new KucoinBasicInfo instance.
        #'
        #' @param config A named list with required API credentials and settings.
        #'   Expected keys: \code{api_key}, \code{api_secret}, \code{api_passphrase}.
        #'   Optional keys: \code{key_version} (default "2"), \code{base_url} (default "https://api.kucoin.com").
        #' @return A new \code{KucoinBasicInfo} object.
        #' @examples
        #' \dontrun{
        #'   config <- list(api_key = "your_key", api_secret = "your_secret",
        #'                  api_passphrase = "your_pass", key_version = "2",
        #'                  base_url = "https://api.kucoin.com")
        #'   basic_info <- KucoinBasicInfo$new(config)
        #' }
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
        #' Retrieves account summary information using the endpoint \code{GET /api/v2/user-info}.
        #'
        #' @return A promise that resolves to a \code{data.table} with one row and the following columns:
        #'   \describe{
        #'     \item{level}{User level (integer).}
        #'     \item{subQuantity}{Number of sub-accounts (integer).}
        #'     \item{maxDefaultSubQuantity}{Max default sub-accounts (integer).}
        #'     \item{maxSubQuantity}{Max total sub-accounts (integer).}
        #'     \item{spotSubQuantity}{Sub-accounts with spot trading enabled (integer).}
        #'     \item{marginSubQuantity}{Sub-accounts with margin trading enabled (integer).}
        #'     \item{futuresSubQuantity}{Sub-accounts with futures trading enabled (integer).}
        #'     \item{maxSpotSubQuantity}{Max additional spot sub-accounts (integer).}
        #'     \item{maxMarginSubQuantity}{Max additional margin sub-accounts (integer).}
        #'     \item{maxFuturesSubQuantity}{Max additional futures sub-accounts (integer).}
        #'   }
        #' @examples
        #' \dontrun{
        #'   basic_info$getAccountSummaryInfo()$
        #'     then(function(dt) {
        #'       # dt is a data.table with one row; print it to inspect the fields.
        #'       print(dt)
        #'     })$
        #'     catch(function(error) {
        #'       message("Error: ", error$message)
        #'     })
        #' }
        getAccountSummaryInfo = function() {
            promises::promise(function(resolve, reject) {
                tryCatch({
                    browser()
                    method <- "GET"
                    endpoint <- "/api/v2/user-info"
                    body <- ""
                    url <- paste0(get_base_url(self$config), endpoint)
                    headers <- build_headers(method, endpoint, body, self$config)
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
                    resolve(data.table::as.data.table(result$data))
                }, error = function(e) {
                    reject(rlang::abort("Failed to get account summary info", parent = e))
                })
            })
        },

        #' Get Account List.
        #'
        #' Retrieves a list of accounts using \code{GET /api/v1/accounts}. Optional query parameters:
        #' \code{currency} and \code{type}.
        #'
        #' @param currency (optional) A string specifying the currency (e.g., "BTC").
        #' @param type (optional) A string specifying the account type (e.g., "main", "trade", "margin", "trade_hf").
        #' @return A promise that resolves to a \code{data.table} where each row corresponds to an account,
        #'   with columns: \code{id}, \code{currency}, \code{type}, \code{balance}, \code{available}, and \code{holds}.
        #' @examples
        #' \dontrun{
        #'   basic_info$getAccountList(currency = "BTC", type = "trade")$
        #'     then(function(dt) {
        #'       print(dt)  # A data.table with one row per account.
        #'     })$
        #'     catch(function(e) {
        #'       message("Error: ", e$message)
        #'     })
        #' }
        getAccountList = function(currency = NULL, type = NULL) {
            promises::promise(function(resolve, reject) {
                tryCatch({
                    method <- "GET"
                    endpoint <- "/api/v1/accounts"
                    params <- list(currency = currency, type = type)
                    query <- build_query(params)
                    url <- paste0(get_base_url(self$config), endpoint, query)
                    headers <- build_headers(method, endpoint, "", self$config)
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
                    dt <- data.table::as.data.table(result$data)
                    resolve(dt)
                }, error = function(e) {
                    reject(rlang::abort("Failed to get account list", parent = e))
                })
            })
        },

        #' Get Account Detail.
        #'
        #' Retrieves detailed information for a single account using \code{GET /api/v1/accounts/{accountId}}.
        #'
        #' @param accountId A string representing the account ID.
        #' @return A promise that resolves to a \code{data.table} containing the account detail,
        #'   with columns: \code{currency}, \code{balance}, \code{available}, and \code{holds}.
        #' @examples
        #' \dontrun{
        #'   basic_info$getAccountDetail("5bd6e9286d99522a52e458de")$
        #'     then(function(dt) {
        #'       print(dt)
        #'     })$
        #'     catch(function(e) {
        #'       message("Error: ", e$message)
        #'     })
        #' }
        getAccountDetail = function(accountId) {
            promises::promise(function(resolve, reject) {
                tryCatch({
                    method <- "GET"
                    endpoint <- paste0("/api/v1/accounts/", accountId)
                    url <- paste0(get_base_url(self$config), endpoint)
                    headers <- build_headers(method, endpoint, "", self$config)
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
                    dt <- data.table::as.data.table(result)
                    resolve(dt)
                }, error = function(e) {
                    reject(rlang::abort("Failed to get account detail", parent = e))
                })
            })
        },

        #' Get Account Ledgers (Spot/Margin).
        #'
        #' Retrieves ledger (transaction) records for Spot/Margin accounts using \code{GET /api/v1/accounts/ledgers}.
        #' The API response is paginated; this method returns only the first page (the "items" field)
        #' as a \code{data.table}. Query parameters include:
        #' \code{currency}, \code{direction} ("in" or "out"), \code{bizType}, \code{startAt}, and \code{endAt}.
        #'
        #' @param currency (optional) A string specifying one or more currencies.
        #' @param direction (optional) A string: "in" or "out".
        #' @param bizType (optional) A string specifying the business type.
        #' @param startAt (optional) A numeric value (milliseconds) representing the start time.
        #' @param endAt (optional) A numeric value (milliseconds) representing the end time.
        #' @return A promise that resolves to a \code{data.table} of ledger items.
        #' @examples
        #' \dontrun{
        #'   basic_info$getAccountLedgers(currency = "BTC", startAt = 1601395200000)$
        #'     then(function(dt) {
        #'       print(dt)  # Each row is a ledger record.
        #'     })
        #' }
        getAccountLedgers = function(
            currency = NULL,
            direction = NULL,
            bizType = NULL,
            startAt = NULL,
            endAt = NULL
        ) {
        promises::promise(function(resolve, reject) {
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
                headers <- build_headers(method, endpoint, "", self$config)
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
                resolve(data.table::as.data.table(result$items))
                }, error = function(e) {
                    reject(rlang::abort("Failed to get account ledgers", parent = e))
                })
            })
        },

        #' Get Account Ledgers - trade_hf.
        #'
        #' Retrieves ledger records for high-frequency trading accounts using
        #' \code{GET /api/v1/hf/accounts/ledgers}. Query parameters include:
        #' \code{currency}, \code{direction}, \code{bizType}, \code{lastId}, \code{limit},
        #' \code{startAt}, and \code{endAt}.
        #'
        #' @param currency (optional) A string of currency symbols (comma-separated).
        #' @param direction (optional) "in" or "out".
        #' @param bizType (optional) A string representing the business type.
        #' @param lastId (optional) A numeric value representing the last ledger ID from a previous page.
        #' @param limit (optional) A numeric value (default 100, maximum 200).
        #' @param startAt (optional) Start time in milliseconds.
        #' @param endAt (optional) End time in milliseconds.
        #' @return A promise that resolves to a \code{data.table} of ledger records.
        #' @examples
        #' \dontrun{
        #'   basic_info$getAccountLedgersTradeHF(currency = "BTC", lastId = 123456, limit = 100)$
        #'     then(function(dt) {
        #'       print(dt)
        #'     })
        #' }
        getAccountLedgersTradeHF = function(
            currency = NULL,
            direction = NULL,
            bizType = NULL,
            lastId = NULL,
            limit = NULL,
            startAt = NULL,
            endAt = NULL
        ) {
            promises::promise(function(resolve, reject) {
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
                    headers <- build_headers(method, endpoint, "", self$config)
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
                    dt <- data.table::as.data.table(result$data)
                    resolve(dt)
                }, error = function(e) {
                    reject(rlang::abort("Failed to get trade HF account ledgers", parent = e))
                })
            })
        },

        #' Get Account Ledgers - margin_hf.
        #'
        #' Retrieves ledger records for high-frequency margin trading accounts using
        #' \code{GET /api/v3/hf/margin/account/ledgers}. Query parameters include:
        #' \code{currency}, \code{direction}, \code{bizType}, \code{lastId}, \code{limit},
        #' \code{startAt}, and \code{endAt}.
        #'
        #' @param currency (optional) A string of currency symbols.
        #' @param direction (optional) "in" or "out".
        #' @param bizType (optional) A string representing the business type.
        #' @param lastId (optional) A numeric value representing the last ledger ID from a previous page.
        #' @param limit (optional) A numeric value (default 100, maximum 200).
        #' @param startAt (optional) Start time in milliseconds.
        #' @param endAt (optional) End time in milliseconds.
        #' @return A promise that resolves to a \code{data.table} of ledger records.
        #' @examples
        #' \dontrun{
        #'   basic_info$getAccountLedgersMarginHF(currency = "BTC", limit = 100)$
        #'     then(function(dt) { print(dt) })
        #' }
        getAccountLedgersMarginHF = function(
            currency = NULL,
            direction = NULL,
            bizType = NULL,
            lastId = NULL,
            limit = NULL,
            startAt = NULL,
            endAt = NULL
        ) {
            promises::promise(function(resolve, reject) {
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
                    headers <- build_headers(method, endpoint, "", self$config)
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
                    dt <- data.table::as.data.table(result$data)
                    resolve(dt)
                }, error = function(e) {
                    reject(rlang::abort("Failed to get margin HF account ledgers", parent = e))
                })
            })
        },

        #' Get Account Ledgers - Futures.
        #'
        #' Retrieves ledger records for Futures accounts using \code{GET /api/v1/transaction-history}.
        #' Query parameters include: \code{offset}, \code{forward}, \code{maxCount},
        #' \code{startAt}, \code{endAt}, \code{type}, and \code{currency}.
        #'
        #' @param offset (optional) A numeric value for the starting offset.
        #' @param forward (optional) A boolean (default TRUE) indicating the lookup direction.
        #' @param maxCount (optional) A numeric value for the number of records per page (default 50).
        #' @param startAt (optional) Start time in milliseconds.
        #' @param endAt (optional) End time in milliseconds.
        #' @param type (optional) A string indicating the transaction type (e.g., "RealisedPNL", "Deposit").
        #' @param currency (optional) A string indicating the currency (e.g., "XBT" or "USDT").
        #' @return A promise that resolves to a \code{data.table} of futures ledger records.
        #' @examples
        #' \dontrun{
        #'   basic_info$getAccountLedgersFutures(offset = 1, maxCount = 50)$
        #'     then(function(dt) { print(dt) })
        #' }
        getAccountLedgersFutures = function(
            offset = NULL,
            forward = TRUE,
            maxCount = NULL,
            startAt = NULL,
            endAt = NULL,
            type = NULL,
            currency = NULL
        ) {
        promises::promise(function(resolve, reject) {
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
                headers <- build_headers(method, endpoint, "", self$config)
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
                # For futures, ledger records are contained in result$data$dataList.
                dt <- data.table::as.data.table(result$data$dataList)
                resolve(dt)
            }, error = function(e) {
                reject(rlang::abort("Failed to get futures account ledgers", parent = e))
            })
        })
        }
    )
)
