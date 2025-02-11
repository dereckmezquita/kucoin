box::use(
    testthat[expect_true, expect_equal, expect_null, expect_s3_class, expect_match],
    later[run_now],
    promises[promise],
    httr[GET, content, status_code],
    rlang[error_cnd]
)

# Helper function to wait for promise resolution with a timeout.
wait_for <- function(p, timeout = 2) {
    start <- Sys.time()
    result <- NULL
    err <- NULL

    # Attach callbacks to record the outcome.
    p$then(function(x) { result <<- x })$
      catch(function(e) { err <<- e })

    # Loop until result or error is set, or timeout.
    while (is.null(result) && is.null(err)) {
        later::run_now(timeout = 0.1)
        if (as.numeric(Sys.time() - start, units = "secs") > timeout) break
    }
    list(result = result, error = err)
}

test_that("get_server_time returns a promise", {
    p <- get_server_time(get_base_url())
    expect_true(inherits(p, "promise"))
    later::run_now()
})

test_that("get_server_time resolves with correct time on success", {
    # Create a fake response that mimics a successful API response.
    fake_response <- list(
        status_code = 200,
        content = function(as = "text", encoding = "UTF-8") {
            '{"code": "200000", "data": 1625079600000}'
        }
    )
    # Override httr::GET for the duration of this test.
    with_mocked_bindings(
        {
            p <- get_server_time("https://api.kucoin.com")
            out <- wait_for(p)
            expect_null(out$error)
            expect_type(out$result, "double")
            expect_equal(out$result, 1625079600000)
        },
        "httr::GET" = function(url, ...) { fake_response }
    )
})

test_that("get_server_time rejects on non-200 status", {
    fake_response_error <- list(
        status_code = 500,
        content = function(as = "text", encoding = "UTF-8") {
            '{"error": "Internal Server Error"}'
        }
    )
    with_mocked_bindings(
        {
            p <- get_server_time("https://api.kucoin.com")
            out <- wait_for(p)
            expect_null(out$result)
            expect_true(!is.null(out$error))
            expect_s3_class(out$error, "rlang_error")
            expect_match(conditionMessage(out$error), "KuCoin API request failed")
        },
        "httr::GET" = function(url, ...) { fake_response_error }
    )
})
