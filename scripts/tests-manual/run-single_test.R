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
    ../../R/impl_account_deposit[
        add_deposit_address_v3_impl,
        get_deposit_addresses_v3_impl,
        get_deposit_history_impl
    ],
    ../../R/impl_account_sub_account[
        add_subaccount_impl,
        get_subaccount_list_summary_impl,
        get_subaccount_detail_balance_impl,
        get_subaccount_spot_v2_impl
    ],
    ../../R/utils[get_api_keys, get_base_url],
    ../../R/utils_time_convert_kucoin[time_convert_from_kucoin, time_convert_to_kucoin],
    coro[async, await],
    later[loop_empty, run_now],
    lubridate
)

main_async <- async(function() {
    # Obtain API keys and base URL
    keys <- get_api_keys()
    base_url <- get_base_url()

    # 2. Get the list of subaccounts
    subaccount_list <- await(get_subaccount_list_summary_impl(
        keys = keys,
        base_url = base_url
    ))
    cat("Subaccount List:\n")
    print(subaccount_list)

    # 3. Get the balance of a subaccount
    subaccount_balance <- await(get_subaccount_detail_balance_impl(
        keys = keys,
        base_url = base_url,
        subUserId = subaccount_list$userId[2]
    ))
    cat("Subaccount Balance:\n")
    print(subaccount_balance)

})

# Run the main async function
main_async()

# Run the event loop until all tasks are completed
while (!loop_empty()) {
    run_now()
}
