# File: utils.R
#' @export
build_query <- function(params) {
    params <- params[!sapply(params, is.null)]
    if (length(params) == 0) return("")
    return(httr::modify_url(url = "", query = params))
}

#' @export
get_base_url <- function(config) {
    if (!is.null(config$base_url)) {
        return(config$base_url)
    }
    return("https://api.kucoin.com")
}

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
                reject(stop(sprintf("HTTP error %s: %s", httr::status_code(res), err_msg)))
            }
            result <- httr::content(res, as = "parsed", simplifyVector = TRUE)
            resolve(result$data)
        }, error = function(e) {
            reject(stop("Failed to get server time: ", e$message))
        })
    })
}

#' @export
build_headers <- coro::async(function(method, endpoint, body, config) {
    timestamp <- await(get_server_time(get_base_url(config)))
    prehash <- paste0(timestamp, toupper(method), endpoint, body)
    sig_raw <- digest::hmac(key = config$api_secret, object = prehash,
                           algo = "sha256", serialize = FALSE, raw = TRUE)
    signature <- base64enc::base64encode(sig_raw)
    passphrase_raw <- digest::hmac(key = config$api_secret,
                                  object = config$api_passphrase,
                                  algo = "sha256", serialize = FALSE, raw = TRUE)
    encrypted_passphrase <- base64enc::base64encode(passphrase_raw)
    httr::add_headers(
        `KC-API-KEY` = config$api_key,
        `KC-API-SIGN` = signature,
        `KC-API-TIMESTAMP` = timestamp,
        `KC-API-PASSPHRASE` = encrypted_passphrase,
        `KC-API-KEY-VERSION` = config$key_version,
        `Content-Type` = "application/json"
    )
})

# File: account.R
#' @export
getAccountSummaryInfo <- coro::async(function(config) {
    tryCatch({
        method <- "GET"
        endpoint <- "/api/v2/user-info"
        body <- ""
        url <- paste0(get_base_url(config), endpoint)
        headers <- await(build_headers(method, endpoint, body, config))
        res <- httr::GET(url, headers)
        if (httr::status_code(res) != 200) {
            err_msg <- tryCatch({
                httr::content(res, as = "text", encoding = "UTF-8")
            }, error = function(e) "NO CONTENT")
            stop(sprintf("HTTP error %s: %s", httr::status_code(res), err_msg))
        }
        result <- httr::content(res, as = "parsed", simplifyVector = TRUE)
        if (!is.null(result$code) && result$code != "200000") {
            stop(sprintf("API error %s: %s", result$code, result$msg))
        }
        data.table::as.data.table(result$data)
    }, error = function(e) {
        stop("Failed to get account summary info: ", e$message)
    })
})

# File: config.R
#' @export
create_config <- function(
    api_key = Sys.getenv("KC-API-KEY"),
    api_secret = Sys.getenv("KC-API-SECRET"),
    api_passphrase = Sys.getenv("KC-API-PASSPHRASE"),
    base_url = Sys.getenv("KC-API-ENDPOINT"),
    key_version = "2"
) {
    list(
        api_key = api_key,
        api_secret = api_secret,
        api_passphrase = api_passphrase,
        base_url = base_url,
        key_version = key_version
    )
}

# File: main.R
#!/usr/bin/env Rscript
options(error = function() {
    traceback(2)
})

box::use(
    coro,
    httr,
    data.table,
    rlang,
    later,
    promises,
    ./utils[build_query, get_base_url],
    ./api[get_server_time, build_headers],
    ./account[getAccountSummaryInfo],
    ./config[create_config]
)

# Create configuration
config <- create_config()

cat("Testing: Get Account Summary Info\n")
getAccountSummaryInfo(config)$
    then(function(dt) {
        cat("Account Summary Info (data.table):\n")
        print(dt)
    })$
    catch(function(e) {
        message("Error in getAccountSummaryInfo: ", e$message)
    })

# Run the later event loop until all async tasks are processed
while (!later::loop_empty()) {
    later::run_now(timeout = 0.1)
}