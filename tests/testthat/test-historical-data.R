# get one pair of symbol prices
prices <- get_kucoin_prices(
    symbols = "BTC/USDT",
    from = "2022-11-05 00:00:00",
    to = "2022-11-06 00:00:00",
    frequency = "1 hour"
)

# test that all columns from historical data returned completelyy
test_that("all columns from historical data completed", {
    expect_equal(colnames(prices), c("datetime", "open", "high", "low", "close", "volume", "turnover"))
})

# get multiple pair of symbol prices
prices <- get_kucoin_prices(
    symbols = c("BTC/USDT", "XMR/BTC", "KCS/BTC"),
    from = "2022-11-05 00:00:00",
    to = "2022-11-06 00:00:00",
    frequency = "1 hour"
)

# test that all columns from historical data returned completelyy
test_that("all columns from historical data completed", {
    expect_equal(colnames(prices), c("symbol", "datetime", "open", "high", "low", "close", "volume", "turnover"))
})
