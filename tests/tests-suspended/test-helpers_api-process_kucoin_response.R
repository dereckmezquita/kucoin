if (interactive()) setwd("./tests/testthat")

box::use(
    testthat[ test_that, expect_error, expect_equal ],
    ../../R/helpers_api[ process_kucoin_response ]
)

test_that("process_kucoin_response returns parsed response when valid", {
    response <- list(
        url         = "http://example.com",
        status_code = 200,
        headers     = list("Content-Type" = "application/json"),
        content     = charToRaw('{"code": "200000", "data": {"x": 1}}')
    )
    class(response) <- "response"
    result <- process_kucoin_response(response, url = "http://example.com")
    expect_equal(result$code, "200000")
    expect_equal(result$data$x, 1)
})

test_that("process_kucoin_response aborts when HTTP status is not 200", {
    response <- list(
        url         = "http://example.com",
        status_code = 404,
        headers     = list("Content-Type" = "text/plain"),
        content     = charToRaw("Not Found")
    )
    class(response) <- "response"
    expect_error(
        process_kucoin_response(response, url = "http://example.com"),
        "HTTP request failed with status code 404 for URL: http://example.com"
    )
})

test_that("process_kucoin_response aborts when 'code' field is missing", {
    response <- list(
        url         = "http://example.com",
        status_code = 200,
        headers     = list("Content-Type" = "application/json"),
        content     = charToRaw('{"data": {"x": 1}}')
    )
    class(response) <- "response"
    expect_error(
        process_kucoin_response(response, url = "http://example.com"),
        "Invalid API response structure: missing 'code' field."
    )
})

test_that("process_kucoin_response aborts when API code is not 200000 with error message", {
    response <- list(
        url         = "http://example.com",
        status_code = 200,
        headers     = list("Content-Type" = "application/json"),
        content     = charToRaw('{"code": "500000", "msg": "error occurred", "data": {}}')
    )
    class(response) <- "response"
    expect_error(
        process_kucoin_response(response, url = "http://example.com"),
        "KuCoin API returned an error: 500000 - error occurred"
    )
})

test_that("process_kucoin_response aborts when API code is not 200000 and no error message provided", {
    response <- list(
        url         = "http://example.com",
        status_code = 200,
        headers     = list("Content-Type" = "application/json"),
        content     = charToRaw('{"code": "400000", "data": {}}')
    )
    class(response) <- "response"
    expect_error(
        process_kucoin_response(response, url = "http://example.com"),
        "KuCoin API returned an error: 400000 - No error message provided."
    )
})
