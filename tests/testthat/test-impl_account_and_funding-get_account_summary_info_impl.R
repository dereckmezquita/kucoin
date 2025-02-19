if (interactive()) setwd("./tests/testthat")

library(testthat)
library(later)
library(promises)
library(data.table)
library(httr)

# Import the function under test from the module.
box::use(
    ../../R/impl_account_and_funding[ get_account_summary_info_impl ]
)

test_that("get_account_summary_info_impl returns a valid data.table on success", {
    fake_keys <- list(
        api_key = "fake_key",
        api_secret = "fake_secret",
        api_passphrase = "fake_pass",
        key_version = "2"
    )
    fake_base_url <- "https://api.fake-kucoin.com"
    
    fake_headers <- list(
        `KC-API-KEY` = "fake_key",
        `KC-API-SIGN` = "fake_sign",
        `KC-API-TIMESTAMP` = "fake_timestamp",
        `KC-API-PASSPHRASE` = "fake_pass"
    )
    
    fake_build_headers <- function(method, endpoint, body, keys) {
        promises::promise_resolve(fake_headers)
    }
    
    fake_data <- list(
        level = 1,
        subQuantity = 2,
        spotSubQuantity = 1,
        marginSubQuantity = 0,
        futuresSubQuantity = 0,
        optionSubQuantity = 0,
        maxSubQuantity = 3,
        maxDefaultSubQuantity = 1,
        maxSpotSubQuantity = 2,
        maxMarginSubQuantity = 0,
        maxFuturesSubQuantity = 0,
        maxOptionSubQuantity = 0
    )
    
    fake_process_kucoin_response <- function(response, url) {
        list(data = fake_data)
    }
    
    fake_httr_GET <- function(url, headers, timeout) {
        list()  # dummy response
    }
    
    result <- NULL
    error <- NULL
    
    # Get the environment where get_account_summary_info_impl() is defined.
    env <- environment(get_account_summary_info_impl)
    
    local_mocked_bindings(
        build_headers = fake_build_headers,
        process_kucoin_response = fake_process_kucoin_response,
        get_api_keys = function() fake_keys,
        get_base_url = function() fake_base_url,
        .env = env
    )
    
    local_mocked_bindings(
        GET = fake_httr_GET,
        .package = "httr"
    )
    
    get_account_summary_info_impl()$
        then(function(dt) {
            result <<- dt
            expect_true(is.data.table(dt))
            expected_cols <- c(
                "level", "subQuantity", "spotSubQuantity", "marginSubQuantity",
                "futuresSubQuantity", "optionSubQuantity", "maxSubQuantity",
                "maxDefaultSubQuantity", "maxSpotSubQuantity", "maxMarginSubQuantity",
                "maxFuturesSubQuantity", "maxOptionSubQuantity"
            )
            expect_equal(sort(names(dt)), sort(expected_cols))
            expect_equal(dt$level, 1)
        })$
        catch(function(e) {
            error <<- e
            fail(paste("Promise rejected with error:", conditionMessage(e)))
        })
    
    while (!loop_empty()) {
        run_now(timeoutSecs = 0.1)
    }
    
    expect_null(error)
    expect_true(!is.null(result))
})

test_that("get_account_summary_info_impl errors when process_kucoin_response fails", {
    fake_keys <- list(
        api_key = "fake_key",
        api_secret = "fake_secret",
        api_passphrase = "fake_pass",
        key_version = "2"
    )
    fake_base_url <- "https://api.fake-kucoin.com"
    
    fake_build_headers <- function(method, endpoint, body, keys) {
        promises::promise_resolve(list())
    }
    
    fake_process_kucoin_response <- function(response, url) {
        stop("Simulated error in process_kucoin_response")
    }
    
    fake_httr_GET <- function(url, headers, timeout) {
        list()
    }
    
    error <- NULL
    
    env <- environment(get_account_summary_info_impl)
    
    local_mocked_bindings(
        build_headers = fake_build_headers,
        process_kucoin_response = fake_process_kucoin_response,
        get_api_keys = function() fake_keys,
        get_base_url = function() fake_base_url,
        .env = env
    )
    
    local_mocked_bindings(
        GET = fake_httr_GET,
        .package = "httr"
    )
    
    get_account_summary_info_impl()$
        then(function(res) {
            fail("Expected error, but promise resolved successfully")
        })$
        catch(function(e) {
            error <<- e
            expect_true(grepl("Simulated error in process_kucoin_response", conditionMessage(e)))
        })
    
    while (!loop_empty()) {
        run_now(timeoutSecs = 0.1)
    }
    
    expect_false(is.null(error))
})

test_that("get_account_summary_info_impl errors when build_headers fails", {
    fake_keys <- list(
        api_key = "fake_key",
        api_secret = "fake_secret",
        api_passphrase = "fake_pass",
        key_version = "2"
    )
    fake_base_url <- "https://api.fake-kucoin.com"
    
    fake_build_headers <- function(method, endpoint, body, keys) {
        promises::promise_reject(simpleError("Simulated build_headers error"))
    }
    
    fake_process_kucoin_response <- function(response, url) {
        list(data = list())
    }
    
    fake_httr_GET <- function(url, headers, timeout) {
        list()
    }
    
    error <- NULL
    
    env <- environment(get_account_summary_info_impl)
    
    local_mocked_bindings(
        build_headers = fake_build_headers,
        process_kucoin_response = fake_process_kucoin_response,
        get_api_keys = function() fake_keys,
        get_base_url = function() fake_base_url,
        .env = env
    )
    
    local_mocked_bindings(
        GET = fake_httr_GET,
        .package = "httr"
    )
    
    get_account_summary_info_impl()$
        then(function(res) {
            fail("Expected error, but promise resolved successfully")
        })$
        catch(function(e) {
            error <<- e
            expect_true(grepl("Simulated build_headers error", conditionMessage(e)))
        })
    
    while (!loop_empty()) {
        run_now(timeoutSecs = 0.1)
    }
    
    expect_false(is.null(error))
})