if (interactive()) setwd("./tests/testthat")

box::use(
    testthat[ test_that, expect_null, expect_true, fail ],
    later[ loop_empty, run_now ],
    promises[ then, catch ],
    lubridate,
    ../../R/helpers_api[ get_server_time ],
    ../../R/utils[ get_base_url ]
)

test_that("get_server_time returns a valid timestamp", {
    # Placeholder to capture any errors that occur in the promise.
    error <- NULL

    get_server_time()$
        then(function(ts) {
            # Perform assertions on the timestamp within the callback.
            expect_true(is.numeric(ts), info = "Timestamp should be numeric")
            expect_true(ts > 0, info = "Timestamp should be greater than 0")

            # Convert the timestamp (milliseconds) to a datetime
            ts_datetime <- lubridate::as_datetime(ts / 1000)
            current_time <- lubridate::now(tzone = "UTC")

            # Calculate the absolute difference in seconds between server and current time.
            time_diff <- abs(as.numeric(difftime(current_time, ts_datetime, units = "secs")))
            expect_true(
                time_diff < 5,
                info = paste("Server time difference is", time_diff, "seconds, which exceeds the allowed 5 seconds.")
            )
        })$
        catch(function(e) {
            # Ensure no error was captured outside of the callbacks.
            expect_null(e)
        })

    # Process all asynchronous tasks until the event loop is empty.
    while (!loop_empty()) {
        run_now(timeoutSecs = 0.1)
    }
})
