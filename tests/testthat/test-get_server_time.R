# File: ./tests/testthat/test-get_server_time.R

box::use(
    testthat[
        test_that, 
        with_mocked_bindings, 
        expect_equal, 
        expect_null, 
        expect_true, 
        expect_match
    ],
    promises,
    later[ run_now, loop_empty ],
    jsonlite,
    rlang
)

test_that("successfully retrieves server time", {
    fake_response <- httr:::response(
        status_code = 200,
        url         = "http://fake-base-url/api/v1/timestamp",
        headers     = list("Content-Type" = "application/json"),
        content     = charToRaw('{"code": "200000", "data": 1618912345678}')
    )

    with_mocked_bindings({
        env <- new.env()
        env$result <- NULL
        env$error  <- NULL

        get_server_time("http://fake-base-url")$
            then(function(val) {
                env$result <- val
                NULL
            })$
            catch(function(e) {
                env$error <- e
                NULL
            })

        while (!loop_empty()) {
            run_now(timeoutSecs = Inf, all = TRUE)
        }

        expect_null(env$error)
        expect_equal(env$result, 1618912345678)
    },
        GET     = function(url, ...) {
            expect_equal(url, "http://fake-base-url/api/v1/timestamp")
            fake_response
        },
        content = function(resp, as, encoding) {
            rawToChar(resp$content)
        },
        .package = "httr"
    )
})

test_that("handles non-200 HTTP response", {
    fake_response <- httr:::response(
        status_code = 500,
        url         = "http://fake-base-url/api/v1/timestamp",
        headers     = list("Content-Type" = "application/json"),
        content     = charToRaw('{"code": "200000", "data": 1618912345678}')
    )

    with_mocked_bindings({
        env <- new.env()
        env$result <- NULL
        env$error  <- NULL

        get_server_time("http://fake-base-url")$
            then(function(val) {
                env$result <- val
                NULL
            })$
            catch(function(e) {
                env$error <- e
                NULL
            })

        while (!loop_empty()) {
            run_now(timeoutSecs = Inf, all = TRUE)
        }

        expect_null(env$result)
        expect_true(inherits(env$error, "error"))
        expect_match(conditionMessage(env$error), "KuCoin API request failed")
    },
        GET     = function(url, ...) fake_response,
        content = function(resp, as, encoding) rawToChar(resp$content),
        .package = "httr"
    )
})

test_that("handles invalid API response structure", {
    fake_response <- httr:::response(
        status_code = 200,
        url         = "http://fake-base-url/api/v1/timestamp",
        headers     = list("Content-Type" = "application/json"),
        content     = charToRaw('{"unexpected": "value"}')
    )

    with_mocked_bindings({
        env <- new.env()
        env$result <- NULL
        env$error  <- NULL

        get_server_time("http://fake-base-url")$
            then(function(val) {
                env$result <- val
                NULL
            })$
            catch(function(e) {
                env$error <- e
                NULL
            })

        while (!loop_empty()) {
            run_now(timeoutSecs = Inf, all = TRUE)
        }

        expect_null(env$result)
        expect_true(inherits(env$error, "error"))
        expect_match(conditionMessage(env$error), "Invalid API response structure")
    },
        GET     = function(url, ...) fake_response,
        content = function(resp, as, encoding) rawToChar(resp$content),
        .package = "httr"
    )
})

test_that("handles API error code", {
    fake_response <- httr:::response(
        status_code = 200,
        url         = "http://fake-base-url/api/v1/timestamp",
        headers     = list("Content-Type" = "application/json"),
        content     = charToRaw('{"code": "400000", "data": "Error message"}')
    )

    with_mocked_bindings({
        env <- new.env()
        env$result <- NULL
        env$error  <- NULL

        get_server_time("http://fake-base-url")$
            then(function(val) {
                env$result <- val
                NULL
            })$
            catch(function(e) {
                env$error <- e
                NULL
            })

        while (!loop_empty()) {
            run_now(timeoutSecs = Inf, all = TRUE)
        }

        expect_null(env$result)
        expect_true(inherits(env$error, "error"))
        expect_match(conditionMessage(env$error), "KuCoin API returned an error")
    },
        GET     = function(url, ...) fake_response,
        content = function(resp, as, encoding) rawToChar(resp$content),
        .package = "httr"
    )
})

test_that("handles error in GET request", {
    with_mocked_bindings({
        env <- new.env()
        env$result <- NULL
        env$error  <- NULL

        get_server_time("http://fake-base-url")$
            then(function(val) {
                env$result <- val
                NULL
            })$
            catch(function(e) {
                env$error <- e
                NULL
            })

        while (!loop_empty()) {
            run_now(timeoutSecs = Inf, all = TRUE)
        }

        expect_null(env$result)
        expect_true(inherits(env$error, "error"))
        expect_match(conditionMessage(env$error), "Error retrieving server time")
    },
        GET = function(url, ...) stop("Network error"),
        .package = "httr"
    )
})
