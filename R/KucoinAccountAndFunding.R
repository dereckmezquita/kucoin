# File: KucoinAccountAndFunding.R

box::use(
    R6,
    rlang[abort],
    ./account_and_funding[
        get_account_summary_info_impl, get_apikey_info_impl, get_spot_account_type_impl,
        get_spot_account_dt_impl, get_spot_account_detail_impl, get_cross_margin_account_impl, get_isolated_margin_account_impl, get_futures_account_impl, get_spot_ledger_impl
    ],
    ./utils[get_api_keys]
)

#' KucoinAccountAndFunding Class for KuCoin Account & Funding Endpoints
#'
#' The `KucoinAccountAndFunding` class provides an interface to interact with various endpoints
#' in the Account & Funding category of the KuCoin API. It leverages asynchronous programming to send HTTP requests
#' and handle responses. Configuration parameters (such as API key, secret, passphrase, base URL, and key version)
#' are loaded from the environment or can be passed in directly.
#'
#' @section Methods:
#' - **initialize(config)**: Creates a new instance of the class. If no configuration is provided,
#'   `get_api_keys()` is used to load API credentials from environment variables.
#' - **get_account_summary_info()**: Returns a promise that resolves to a data.table containing the account summary data.
#' - **get_apikey_info()**: Returns a promise that resolves to a data.table containing the API key information.
#'
#' For more details, please refer to:
#' - Get Account Summary Info: [KuCoin API Documentation](https://www.kucoin.com/docs-new/rest/account-info/account-funding/get-account-summary-info)
#' - Get Apikey Info: [KuCoin API Documentation](https://www.kucoin.com/docs-new/rest/account-info/account-funding/get-apikey-info)
#'
#' @examples
#' \dontrun{
#'   library(coro)
#'   account <- KucoinAccountAndFunding$new()
#'   coro::run(function() {
#'       dt_summary <- await(account$get_account_summary_info())
#'       print(dt_summary)
#'       dt_apikey <- await(account$get_apikey_info())
#'       print(dt_apikey)
#'   })
#' }
#'
#' @export
KucoinAccountAndFunding <- R6::R6Class(
    "KucoinAccountAndFunding",
    public = list(
        #' @field config A list containing API configuration parameters such as
        #' `api_key`, `api_secret`, `api_passphrase`, `base_url`, and `key_version`.
        config = NULL,
        
        #' Initialize a new KucoinAccountAndFunding object.
        #'
        #' @description
        #' Sets up the configuration for making authenticated API requests.
        #' If no configuration is provided, `get_api_keys()` is invoked to load the necessary credentials from environment variables.
        #'
        #' @param config A list containing API configuration parameters.
        #'               Defaults to the output of `get_api_keys()`.
        #' @return A new instance of the `KucoinAccountAndFunding` class.
        initialize = function(config = get_api_keys()) {
            self$config <- config
        },
        
        #' Get Account Summary Information from KuCoin.
        #'
        #' @description
        #' Asynchronously retrieves account summary information by sending a GET request to the
        #' `/api/v2/user-info` endpoint of the KuCoin API.
        #' 
        #' For full endpoint details, refer to the [KuCoin API Documentation](https://www.kucoin.com/docs-new/rest/account-info/account-funding/get-account-summary-info).
        #'
        #' @details
        #' **Endpoint:** `GET https://api.kucoin.com/api/v2/user-info`
        #' 
        #' **Response Schema:**
        #' - **code** (string): `"200000"` indicates success.
        #' - **data** (object): Contains fields such as `level`, `subQuantity`, `spotSubQuantity`,
        #'   `marginSubQuantity`, `futuresSubQuantity`, `optionSubQuantity`, `maxSubQuantity`,
        #'   `maxDefaultSubQuantity`, `maxSpotSubQuantity`, `maxMarginSubQuantity`, `maxFuturesSubQuantity`, and `maxOptionSubQuantity`.
        #'
        #' @return A promise that resolves to a data.table containing the account summary data.
        #' @examples
        #' \dontrun{
        #'   coro::run(function() {
        #'       dt <- await(account$get_account_summary_info())
        #'       print(dt)
        #'   })
        #' }
        get_account_summary_info = function() {
            get_account_summary_info_impl(self$config)
        },
        
        #' Get API Key Information from KuCoin.
        #'
        #' @description
        #' Asynchronously retrieves API key information by sending a GET request to the
        #' `/api/v1/user/api-key` endpoint of the KuCoin API.
        #' The returned JSON data is converted to a data.table.
        #' 
        #' For full endpoint details, refer to the [KuCoin API Documentation](https://www.kucoin.com/docs-new/rest/account-info/account-funding/get-apikey-info).
        #'
        #' @details
        #' **Endpoint:** `GET https://api.kucoin.com/api/v1/user/api-key`
        #' 
        #' **Response Schema:**
        #' - **code** (string): `"200000"` indicates success.
        #' - **data** (object): Contains fields such as:
        #'     - **uid** (integer): Account UID.
        #'     - **subName** (string, optional): Sub account name (if applicable).
        #'     - **remark** (string): Remarks.
        #'     - **apiKey** (string): The API key.
        #'     - **apiVersion** (integer): API version.
        #'     - **permission** (string): Comma-separated list of permissions (e.g., General, Spot, Margin, Futures, InnerTransfer, Transfer, Earn).
        #'     - **ipWhitelist** (string, optional): IP whitelist.
        #'     - **isMaster** (boolean): Whether it is the master account.
        #'     - **createdAt** (integer): API key creation time in milliseconds.
        #'
        #' @return A promise that resolves to a data.table containing the API key information.
        #' @examples
        #' \dontrun{
        #'   coro::run(function() {
        #'       dt <- await(account$get_apikey_info())
        #'       print(dt)
        #'   })
        #' }
        get_apikey_info = function() {
            get_apikey_info_impl(self$config)
        },

        #' Get Spot Account Type from KuCoin.
        #'
        #' @description
        #' Asynchronously determines whether the current user is a high-frequency or low-frequency spot user
        #' by sending a GET request to the `/api/v1/hf/accounts/opened` endpoint.
        #' The response is a boolean value: TRUE indicates a high-frequency spot user, FALSE indicates a low-frequency spot user.
        #'
        #' @details
        #' **Endpoint:** `GET https://api.kucoin.com/api/v1/hf/accounts/opened`
        #' 
        #' **Response Schema:**
        #' - **code** (string): `"200000"` indicates success.
        #' - **data** (boolean): The spot account type. TRUE means the user is high-frequency, FALSE means low-frequency.
        #'
        #' For more details, refer to the [KuCoin API Documentation](https://www.kucoin.com/docs-new/rest/account-info/account-funding/get-account-type-spot).
        #'
        #' @return A promise that resolves to a boolean indicating the spot account type.
        #' @examples
        #' \dontrun{
        #'   coro::run(function() {
        #'       is_high_freq <- await(account$get_spot_account_type())
        #'       print(is_high_freq)
        #'   })
        #' }
        get_spot_account_type = function() {
            get_spot_account_type_impl(self$config)
        },

        #' Get Spot Account List from KuCoin.
        #'
        #' @description
        #' Asynchronously retrieves a list of spot accounts by sending a GET request to the
        #' `/api/v1/accounts` endpoint with optional query parameters.
        #' Query parameters may include:
        #'   - **currency** (string, optional): e.g., "USDT".
        #'   - **type** (string, optional): Allowed values are "main" or "trade".
        #' The returned JSON data is converted to a data.table.
        #'
        #' @details
        #' **Endpoint:** `GET https://api.kucoin.com/api/v1/accounts`
        #' 
        #' **Response Schema:**
        #' - **code** (string): `"200000"` indicates success.
        #' - **data** (array of objects): Each object contains:
        #'     - **id** (string): Account ID.
        #'     - **currency** (string): Currency code.
        #'     - **type** (string): Account type (e.g., "main", "trade", "balance").
        #'     - **balance** (string): Total funds in the account.
        #'     - **available** (string): Funds available for withdrawal or trading.
        #'     - **holds** (string): Funds on hold.
        #'
        #' @param query A list of query parameters to filter the account list.
        #'              For example: list(currency = "USDT", type = "main").
        #'
        #' @return A promise that resolves to a data.table containing the spot account list.
        #' @examples
        #' \dontrun{
        #'   coro::run(function() {
        #'       dt <- await(account$get_spot_account_list(list(currency = "USDT", type = "main")))
        #'       print(dt)
        #'   })
        #' }
        get_spot_account_dt = function(query = list()) {
            get_spot_account_dt_impl(self$config, query)
        },

        #' Get Spot Account Detail from KuCoin.
        #'
        #' @description
        #' Asynchronously retrieves detailed information for a single spot account by sending a GET request to the
        #' `/api/v1/accounts/{accountId}` endpoint. This endpoint is used when the account ID is known.
        #' The returned JSON object is converted to a data.table.
        #'
        #' @param accountId A string representing the account ID.
        #'
        #' @return A promise that resolves to a data.table containing the account detail for the specified account.
        #' @details
        #' **Endpoint:** `GET https://api.kucoin.com/api/v1/accounts/{accountId}`
        #' 
        #' **Response Schema:**
        #' - **code** (string): `"200000"` indicates success.
        #' - **data** (object): Contains the following fields:
        #'     - **currency** (string): The currency of the account.
        #'     - **balance** (string): Total funds in the account.
        #'     - **available** (string): Funds available for withdrawal or trading.
        #'     - **holds** (string): Funds on hold (not available for use).
        #'
        #' For further details, refer to the [KuCoin API Documentation](https://www.kucoin.com/docs-new/rest/account-info/account-funding/get-account-detail-spot).
        #'
        #' @examples
        #' \dontrun{
        #'   coro::run(function() {
        #'       dt <- await(account$get_spot_account_detail("548674591753"))
        #'       print(dt)
        #'   })
        #' }
        get_spot_account_detail = function(accountId) {
            get_spot_account_detail_impl(self$config, accountId)
        },

        #' Get Cross Margin Account from KuCoin.
        #'
        #' @description
        #' Asynchronously retrieves information about the cross margin account by sending a GET request to the
        #' `/api/v3/margin/accounts` endpoint with optional query parameters. The response is converted to a data.table.
        #'
        #' @param query A list of query parameters to filter the account information. Supported parameters include:
        #'   - **quoteCurrency** (string, optional): Allowed values: `"USDT"`, `"KCS"`, `"BTC"`. Default is `"USDT"`.
        #'   - **queryType** (string, optional): Allowed values: `"MARGIN"`, `"MARGIN_V2"`, `"ALL"`. Default is `"MARGIN"`.
        #'
        #' @return A promise that resolves to a data.table containing the cross margin account information.
        #'
        #' @details
        #' **Endpoint:** `GET https://api.kucoin.com/api/v3/margin/accounts`
        #'
        #' For further details, refer to the [KuCoin API Documentation](https://www.kucoin.com/docs-new/rest/account-info/account-funding/get-account-cross-margin).
        #'
        #' @examples
        #' \dontrun{
        #'   coro::run(function() {
        #'       dt <- await(account$get_cross_margin_account(list(quoteCurrency = "USDT", queryType = "MARGIN")))
        #'       print(dt)
        #'   })
        #' }
        get_cross_margin_account = function(query = list()) {
            get_cross_margin_account_impl(self$config, query)
        },

        #' Get Isolated Margin Account from KuCoin.
        #'
        #' @description
        #' Asynchronously retrieves information about the isolated margin account by sending a GET request to the
        #' `/api/v3/isolated/accounts` endpoint with optional query parameters. The response is converted to a data.table.
        #'
        #' @param query A list of query parameters to filter the isolated margin account information.
        #'        Supported parameters include:
        #'         - **symbol** (string, optional): For isolated trading pairs; if omitted, queries all pairs.
        #'         - **quoteCurrency** (string, optional): Allowed values: `"USDT"`, `"KCS"`, `"BTC"`. Default is `"USDT"`.
        #'         - **queryType** (string, optional): Allowed values: `"ISOLATED"`, `"ISOLATED_V2"`, `"ALL"`. Default is `"ISOLATED"`.
        #'
        #' @return A promise that resolves to a data.table containing the isolated margin account information.
        #'
        #' @details
        #' **Endpoint:** `GET https://api.kucoin.com/api/v3/isolated/accounts`
        #'
        #' For more details, refer to the [KuCoin API Documentation](https://www.kucoin.com/docs-new/rest/account-info/account-funding/get-account-isolated-margin).
        #'
        #' @examples
        #' \dontrun{
        #'     coro::run(function() {
        #'         dt <- await(account$get_isolated_margin_account(list(quoteCurrency = "USDT", queryType = "ISOLATED")))
        #'         print(dt)
        #'     })
        #' }
        get_isolated_margin_account = function(query = list()) {
            get_isolated_margin_account_impl(self$config, query)
        },

        #' Get Futures Account from KuCoin Futures API
        #'
        #' @description
        #' Asynchronously retrieves the futures account information by calling the futures endpoint.
        #'
        #' @param query A list of query parameters to filter the account information.
        #'              Supported parameter: **currency** (string, optional) – the account currency (default is "XBT").
        #'
        #' @return A promise that resolves to a data.table containing the futures account information.
        #'
        #' @examples
        #' \dontrun{
        #'     coro::run(function() {
        #'         dt <- await(account$get_futures_account(list(currency = "USDT")))
        #'         print(dt)
        #'     })
        #' }
        get_futures_account = function(query = list()) {
            get_futures_account_impl(self$config, query)
        },

        #' Get Spot Ledger from KuCoin
        #'
        #' @description
        #' Asynchronously retrieves the spot (and margin) ledger records by querying the `/api/v1/accounts/ledgers` endpoint.
        #'
        #' @param query A list of query parameters to filter the ledger records.
        #'              Supported parameters include:
        #'              - **currency** (string, optional): One or more currencies (up to 10).
        #'              - **direction** (string, optional): "in" or "out".
        #'              - **bizType** (string, optional): The business type (e.g., "TRANSFER").
        #'              - **startAt** (integer, optional): Start time in milliseconds.
        #'              - **endAt** (integer, optional): End time in milliseconds.
        #'              - **currentPage** (integer, optional): The page number (default is 1).
        #'              - **pageSize** (integer, optional): Number of results per page (default is 50).
        #'
        #' @return A promise that resolves to a data.table containing the ledger records.
        #'
        #' @examples
        #' \dontrun{
        #'     coro::run(function() {
        #'         dt <- await(account$get_spot_ledger(list(currency = "BTC", direction = "in", bizType = "TRANSFER", currentPage = 1, pageSize = 50)))
        #'         print(dt)
        #'     })
        #' }
        get_spot_ledger = function(query = list()) {
            get_spot_ledger_impl(self$config, query)
        }
    )
)
