
metadata <- kucoin::get_market_metadata()

# test that columns match; note in sandbox api the "min_funds" column is missing
testthat::test_that("all columns from metadata returned completely", {
    expect_equal(colnames(metadata), c("symbol", "name", "base_currency", "quote_currency", "fee_currency", "market", "base_min_size", "quote_min_size", "base_max_size", "quote_max_size", "base_increment", "quote_increment", "price_increment", "price_limit_rate", "min_funds", "is_margin_enabled", "enable_trading"))
})
