if (interactive()) setwd("./scripts/tests-manual")

box::use(
    ../../R/impl_account_account_and_funding[
        get_cross_margin_account_impl
    ],
    ../../R/utils[get_api_keys, get_base_url],
    coro[async, await],
    later[loop_empty, run_now]
)

main_async <- async(function() {
    # Obtain API keys and base URL
    keys <- get_api_keys()
    base_url <- get_base_url()

    # 6. Retrieve cross margin account information
    cross_margin <- await(get_cross_margin_account_impl(keys = keys, base_url = base_url))
    cat("Cross Margin Account Summary:\n")
    print(cross_margin$summary)
    cat("Cross Margin Accounts:\n")
    print(cross_margin$accounts)
})

# Run the main async function
main_async()

# Run the event loop until all tasks are completed
while (!loop_empty()) {
    run_now()
}
