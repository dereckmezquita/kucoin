if (interactive()) setwd("./scripts/tests-manual")

box::use(
    ../../R/impl_account_account_and_funding[
        get_account_summary_info_impl,
        get_apikey_info_impl,
        get_spot_account_type_impl,
        get_spot_account_list_impl,
        get_spot_account_detail_impl,
        get_cross_margin_account_impl,
        get_isolated_margin_account_impl,
        get_spot_ledger_impl
    ],
    ../../R/utils[get_api_keys, get_base_url],
    coro[async, await],
    later[loop_empty, run_now]
)

main_async <- async(function() {
    # Obtain API keys and base URL
    keys <- get_api_keys()
    base_url <- get_base_url()

    # 8. Retrieve spot ledger records (first page only for simplicity)
    spot_ledger <- await(get_spot_ledger_impl(
        keys = keys,
        base_url = base_url
    ))
    cat("\nSpot Ledger Records (first page):\n")
    print(spot_ledger)
})

# Run the main async function
main_async()

# Run the event loop until all tasks are completed
while (!loop_empty()) {
    run_now()
}
