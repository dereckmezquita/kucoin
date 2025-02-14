# File: ./R/KucoinSubAccount.R

box::use(
    impl = ./accounts_sub_account,
    ./utils[ get_api_keys, get_subaccount ]
)

#' KuCoin SubAccount Class
#'
#' The `KuCoinSubAccount` class provides a comprehensive, user-facing interface for interacting with KuCoin's 
#' sub-account endpoints. This class leverages asynchronous programming (using the `coro` package) to perform 
#' non-blocking HTTP requests and process responses efficiently. It is designed for users who need to manage 
#' sub-accounts—such as creating new sub-accounts, retrieving a paginated summary of all sub-accounts, and 
#' fetching detailed balance information for a specific sub-account.
#'
#' The class automatically loads API configuration parameters from the environment (via `get_api_keys()`) and 
#' sub-account–specific parameters via `get_subaccount()`, but these can also be provided explicitly.
#'
#' ## Available Methods
#'
#' - **initialize(config):**  
#'   Creates a new instance of the `KuCoinSubAccount` class with the given API configuration.
#'
#' - **add_subaccount(password, subName, access, remarks):**  
#'   Creates a new sub-account on KuCoin by sending a POST request to the endpoint `/api/v2/sub/user/created`.
#'   This method handles request body construction, header generation, error checking, and returns a `data.table` with the new sub-account's details.
#'   **Official API Docs:** [Add SubAccount](https://www.kucoin.com/docs-new/rest/account-info/sub-account/add-subaccount)
#'
#' - **get_subaccount_list_summary(page_size, max_pages):**  
#'   Retrieves a paginated summary list of sub-accounts by sending GET requests to `/api/v2/sub/user`. 
#'   The method automatically paginates and aggregates results into a single `data.table`, converting timestamp fields to POSIXct datetimes.
#'   **Official API Docs:** [Get Sub-Account List - Summary Info](https://www.kucoin.com/docs-new/rest/account-info/sub-account/get-subaccount-list-summary-info)
#'
#' - **get_subaccount_detail_balance(subUserId, includeBaseAmount):**  
#'   Retrieves detailed balance information for a specified sub-account by sending a GET request to 
#'   `/api/v1/sub-accounts/{subUserId}`. It processes multiple arrays (mainAccounts, tradeAccounts, marginAccounts, and tradeHFAccounts),
#'   converts them to `data.table`s with an added "accountType" column, aggregates them, and appends sub-account metadata.
#'   **Official API Docs:** [Get SubAccount Detail - Balance](https://www.kucoin.com/docs-new/rest/account-info/sub-account/get-subaccount-detail-balance)
#'
#' @examples
#' \dontrun{
#'     options(error = function() {
#'         rlang::entrace()
#'         rlang::last_trace()
#'         traceback()
#'     })
#'
#'     subAcc <- KuCoinSubAccount$new()
#'
#'     async_main <- coro::async(function() {
#'         result <- await(subAcc$add_subaccount(
#'             password = "SomeStrongPass12345",
#'             subName  = "Name12345678",
#'             access   = "Spot",
#'             remarks  = "Test sub-account"
#'         ))
#'         cat("SubAccount Creation Result:\n")
#'         print(result)
#'
#'         # Retrieve sub-account list summary.
#'         # Here we fetch 3 pages with a page size of 50.
#'         dt_summary <- await(subAcc$get_subaccount_list_summary(
#'             page_size = 50,
#'             max_pages = 3
#'         ))
#'         cat("SubAccount List Summary:\n")
#'         print(dt_summary)
#'
#'         # Example: Retrieve sub-account detail (balance) for a given subUserId.
#'         dt_balance <- await(subAcc$get_subaccount_detail_balance("some-accout-num", includeBaseAmount = FALSE))
#'         cat("SubAccount Detail - Balance:\n")
#'         print(dt_balance)
#'     })
#'
#'     async_main()
#'
#'     while (!later::loop_empty()) {
#'         later::run_now(timeoutSecs = Inf, all = TRUE)
#'     }
#' }
#'
#' @md
#' @export
KuCoinSubAccount <- R6::R6Class(
    "KuCoinSubAccount",
    public = list(
        config = NULL,
        #' Initialize a new KuCoinSubAccount object.
        #'
        #' @description
        #' Sets up the KuCoinSubAccount object with API credentials and sub-account configuration.
        #' If no configuration is provided, it automatically loads API parameters using `get_api_keys()`
        #' and sub-account parameters via `get_subaccount()`.
        #'
        #' @param config A list containing API configuration parameters (e.g., `api_key`, `api_secret`, `api_passphrase`, `base_url`, `key_version`).
        #'               Defaults to the output of `get_api_keys()`.
        #' @return A new instance of the `KuCoinSubAccount` class.
        initialize = function(config = get_api_keys()) {
            self$config <- config
        },

        #' Add SubAccount
        #'
        #' @description
        #' Creates a new sub-account under the master account by sending a POST request to KuCoin. This method builds the JSON request
        #' body using the provided sub-account details, generates authentication headers, sends the request, and processes the response.
        #' On success, it returns a `data.table` containing key details of the newly created sub-account.
        #'
        #' **API Endpoint:**  
        #' `POST https://api.kucoin.com/api/v2/sub/user/created`
        #'
        #' **Detailed Workflow:**  
        #' 1. Constructs the full URL by appending `/api/v2/sub/user/created` to the base URL from the configuration.
        #' 2. Prepares the request body with required parameters:
        #'    - `password`: (7–24 characters; must include letters and numbers)
        #'    - `subName`: (7–32 characters; must include at least one letter and one number; no spaces)
        #'    - `access`: Permission type (allowed values: "Spot", "Futures", "Margin")
        #'    - `remarks`: (Optional; if provided, must be 1–24 characters)
        #' 3. Converts the request body to JSON.
        #' 4. Asynchronously generates authentication headers.
        #' 5. Sends the POST request with a 3-second timeout.
        #' 6. Processes the JSON response; if the HTTP status is not 200 or the API code is not "200000", an error is raised.
        #' 7. Converts the returned `data` into a `data.table` and returns it.
        #'
        #' **API Documentation:**  
        #' [Add SubAccount](https://www.kucoin.com/docs-new/rest/account-info/sub-account/add-subaccount)
        #'
        #' @param password A string representing the sub-account password.
        #' @param subName A string representing the sub-account name.
        #' @param access A string representing the permission type ("Spot", "Futures", or "Margin").
        #' @param remarks (Optional) A string for additional remarks.
        #'
        #' @return A promise that resolves to a `data.table` with sub-account details (e.g., `uid`, `subName`, `remarks`, `access`).
        add_subaccount = function(password, subName, access, remarks = NULL) {
            return(impl$add_subaccount_impl(self$config, password, subName, access, remarks))
        },

        #' Get SubAccount List Summary (Paginated)
        #'
        #' @description
        #' Retrieves a complete summary of sub-accounts associated with your master account. This method sends GET requests to the 
        #' sub-account summary endpoint, automatically paginates through the results, and aggregates the data into a single `data.table`.
        #' If the response includes a "createdAt" field (in milliseconds), it is converted to a POSIXct datetime and stored in a new
        #' column "createdDatetime".
        #'
        #' **API Endpoint:**  
        #' `GET https://api.kucoin.com/api/v2/sub/user`
        #'
        #' **Detailed Workflow:**  
        #' 1. Initializes pagination with `currentPage = 1` and the specified `page_size`.
        #' 2. Uses an asynchronous helper function to fetch each page.
        #' 3. Aggregates the results from each page using `data.table::rbindlist()`.
        #' 4. Converts the "createdAt" column (if present) from milliseconds to POSIXct datetime.
        #'
        #' **API Documentation:**  
        #' [Get Sub-Account List - Summary Info](https://www.kucoin.com/docs-new/rest/account-info/sub-account/get-subaccount-list-summary-info)
        #'
        #' @param page_size An integer specifying the number of results per page (default is 100; valid range: 1–100).
        #' @param max_pages An integer specifying the maximum number of pages to fetch (default is Inf for all pages).
        #'
        #' @return A promise that resolves to a `data.table` containing aggregated sub-account summary information.
        get_subaccount_list_summary = function(page_size = 100, max_pages = Inf) {
            return(impl$get_subaccount_list_summary_impl(self$config, page_size, max_pages))
        },

        #' Get SubAccount Detail - Balance
        #'
        #' @description
        #' Retrieves detailed balance information for a specific sub-account, identified by its subUserId. This method sends 
        #' a GET request to the KuCoin endpoint for sub-account details and processes the response by handling separate arrays 
        #' for each account type (e.g., mainAccounts, tradeAccounts, marginAccounts, tradeHFAccounts). For each non-empty array,
        #' the method converts it into a `data.table`, adds an "accountType" column (indicating the source, such as "mainAccounts"),
        #' and aggregates all the results into a single `data.table`. It also appends the sub-account's `subUserId` and `subName`
        #' to every row.
        #'
        #' **API Endpoint:**  
        #' `GET https://api.kucoin.com/api/v1/sub-accounts/{subUserId}?includeBaseAmount={includeBaseAmount}`
        #'
        #' **Detailed Workflow:**  
        #' 1. Constructs the endpoint URL by inserting the provided `subUserId` and appending the query parameter 
        #'    `includeBaseAmount` (default is `FALSE`).
        #' 2. Generates authentication headers and sends a GET request with a 3-second timeout.
        #' 3. Processes the JSON response by checking for arrays corresponding to different account types.
        #' 4. Converts each non-empty array into a `data.table`, adds an "accountType" column, and aggregates them.
        #' 5. Appends the sub-account's `subUserId` and `subName` from the response to every row.
        #'
        #' **API Documentation:**  
        #' [Get SubAccount Detail - Balance](https://www.kucoin.com/docs-new/rest/account-info/sub-account/get-subaccount-detail-balance)
        #'
        #' @param subUserId A string representing the sub-account user ID.
        #' @param includeBaseAmount A boolean indicating whether to include currencies with zero balance (default is FALSE).
        #'
        #' @return A promise that resolves to a `data.table` containing detailed balance information for the sub-account. 
        #'         Each row includes currency information, an "accountType" column, and the sub-account's `subUserId` and `subName`.
        get_subaccount_detail_balance = function(subUserId, includeBaseAmount = FALSE) {
            return(impl$get_subaccount_detail_balance_impl(self$config, subUserId, includeBaseAmount))
        }
    )
)
