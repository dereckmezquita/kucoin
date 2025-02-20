# File: ./R/KucoinSubAccount

# box::use(
#     impl = ./impl_account_sub_account,
#     ./utils[ get_api_keys, get_base_url ]
# )

#' KuCoin SubAccount Class
#' 
#' @export
KucoinSubAccount <- R6::R6Class(
    "KucoinSubAccount",
    public = list(
        #' @field keys A list containing the KuCoin API keys (apiKey, secret, and passphrase).
        keys = NULL,
        #' @field base_url A string representing the base URL for KuCoin API endpoints.
        base_url = NULL,

        #' Initialize KucoinSubAccount
        #' @param keys A list containing the KuCoin API keys (apiKey, secret, and passphrase).
        #' @param base_url A string representing the base URL for KuCoin API endpoints.
        #' @return A new KucoinSubAccount object.
        initialize = function(keys = get_api_keys(), base_url = get_base_url()) {
            self$keys <- keys
            self$base_url <- base_url
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
            return(impl$add_subaccount_impl(
                keys     = self$keys,
                base_url = self$base_url,
                password = password,
                subName  = subName,
                access   = access,
                remarks  = remarks
            ))
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
            return(impl$get_subaccount_list_summary_impl(self$keys, self$base_url, page_size, max_pages))
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
