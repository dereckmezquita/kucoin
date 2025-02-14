# File: ./R/KucoinAccountAndFunding.R

box::use(
    impl = ./impl_account_and_funding,
    ./utils[ get_api_keys ]
)

#' KucoinAccountAndFunding Class for KuCoin Account & Funding Endpoints
#'
#' The `KucoinAccountAndFunding` class is designed to provide a comprehensive interface for interacting
#' with the Account & Funding endpoints of the KuCoin API. It leverages asynchronous programming (via the
#' `coro` package) to perform non-blocking HTTP requests. This class allows users to:
#'
#' - Retrieve an overall summary of their account, including VIP level and sub-account limits.
#' - Obtain detailed information about the API key being used, including permissions and metadata.
#' - Determine the type of spot account (high-frequency vs. low-frequency).
#' - List all spot accounts or retrieve detailed data for a specific spot account.
#' - Access cross margin account details including asset/liability summaries.
#' - Retrieve isolated margin account data for specific trading pairs.
#' - Get detailed transaction ledger records for spot and margin accounts.
#'
#' The class expects a configuration list containing your KuCoin API credentials and settings. If no configuration
#' is provided, it automatically loads credentials from environment variables using the `get_api_keys()` function.
#'
#' @section Methods:
#' - **initialize(config)**: General initialization; sets up API credentials.
#' - **get_account_summary_info()**: Retrieves account summary details.
#' - **get_apikey_info()**: Retrieves detailed API key information.
#' - **get_spot_account_type()**: Determines if your spot account is high-frequency or low-frequency.
#' - **get_spot_account_dt(query)**: Lists all spot accounts, with optional filtering.
#' - **get_spot_account_detail(accountId)**: Retrieves detailed information for a specific spot account.
#' - **get_cross_margin_account(query)**: Retrieves cross margin account information.
#' - **get_isolated_margin_account(query)**: Retrieves isolated margin account details for trading pairs.
#' - **get_spot_ledger(query)**: Retrieves transaction ledger records for spot and margin accounts.
#'
#' For more detailed information on each endpoint, please refer to the corresponding KuCoin API documentation.
#'
#' @examples
#' \dontrun{
#'     options(error = function() {
#'         rlang::entrace()
#'         rlang::last_trace()
#'         traceback()
#'     })
#'
#'     # Create an instance of the class (credentials are loaded from the environment by default)
#'     account <- KucoinAccountAndFunding$new()
#'
#'     # Define a main asynchronous function that calls all endpoints
#'     async_main <- coro::async(function() {
#'         # Retrieve account summary info
#'         dt_summary <- await(account$get_account_summary_info())
#'         cat("Account Summary Info (data.table):\n")
#'         print(dt_summary)
#'
#'         # Retrieve API key info
#'         dt_apikey <- await(account$get_apikey_info())
#'         cat("API Key Info (data.table):\n")
#'         print(dt_apikey)
#'
#'         # Retrieve spot account type (a boolean)
#'         is_high_freq <- await(account$get_spot_account_type())
#'         cat("Spot Account Type (boolean):\n")
#'         print(is_high_freq)
#'
#'         # Retrieve spot account list (as a data.table)
#'         dt_spot <- await(account$get_spot_account_dt())
#'         cat("Spot Account DT (data.table):\n")
#'         print(dt_spot)
#'
#'         # Optionally, retrieve spot account detail for a specific account
#'         if (nrow(dt_spot) > 0) {
#'             account_id <- dt_spot$id[1]
#'             cat("Retrieving spot account detail for account", account_id, "...\n")
#'             dt_detail <- await(account$get_spot_account_detail(account_id))
#'             cat("Spot Account Detail (data.table) for account", account_id, ":\n")
#'             print(dt_detail)
#'         } else {
#'             cat("No spot accounts available for detail retrieval.\n")
#'         }
#'
#'         # Retrieve cross margin account info using the new method.
#'         query_cm <- list(quoteCurrency = "USDT", queryType = "MARGIN")
#'         dt_cross_margin <- await(account$get_cross_margin_account(query_cm))
#'         cat("Cross Margin Account Info (data.table):\n")
#'         print(dt_cross_margin)
#'
#'         # Retrieve isolated margin account info with optional query parameters.
#'         query_im <- list(quoteCurrency = "USDT", queryType = "ISOLATED")
#'         dt_isolated <- await(account$get_isolated_margin_account(query_im))
#'         cat("Isolated Margin Account Info (data.table):\n")
#'         print(dt_isolated)
#'
#'         # Retrieve futures account info using the new method.
#'         query_futures <- list(currency = "USDT")
#'         dt_futures <- await(account$get_futures_account(query_futures))
#'         cat("Futures Account Info (data.table):\n")
#'         print(dt_futures)
#'
#'         # Retrieve spot ledger info (account ledgers for spot/margin)
#'         query_ledgers <- list(currency = "BTC", direction = "in", bizType = "TRANSFER", currentPage = 1, pageSize = 50)
#'         dt_ledgers <- await(account$get_spot_ledger(query_ledgers))
#'         cat("Spot Ledger Info (data.table):\n")
#'         print(dt_ledgers)
#'     })
#'
#'     async_main()
#'
#'     # Keep the event loop running until all asynchronous tasks have completed.
#'     while (!later::loop_empty()) {
#'         later::run_now(timeoutSecs = Inf, all = TRUE)
#'     }
#' }
#'
#' @export
#' @md
KucoinAccountAndFunding <- R6::R6Class(
    "KucoinAccountAndFunding",
    public = list(
        #' @field config A list containing API configuration parameters such as
        #' `api_key`, `api_secret`, `api_passphrase`, `base_url`, and `key_version`.
        config = NULL,

        #' Initialize a new KucoinAccountAndFunding object.
        #'
        #' @description
        #' Initializes the class with the configuration needed for authenticated requests.
        #' If no configuration is provided, it calls `get_api_keys()` to load API credentials from the environment.
        #'
        #' @param config A list of API configuration parameters. Expected keys include:
        #' - `api_key`: Your KuCoin API key.
        #' - `api_secret`: Your KuCoin API secret.
        #' - `api_passphrase`: Your KuCoin API passphrase.
        #' - `base_url`: The base URL of the KuCoin API (e.g., "https://api.kucoin.com").
        #' - `key_version`: The version of your API key (typically "2").
        #'
        #' @return A new instance of the `KucoinAccountAndFunding` class.
        initialize = function(config = get_api_keys()) {
            self$config <- config
        },

        #' Retrieve Account Summary Information.
        #'
        #' @description
        #' This method sends an asynchronous GET request to the KuCoin API endpoint for account summary information.
        #' The summary includes key details such as VIP level, sub-account counts, and various limits that govern your
        #' trading capacity.
        #'
        #' **API Endpoint:**  
        #' `GET https://api.kucoin.com/api/v2/user-info`
        #'
        #' **How It Works:**  
        #' - Constructs the full URL using the provided base URL.
        #' - Prepares authentication headers using the API credentials.
        #' - Sends the GET request and waits for the response.
        #' - Processes the JSON response into a `data.table`.
        #'
        #' **Response Schema:**  
        #' The response contains:
        #' - `code`: A string, with `"200000"` indicating success.
        #' - `data`: An object containing:
        #'   - `level`: User's VIP level.
        #'   - `subQuantity`: Total number of sub-accounts.
        #'   - `spotSubQuantity`: Number of spot trading sub-accounts.
        #'   - `marginSubQuantity`: Number of margin trading sub-accounts.
        #'   - `futuresSubQuantity`: Number of futures trading sub-accounts.
        #'   - `optionSubQuantity`: Number of option trading sub-accounts.
        #'   - `maxSubQuantity`: Maximum allowed sub-accounts.
        #'   - `maxDefaultSubQuantity`, `maxSpotSubQuantity`, `maxMarginSubQuantity`, `maxFuturesSubQuantity`, `maxOptionSubQuantity`: Detailed limits.
        #'
        #' For more details, see the [Account Summary API Documentation](https://www.kucoin.com/docs-new/rest/account-info/account-funding/get-account-summary-info).
        #'
        #' @return A promise that resolves to a `data.table` with the account summary.
        get_account_summary_info = function() {
            return(impl$get_account_summary_info_impl(self$config))
        },

        #' Retrieve API Key Information.
        #'
        #' @description
        #' This method fetches detailed information about the API key used for authentication. It returns data that
        #' includes the key itself, its permissions, the API version, and additional metadata (such as creation time).
        #'
        #' **API Endpoint:**  
        #' `GET https://api.kucoin.com/api/v1/user/api-key`
        #'
        #' **How It Works:**  
        #' - Constructs the request URL and builds authentication headers.
        #' - Sends an asynchronous GET request to the API.
        #' - Processes the returned JSON data into a `data.table`.
        #'
        #' **Response Schema:**  
        #' The response contains:
        #' - `code`: `"200000"` on success.
        #' - `data`: An object containing:
        #'   - `uid`: Account UID.
        #'   - `subName`: (Optional) Sub account name.
        #'   - `remark`: Remarks for the API key.
        #'   - `apiKey`: The API key string.
        #'   - `apiVersion`: The version of the API key.
        #'   - `permission`: A comma-separated list of permissions.
        #'   - `ipWhitelist`: (Optional) IP whitelist.
        #'   - `isMaster`: Boolean indicating if this is the master account key.
        #'   - `createdAt`: Creation timestamp in milliseconds.
        #'
        #' For more information, refer to the [API Key Info Documentation](https://www.kucoin.com/docs-new/rest/account-info/account-funding/get-apikey-info).
        #'
        #' @return A promise that resolves to a `data.table` with API key information.
        get_apikey_info = function() {
            return(impl$get_apikey_info_impl(self$config))
        },

        #' Retrieve Spot Account Type.
        #'
        #' @description
        #' This method determines the type of your spot account (high-frequency vs. low-frequency). The account type
        #' influences which endpoints you use for transferring assets and querying balances.
        #'
        #' **API Endpoint:**  
        #' `GET https://api.kucoin.com/api/v1/hf/accounts/opened`
        #'
        #' **How It Works:**  
        #' - Builds the request URL and authentication headers.
        #' - Sends a GET request asynchronously.
        #' - The response is processed to return a boolean value:
        #'   - `TRUE`: Indicates a high-frequency spot account.
        #'   - `FALSE`: Indicates a low-frequency spot account.
        #'
        #' For more details, see the [Spot Account Type Documentation](https://www.kucoin.com/docs-new/rest/account-info/account-funding/get-account-type-spot).
        #'
        #' @return A promise that resolves to a boolean (TRUE for high-frequency, FALSE for low-frequency).
        get_spot_account_type = function() {
            return(impl$get_spot_account_type_impl(self$config))
        },

        #' Retrieve Spot Account List.
        #'
        #' @description
        #' This method obtains a list of all spot accounts linked to your KuCoin account. You can filter the list
        #' by currency and account type (such as "main" or "trade"). This is especially useful if you manage multiple
        #' accounts and need to query specific subsets.
        #'
        #' **API Endpoint:**  
        #' `GET https://api.kucoin.com/api/v1/accounts`
        #'
        #' **How It Works:**  
        #' - Constructs the endpoint URL with an optional query string.
        #' - Sends an asynchronous GET request with proper authentication.
        #' - Converts the returned JSON array into a `data.table`.
        #'
        #' **Response Schema:**  
        #' The response includes:
        #' - `code`: `"200000"` if the request is successful.
        #' - `data`: An array of objects, each containing:
        #'   - `id`: Unique account identifier.
        #'   - `currency`: Currency code (e.g., "USDT").
        #'   - `type`: Type of account (e.g., "main", "trade", "balance").
        #'   - `balance`: Total funds.
        #'   - `available`: Funds available for trading/withdrawal.
        #'   - `holds`: Funds on hold.
        #'
        #' For more details, refer to the [Spot Account List Documentation](https://www.kucoin.com/docs-new/rest/account-info/account-funding/get-account-list-spot).
        #'
        #' @param query A named list of query parameters (e.g., `list(currency = "USDT", type = "main")`).
        #' @return A promise that resolves to a `data.table` with the list of spot accounts.
        get_spot_account_dt = function(query = list()) {
            return(impl$get_spot_account_dt_impl(self$config, query))
        },

        #' Retrieve Spot Account Detail.
        #'
        #' @description
        #' This method retrieves detailed information for a specific spot account identified by its account ID.
        #' The detailed information includes currency, total balance, available balance, and funds on hold.
        #'
        #' **API Endpoint:**  
        #' `GET https://api.kucoin.com/api/v1/accounts/{accountId}`
        #'
        #' **How It Works:**  
        #' - Interpolates the provided account ID into the endpoint URL.
        #' - Sends an asynchronous GET request with authentication headers.
        #' - Processes the response to return a `data.table` with the account details.
        #'
        #' **Response Schema:**  
        #' - `code`: `"200000"` signifies success.
        #' - `data`: An object containing:
        #'   - `currency`: The currency of the account.
        #'   - `balance`: The total funds held.
        #'   - `available`: Funds available for trading or withdrawal.
        #'   - `holds`: Funds that are locked or on hold.
        #'
        #' For further details, refer to the [Spot Account Detail Documentation](https://www.kucoin.com/docs-new/rest/account-info/account-funding/get-account-detail-spot).
        #'
        #' @param accountId A string representing the unique account ID.
        #' @return A promise that resolves to a `data.table` with detailed spot account information.
        get_spot_account_detail = function(accountId) {
            return(impl$get_spot_account_detail_impl(self$config, accountId))
        },

        #' Retrieve Cross Margin Account Information.
        #'
        #' @description
        #' This method retrieves detailed information about your cross margin account, which allows you to use collateral
        #' from multiple trading pairs. The returned data includes total assets, liabilities, debt ratios, and individual
        #' margin account details.
        #'
        #' **API Endpoint:**  
        #' `GET https://api.kucoin.com/api/v3/margin/accounts`
        #'
        #' **How It Works:**  
        #' - Constructs a query string from the provided parameters.
        #' - Sends an authenticated asynchronous GET request.
        #' - Processes the response to produce a `data.table` with both summary and detailed margin account information.
        #'
        #' **Query Parameters:**  
        #' - `quoteCurrency`: (Optional) Filter by quote currency (e.g., "USDT"); defaults to "USDT".
        #' - `queryType`: (Optional) Filter by account type: "MARGIN", "MARGIN_V2", or "ALL"; defaults to "MARGIN".
        #'
        #' **Response Schema:**  
        #' The response includes:
        #' - `code`: "200000" indicates success.
        #' - `data`: An object containing overall metrics (e.g., total assets, liabilities, debt ratio, status) and an array `accounts` 
        #'   with detailed information for each margin account.
        #'
        #' For more details, see the [Cross Margin API Documentation](https://www.kucoin.com/docs-new/rest/account-info/account-funding/get-account-cross-margin).
        #'
        #' @param query A named list of query parameters (e.g., `list(quoteCurrency = "USDT", queryType = "MARGIN")`).
        #' @return A promise that resolves to a `data.table` containing cross margin account information.
        get_cross_margin_account = function(query = list()) {
            return(impl$get_cross_margin_account_impl(self$config, query))
        },

        #' Retrieve Isolated Margin Account Information.
        #'
        #' @description
        #' This method retrieves isolated margin account details for specific trading pairs. Isolated margin allows you
        #' to limit risk exposure to an individual pair by separating collateral. The response includes detailed asset 
        #' and liability information per trading pair.
        #'
        #' **API Endpoint:**  
        #' `GET https://api.kucoin.com/api/v3/isolated/accounts`
        #'
        #' **How It Works:**  
        #' - Builds the endpoint URL with an optional query string based on parameters.
        #' - Sends an authenticated GET request asynchronously.
        #' - Processes the JSON response into a `data.table` containing isolated margin data.
        #'
        #' **Query Parameters:**  
        #' - `symbol`: (Optional) Specify a trading pair (e.g., "BTC-USDT"). If omitted, data for all pairs is returned.
        #' - `quoteCurrency`: (Optional) Filter by quote currency; defaults to "USDT".
        #' - `queryType`: (Optional) Allowed values: "ISOLATED", "ISOLATED_V2", "ALL"; defaults to "ISOLATED".
        #'
        #' **Response Schema:**  
        #' The response returns:
        #' - `code`: "200000" on success.
        #' - `data`: An object that includes overall metrics and an `assets` array with details for each pair.
        #'
        #' For more details, refer to the [Isolated Margin API Documentation](https://www.kucoin.com/docs-new/rest/account-info/account-funding/get-account-isolated-margin).
        #'
        #' @param query A named list of query parameters (e.g., `list(quoteCurrency = "USDT", queryType = "ISOLATED")`).
        #' @return A promise that resolves to a `data.table` with isolated margin account information.
        get_isolated_margin_account = function(query = list()) {
            return(impl$get_isolated_margin_account_impl(self$config, query))
        },

        #' Retrieve Spot Ledger Records.
        #'
        #' @description
        #' This method retrieves detailed ledger records for your spot and margin accounts. Ledger records include
        #' transaction histories such as deposits, withdrawals, transfers, and trades. The method supports filtering
        #' by multiple criteria, including currency, transaction direction, business type, and time range.
        #'
        #' **API Endpoint:**  
        #' `GET https://api.kucoin.com/api/v1/accounts/ledgers`
        #'
        #' **How It Works:**  
        #' - Constructs the endpoint URL with a query string based on provided parameters.
        #' - Sends an asynchronous GET request with authentication headers.
        #' - Processes the paginated JSON response into a `data.table` that includes both the ledger items and pagination details.
        #'
        #' **Query Parameters:**  
        #' - `currency`: (Optional) One or more currencies to filter by (up to 10).
        #' - `direction`: (Optional) "in" for incoming or "out" for outgoing transactions.
        #' - `bizType`: (Optional) The business type (e.g., "DEPOSIT", "WITHDRAW", "TRANSFER").
        #' - `startAt` / `endAt`: (Optional) Millisecond timestamps to specify a time range.
        #' - `currentPage`: (Optional) Page number (default is 1).
        #' - `pageSize`: (Optional) Number of records per page (default is 50; minimum 10, maximum 500).
        #'
        #' **Response Schema:**  
        #' The response includes:
        #' - `code`: "200000" if successful.
        #' - `data`: An object containing:
        #'   - Pagination metadata: `currentPage`, `pageSize`, `totalNum`, `totalPage`.
        #'   - `items`: An array of ledger record objects detailing individual transactions.
        #'
        #' For further information, see the [Spot Ledger API Documentation](https://www.kucoin.com/docs-new/rest/account-info/account-funding/get-account-ledgers-spot-margin).
        #'
        #' @param query A named list of query parameters (e.g., `list(currency = "BTC", direction = "in", bizType = "TRANSFER", currentPage = 1, pageSize = 50)`).
        #' @return A promise that resolves to a `data.table` containing ledger records and pagination info.
        get_spot_ledger = function(query = list()) {
            return(impl$get_spot_ledger_impl(self$config, query))
        }
    )
)
