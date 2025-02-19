if (interactive()) setwd("./tests/testthat")

box::use(
    testthat[ 
        test_that, 
        expect_true, 
        expect_false, 
        expect_equal, 
        expect_error 
    ],
    ../../R/utils_time_convert_kucoin[ time_convert_from_kucoin, time_convert_to_kucoin ]
)


### Tests for time_convert_from_kucoin

# Define a known time: 2021-01-01 00:00:00 UTC
expected_time <- as.POSIXct("2021-01-01 00:00:00", tz = "UTC")

test_that("time_convert_from_kucoin converts milliseconds correctly", {
    # 1609459200000 ms = 2021-01-01 00:00:00 UTC
    result <- time_convert_from_kucoin(1609459200000, unit = "ms")
    expect_equal(result, expected_time)
})

test_that("time_convert_from_kucoin converts seconds correctly", {
    # 1609459200 s = 2021-01-01 00:00:00 UTC
    result <- time_convert_from_kucoin(1609459200, unit = "s")
    expect_equal(result, expected_time)
})

test_that("time_convert_from_kucoin converts nanoseconds correctly", {
    # 1609459200000000000 ns = 2021-01-01 00:00:00 UTC
    result <- time_convert_from_kucoin(1609459200000000000, unit = "ns")
    expect_equal(result, expected_time)
})

test_that("time_convert_from_kucoin errors on non-numeric input", {
    expect_error(time_convert_from_kucoin("not a number"), "Input must be a numeric value.")
})

### Tests for time_convert_to_kucoin

# Use the same known time for conversion.
test_that("time_convert_to_kucoin converts to milliseconds correctly", {
    result <- time_convert_to_kucoin(expected_time, unit = "ms")
    # Expect numeric value 1609459200000 (within a tolerance if needed)
    expect_equal(result, 1609459200000)
})

test_that("time_convert_to_kucoin converts to seconds correctly", {
    result <- time_convert_to_kucoin(expected_time, unit = "s")
    expect_equal(result, 1609459200)
})

test_that("time_convert_to_kucoin converts to nanoseconds correctly", {
    result <- time_convert_to_kucoin(expected_time, unit = "ns")
    expect_equal(result, 1609459200000000000)
})

test_that("time_convert_to_kucoin errors on non-POSIXct input", {
    expect_error(time_convert_to_kucoin("not a date"), "Input must be a POSIXct object.")
})
