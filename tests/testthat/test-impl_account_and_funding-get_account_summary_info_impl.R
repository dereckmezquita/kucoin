if (interactive()) setwd("./tests/testthat")

box::use(
    testthat[ test_that, skip_if, expect_true, expect_equal, fail, expect_null ],
    later[ loop_empty, run_now ],
    promises[ then, catch ],
    data.table[ is.data.table ],
    impl = ../../R/impl_account_and_funding,
    utils = ../../R/utils
)

test_that("get_account_summary_info_impl returns valid data from live API", {
    # Retrieve API keys and base URL from the util functions.
    keys <- utils$get_api_keys()
    base_url <- utils$get_base_url()

    # If API keys are not set, skip the test.
    skip_if(is.null(keys$api_key) || keys$api_key == "", "No API key set in environment; skipping live API test")

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
            expect_equal(sort(names(dt)), sort(expected_cols))
        })$
        catch(function(e) {
            error <<- e
            fail(paste("Promise rejected with error:", conditionMessage(e)))
        })

    while (!later::loop_empty()) {
        later::run_now(timeoutSecs = 0.1)
    }

    expect_null(error)
    expect_true(!is.null(result))
})
