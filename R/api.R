# box::use(./utils[get_base_url])

#' Get Server Time from KuCoin Futures API
#'
#' Retrieves the current API server time (Unix timestamp in milliseconds) from the KuCoin Futures API.
#' This function performs an asynchronous GET request and returns a promise that either resolves to the
#' server timestamp or rejects with an error. The server time is a critical component when making
#' authenticated requests to KuCoin's API. For these requests (e.g., placing orders or fetching account data),
#' the API requires you to include a timestamp header that is within 5 seconds of the actual server time.
#' This helps ensure that requests are timely and protects against replay attacks.
#'
#' The helper function \code{get_base_url()} is used to retrieve the base URL for the Futures domain.
#'
#' For further details, refer to the official KuCoin API documentation:
#' \url{https://www.kucoin.com/docs-new/rest/futures-trading/market-data/get-server-time}
#'
#' @param base_url The base URL for the KuCoin Futures API. Defaults to the result of \code{get_base_url()}.
#' @return A promise that resolves to a numeric Unix timestamp in milliseconds.
#'
#' @examples
#' \dontrun{
#'     # Asynchronously retrieve the server time.
#'     get_server_time()$
#'         then(function(timestamp) {
#'             cat("KuCoin Server Time:", timestamp, "\n")
#'         })$
#'         catch(function(e) {
#'             message("Error retrieving server time: ", conditionMessage(e))
#'         })
#'
#'     # Run the event loop until all asynchronous tasks are processed.
#'     while (!later::loop_empty()) {
#'         later::run_now(timeoutSecs = Inf, all = TRUE)
#'     }
#' }
#'
#' @importFrom httr GET timeout content status_code
#' @importFrom jsonlite fromJSON
#' @importFrom rlang abort
#' @importFrom promises promise
#' @export
get_server_time <- function(base_url = get_base_url()) {
    promises::promise(function(resolve, reject) {
        tryCatch({
            url <- paste0(base_url, "/api/v1/timestamp")
            response <- httr::GET(url, httr::timeout(3))
            if (httr::status_code(response) != 200) {
                reject(rlang::abort(
                    "KuCoin API request failed",
                    error_details = list(
                        status_code = httr::status_code(response),
                        url = url
                    )
                ))
                return(NULL)
            }
            # Extract and parse the response.
            response_text <- httr::content(response, as = "text", encoding = "UTF-8")
            parsed_response <- jsonlite::fromJSON(response_text)
            # Check that the response contains the required fields.
            if (!all(c("code", "data") %in% names(parsed_response))) {
                reject(rlang::abort(
                    "Invalid API response structure",
                    error_details = list(response = parsed_response)
                ))
                return(NULL)
            }
            # Ensure that the API returned a successful code.
            if (parsed_response$code != "200000") {
                reject(rlang::abort(
                    "KuCoin API returned an error",
                    error_details = list(
                        code = parsed_response$code,
                        response = parsed_response
                    )
                ))
                return(NULL)
            }
            resolve(parsed_response$data)
        }, error = function(e) {
            reject(rlang::abort("Error retrieving server time", parent = e))
        })
    })
}

#' Build Request Headers for Kucoin API
#'
#' Asynchronously builds the HTTP request headers required for authenticated requests to the
#' Kucoin API. These headers include the API key, a signature, the current timestamp, an encrypted
#' passphrase, the API key version, and the content type.
#'
#' The function performs the following steps:
#'
#' \enumerate{
#'   \item **Retrieve the Server Time:**  
#'         Calls [get_server_time()] (using the base URL from [get_base_url()]) to obtain the current
#'         server timestamp (in milliseconds). This timestamp is required in every request.
#'
#'   \item **Construct the Prehash String:**  
#'         The prehash is constructed by concatenating the timestamp, the HTTP method (in uppercase),
#'         the API endpoint, and the request body. Note that the `body` parameter must be provided even if
#'         it is empty (e.g., for GET requests) to ensure that the signature reflects all parts of the request.
#'
#'   \item **Generate the Signature:**  
#'         Computes an HMAC-SHA256 signature of the prehash string using the API secret. The raw signature is
#'         then encoded in base64.
#'
#'   \item **Encrypt the Passphrase:**  
#'         Similarly, the API passphrase is HMAC-signed (using the API secret) and the result is encoded in base64.
#'
#'   \item **Build the Headers:**  
#'         Returns a list of HTTP headers (via [httr::add_headers()]) that includes all the required authentication
#'         fields.
#' }
#'
#' @param method A character string specifying the HTTP method (e.g., "GET", "POST").
#' @param endpoint A character string representing the API endpoint (e.g., "/api/v1/orders").
#' @param body A character string containing the request body in JSON format. If no payload is required,
#'   pass an empty string (`""`). This parameter is included in the signature calculation.
#' @param config A list containing configuration settings for the API. The list must include:
#'   \describe{
#'     \item{api_key}{Your Kucoin API key.}
#'     \item{api_secret}{Your Kucoin API secret used for signing requests.}
#'     \item{api_passphrase}{Your Kucoin API passphrase.}
#'     \item{key_version}{The API key version (e.g., "2").}
#'     \item{base_url}{(Optional) The base URL for the API; if not provided, [get_base_url()] is used.}
#'   }
#'
#' @return A list of HTTP headers (created by [httr::add_headers()]) that contains the authentication fields
#' required for making a request to the Kucoin API.
#'
#' @details
#' This function is used to generate the authentication headers needed when interacting with any of the Kucoin APIs.
#' The headers ensure that the API can verify the integrity and authenticity of each request.
#'
#' The `body` parameter is part of the signature calculation. Even if a request (such as GET) has no payload,
#' passing an empty string guarantees that the signature is computed over all expected components:
#' timestamp, HTTP method, endpoint, and body.
#'
#' @note This function is asynchronous. When calling it from synchronous code, use [coro::await()] to retrieve the result.
#'
#' @examples
#' \dontrun{
#'   config <- list(
#'     api_key = "your_api_key",
#'     api_secret = "your_api_secret",
#'     api_passphrase = "your_api_passphrase",
#'     key_version = "2",
#'     base_url = "https://api.kucoin.com"
#'   )
#'
#'   # Build headers for a POST request with a JSON body.
#'   headers <- coro::await(build_headers("POST", "/api/v1/orders", '{"size": 1}', config))
#'   print(headers)
#'
#'   # For a GET request with no payload, pass an empty string:
#'   headers <- coro::await(build_headers("GET", "/api/v1/orders", "", config))
#' }
#'
#' @importFrom httr add_headers
#' @importFrom digest hmac
#' @importFrom base64enc base64encode
#' @importFrom rlang abort
#' @export
build_headers <- coro::async(function(method, endpoint, body, config) {
    tryCatch({
        # Retrieve the current server time from the Kucoin API.
        timestamp <- await(get_server_time(get_base_url(config)))
        
        # Construct the prehash string: timestamp + UPPERCASE(method) + endpoint + body.
        prehash <- paste0(timestamp, toupper(method), endpoint, body)
        
        # Compute the HMAC-SHA256 signature using the API secret.
        sig_raw <- digest::hmac(
            key = config$api_secret,
            object = prehash,
            algo = "sha256",
            serialize = FALSE,
            raw = TRUE
        )
        # Base64-encode the signature.
        signature <- base64enc::base64encode(sig_raw)
        
        # Compute the encrypted passphrase by signing the API passphrase.
        passphrase_raw <- digest::hmac(
            key = config$api_secret,
            object = config$api_passphrase,
            algo = "sha256",
            serialize = FALSE,
            raw = TRUE
        )
        encrypted_passphrase <- base64enc::base64encode(passphrase_raw)
        
        # Return the HTTP headers with authentication information.
        httr::add_headers(
            `KC-API-KEY` = config$api_key,
            `KC-API-SIGN` = signature,
            `KC-API-TIMESTAMP` = timestamp,
            `KC-API-PASSPHRASE` = encrypted_passphrase,
            `KC-API-KEY-VERSION` = config$key_version,
            `Content-Type` = "application/json"
        )
    }, error = function(e) {
        rlang::abort(
            paste("Failed to build request headers:", conditionMessage(e)),
            parent = e
        )
    })
})
