# tests/testthat/test-impl_account_sub_account_stub.R
if (interactive()) setwd("./tests/testthat")

# box::use(
#     testthat[ test_that, skip_if, expect_true, expect_null, expect_match ],
#     later[ loop_empty, run_now ],
#     promises[ then, catch ],
#     data.table[ is.data.table ],
#     subimpl = R/impl_account_sub_account,
#     utils   = R/utils
# )

# Global delay (in seconds) between tests
delay_seconds <- 2

# Retrieve API keys and base URL once.
keys     <- get_api_keys()
base_url <- get_base_url()

# Determine whether to skip live tests.
skip_live <- is.null(keys$api_key) || keys$api_key == ""

test_that("add_subaccount_impl aborts using stubbed process_kucoin_response", {
    skip_if(skip_live, "No API key set in environment; skipping live API test")

    error  <- NULL
    result <- NULL

    # Generate a unique subaccount name.
    subName  <- paste0("TestSub", format(Sys.time(), "%Y%m%d%H%M%S"))
    password <- "Test1234"   # Must be 7-24 characters, letters and numbers
    access   <- "Spot"       # Allowed values: "Spot", "Futures", "Margin"
    remarks  <- "Test sub-account creation"

    # Load the saved HTTP response from the RDS file.
    saved_response <- readRDS("./api-responses/add_subaccount_impl.Rds")

    # --- Mock the HTTP POST call ---
    testthat::local_mocked_bindings(
        POST = function(url, headers, body, encode, timeout) {
            return(saved_response)
        },
        .package = "httr"
    )

    # Call the asynchronous function.
    subimpl$add_subaccount_impl(keys, base_url, password, subName, access, remarks)$
        then(function(dt) {
            result <<- dt
        })$
        catch(function(e) {
            error <<- e
        })

    # Run the event loop until all promises are resolved.
    while (!loop_empty()) {
        run_now(timeoutSecs = 0.1)
    }

    # Check that an error was thrown and that its message contains "YEETTTTT".
    expect_true(!is.null(error))
    err_msg <- if (inherits(error, "error")) conditionMessage(error) else as.character(error)
    expect_match(err_msg, "YEETTTTT")

    # Confirm that no result was returned.
    expect_null(result)

    Sys.sleep(delay_seconds)
})
