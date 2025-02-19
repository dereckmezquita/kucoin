if (interactive()) setwd("./tests/testthat")

box::use(
    testthat[ test_that, skip_if, expect_true, expect_equal, fail, expect_null, expect_false, expect_match ],
    later[ loop_empty, run_now ],
    promises[ then, catch ],
    data.table[ is.data.table ],
    impl = ../../R/impl_account_and_funding,
    utils = ../../R/utils
)

# Global delay (in seconds) between tests
delay_seconds <- 2

# Retrieve API keys and base URL only once.
keys <- utils$get_api_keys()
base_url <- utils$get_base_url()

# Determine whether to skip live tests.
skip_live <- is.null(keys$api_key) || keys$api_key == ""

# Helper to format errors in a more descriptive way.
format_error <- function(e) {
    return(paste0(
        "Error message: ",
        conditionMessage(e),
        "\nFull error output:\n",
        paste(capture.output(print(e)),
        collapse = "\n")
    ))
}

# Test: Get Account Summary Info
test_that("get_account_summary_info_impl returns valid data from live API", {
    skip_if(skip_live, "No API key set in environment; skipping live API test")
    error <- NULL
    result <- NULL

    impl$get_account_summary_info_impl(keys, base_url)$
        then(function(dt) {
            result <<- dt
            expect_true(is.data.table(dt))
            expected_cols <- c(
                "level", "subQuantity", "spotSubQuantity", "marginSubQuantity",
                "futuresSubQuantity", "optionSubQuantity", "maxSubQuantity",
                "maxDefaultSubQuantity", "maxSpotSubQuantity", "maxMarginSubQuantity",
                "maxFuturesSubQuantity", "maxOptionSubQuantity"
            )
            expect_equal(sort(names(dt)), sort(expected_cols), 
                         info = paste("Actual columns: ", paste(names(dt), collapse = ", ")))
        })$
        catch(function(e) {
            error <<- e
            fail(format_error(e))
        })

    while (!loop_empty()) {
        run_now(timeoutSecs = 0.1)
    }
    expect_null(error)
    expect_true(!is.null(result))
    Sys.sleep(delay_seconds)
})

# Test: Get API Key Info
test_that("get_apikey_info_impl returns valid API key info from live API", {
    skip_if(skip_live, "No API key set in environment; skipping live API test")
    error <- NULL
    result <- NULL

    impl$get_apikey_info_impl(keys, base_url)$
        then(function(dt) {
            result <<- dt
            expect_true(is.data.table(dt))
            expected_cols <- c("uid", "subName", "remark", "apiKey", 
                               "apiVersion", "permission", "ipWhitelist", "isMaster", "createdAt")
            expect_true(all(expected_cols %in% names(dt)),
                        info = paste("Actual columns: ", paste(names(dt), collapse = ", ")))
        })$
        catch(function(e) {
            error <<- e
            fail(format_error(e))
        })

    while (!loop_empty()) {
        run_now(timeoutSecs = 0.1)
    }
    expect_null(error)
    expect_true(!is.null(result))
    Sys.sleep(delay_seconds)
})

# Test: Get Spot Account Type
test_that("get_spot_account_type_impl returns a boolean value from live API", {
    skip_if(skip_live, "No API key set in environment; skipping live API test")
    error <- NULL
    result <- NULL

    impl$get_spot_account_type_impl(keys, base_url)$
        then(function(res) {
            result <<- res
            expect_true(is.logical(res))
            expect_true(res %in% c(TRUE, FALSE))
        })$
        catch(function(e) {
            error <<- e
            fail(format_error(e))
        })

    while (!loop_empty()) {
        run_now(timeoutSecs = 0.1)
    }
    expect_null(error)
    expect_true(!is.null(result))
    Sys.sleep(delay_seconds)
})

# Test: Get Spot Account List (Data Table)
test_that("get_spot_account_dt_impl returns a valid spot account list from live API", {
    skip_if(skip_live, "No API key set in environment; skipping live API test")
    error <- NULL
    result <- NULL
    query <- list(currency = "USDT", type = "main")  # Adjust query as needed

    impl$get_spot_account_dt_impl(keys, base_url, query)$
        then(function(dt) {
            result <<- dt
            expect_true(is.data.table(dt))
            expected_cols <- c("id", "currency", "type", "balance", "available", "holds")
            expect_true(all(expected_cols %in% names(dt)),
                        info = paste("Actual columns: ", paste(names(dt), collapse = ", ")))
        })$
        catch(function(e) {
            error <<- e
            fail(format_error(e))
        })

    while (!loop_empty()) {
        run_now(timeoutSecs = 0.1)
    }
    expect_null(error)
    expect_true(!is.null(result))
    Sys.sleep(delay_seconds)
})

# Test: Get Spot Account Detail
test_that("get_spot_account_detail_impl returns valid spot account detail from live API", {
    skip_if(skip_live, "No API key set in environment; skipping live API test")
    account_list <- NULL
    impl$get_spot_account_dt_impl(keys, base_url)$
        then(function(dt) {
            account_list <<- dt
        })$
        catch(function(e) {
            fail(format_error(e))
        })
    while (!loop_empty()) {
        run_now(timeoutSecs = 0.1)
    }
    skip_if(is.null(account_list) || nrow(account_list) == 0, "No spot accounts available")
    
    error <- NULL
    detail <- NULL
    accountId <- account_list$id[1]

    impl$get_spot_account_detail_impl(keys, base_url, accountId)$
        then(function(dt) {
            detail <<- dt
            expect_true(is.data.table(dt))
            expected_cols <- c("currency", "balance", "available", "holds")
            expect_true(all(expected_cols %in% names(dt)),
                        info = paste("Actual columns: ", paste(names(dt), collapse = ", ")))
        })$
        catch(function(e) {
            error <<- e
            fail(format_error(e))
        })
    while (!loop_empty()) {
        run_now(timeoutSecs = 0.1)
    }
    expect_null(error)
    expect_true(!is.null(detail))
    Sys.sleep(delay_seconds)
})

# Test: Get Cross Margin Account Info
test_that("get_cross_margin_account_impl returns valid cross margin account info from live API", {
    skip_if(skip_live, "No API key set in environment; skipping live API test")
    error <- NULL
    result <- NULL
    query <- list(quoteCurrency = "USDT", queryType = "MARGIN")

    impl$get_cross_margin_account_impl(keys, base_url, query)$
        then(function(res) {
            result <<- res
            expect_true(is.list(res))
            expect_true("summary" %in% names(res))
            expect_true("accounts" %in% names(res))
            expect_true(is.data.table(res$summary))
            expect_true(is.data.table(res$accounts))
        })$
        catch(function(e) {
            error <<- e
            fail(format_error(e))
        })
    while (!loop_empty()) {
        run_now(timeoutSecs = 0.1)
    }
    expect_null(error)
    expect_true(!is.null(result))
    Sys.sleep(delay_seconds)
})

# Test: Get Isolated Margin Account Info
test_that("get_isolated_margin_account_impl returns valid isolated margin account info from live API", {
    skip_if(skip_live, "No API key set in environment; skipping live API test")
    error <- NULL
    result <- NULL
    query <- list(quoteCurrency = "USDT", queryType = "ISOLATED")

    impl$get_isolated_margin_account_impl(keys, base_url, query)$
        then(function(res) {
            result <<- res
            expect_true(is.list(res))
            expect_true("summary" %in% names(res))
            expect_true("assets" %in% names(res))
            expect_true(is.data.table(res$summary))
            expect_true(is.data.table(res$assets))
        })$
        catch(function(e) {
            error <<- e
            fail(format_error(e))
        })
    while (!loop_empty()) {
        run_now(timeoutSecs = 0.1)
    }
    expect_null(error)
    expect_true(!is.null(result))
    Sys.sleep(delay_seconds)
})

# Test: Get Spot Ledger Data
test_that("get_spot_ledger_impl returns valid ledger data from live API", {
    skip_if(skip_live, "No API key set in environment; skipping live API test")
    error <- NULL
    result <- NULL
    query <- list(currency = "BTC", direction = "in", bizType = "TRANSFER")
    
    impl$get_spot_ledger_impl(keys, base_url, query, page_size = 50, max_pages = 2)$
        then(function(dt) {
            result <<- dt
            expect_true(is.data.table(dt))
            expected_cols <- c("id", "currency", "amount", "fee", "balance", 
                               "accountType", "bizType", "direction", 
                               "createdAt", "createdAtDatetime", "context")
            expect_true(all(expected_cols %in% names(dt)),
                        info = paste("Actual columns: ", paste(names(dt), collapse = ", ")))
        })$
        catch(function(e) {
            error <<- e
            fail(format_error(e))
        })
    while (!loop_empty()) {
        run_now(timeoutSecs = 0.1)
    }
    expect_null(error)
    expect_true(!is.null(result))
    Sys.sleep(delay_seconds)
})
