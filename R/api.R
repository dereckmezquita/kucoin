box::use(
    ./utils[get_base_url],
    ./errors[kucoin_error, http_error]
)

# File: api.R
#' @export
get_server_time <- function(base_url = "https://api.kucoin.com") {
    promises::promise(function(resolve, reject) {
        tryCatch({
            res <- httr::GET(paste0(base_url, "/api/v1/timestamp"))
            if (httr::status_code(res) != 200) {
                err_msg <- tryCatch({
                    httr::content(res, as = "text", encoding = "UTF-8")
                }, error = function(e) "NO CONTENT")
                reject(http_error(
                    status = httr::status_code(res),
                    content = err_msg
                ))
            }
            result <- httr::content(res, as = "parsed", simplifyVector = TRUE)
            resolve(result$data)
        }, error = function(e) {
            if (inherits(e, "kucoin_error")) {
                reject(e)
            } else {
                reject(kucoin_error(
                    message = "Failed to get server time",
                    class = "kucoin_server_time_error",
                    parent = e
                ))
            }
        })
    })
}

#' @export
build_headers <- coro::async(function(method, endpoint, body, config) {
    tryCatch({
        timestamp <- await(get_server_time(get_base_url(config)))
        prehash <- paste0(timestamp, toupper(method), endpoint, body)
        sig_raw <- digest::hmac(
            key = config$api_secret,
            object = prehash,
            algo = "sha256",
            serialize = FALSE,
            raw = TRUE
        )
        signature <- base64enc::base64encode(sig_raw)
        passphrase_raw <- digest::hmac(
            key = config$api_secret,
            object = config$api_passphrase,
            algo = "sha256",
            serialize = FALSE,
            raw = TRUE
        )
        encrypted_passphrase <- base64enc::base64encode(passphrase_raw)
        httr::add_headers(
            `KC-API-KEY` = config$api_key,
            `KC-API-SIGN` = signature,
            `KC-API-TIMESTAMP` = timestamp,
            `KC-API-PASSPHRASE` = encrypted_passphrase,
            `KC-API-KEY-VERSION` = config$key_version,
            `Content-Type` = "application/json"
        )
    }, error = function(e) {
        if (inherits(e, "kucoin_error")) {
            rlang::abort(e$message, parent = e)
        } else {
            kucoin_error(
                message = "Failed to build request headers",
                class = "kucoin_headers_error",
                parent = e
            )
        }
    })
})