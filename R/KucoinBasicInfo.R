box::use(
    rlang,
    httr,
    data.table,
    coro,
    ./account[
        getAccountSummaryInfo,
        getAccountList,
        getAccountDetail,
        getAccountLedgers,
        getAccountLedgersTradeHF,
        getAccountLedgersMarginHF,
        getAccountLedgersFutures
    ],
    ./get_api_keys[get_api_keys]
)

#' KucoinAPI R6 Class for KuCoin API Endpoints
#'
#' This class wraps the asynchronous API endpoint functions from the modules.
#' All methods return a promise that resolves to a data.table.
#'
#' @export
KucoinAccountsBasicInfo <- R6::R6Class("KucoinAccountsBasicInfo",
    public = list(
        #' @field config A list containing API credentials and settings.
        config = NULL,

        #' Initialize a new KucoinAPI instance.
        #'
        #' @param config A named list with required API credentials and settings.
        #'   Required keys: `api_key`, `api_secret`, `api_passphrase`.
        #'   Optional keys: `key_version` (default "2"), `base_url` (default "https://api.kucoin.com").
        initialize = function(config) {
            required <- c("api_key", "api_secret", "api_passphrase")
            missing <- setdiff(required, names(config))
            if (length(missing) > 0) {
                stop(sprintf("Missing required config fields: %s", paste(missing, collapse = ", ")))
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
            getAccountSummaryInfo(self$config)
        }),

        #' Get Account List.
        #'
        #' Retrieves a list of accounts using the endpoint `GET /api/v1/accounts`.
        #'
        #' @param currency (optional) Filter by currency.
        #' @param type (optional) Filter by account type (e.g., "main", "trade").
        #' @return A promise that resolves to a data.table of accounts.
        getAccountList = coro::async(function(currency = NULL, type = NULL) {
            getAccountList(self$config, currency, type)
        }),

        #' Get Account Detail.
        #'
        #' Retrieves detailed information for a specific account using the endpoint `GET /api/v1/accounts/{accountId}`.
        #'
        #' @param accountId A string representing the account ID.
        #' @return A promise that resolves to a data.table with account details.
        getAccountDetail = coro::async(function(accountId) {
            getAccountDetail(self$config, accountId)
        }),

        #' Get Account Ledgers.
        #'
        #' Retrieves ledger records for Spot/Margin accounts using the endpoint `GET /api/v1/accounts/ledgers`.
        #'
        #' @param currency (optional) Filter by currency.
        #' @param direction (optional) "in" or "out".
        #' @param bizType (optional) Filter by business type.
        #' @param startAt (optional) Start time (milliseconds).
        #' @param endAt (optional) End time (milliseconds).
        #' @return A promise that resolves to a data.table of ledger records.
        getAccountLedgers = coro::async(function(currency = NULL, direction = NULL, bizType = NULL, startAt = NULL, endAt = NULL) {
            getAccountLedgers(self$config, currency, direction, bizType, startAt, endAt)
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
        getAccountLedgersTradeHF = coro::async(function(currency = NULL, direction = NULL, bizType = NULL, lastId = NULL, limit = NULL, startAt = NULL, endAt = NULL) {
            getAccountLedgersTradeHF(self$config, currency, direction, bizType, lastId, limit, startAt, endAt)
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
        getAccountLedgersMarginHF = coro::async(function(currency = NULL, direction = NULL, bizType = NULL, lastId = NULL, limit = NULL, startAt = NULL, endAt = NULL) {
            getAccountLedgersMarginHF(self$config, currency, direction, bizType, lastId, limit, startAt, endAt)
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
        getAccountLedgersFutures = coro::async(function(offset = NULL, forward = TRUE, maxCount = NULL, startAt = NULL, endAt = NULL, type = NULL, currency = NULL) {
            getAccountLedgersFutures(self$config, offset, forward, maxCount, startAt, endAt, type, currency)
        })
    )
)