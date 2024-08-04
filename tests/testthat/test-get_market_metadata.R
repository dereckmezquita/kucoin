box::use(kucoin[ get_market_metadata ])
box::use(testthat[ expect_equal, test_that ])

# using v2 api; this is not available in the sandbox - expect errors
metadata <- get_market_metadata()

# test that columns match; note in sandbox api the "min_funds" column is missing
test_that("all columns from metadata returned completely", {
    expected_columns <- c(
        "symbol", "name", "base_currency", "quote_currency",
        "fee_currency", "market", "base_min_size", "quote_min_size",
        "base_max_size", "quote_max_size", "base_increment",
        "quote_increment", "price_increment", "price_limit_rate",
        "min_funds", "is_margin_enabled", "enable_trading"
    )

    expect_equal(colnames(metadata), expected_columns)
})
