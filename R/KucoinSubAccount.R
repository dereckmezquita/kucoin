# File: ./R/KucoinSubAccount.R

box::use(
    impl = ./accounts_sub_account
    ./utils[get_api_keys, get_subaccount]
)

#' KuCoin SubAccount Class
#'
#' This class provides an interface to interact with KuCoin SubAccount endpoints.
#' It uses asynchronous programming to send HTTP requests and handle responses.
#' API configuration parameters are loaded from the environment by default,
#' and sub‐account–specific parameters can also be loaded via the helper function.
#'
#' @section Methods:
#' - **initialize(config, sub_account)**: Creates a new instance with API and sub‐account configuration.
#' - **add_subaccount(password, subName, access, remarks)**: Creates a new sub‐account on KuCoin.
#'
#' @examples
#' \dontrun{
#'   library(coro)
#'   subAcc <- KuCoinSubAccount$new()
#'   coro::run(function() {
#'       result <- await(subAcc$add_subaccount(
#'           password = "1234567",
#'           subName  = "Name1234567",
#'           access   = "Spot",
#'           remarks  = "Test sub-account"
#'       ))
#'       print(result)
#'   })
#' }
#'
#' @export
KuCoinSubAccount <- R6::R6Class(
    "KuCoinSubAccount",
    public = list(
        config = NULL,
        sub_account = NULL,
        
        #' Initialize a new KuCoinSubAccount object.
        #'
        #' @param config A list containing API configuration parameters. Defaults to the output of `get_api_keys()`.
        #' @param sub_account A list containing sub‐account configuration parameters. Defaults to the output of `get_subaccount()`.
        #' @return A new instance of the `KuCoinSubAccount` class.
        initialize = function(config = get_api_keys(), sub_account = get_subaccount()) {
            self$config <- config
            self$sub_account <- sub_account
        },
        
        #' Add SubAccount
        #'
        #' @description
        #' Creates a new sub‐account on KuCoin by sending a POST request to the appropriate endpoint.
        #' On success, the function returns a data.table with sub‐account details.
        #'         uid      subName          remarks access
        #'     <int>       <char>           <char> <char>
        #' 1: 237231855 Name12345678 Test sub-account   Spot
        #'
        #' @param password A string representing the sub‐account password (7–24 characters, must contain letters and numbers).
        #' @param subName A string representing the sub‐account name (7–32 characters, must contain at least one letter and one number, with no spaces).
        #' @param access A string representing the permission type (allowed values: "Spot", "Futures", "Margin").
        #' @param remarks An optional string for remarks (1–24 characters).
        #'
        #' @return A promise that resolves to a data.table containing sub‐account details (e.g., uid, subName, remarks, access).
        #' @examples
        #' \dontrun{
        #'   coro::run(function() {
        #'       result <- await(subAcc$add_subaccount(
        #'           password = "1234567",
        #'           subName  = "Name1234567",
        #'           access   = "Spot",
        #'           remarks  = "Test sub-account"
        #'       ))
        #'       print(result)
        #'   })
        #' }
        add_subaccount = function(password, subName, access, remarks = NULL) {
            return(impl$add_subaccount_impl(self$config, password, subName, access, remarks))
        },

        #' Get SubAccount List Summary (Paginated)
        #'
        #' Retrieves sub-account summary information with pagination. Users can specify the page size and the maximum number of pages to fetch.
        #'
        #' @param page_size An integer specifying the number of results per page (default is 100).
        #' @param max_pages The maximum number of pages to fetch (default is Inf to fetch all pages).
        #'
        #' @return A promise that resolves to a data.table containing the aggregated sub-account summary information,
        #'         with the "createdAt" column converted to a datetime object if present.
        get_subaccount_list_summary = function(page_size = 100, max_pages = Inf) {
            return(impl$get_subaccount_list_summary_impl(self$config, page_size, max_pages))
        },

        #' Get SubAccount Detail - Balance
        #'
        #' 
        #' https://www.kucoin.com/docs-new/rest/account-info/sub-account/get-subaccount-detail-balance
        #' 
        #' Retrieves the balance details for a sub-account identified by its subUserId.
        #'
        #' @param subUserId A string representing the sub-account user ID.
        #' @param includeBaseAmount A boolean indicating whether to include currencies with zero balance (default is FALSE).
        #'
        #' @return A promise that resolves to a data.table containing the sub-account detail.
        get_subaccount_detail_balance = function(subUserId, includeBaseAmount = FALSE) {
            return(impl$get_subaccount_detail_balance_impl(self$config, subUserId, includeBaseAmount))
        }
    )
)
