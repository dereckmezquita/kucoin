box::use(
    ../R/impl_account_account_and_funding[
        get_account_summary_info_impl,
        get_apikey_info_impl,
        get_spot_account_type_impl,
        get_spot_account_dt_impl,
        get_spot_account_detail_impl,
        get_cross_margin_account_impl,
        get_isolated_margin_account_impl,
        get_spot_ledger_impl
    ],
    ../R/utils[get_api_keys, get_base_url],
    coro[async, await],
    later[loop_empty, run_now]
)

# Define the asynchronous main function
main_async <- async(function() {
    # Obtain API keys and base URL
    keys <- get_api_keys()
    base_url <- get_base_url()

    # 1. Retrieve account summary information
    account_summary <- await(get_account_summary_info_impl(keys = keys, base_url = base_url))
    print("Account Summary:")
    print(account_summary)

    # 2. Retrieve API key information
    apikey_info <- await(get_apikey_info_impl(keys = keys, base_url = base_url))
    print("API Key Info:")
    print(apikey_info)

    # 3. Determine spot account type (high-frequency or low-frequency)
    spot_account_type <- await(get_spot_account_type_impl(keys = keys, base_url = base_url))
    print("Spot Account Type (High-Frequency):")
    print(spot_account_type)

    # 4. Retrieve list of spot accounts
    spot_accounts <- await(get_spot_account_dt_impl(keys = keys, base_url = base_url))
    print("Spot Accounts:")
    print(spot_accounts)

    # 5. Retrieve details for the first spot account (if available)
    if (nrow(spot_accounts) > 0) {
        accountId <- spot_accounts$id[1]
        spot_account_detail <- await(get_spot_account_detail_impl(
            keys = keys,
            base_url = base_url,
            accountId = accountId
        ))
        print("Spot Account Detail for first account:")
        print(spot_account_detail)
    }

    # 6. Retrieve cross margin account information
    cross_margin <- await(get_cross_margin_account_impl(keys = keys, base_url = base_url))
    print("Cross Margin Account Summary:")
    print(cross_margin$summary)
    print("Cross Margin Accounts:")
    print(cross_margin$accounts)

    # 7. Retrieve isolated margin account information for BTC-USDT
    isolated_margin <- await(get_isolated_margin_account_impl(
        keys = keys,
        base_url = base_url
    ))
    print("Isolated Margin Account Summary:")
    print(isolated_margin$summary)
    print("Isolated Margin Assets:")
    print(isolated_margin$assets)

    # 8. Retrieve spot ledger records (first page only for simplicity)
    spot_ledger <- await(get_spot_ledger_impl(
        keys = keys,
        base_url = base_url
    ))
    print("Spot Ledger Records (first page):")
    print(spot_ledger)
})

# Run the main async function
main_async()

# Run the event loop until all tasks are completed
while (!later::loop_empty()) {
  later::run_now()
}