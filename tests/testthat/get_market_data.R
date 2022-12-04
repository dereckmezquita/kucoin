# get one pair of symbol prices
prices <- kucoin::get_market_data(
    symbols = "BTC/USDT",
    from = "2022-11-05 00:00:00",
    to = "2022-11-06 00:00:00",
    frequency = "1 hour"
)

# test that all columns from historical data returned completely
testthat::test_that("all columns from historical data completed", {
    testthat::expect_equal(colnames(prices), c("symbol", "datetime", "open", "high", "low", "close", "volume", "turnover"))
})

# get multiple pair of symbol prices
prices <- kucoin::get_market_data(
    symbols = c("BTC/USDT", "XMR/BTC", "KCS/BTC"),
    from = "2022-11-05 00:00:00",
    to = "2022-11-06 00:00:00",
    frequency = "1 hour"
)

# test that all columns from historical data returned completely
testthat::test_that("all columns from historical data completed", {
    testthat::expect_equal(colnames(prices), c("symbol", "datetime", "open", "high", "low", "close", "volume", "turnover"))
})
