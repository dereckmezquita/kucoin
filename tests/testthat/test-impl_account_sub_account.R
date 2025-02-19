if (interactive()) setwd("./tests/testthat")

box::use(
    testthat[
        test_that,
        skip_if,
        expect_true,
        expect_equal,
        fail,
        expect_null,
        expect_false,
        expect_match
    ],
    later[ loop_empty, run_now ],
    promises[ then, catch ],
    data.table[ is.data.table ],
    subimpl = ../../R/impl_account_sub_account,
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
    paste0(
        "Error message: ", conditionMessage(e), "\nFull error output:\n",
        paste(capture.output(print(e)), collapse = "\n")
    )
}

# Test: Add SubAccount Implementation
test_that("add_subaccount_impl creates a subaccount and returns valid data", {
    skip_if(skip_live, "No API key set in environment; skipping live API test")
    error <- NULL
    result <- NULL
    # Generate a unique subaccount name using the current timestamp.
    subName <- paste0("TestSub_", format(Sys.time(), "%Y%m%d%H%M%S"))
    password <- "Test1234"   # Must meet requirements (7-24 characters, letters and numbers)
    access <- "Spot"         # Allowed values: "Spot", "Futures", "Margin"
    remarks <- "Test sub-account creation"

    subimpl$add_subaccount_impl(keys, base_url, password, subName, access, remarks)$
        then(function(dt) {
            result <<- dt
            expect_true(is.data.table(dt))
            expected_cols <- c("uid", "subName", "remarks", "access")
            expect_true(
                all(expected_cols %in% names(dt)),
                info = paste("Actual columns:", paste(names(dt), collapse = ", "))
            )
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

# Test: Get SubAccount List Summary Implementation
test_that("get_subaccount_list_summary_impl returns valid subaccount summary data", {
    skip_if(skip_live, "No API key set in environment; skipping live API test")
    error <- NULL
    result <- NULL

    subimpl$get_subaccount_list_summary_impl(keys, base_url)$
        then(function(dt) {
            result <<- dt
            expect_true(is.data.table(dt))
            # Expected columns from the subaccount summary. Adjust as needed.
            expected_cols <- c("uid", "subName", "status", "access", "createdAt")
            expect_true(
                all(expected_cols %in% names(dt)),
                info = paste("Actual columns:", paste(names(dt), collapse = ", "))
            )
            # Verify that the datetime conversion has been added.
            expect_true("createdDatetime" %in% names(dt))
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

# Test: Get SubAccount Detail Balance Implementation
test_that("get_subaccount_detail_balance_impl returns valid balance details for a subaccount", {
    skip_if(skip_live, "No API key set in environment; skipping live API test")
    # First, retrieve the subaccount summary list.
    subaccount_list <- NULL
    subimpl$get_subaccount_list_summary_impl(keys, base_url)$
        then(function(dt) {
            subaccount_list <<- dt
        })$
        catch(function(e) {
            fail(format_error(e))
        })
    while (!loop_empty()) {
        run_now(timeoutSecs = 0.1)
    }
    skip_if(is.null(subaccount_list) || nrow(subaccount_list) == 0,
        "No subaccounts available")

    error <- NULL
    result <- NULL
    # Use the first subaccount's uid as subUserId.
    subUserId <- subaccount_list$uid[1]

    subimpl$get_subaccount_detail_balance_impl(keys, base_url, subUserId)$
        then(function(dt) {
            result <<- dt
            expect_true(is.data.table(dt))
            expected_cols <- c("currency", "balance", "available", "holds", "accountType", "subUserId", "subName")
            expect_true(
                all(expected_cols %in% names(dt)),
                info = paste("Actual columns:", paste(names(dt), collapse = ", "))
            )
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
