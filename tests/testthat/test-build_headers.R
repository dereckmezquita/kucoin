box::use(
    testthat[expect_error, expect_setequal, expect_true, expect_equal],
    later[run_now],
    promises[promise],
    httr[GET, content, status_code],
    jsonlite[fromJSON],
    rlang[error_cnd]
)

# Helper function to wait for promise resolution.
wait_for <- function(p, timeout = 2) {
    start <- Sys.time()
    result <- NULL
    err <- NULL

    p$then(function(x) { result <<- x })$
      catch(function(e) { err <<- e })

    while (is.null(result) && is.null(err)) {
        later::run_now(timeout = 0.1)
        if (as.numeric(Sys.time() - start, units = "secs") > timeout) break
    }
    list(result = result, error = err)
}

test_that("build_headers returns correct headers on success", {
    config <- list(
        api_key        = "test_key",
        api_secret     = "test_secret",
        api_passphrase = "test_passphrase",
        key_version    = "2",
        base_url       = "https://api.kucoin.com"
    )
    # Create a fake response for get_server_time.
    fake_response <- list(
        status_code = 200,
        content = function(as = "text", encoding = "UTF-8") {
            '{"code": "200000", "data": 1625079600000}'
        }
    )
    with_mocked_bindings(
        {
            # build_headers is asynchronous; use coro::await to wait for the result.
            headers <- coro::await(build_headers("POST", "/api/v1/orders", '{"size":1}', config))
            expect_true(is.list(headers))
            expected_names <- c("KC-API-KEY", "KC-API-SIGN", "KC-API-TIMESTAMP",
                                "KC-API-PASSPHRASE", "KC-API-KEY-VERSION", "Content-Type")
            expect_setequal(names(headers), expected_names)
            expect_equal(headers[["KC-API-KEY"]], config$api_key)
            expect_true(nzchar(headers[["KC-API-SIGN"]]))
            expect_equal(headers[["KC-API-TIMESTAMP"]], 1625079600000)
            expect_true(nzchar(headers[["KC-API-PASSPHRASE"]]))
            expect_equal(headers[["KC-API-KEY-VERSION"]], config$key_version)
            expect_equal(headers[["Content-Type"]], "application/json")
        },
        "httr::GET" = function(url, ...) { fake_response }
    )
})

test_that("build_headers fails when get_server_time returns an error", {
    config <- list(
        api_key        = "test_key",
        api_secret     = "test_secret",
        api_passphrase = "test_passphrase",
        key_version    = "2",
        base_url       = "https://api.kucoin.com"
    )
    fake_response_error <- list(
        status_code = 500,
        content = function(as = "text", encoding = "UTF-8") {
            '{"error": "Internal Server Error"}'
        }
    )
    with_mocked_bindings(
        {
            expect_error(
                coro::await(build_headers("POST", "/api/v1/orders", '{"size":1}', config)),
                "KuCoin API request failed"
            )
        },
        "httr::GET" = function(url, ...) { fake_response_error }
    )
})
