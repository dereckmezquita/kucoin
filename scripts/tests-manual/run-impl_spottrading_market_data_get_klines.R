if (interactive()) setwd("./scripts")

box::use(
    ../R/impl_spottrading_market_data_get_klines[
        get_klines_impl
    ],
    ../R/utils[get_api_keys, get_base_url],
    coro[async, await],
    later[loop_empty, run_now]
)

# Define the asynchronous main function
main_async <- async(function() {
    market_data <- await(get_klines_impl(
        base_url = get_base_url(),
        symbol = "BTC-USDT",
        freq = "15min",
        from = lubridate::now() - 24 * 3600,
        to = lubridate::now(),
        concurrent = TRUE,
        delay_ms = 0,
        retries = 3,
        verbose = FALSE
    ))

    print(market_data)
})

# Run the main async function
main_async()

# Run the event loop until all tasks are completed
while (!later::loop_empty()) {
  later::run_now()
}
