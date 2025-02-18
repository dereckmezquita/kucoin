git#!/usr/bin/env Rscript
if (interactive()) {
    setwd("./tests-manual")
}

options(error = function() {
    rlang::entrace()
    rlang::last_trace()
    traceback()
})

box::use(
    rlang,
    later,
    coro,
    ../R/KucoinSpotMarketData[ KucoinSpotMarketData ]
)

market_data <- KucoinSpotMarketData$new()

async_main <- coro::async(function() {
    cat("Get get_announcements\n")
    annc <- await(market_data$get_announcements())
    print(annc)

    # cat("Get market data ticker data\n")
    # data <- await(market_data$get_klines(
    #     symbol = "BTC-USDT",
    #     freq = "15min",
    #     from = lubridate::now() - lubridate::days(90),
    #     to = lubridate::now(),
    #     concurrent = TRUE
    # ))

    # print(data)

    # cat("Get currency information\n")
    # currency_data <- await(market_data$get_currency(
    #     currency = "BTC"
    # ))

    # print(currency_data)

    # cat("Get all currencies\n")
    # all_currencies <- await(market_data$get_all_currencies())
    # print(all_currencies)

    # cat("Get symbol\n")
    # symbol_data <- await(market_data$get_symbol(
    #     symbol = "BTC-USDT"
    # ))

    # print(symbol_data)

    # cat("Get all symbols\n")
    # all_symbols <- await(market_data$get_all_symbols())
    # print(all_symbols)

    # cat("Get ticker\n")
    # ticker_data <- await(market_data$get_ticker(
    #     symbol = "BTC-USDT"
    # ))
    # print(ticker_data)

    # cat("Get all tickers\n")
    # all_tickers <- await(market_data$get_all_tickers())
    # print(all_tickers)

    # cat("Get trade history\n")
    # trade_history <- await(market_data$get_trade_history(symbol = "BTC-USDT"))
    # print(trade_history)
    # print(class(trade_history))

    # cat("Get part order book\n")
    # order_book <- await(market_data$get_part_orderbook(
    #     symbol = "BTC-USDT",
    #     size = 20
    # ))
    # print(order_book)

    # cat("Get full order book\n")
    # order_book_full <- await(market_data$get_full_orderbook(
    #     symbol = "BTC-USDT"
    # ))
    # print(order_book_full)

    # cat("Get 24 hour stats\n")
    # stats <- await(market_data$get_24hr_stats(
    #     symbol = "BTC-USDT"
    # ))
    # print(stats)

    # cat("Get get_market_list\n")
    # market_list <- await(market_data$get_market_list())
    # print(market_list)
})

async_main()

while (!later::loop_empty()) {
    later::run_now(timeoutSecs = Inf, all = TRUE)
}
