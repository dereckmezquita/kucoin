# File: account_methods.R

box::use(
    httr[GET, status_code, content, add_headers, timeout],
    jsonlite[fromJSON],
    rlang[abort],
    coro,
    promises,
    ./helpers_api[build_headers],
    ./utils[get_base_url]
)

#' Get Account Summary Information Implementation
#'
#' This asynchronous function implements the logic for retrieving account summary information
#' from the KuCoin API. It constructs the full URL, builds the authentication headers, sends the
#' GET request, and returns the parsed response data.
#'
#' @param config A list containing API configuration parameters.
#'
#' @return A promise that resolves to a list containing the account summary data.
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
#' For full endpoint details, refer to the [KuCoin API Documentation](https://www.kucoin.com/docs-new/rest/account-info/account-funding/get-account-summary-info).
#'
#' @examples
#' \dontrun{
#'   config <- list(
#'       api_key = "your_api_key",
#'       api_secret = "your_api_secret",
#'       api_passphrase = "your_api_passphrase",
#'       base_url = "https://api.kucoin.com",
#'       key_version = "2"
#'   )
#'   # Run the asynchronous request using coro::run
#'   coro::run(function() {
#'       data <- await(get_account_summary_info_impl(config))
#'       print(data)
#'   })
#' }
#'
#' @export
get_account_summary_info_impl <- coro::async(function(config) {
    tryCatch({
        # Retrieve the base URL from the configuration.
        base_url <- get_base_url(config)
        # Define the endpoint for account summary information.
        endpoint <- "/api/v2/user-info"
        method <- "GET"
        body <- ""
        # Build the authentication headers asynchronously.
        headers <- await(build_headers(method, endpoint, body, config))
        # Construct the full URL.
        url <- paste0(base_url, endpoint)
        
        # Send the GET request to the KuCoin API using the headers directly.
        response <- GET(url, headers, timeout(3))
        
        # Check that the HTTP status code is 200 (OK).
        if (status_code(response) != 200) {
            abort(paste("Request failed with status code", status_code(response)))
        }
        
        # Retrieve and parse the response content.
        response_text <- content(response, as = "text", encoding = "UTF-8")
        parsed_response <- fromJSON(response_text)
        
        # Validate the structure of the API response.
        if (!all(c("code", "data") %in% names(parsed_response))) {
            abort("Invalid API response structure.")
        }
        
        # Check for a successful API response code.
        if (parsed_response$code != "200000") {
            abort(paste("KuCoin API returned an error:", parsed_response$code))
        }
        
        # Return the account summary data.
        return(parsed_response$data)
    }, error = function(e) {
        abort(paste("Error in get_account_summary_info_impl:", conditionMessage(e)))
    })
})