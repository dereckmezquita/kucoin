
# get one pair of symbol prices
kucoin::get_market_data(
    symbols = "BTC/USDT",
    from = "2022-11-05 00:00:00",
    to = "2022-11-06 00:00:00",
    frequency = "1 hour"
)

# get multiple pair of symbols prices
kucoin::get_market_data(
    symbols = c("BTC/USDT", "XMR/BTC", "KCS/USDT"),
    from = "2022-11-05 00:00:00",
    to = "2022-11-06 00:00:00",
    frequency = "1 hour"
)
