# File: scripts/tests-manual/run-impl_spottrading_market_data.R

box::use(
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
    coro[async, await],
    later[loop_empty, run_now],
    lubridate[now, days]
)

# Define the asynchronous main function
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

    # Test 2: Get Currency Details
    cat("\n--- Testing get_currency_impl ---\n")
    btc_details <- await(get_currency_impl(
        base_url = base_url,
        currency = "BTC"
    ))
    print(btc_details)

    # Test 3: Get Currency Details with Chain
    cat("\n--- Testing get_currency_impl with chain ---\n")
    usdt_erc20 <- await(get_currency_impl(
        base_url = base_url,
        currency = "USDT",
        chain = "ERC20"
    ))
    print(usdt_erc20)

    # Test 4: Get All Currencies
    cat("\n--- Testing get_all_currencies_impl ---\n")
    currencies <- await(get_all_currencies_impl(
        base_url = base_url
    ))
    cat("Total currencies:", nrow(currencies), "\n")
    print(head(currencies, 3))

    # Test 5: Get Symbol
    cat("\n--- Testing get_symbol_impl ---\n")
    btc_usdt <- await(get_symbol_impl(
        base_url = base_url,
        symbol = "BTC-USDT"
    ))
    print(btc_usdt)

    # Test 6: Get All Symbols
    cat("\n--- Testing get_all_symbols_impl ---\n")
    symbols <- await(get_all_symbols_impl(
        base_url = base_url
    ))
    cat("Total symbols:", nrow(symbols), "\n")
    print(head(symbols, 3))

    # Test 7: Get All Symbols filtered by market
    cat("\n--- Testing get_all_symbols_impl with market filter ---\n")
    usds_symbols <- await(get_all_symbols_impl(
        base_url = base_url,
        market = "USDS"
    ))
    cat("Total USDS symbols:", nrow(usds_symbols), "\n")
    print(head(usds_symbols, 3))

    # Test 8: Get Ticker
    cat("\n--- Testing get_ticker_impl ---\n")
    ticker <- await(get_ticker_impl(
        base_url = base_url,
        symbol = "BTC-USDT"
    ))
    print(ticker)

    # Test 9: Get All Tickers
    cat("\n--- Testing get_all_tickers_impl ---\n")
    tickers <- await(get_all_tickers_impl(
        base_url = base_url
    ))
    cat("Total tickers:", nrow(tickers), "\n")
    print(head(tickers, 3))

    # Test 10: Get Trade History
    cat("\n--- Testing get_trade_history_impl ---\n")
    trades <- await(get_trade_history_impl(
        base_url = base_url,
        symbol = "BTC-USDT"
    ))
    cat("Total trades:", nrow(trades), "\n")
    print(head(trades, 3))

    # Test 11: Get Part OrderBook (20 levels)
    cat("\n--- Testing get_part_orderbook_impl (20 levels) ---\n")
    orderbook20 <- await(get_part_orderbook_impl(
        base_url = base_url,
        symbol = "BTC-USDT",
        size = 20
    ))
    cat("Total order levels:", nrow(orderbook20), "\n")
    print(head(orderbook20, 3))

    # Test 12: Get Part OrderBook (100 levels)
    cat("\n--- Testing get_part_orderbook_impl (100 levels) ---\n")
    orderbook100 <- await(get_part_orderbook_impl(
        base_url = base_url,
        symbol = "BTC-USDT",
        size = 100
    ))
    cat("Total order levels:", nrow(orderbook100), "\n")
    print(head(orderbook100, 3))

    # Test 13: Get Full OrderBook (Authenticated)
    cat("\n--- Testing get_full_orderbook_impl ---\n")
    full_orderbook <- await(get_full_orderbook_impl(
        keys = keys,
        base_url = base_url,
        symbol = "BTC-USDT"
    ))
    cat("Total order levels:", nrow(full_orderbook), "\n")
    print(head(full_orderbook, 3))

    # Test 14: Get 24-Hour Statistics
    cat("\n--- Testing get_24hr_stats_impl ---\n")
    stats <- await(get_24hr_stats_impl(
        base_url = base_url,
        symbol = "BTC-USDT"
    ))
    print(stats)

    # Test 15: Get Market List
    cat("\n--- Testing get_market_list_impl ---\n")
    markets <- await(get_market_list_impl(
        base_url = base_url
    ))
    print(markets)

    cat("\n--- All tests completed ---\n")
})

# Run the main async function
cat("Starting market data API tests...\n")
main_async()

# Run the event loop until all tasks are completed
while (!later::loop_empty()) {
    later::run_now(timeoutSecs = 1, all = TRUE)
}