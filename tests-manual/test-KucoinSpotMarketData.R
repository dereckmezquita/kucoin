#!/usr/bin/env Rscript
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
    data <- await(market_data$get_klines(
        symbol = "BTC-USDT",
        freq = "1min",
        from = lubridate::now() - 24 * 3600,
        to = lubridate::now(),
        concurrent = TRUE
    ))

    print(data)
})

async_main()

while (!later::loop_empty()) {
    later::run_now(timeoutSecs = Inf, all = TRUE)
}
