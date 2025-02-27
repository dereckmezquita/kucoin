# File: scripts/tests-manual/run-impl_spottrading_market_data.R
if (interactive()) setwd("./scripts/tests-manual")

box::use(
    ../../R/impl_spottrading_orders_add_order[
        add_order_impl,
        add_order_test_impl,
        add_order_batch_impl
    ],
    ../../R/impl_spottrading_orders_cancel_order[
        cancel_order_by_order_id_impl,
        cancel_order_by_client_oid_impl,
        cancel_partial_order_impl,
        cancel_all_orders_by_symbol_impl,
        cancel_all_orders_impl
    ],
    ../../R/utils[get_api_keys, get_base_url],
    coro[async, await],
    later[loop_empty, run_now],
    lubridate[now, days],
    uuid[UUIDgenerate]
)

# Define the asynchronous main function
main_async <- async(function() {
    # Obtain API keys and base URL
    keys <- get_api_keys()
    base_url <- get_base_url()

    local_symbol <- "BTC-USDT"

    # Test 1: Add a new order
    cat("Test 1: Add a new order\n")
    order_dt <- await(add_order_impl(
        type = "limit",
        symbol = local_symbol,
        side = "buy",
        price = 1,                # Extremely low price for testing purposes
        size = 0.0001,              # Small order size
        remark = "Test:limit absurd"
    ))
    print(order_dt)
    returned_orderId <- order_dt$orderId

    Sys.sleep(10)

    # Test 2: Cancel the order
    cat("Test 2: Cancel the porevious order\n")
    cancelled_orderId <- await(cancel_order_by_order_id_impl(
        orderId = returned_orderId,
        symbol = local_symbol
    ))

    print(cancelled_orderId)
})

main_async()

# Run the event loop until all tasks are completed
while (!later::loop_empty()) {
    later::run_now(timeoutSecs = 1, all = TRUE)
}
