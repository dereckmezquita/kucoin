# File: scripts/tests-manual/run-kcs-trading.R
if (interactive()) setwd("./scripts/tests-manual")

box::use(
    ../../R/impl_spottrading_orders_add_order[
        add_order_impl,
        add_order_test_impl
    ],
    ../../R/impl_spottrading_market_data[
        get_all_symbols_impl,
        get_symbol_impl,
        get_ticker_impl
    ],
    ../../R/impl_account_account_and_funding[
        get_spot_account_list_impl
    ],
    ../../R/utils[get_api_keys, get_base_url],
    coro[async, await],
    later[loop_empty, run_now],
    uuid[UUIDgenerate],
    data.table[as.data.table]
)

main_async <- async(function() {
    # 1. Setup
    cat("Setting up API connection...\n")
    keys <- get_api_keys()
    base_url <- get_base_url()
    
    # 2. Check our balances
    cat("\n== CHECKING ACCOUNT BALANCES ==\n")
    balances <- await(get_spot_account_list_impl(
        keys = keys,
        base_url = base_url
    ))
    
    # Filter for KCS and BTC balances
    kcs_balance <- balances[currency == "KCS"]
    btc_balance <- balances[currency == "BTC"]
    
    cat("KCS Balance:\n")
    print(kcs_balance[, .(currency, type, balance, available, holds)])
    
    cat("BTC Balance:\n")
    print(btc_balance[, .(currency, type, balance, available, holds)])
    
    # 3. Find available trading pairs for KCS
    cat("\n== FINDING AVAILABLE TRADING PAIRS FOR KCS ==\n")
    all_symbols <- await(get_all_symbols_impl(
        base_url = base_url
    ))
    
    # Find pairs where KCS is the base currency (KCS-*)
    kcs_base_pairs <- all_symbols[baseCurrency == "KCS" & enableTrading == TRUE]
    
    cat("Pairs where KCS is the base currency:\n")
    if (nrow(kcs_base_pairs) > 0) {
        print(kcs_base_pairs[, .(symbol, quoteCurrency, minFunds, baseMinSize)])
    } else {
        cat("No pairs found where KCS is the base currency\n")
    }
    
    # Find pairs where KCS is the quote currency (*-KCS)
    kcs_quote_pairs <- all_symbols[quoteCurrency == "KCS" & enableTrading == TRUE]
    
    cat("Pairs where KCS is the quote currency:\n")
    if (nrow(kcs_quote_pairs) > 0) {
        print(kcs_quote_pairs[, .(symbol, baseCurrency, minFunds, baseMinSize)])
    } else {
        cat("No pairs found where KCS is the quote currency\n")
    }
    
    # 4. Choose a target trading pair
    # Let's check if KCS-BTC or BTC-KCS exists, otherwise find the best pair
    
    if ("KCS-BTC" %in% all_symbols$symbol && all_symbols[symbol == "KCS-BTC", enableTrading]) {
        symbol <- "KCS-BTC"
        is_kcs_base <- TRUE
    } else if ("BTC-KCS" %in% all_symbols$symbol && all_symbols[symbol == "BTC-KCS", enableTrading]) {
        symbol <- "BTC-KCS"
        is_kcs_base <- FALSE
    } else if (nrow(kcs_base_pairs) > 0) {
        # Just take the first available KCS pair
        symbol <- kcs_base_pairs$symbol[1]
        is_kcs_base <- TRUE
    } else if (nrow(kcs_quote_pairs) > 0) {
        symbol <- kcs_quote_pairs$symbol[1]
        is_kcs_base <- FALSE
    } else {
        stop("No valid trading pairs found for KCS!")
    }
    
    cat("\n== SELECTED TRADING PAIR ==\n")
    cat("Symbol:", symbol, "\n")
    
    # 5. Get detailed requirements for the chosen pair
    cat("\n== FETCHING SYMBOL REQUIREMENTS ==\n")
    symbol_info <- await(get_symbol_impl(
        base_url = base_url,
        symbol = symbol
    ))
    
    print("Symbol trading requirements:")
    print(symbol_info[, .(
        symbol, 
        baseCurrency, 
        quoteCurrency,
        baseMinSize, 
        quoteMinSize, 
        minFunds, 
        priceIncrement, 
        baseIncrement
    )])
    
    # Set base and quote currencies based on the selected pair
    base_currency <- symbol_info$baseCurrency
    quote_currency <- symbol_info$quoteCurrency
    
    # 6. Get current market data
    cat("\n== RETRIEVING CURRENT MARKET DATA ==\n")
    ticker_data <- await(get_ticker_impl(
        base_url = base_url,
        symbol = symbol
    ))
    
    cat("Current market data for", symbol, ":\n")
    print(ticker_data[, .(
        time_datetime, 
        price, 
        bestBid, 
        bestAsk
    )])
    
    # 7. Calculate order parameters
    cat("\n== CALCULATING ORDER PARAMETERS ==\n")
    
    # Extract requirements
    base_min_size <- as.numeric(symbol_info$baseMinSize)
    quote_min_size <- as.numeric(symbol_info$quoteMinSize)
    min_funds <- as.numeric(symbol_info$minFunds)
    price_increment <- as.numeric(symbol_info$priceIncrement)
    base_increment <- as.numeric(symbol_info$baseIncrement)
    
    # Get current prices
    current_price <- as.numeric(ticker_data$price)
    
    # Round to price increment
    floor_to_increment <- function(value, increment) {
        return(floor(value / increment) * increment)
    }
    
    # Decide whether to buy or sell based on which currency is the base
    if (base_currency == "KCS") {
        # We'll sell KCS for the quote currency (probably USDT or BTC)
        side <- "sell"
        
        # Get the available KCS in trading account
        trading_kcs <- kcs_balance[type == "trade", as.numeric(available)]
        
        if (length(trading_kcs) == 0 || trading_kcs == 0) {
            cat("No KCS available in trading account.\n")
            return()
        }
        
        # Calculate a size that meets minimum requirements
        valid_size <- max(base_min_size, base_increment)
        
        # Ensure we don't sell more than we have
        if (trading_kcs < valid_size) {
            cat("Not enough KCS in trading account for minimum order size.\n")
            return()
        }
        
        # Let's sell a small amount (1% of available KCS but at least minimum size)
        size <- max(floor_to_increment(trading_kcs * 0.01, base_increment), valid_size)
        
        # Check if this meets minimum funds requirement
        order_value <- size * current_price
        if (order_value < min_funds) {
            # Adjust size to meet minimum funds
            size <- ceiling(min_funds / current_price / base_increment) * base_increment
            order_value <- size * current_price
        }
        
        # Set price slightly below current price for faster execution
        price <- floor_to_increment(current_price * 0.998, price_increment)
        
        cat("Order Type: SELL\n")
        cat("Selling", size, base_currency, "at", price, quote_currency, "per", base_currency, "\n")
        cat("Total order value:", order_value, quote_currency, "\n")
        
    } else if (quote_currency == "KCS") {
        # We'll buy the base currency with KCS
        side <- "buy"
        
        # Get the available KCS in trading account
        trading_kcs <- kcs_balance[type == "trade", as.numeric(available)]
        
        if (length(trading_kcs) == 0 || trading_kcs == 0) {
            cat("No KCS available in trading account.\n")
            return()
        }
        
        # Calculate a size that meets minimum requirements
        valid_size <- max(base_min_size, base_increment)
        
        # Set price slightly above current price for faster execution
        price <- floor_to_increment(current_price * 1.002, price_increment)
        
        # Calculate order value
        order_value <- valid_size * price
        
        # Check if we have enough KCS
        if (trading_kcs < order_value) {
            cat("Not enough KCS in trading account for minimum order value.\n")
            return()
        }
        
        size <- valid_size
        
        cat("Order Type: BUY\n")
        cat("Buying", size, base_currency, "at", price, quote_currency, "per", base_currency, "\n")
        cat("Total order value:", order_value, quote_currency, "\n")
    } else {
        cat("Neither KCS is base nor quote currency in the selected pair. Something went wrong.\n")
        return()
    }
    
    # 8. Test the order first
    cat("\n== TESTING ORDER PLACEMENT ==\n")
    
    test_result <- await(add_order_test_impl(
        keys = keys,
        base_url = base_url,
        type = "limit",
        symbol = symbol,
        side = side,
        price = price,
        size = size,
        # clientOid = UUIDgenerate(),
        remark = "Test KCS trade"
    ))
    
    cat("Test order successful!\n")
    print(test_result)
    
    # 9. Ask for confirmation before placing real order
    cat("\n== CONFIRM ORDER PLACEMENT ==\n")
    cat("The test order was successful. Do you want to place the real order?\n")
    cat("To place the real order, modify the code to set placeRealOrder = TRUE\n")
    
    # Safety flag - set to TRUE to place a real order
    placeRealOrder <- FALSE
    
    if (placeRealOrder) {
        cat("\n== PLACING REAL ORDER ==\n")
        
        order_result <- await(add_order_impl(
            keys = keys,
            base_url = base_url,
            type = "limit",
            symbol = symbol,
            side = side,
            price = price,
            size = size,
            clientOid = UUIDgenerate(),
            remark = "KCS trade"
        ))
        
        cat("Order placed successfully!\n")
        print(order_result)
    } else {
        cat("\nSkipping real order placement (safety feature).\n")
        cat("To place a real order, set placeRealOrder = TRUE in the script.\n")
    }
})

# Execute the async function
cat("Starting KuCoin KCS Trading Script...\n")
main_async()

# Run the event loop until all tasks are completed
while (!later::loop_empty()) {
    later::run_now(timeoutSecs = 1, all = TRUE)
}
cat("Script execution completed.\n")
