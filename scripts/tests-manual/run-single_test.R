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
    ../../R/impl_spottrading_market_data[
        get_announcements_impl,
        get_currency_impl,
        get_all_currencies_impl,
        get_symbol_impl,
        get_all_symbols_impl,
        get_ticker_impl,
        get_all_tickers_impl,
        get_trade_history_impl,
        get_part_orderbook_impl,
        get_full_orderbook_impl,
        get_24hr_stats_impl,
        get_market_list_impl
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

    # Test 1: Get Announcements
    cat("\n--- Testing get_announcements_impl ---\n")
    announcements <- await(get_announcements_impl(
        base_url = base_url,
        query = list(annType = "new-listings", lang = "en_US"),
        page_size = 5,
        max_pages = 1
    ))
    print(announcements)

})

# Run the main async function
main_async()

# Run the event loop until all tasks are completed
while (!loop_empty()) {
    run_now()
}
