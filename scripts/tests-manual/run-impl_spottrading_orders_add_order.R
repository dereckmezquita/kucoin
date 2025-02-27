# File: scripts/tests-manual/run-impl_spottrading_market_data.R

box::use(
    ../../R/impl_spottrading_orders_add_order[
        add_order_impl,
        add_order_test_impl,
        add_order_batch_impl
    ],
    ../../R/utils[get_api_keys, get_base_url],
    coro[async, await],
    later[loop_empty, run_now],
    lubridate[now, days]
)

# Define the asynchronous main function
main_async <- async(function() {
    # Obtain API keys and base URL
    keys <- get_api_keys()
    base_url <- get_base_url()

    # Test 1: Add a new order
    cat("Test 1: Add a new order\n")
    order <- await(add_order_impl(
        type = "limit",
        symbol = "BTC-USDT",
        side = "buy",
        price = "1",                # Extremely low price for testing purposes
        size = 0.0001,            # Small order size
        clientOid = UUIDgenerate(), # Generate a unique client order ID
        remark = "Test: limit order at absurd price"
    ))
    print(order)
})

main_async()

# Run the event loop until all tasks are completed
while (!later::loop_empty()) {
    later::run_now(timeoutSecs = 1, all = TRUE)
}