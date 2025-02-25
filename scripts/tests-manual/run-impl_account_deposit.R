box::use(
    ../../R/impl_account_deposit[
        add_deposit_address_v3_impl,
        get_deposit_addresses_v3_impl,
        get_deposit_history_impl
    ],
    ../../R/utils[get_api_keys, get_base_url],
    coro[async, await],
    later[loop_empty, run_now]
)

main_async <- async(function() {
    # Obtain API keys and base URL
    keys <- get_api_keys()
    base_url <- get_base_url()

    # Add a new deposit address for USDT on TRX
    new_address <- await(add_deposit_address_v3_impl(
        keys = keys,
        base_url = base_url,
        currency = "USDT",
        chain = "trx"
    ))
    cat("\nAdded Deposit Address:\n")
    print(new_address)

    # Get all deposit addresses for USDT on TRX
    addresses <- await(get_deposit_addresses_v3_impl(
        keys = keys,
        base_url = base_url,
        currency = "USDT",
        chain = "trx"
    ))
    cat("\nDeposit Addresses for USDT on TRX:\n")
    print(addresses)

    # Get deposit history for USDT (first page)
    history <- await(get_deposit_history_impl(
        keys = keys,
        base_url = base_url,
        currency = "USDT",
        page_size = 10,
        max_pages = 1
    ))
    cat("\nDeposit History for USDT (first page):\n")
    print(history)
})

# Run the main async function
main_async()

# Run the event loop until all tasks are completed
while (!later::loop_empty()) {
    later::run_now(timeoutSecs = Inf, all = TRUE)
}
