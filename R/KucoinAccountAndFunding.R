# File: ./R/KucoinAccountAndFunding.R

# box::use(
#     impl = ./impl_account_and_funding,
#     ./utils[ get_api_keys, get_base_url ]
# )

#' KucoinAccountAndFunding Class for KuCoin Account & Funding Endpoints
#'
#' The `KucoinAccountAndFunding` class provides a comprehensive, asynchronous interface for interacting with the 
#' Account & Funding endpoints of the KuCoin API. It leverages the `coro` package to perform non-blocking HTTP requests
#' and returns promises that often resolve to `data.table` objects. This class covers a wide range of functionalities, including:
#'
#' - Retrieving a complete account summary (VIP level, sub-account counts, and various limits).
#' - Fetching detailed API key information (key details, permissions, IP whitelist, creation time, etc.).
#' - Determining the type of your spot account (high-frequency vs. low-frequency).
#' - Listing all spot accounts, with optional filters for currency and account type.
#' - Obtaining detailed information for a specific spot account.
#' - Retrieving cross margin account information with asset/liability summaries.
#' - Fetching isolated margin account data for specific trading pairs.
#' - Obtaining detailed ledger records (transaction histories) for spot and margin accounts.
#'
#' **Usage:**  
#' The class is initialized with API credentials, which can be automatically loaded using `get_api_keys()`. The base URL 
#' is determined by `get_base_url()`. For detailed information on each endpoint and the expected response schema, please 
#' refer to the official [KuCoin API Documentation](https://www.kucoin.com/docs-new).
#'
#' @section Methods:
#'
#' - **initialize(keys, base_url):** Initializes the object with API credentials and the base URL.
#' - **get_account_summary_info():** Retrieves a comprehensive summary of the user's account.
#' - **get_apikey_info():** Retrieves detailed information about the API key.
#' - **get_spot_account_type():** Determines whether the spot account is high-frequency or low-frequency.
#' - **get_spot_account_dt(query):** Retrieves a list of all spot accounts with optional filters.
#' - **get_spot_account_detail(accountId):** Retrieves detailed information for a specific spot account.
#' - **get_cross_margin_account(query):** Retrieves cross margin account information based on specified filters.
#' - **get_isolated_margin_account(query):** Retrieves isolated margin account data for specific trading pairs.
#' - **get_spot_ledger(query):** Retrieves detailed ledger records for spot and margin accounts, including pagination.
#'
#' @md
#' @export
KucoinAccountAndFunding <- R6::R6Class(
    "KucoinAccountAndFunding",
    public = list(
        #' @field keys A list of API configuration parameters from `get_api_keys()`, including `api_key`, `api_secret`, 
        #' `api_passphrase`, and `key_version`.
        keys = NULL,
        #' @field base_url A character string representing the base URL for the KuCoin API (obtained via `get_base_url()`).
        base_url = NULL,

        #' Initialize a new KucoinAccountAndFunding object.
        #'
        #' @description
        #' Initializes the KucoinAccountAndFunding object with API credentials and the base URL. If no credentials are provided, 
        #' they are automatically loaded using `get_api_keys()`. Similarly, the base URL is determined using `get_base_url()`.
        #'
        #' @param keys A list of API configuration parameters. Defaults to `get_api_keys()`.
        #' @param base_url (Optional) A character string representing the base URL for the KuCoin API. Defaults to `get_base_url()`.
        #'
        #' @return A new instance of the `KucoinAccountAndFunding` class.
        initialize = function(keys = get_api_keys(), base_url = get_base_url()) {
            self$keys <- keys
            self$base_url <- base_url
        },

        #' Retrieve Account Summary Information
        #'
        #' @description
        #' This method retrieves a comprehensive summary of the user's account from KuCoin. It includes details such as the user's VIP level,
        #' the total number of sub-accounts, and a breakdown of sub-accounts by type (spot, margin, futures, options), along with various limits.
        #'
        #' **API Endpoint:**  
        #' `GET https://api.kucoin.com/api/v2/user-info`
        #'
        #' Internally, this method calls the asynchronous implementation function
        #' \code{get_account_summary_info_impl} to handle the API request and response processing.
        #'
        #' @return A promise that resolves to a \code{data.table} containing the account summary data. The table comprises the following columns:
        #'   \describe{
        #'     \item{\code{level}}{(integer) The user's VIP level.}
        #'     \item{\code{subQuantity}}{(integer) Total number of sub-accounts.}
        #'     \item{\code{spotSubQuantity}}{(integer) Number of sub-accounts with spot trading permissions.}
        #'     \item{\code{marginSubQuantity}}{(integer) Number of sub-accounts with margin trading permissions.}
        #'     \item{\code{futuresSubQuantity}}{(integer) Number of sub-accounts with futures trading permissions.}
        #'     \item{\code{optionSubQuantity}}{(integer) Number of sub-accounts with option trading permissions.}
        #'     \item{\code{maxSubQuantity}}{(integer) Maximum allowed sub-accounts (calculated as the sum of \code{maxDefaultSubQuantity} and \code{maxSpotSubQuantity}).}
        #'     \item{\code{maxDefaultSubQuantity}}{(integer) Maximum default open sub-accounts based on VIP level.}
        #'     \item{\code{maxSpotSubQuantity}}{(integer) Maximum additional sub-accounts with spot trading permissions.}
        #'     \item{\code{maxMarginSubQuantity}}{(integer) Maximum additional sub-accounts with margin trading permissions.}
        #'     \item{\code{maxFuturesSubQuantity}}{(integer) Maximum additional sub-accounts with futures trading permissions.}
        #'     \item{\code{maxOptionSubQuantity}}{(integer) Maximum additional sub-accounts with option trading permissions.}
        #'   }
        #'
        #' @details
        #' This method utilises the internal asynchronous function \code{get_account_summary_info_impl} to execute the following steps:
        #'   \enumerate{
        #'     \item \strong{URL Construction:} The full API URL is constructed by appending the endpoint to the base URL.
        #'     \item \strong{Header Preparation:} Authentication headers are built based on the HTTP method, endpoint, and request body.
        #'     \item \strong{API Request:} A \code{GET} request is sent to the KuCoin API to retrieve account summary information.
        #'     \item \strong{Response Processing:} The API response is processed, and the \code{"data"} field is converted into a \code{data.table}.
        #'   }
        #' 
        #' For additional details on the endpoint, including rate limits and response schema, please refer to the [KuCoin API Documentation](https://www.kucoin.com/docs-new/rest/account-info/account-funding/get-account-summary-info).
        get_account_summary_info = function() {
            return(impl$get_account_summary_info_impl(self$keys, self$base_url))
        },

        #' Retrieve API Key Information
        #'
        #' @description
        #' This method retrieves detailed API key information from the KuCoin API. It fetches metadata about the API key used for authentication, including the account UID, sub-account name (if applicable), remarks, API key string, API version, permissions, IP whitelist, whether the key belongs to the master account, and the creation timestamp.
        #'
        #' **API Endpoint:**  
        #' `GET https://api.kucoin.com/api/v1/user/api-key`
        #'
        #' @return A promise that resolves to a \code{data.table} containing the API key information. The resulting data.table includes the following columns:
        #'   \describe{
        #'     \item{\code{uid}}{(integer) The account UID.}
        #'     \item{\code{subName}}{(character, optional) The sub-account name, if applicable. This field is not provided for master accounts.}
        #'     \item{\code{remark}}{(character) Remarks associated with the API key.}
        #'     \item{\code{apiKey}}{(character) The API key string.}
        #'     \item{\code{apiVersion}}{(integer) The API version.}
        #'     \item{\code{permission}}{(character) A comma-separated list of permissions. Possible values include: \emph{General, Spot, Margin, Futures, InnerTransfer, Transfer, Earn}.}
        #'     \item{\code{ipWhitelist}}{(character, optional) The IP whitelist, if applicable.}
        #'     \item{\code{isMaster}}{(logical) Indicates whether the API key belongs to the master account.}
        #'     \item{\code{createdAt}}{(integer) The API key creation time in milliseconds.}
        #'   }
        #'
        #' @details
        #' This method utilises the internal asynchronous function \code{get_apikey_info_impl} to perform the following operations:
        #'   \enumerate{
        #'     \item \strong{URL Construction:} The complete API URL is formed by combining the base URL with the endpoint `/api/v1/user/api-key`.
        #'     \item \strong{Header Preparation:} Authentication headers are generated based on the HTTP method, endpoint, and request body.
        #'     \item \strong{API Request:} An asynchronous GET request is sent to the KuCoin API.
        #'     \item \strong{Response Processing:} The JSON response is processed, and the \code{"data"} field is converted into a \code{data.table}.
        #'   }
        #'
        #' For additional details on the endpoint, including rate limits and response schema, please refer to the [KuCoin API Documentation](https://www.kucoin.com/docs-new/rest/account-info/account-funding/get-apikey-info).
        get_apikey_info = function() {
            return(impl$get_apikey_info_impl(self$keys, self$base_url))
        },

        #' Retrieve Spot Account Type.
        #'
        #' @description
        #' Determines whether the spot account is high-frequency or low-frequency. This distinction affects the endpoints used 
        #' for asset transfers and balance queries.
        #'
        #' **API Endpoint:**  
        #' `GET https://api.kucoin.com/api/v1/hf/accounts/opened`
        #'
        #' **Return Value:**  
        #' - `TRUE`: Indicates a high-frequency spot account.
        #' - `FALSE`: Indicates a low-frequency spot account.
        #'
        #' For additional details, refer to the [Spot Account Type Documentation](https://www.kucoin.com/docs-new/rest/account-info/account-funding/get-account-type-spot).
        #'
        #' @return A promise that resolves to a boolean.
        get_spot_account_type = function() {
            return(impl$get_spot_account_type_impl(self$keys, self$base_url))
        },

        #' Retrieve Spot Account List.
        #'
        #' @description
        #' Retrieves a list of all spot accounts associated with the KuCoin account. Users can filter results by currency 
        #' (e.g., "USDT") and account type (e.g., "main" or "trade"). The returned data is aggregated into a `data.table`, 
        #' where each row represents a distinct spot account with key financial metrics.
        #'
        #' **API Endpoint:**  
        #' `GET https://api.kucoin.com/api/v1/accounts`
        #'
        #' @details
        #' This method leverages the internal asynchronous function \code{get_spot_account_dt_impl} to perform several operations:
        #' \enumerate{
        #'   \item \strong{URL Construction:} Constructs the full API URL by appending `/api/v1/accounts` along with any query 
        #'         parameters (e.g., filtering by currency or account type) to the base URL.
        #'   \item \strong{Header Preparation:} Generates the required authentication headers using the HTTP method, full endpoint,
        #'         and an empty request body.
        #'   \item \strong{API Request:} Sends an asynchronous GET request to the constructed URL with a specified timeout to manage network delays.
        #'   \item \strong{Response Processing:} Processes the API response by extracting the `"data"` field from the JSON response and converting it into a `data.table`.
        #'   \item \strong{Error Handling:} Catches and handles errors encountered during any of the above steps, providing a descriptive error message.
        #' }
        #'
        #' For further details, including rate limits, authentication requirements, and response schema, please refer to the 
        #' [Spot Account List Documentation](https://www.kucoin.com/docs-new/rest/account-info/account-funding/get-account-list-spot).
        #'
        #' @param query A named list of query parameters for filtering the account list. For example, \code{list(currency = "USDT", type = "main")}.
        #'
        #' @return A promise that resolves to a \code{data.table} containing the spot account list. The table includes the following columns:
        #'  \describe{
        #'    \item{\code{id}}{(character) The unique account ID.}
        #'    \item{\code{currency}}{(character) The currency code associated with the account.}
        #'    \item{\code{type}}{(character) The account type (e.g., "main", "trade", or "balance").}
        #'    \item{\code{balance}}{(character) The total funds held in the account.}
        #'    \item{\code{available}}{(character) The funds available for withdrawal or trading.}
        #'    \item{\code{holds}}{(character) The funds on hold (not available for immediate use).}
        #' }
        #'
        get_spot_account_dt = function(query = list()) {
            return(impl$get_spot_account_dt_impl(self$keys, self$base_url, query))
        },

        #' Retrieve Spot Account Detail.
        #'
        #' @description
        #' Retrieves detailed information for a specific spot account identified by its account ID. The response provides comprehensive financial metrics including the account's currency, total balance, available funds, and funds on hold.
        #'
        #' **API Endpoint:**  
        #' `GET https://api.kucoin.com/api/v1/accounts/{accountId}`
        #'
        #' @details
        #' This method leverages the internal asynchronous function \code{get_spot_account_detail_impl} to perform the following steps:
        #' \enumerate{
        #'   \item \strong{URL Construction:} Constructs the full API URL by embedding the provided \code{accountId} into the endpoint `/api/v1/accounts/` and appending it to the base URL.
        #'   \item \strong{Header Preparation:} Generates the required authentication headers based on the HTTP method, endpoint, and an empty request body to ensure secure access.
        #'   \item \strong{API Request:} Dispatches an asynchronous GET request to the constructed URL with a defined timeout to manage network delays.
        #'   \item \strong{Response Processing:} Processes the API response using a helper function (\code{process_kucoin_response}). This function extracts the \code{"data"} field from the JSON payload and converts it into a \code{data.table}.
        #'   \item \strong{Error Handling:} Captures any errors encountered during the process and returns a descriptive error message.
        #' }
        #'
        #' @return A promise that resolves to a \code{data.table} containing the following columns:
        #'   \describe{
        #'     \item{\code{currency}}{(character) The currency of the account.}
        #'     \item{\code{balance}}{(character) The total funds in the account.}
        #'     \item{\code{available}}{(character) The funds available for withdrawal or trading.}
        #'     \item{\code{holds}}{(character) The funds on hold and not available for immediate use.}
        #'   }
        #'
        #' For further details, including rate limits, authentication requirements, and the full response schema, please refer to the 
        #' [Spot Account Detail Documentation](https://www.kucoin.com/docs-new/rest/account-info/account-funding/get-account-detail-spot).
        #'
        #' @param accountId A string representing the unique account ID for which detailed spot account information is requested. Try using `KucoinAccountAndFunding$get_spot_account_dt()` to get the account ID.
        get_spot_account_detail = function(accountId) {
            return(impl$get_spot_account_detail_impl(self$keys, self$base_url, accountId))
        },

        #' Retrieve Cross Margin Account Information.
        #'
        #' @description
        #' Retrieves detailed information about the cross margin account, which allows for the use of collateral across multiple trading pairs. The response includes overall metrics (total assets, total liabilities, and debt ratio) and a list of individual margin accounts with detailed breakdowns.
        #'
        #' **API Endpoint:**  
        #' `GET https://api.kucoin.com/api/v3/margin/accounts`
        #'
        #' @details
        #' This method leverages the internal asynchronous function \code{get_cross_margin_account_impl} to perform the following steps:
        #' \enumerate{
        #'   \item \strong{URL Construction:} Constructs the full API URL by appending `/api/v3/margin/accounts` along with any query parameters to the base URL.
        #'   \item \strong{Header Preparation:} Generates the necessary authentication headers using the provided API keys.
        #'   \item \strong{API Request:} Sends an asynchronous GET request to the specified endpoint.
        #'   \item \strong{Response Processing:} Processes the API response by extracting the \code{"data"} field and converting it into two separate data tables:
        #'         \itemize{
        #'           \item A summary data table containing overall cross margin account information.
        #'           \item A detailed data table containing the list of margin account objects.
        #'         }
        #' }
        #'
        #' @param query A named list of query parameters to filter the account information. Supported parameters include:
        #'   \describe{
        #'     \item{\code{quoteCurrency}}{(string, optional): Filter by quote currency (default is `"USDT"`).}
        #'     \item{\code{queryType}}{(string, optional): Filter by account type (`"MARGIN"`, `"MARGIN_V2"`, or `"ALL"`; default is `"MARGIN"`).}
        #'   }
        #'
        #' @return A promise that resolves to a named list with two elements:
        #'   \describe{
        #'     \item{\code{summary}}{A data.table containing the overall cross margin account summary with the following columns:
        #'         \describe{
        #'           \item{\code{totalAssetOfQuoteCurrency}}{(string) Total assets in the quote currency.}
        #'           \item{\code{totalLiabilityOfQuoteCurrency}}{(string) Total liabilities in the quote currency.}
        #'           \item{\code{debtRatio}}{(string) The debt ratio.}
        #'           \item{\code{status}}{(string) The position status (e.g., "EFFECTIVE", "BANKRUPTCY", "LIQUIDATION", "REPAY", or "BORROW").}
        #'         }
        #'     }
        #'     \item{\code{accounts}}{A data.table containing detailed margin account information. Each row represents a margin account and includes the following columns:
        #'         \describe{
        #'           \item{\code{currency}}{(string) Currency code.}
        #'           \item{\code{total}}{(string) Total funds in the account.}
        #'           \item{\code{available}}{(string) Funds available for withdrawal or trading.}
        #'           \item{\code{hold}}{(string) Funds on hold.}
        #'           \item{\code{liability}}{(string) Current liabilities.}
        #'           \item{\code{maxBorrowSize}}{(string) Maximum borrowable amount.}
        #'           \item{\code{borrowEnabled}}{(boolean) Indicates whether borrowing is enabled.}
        #'           \item{\code{transferInEnabled}}{(boolean) Indicates whether transfers into the account are enabled.}
        #'         }
        #'     }
        #'   }
        #'
        #' For further details, please refer to the [Cross Margin API Documentation](https://www.kucoin.com/docs-new/rest/account-info/account-funding/get-account-cross-margin).
        #'
        get_cross_margin_account = function(query = list()) {
            return(impl$get_cross_margin_account_impl(self$keys, self$base_url, query))
        },

        #' Retrieve Isolated Margin Account Information.
        #'
        #' @description
        #' Retrieves isolated margin account details for specific trading pairs. Isolated margin allows you to limit risk exposure 
        #' to an individual trading pair by segregating collateral. The response includes detailed asset and liability information 
        #' for each trading pair.
        #'
        #' **API Endpoint:**  
        #' `GET https://api.kucoin.com/api/v3/isolated/accounts`
        #'
        #' **Workflow:**
        #' - Constructs the URL by appending `/api/v3/isolated/accounts` and any query parameters to the base URL.
        #' - Generates authentication headers.
        #' - Sends an asynchronous GET request.
        #' - Processes the response and converts the `"data"` field into a flat structure consisting of two data.tables:
        #'   \describe{
        #'     \item{\code{summary}}{Contains overall isolated margin account information, including:
        #'       \describe{
        #'         \item{\code{totalAssetOfQuoteCurrency}}{(string) Total assets in the quote currency.}
        #'         \item{\code{totalLiabilityOfQuoteCurrency}}{(string) Total liabilities in the quote currency.}
        #'         \item{\code{timestamp}}{(integer) The raw timestamp in milliseconds.}
        #'         \item{\code{datetime}}{(POSIXct) The converted date-time (via \code{time_convert_from_kucoin("ms")}).}
        #'       }
        #'     }
        #'     \item{\code{assets}}{Contains detailed information for each isolated margin account asset with the following flattened columns:
        #'       \describe{
        #'         \item{\code{symbol}}{(string) Trading pair symbol (e.g., "BTC-USDT").}
        #'         \item{\code{status}}{(string) Position status.}
        #'         \item{\code{debtRatio}}{(string) Debt ratio.}
        #'         \item{\code{base_currency}}{(string) Currency code from the base asset.}
        #'         \item{\code{base_borrowEnabled}}{(boolean) Indicates whether borrowing is enabled for the base asset.}
        #'         \item{\code{base_transferInEnabled}}{(boolean) Indicates whether transfers into the base asset account are enabled.}
        #'         \item{\code{base_liability}}{(string) Liability for the base asset.}
        #'         \item{\code{base_total}}{(string) Total amount of the base asset.}
        #'         \item{\code{base_available}}{(string) Available amount of the base asset.}
        #'         \item{\code{base_hold}}{(string) Base asset amount on hold.}
        #'         \item{\code{base_maxBorrowSize}}{(string) Maximum borrowable amount for the base asset.}
        #'         \item{\code{quote_currency}}{(string) Currency code from the quote asset.}
        #'         \item{\code{quote_borrowEnabled}}{(boolean) Indicates whether borrowing is enabled for the quote asset.}
        #'         \item{\code{quote_transferInEnabled}}{(boolean) Indicates whether transfers into the quote asset account are enabled.}
        #'         \item{\code{quote_liability}}{(string) Liability for the quote asset.}
        #'         \item{\code{quote_total}}{(string) Total amount of the quote asset.}
        #'         \item{\code{quote_available}}{(string) Available amount of the quote asset.}
        #'         \item{\code{quote_hold}}{(string) Quote asset amount on hold.}
        #'         \item{\code{quote_maxBorrowSize}}{(string) Maximum borrowable amount for the quote asset.}
        #'       }
        #'     }
        #'   }
        #'
        #' **Query Parameters:**  
        #' - `symbol`: (Optional) Specify a trading pair (e.g., `"BTC-USDT"`); if omitted, data for all pairs is returned.
        #' - `quoteCurrency`: (Optional) Filter by quote currency (default is `"USDT"`).
        #' - `queryType`: (Optional) Allowed values: `"ISOLATED"`, `"ISOLATED_V2"`, `"ALL"`; default is `"ISOLATED"`.
        #'
        #' For more details, refer to the [Isolated Margin API Documentation](https://www.kucoin.com/docs-new/rest/account-info/account-funding/get-account-isolated-margin).
        #'
        #' @param query A named list of query parameters.
        #'
        #' @return A promise that resolves to a named list with two elements:
        #'   \describe{
        #'     \item{\code{summary}}{
        #'       A data.table with the following columns:
        #'       \describe{
        #'         \item{\code{totalAssetOfQuoteCurrency}}{(string) Total assets in the quote currency.}
        #'         \item{\code{totalLiabilityOfQuoteCurrency}}{(string) Total liabilities in the quote currency.}
        #'         \item{\code{timestamp}}{(integer) The raw timestamp in milliseconds.}
        #'         \item{\code{datetime}}{(POSIXct) The converted date-time (via \code{time_convert_from_kucoin("ms")}).}
        #'       }
        #'     }
        #'     \item{\code{assets}}{
        #'       A data.table where each row represents an isolated margin account asset with the following columns:
        #'       \describe{
        #'         \item{\code{symbol}}{(string) Trading pair symbol (e.g., "BTC-USDT").}
        #'         \item{\code{status}}{(string) Position status.}
        #'         \item{\code{debtRatio}}{(string) Debt ratio.}
        #'         \item{\code{base_currency}}{(string) Currency code from the base asset.}
        #'         \item{\code{base_borrowEnabled}}{(boolean) Indicates whether borrowing is enabled for the base asset.}
        #'         \item{\code{base_transferInEnabled}}{(boolean) Indicates whether transfers into the base asset account are enabled.}
        #'         \item{\code{base_liability}}{(string) Liability for the base asset.}
        #'         \item{\code{base_total}}{(string) Total amount of the base asset.}
        #'         \item{\code{base_available}}{(string) Available amount of the base asset.}
        #'         \item{\code{base_hold}}{(string) Base asset amount on hold.}
        #'         \item{\code{base_maxBorrowSize}}{(string) Maximum borrowable amount for the base asset.}
        #'         \item{\code{quote_currency}}{(string) Currency code from the quote asset.}
        #'         \item{\code{quote_borrowEnabled}}{(boolean) Indicates whether borrowing is enabled for the quote asset.}
        #'         \item{\code{quote_transferInEnabled}}{(boolean) Indicates whether transfers into the quote asset account are enabled.}
        #'         \item{\code{quote_liability}}{(string) Liability for the quote asset.}
        #'         \item{\code{quote_total}}{(string) Total amount of the quote asset.}
        #'         \item{\code{quote_available}}{(string) Available amount of the quote asset.}
        #'         \item{\code{quote_hold}}{(string) Quote asset amount on hold.}
        #'         \item{\code{quote_maxBorrowSize}}{(string) Maximum borrowable amount for the quote asset.}
        #'       }
        #'     }
        #'   }
        #'
        #' @export
        get_isolated_margin_account = function(query = list()) {
        #'   Retrieves isolated margin account information by invoking the internal implementation.
            return(impl$get_isolated_margin_account_impl(self$keys, self$base_url, query))
        },

        #' Retrieve Spot Ledger Records.
        #'
        #' @description
        #' Retrieves detailed ledger records for spot and margin accounts, including transaction histories for deposits, withdrawals, transfers, and trades.
        #' The response is paginated and includes metadata such as current page, page size, total number of records, and total pages.
        #' The results are aggregated into a single flat data.table.
        #'
        #' **API Endpoint:**  
        #' `GET https://api.kucoin.com/api/v1/accounts/ledgers`
        #'
        #' **Workflow:**
        #' - Constructs the URL by appending `/api/v1/accounts/ledgers` and any user-supplied query parameters to the base URL.
        #' - Generates authentication headers.
        #' - Sends an asynchronous GET request.
        #' - Automatically paginates through all pages using the \code{auto_paginate} helper. Pagination parameters are supplied as separate arguments.
        #' - Aggregates the ledger records into a single data.table.
        #'
        #' **Query Parameters:**  
        #' - `currency`: (Optional) Filter by one or more currencies.
        #' - `direction`: (Optional) `"in"` for incoming or `"out"` for outgoing transactions.
        #' - `bizType`: (Optional) The business type (e.g., `"DEPOSIT"`, `"WITHDRAW"`, `"TRANSFER"`, etc.).
        #' - `startAt` / `endAt`: (Optional) Millisecond timestamps defining a time range.
        #'
        #' @param query A named list of additional query parameters (excluding pagination parameters).
        #' @param page_size (integer, optional) Number of results per page (default is 50; range: 10–500).
        #' @param max_pages (integer, optional) Maximum number of pages to fetch (default is \code{Inf} to fetch all pages).
        #'
        #' @return A promise that resolves to a data.table containing the aggregated ledger records.
        #' Each row represents a ledger record with columns including:
        #'   - \code{id}: Ledger record ID.
        #'   - \code{currency}: The currency.
        #'   - \code{amount}: Transaction amount.
        #'   - \code{fee}: Transaction fee.
        #'   - \code{balance}: Account balance after the transaction.
        #'   - \code{accountType}: The account type (e.g., "TRADE").
        #'   - \code{bizType}: Business type (e.g., "TRANSFER").
        #'   - \code{direction}: Transaction direction ("in" or "out").
        #'   - \code{createdAt}: Transaction timestamp in milliseconds.
        #'   - \item{\code{createdAtDatetime}}{(POSIXct) The converted date-time value (obtained via \code{time_convert_from_kucoin("ms")}).}
        #'   - \code{context}: Additional context for the transaction.
        #'   - \code{currentPage}: Current page number from the response.
        #'   - \code{pageSize}: Page size from the response.
        #'   - \code{totalNum}: Total number of records.
        #'   - \code{totalPage}: Total number of pages.
        #'
        #' For further details, please refer to the [Spot Ledger API Documentation](https://www.kucoin.com/docs-new/rest/account-info/account-funding/get-account-ledgers-spot-margin).
        #'
        #' @export
        get_spot_ledger = function(query = list(), page_size = 50, max_pages = Inf) {
            return(impl$get_spot_ledger_impl(
                keys = self$keys,
                base_url = self$base_url,
                query = query,
                page_size = page_size,
                max_pages = max_pages
            ))
        }
    )
)
