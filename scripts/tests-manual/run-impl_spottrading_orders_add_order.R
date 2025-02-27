# File: scripts/tests-manual/run-find-trading-pairs.R
if (interactive()) setwd("./scripts/tests-manual")

box::use(
    ../../R/impl_spottrading_market_data[
        get_all_symbols_impl,
        get_market_list_impl
    ],
    ../../R/impl_account_account_and_funding[
        get_spot_account_list_impl
    ],
    ../../R/utils[get_api_keys, get_base_url],
    coro[async, await],
    later[loop_empty, run_now],
    data.table[as.data.table, setorder]
)

# Define the asynchronous main function
main_async <- async(function() {
    # Obtain API keys and base URL
    cat("Setting up API connection...\n")
    keys <- get_api_keys()
    base_url <- get_base_url()
    
    # Step 1: Get all spot account balances
    cat("\n== STEP 1: CHECKING ALL ACCOUNT BALANCES ==\n")
    all_balances <- await(get_spot_account_list_impl(
        keys = keys,
        base_url = base_url
    ))
    
    # Get non-zero balances
    non_zero_balances <- all_balances[as.numeric(available) > 0]
    cat("You have balances in the following currencies:\n")
    print(non_zero_balances[, .(currency, type, balance, available, holds)])
    
    # Step 2: Get all available markets
    cat("\n== STEP 2: FETCHING AVAILABLE MARKETS ==\n")
    markets <- await(get_market_list_impl(
        base_url = base_url
    ))
    
    cat("Available markets on KuCoin:\n")
    print(markets)
    
    # Step 3: Get all trading symbols
    cat("\n== STEP 3: FETCHING ALL TRADING PAIRS ==\n")
    all_symbols <- await(get_all_symbols_impl(
        base_url = base_url
    ))
    
    cat("Found", nrow(all_symbols), "trading pairs\n")
    
    # Step 4: Find which currencies you hold have trading pairs
    cat("\n== STEP 4: FINDING VALID TRADING PAIRS FOR YOUR CURRENCIES ==\n")
    
    # Focus on KCS pairs first
    if (any(non_zero_balances$currency == "KCS")) {
        cat("\nLooking for trading pairs where KCS is the base or quote currency:\n")
        
        # Find pairs where KCS is the base currency
        kcs_base_pairs <- all_symbols[baseCurrency == "KCS"]
        if (nrow(kcs_base_pairs) > 0) {
            cat("\nPairs where KCS is the base currency:\n")
            print(kcs_base_pairs[, .(symbol, quoteCurrency, enableTrading)])
        } else {
            cat("No pairs found where KCS is the base currency\n")
        }
        
        # Find pairs where KCS is the quote currency
        kcs_quote_pairs <- all_symbols[quoteCurrency == "KCS"]
        if (nrow(kcs_quote_pairs) > 0) {
            cat("\nPairs where KCS is the quote currency:\n")
            print(kcs_quote_pairs[, .(symbol, baseCurrency, enableTrading)])
        } else {
            cat("No pairs found where KCS is the quote currency\n")
        }
    }
    
    # Also check for BTC pairs since you have some BTC
    if (any(non_zero_balances$currency == "BTC")) {
        cat("\nLooking for trading pairs where BTC is the base or quote currency:\n")
        
        # Find pairs where BTC is the base currency
        btc_base_pairs <- all_symbols[baseCurrency == "BTC"]
        cat("\nPairs where BTC is the base currency (showing first 10):\n")
        print(head(btc_base_pairs[, .(symbol, quoteCurrency, enableTrading)], 10))
        
        # Find pairs where BTC is the quote currency
        btc_quote_pairs <- all_symbols[quoteCurrency == "BTC"]
        cat("\nPairs where BTC is the quote currency (showing first 10):\n")
        print(head(btc_quote_pairs[, .(symbol, baseCurrency, enableTrading)], 10))
    }
    
    # Find valid trading pairs for all your currencies
    cat("\n== STEP 5: FINDING TRADABLE PAIRS FOR ALL YOUR CURRENCIES ==\n")
    
    your_currencies <- unique(non_zero_balances$currency)
    
    # Find trading pairs where any of your currencies can be traded
    trading_options <- list()
    
    for (curr in your_currencies) {
        # Where currency is base
        base_pairs <- all_symbols[baseCurrency == curr & enableTrading == TRUE]
        
        # Where currency is quote
        quote_pairs <- all_symbols[quoteCurrency == curr & enableTrading == TRUE]
        
        if (nrow(base_pairs) > 0 || nrow(quote_pairs) > 0) {
            trading_options[[curr]] <- list(
                as_base = base_pairs,
                as_quote = quote_pairs
            )
        }
    }
    
    # Print summary of trading options
    cat("\nSummary of available trading options for your currencies:\n")
    
    for (curr in names(trading_options)) {
        base_count <- nrow(trading_options[[curr]]$as_base)
        quote_count <- nrow(trading_options[[curr]]$as_quote)
        
        if (base_count > 0 || quote_count > 0) {
            cat("\n", curr, ":\n")
            
            if (base_count > 0) {
                cat("  -", base_count, "pairs where", curr, "is the base currency\n")
                if (base_count <= 5) {
                    cat("    Pairs:", paste(trading_options[[curr]]$as_base$symbol, collapse=", "), "\n")
                } else {
                    cat("    Example pairs:", paste(head(trading_options[[curr]]$as_base$symbol, 5), collapse=", "), "...\n")
                }
            }
            
            if (quote_count > 0) {
                cat("  -", quote_count, "pairs where", curr, "is the quote currency\n")
                if (quote_count <= 5) {
                    cat("    Pairs:", paste(trading_options[[curr]]$as_quote$symbol, collapse=", "), "\n")
                } else {
                    cat("    Example pairs:", paste(head(trading_options[[curr]]$as_quote$symbol, 5), collapse=", "), "...\n")
                }
            }
        }
    }
    
    # Suggest the best trading pairs based on available balances
    cat("\n== STEP 6: RECOMMENDED TRADING PAIRS ==\n")
    
    recommended_pairs <- c()
    
    # First priority: KCS pairs if you have KCS
    if (any(non_zero_balances$currency == "KCS") && "KCS" %in% names(trading_options)) {
        if (nrow(trading_options[["KCS"]]$as_quote) > 0) {
            # KCS as quote currency
            top_kcs_pairs <- head(trading_options[["KCS"]]$as_quote[enableTrading == TRUE], 3)
            if (nrow(top_kcs_pairs) > 0) {
                recommended_pairs <- c(recommended_pairs, top_kcs_pairs$symbol)
            }
        }
        
        if (nrow(trading_options[["KCS"]]$as_base) > 0) {
            # KCS as base currency
            top_kcs_pairs <- head(trading_options[["KCS"]]$as_base[enableTrading == TRUE], 3)
            if (nrow(top_kcs_pairs) > 0) {
                recommended_pairs <- c(recommended_pairs, top_kcs_pairs$symbol)
            }
        }
    }
    
    # Second priority: BTC pairs if you have BTC
    if (any(non_zero_balances$currency == "BTC") && "BTC" %in% names(trading_options)) {
        if (nrow(trading_options[["BTC"]]$as_quote) > 0) {
            # BTC as quote currency
            top_btc_pairs <- head(trading_options[["BTC"]]$as_quote[enableTrading == TRUE], 3)
            if (nrow(top_btc_pairs) > 0) {
                recommended_pairs <- c(recommended_pairs, top_btc_pairs$symbol)
            }
        }
        
        if (nrow(trading_options[["BTC"]]$as_base) > 0) {
            # BTC as base currency
            top_btc_pairs <- head(trading_options[["BTC"]]$as_base[enableTrading == TRUE], 3)
            if (nrow(top_btc_pairs) > 0) {
                recommended_pairs <- c(recommended_pairs, top_btc_pairs$symbol)
            }
        }
    }
    
    # Third priority: Other currencies that you have decent amounts of
    for (curr in your_currencies) {
        if (curr != "KCS" && curr != "BTC" && curr %in% names(trading_options)) {
            curr_balance <- non_zero_balances[currency == curr, max(as.numeric(available))]
            
            if (curr_balance > 0.01) { # Arbitrary threshold to filter out dust
                if (nrow(trading_options[[curr]]$as_quote) > 0) {
                    # As quote currency
                    top_pairs <- head(trading_options[[curr]]$as_quote[enableTrading == TRUE], 2)
                    if (nrow(top_pairs) > 0) {
                        recommended_pairs <- c(recommended_pairs, top_pairs$symbol)
                    }
                }
                
                if (nrow(trading_options[[curr]]$as_base) > 0) {
                    # As base currency
                    top_pairs <- head(trading_options[[curr]]$as_base[enableTrading == TRUE], 2)
                    if (nrow(top_pairs) > 0) {
                        recommended_pairs <- c(recommended_pairs, top_pairs$symbol)
                    }
                }
            }
        }
    }
    
    # Remove any duplicates and limit to 10 pairs
    recommended_pairs <- unique(recommended_pairs)
    if (length(recommended_pairs) > 10) {
        recommended_pairs <- recommended_pairs[1:10]
    }
    
    if (length(recommended_pairs) > 0) {
        cat("\nTop recommended trading pairs based on your balances:\n")
        for (pair in recommended_pairs) {
            cat("- ", pair, "\n")
        }
        
        # Provide the pair to use for the next script
        cat("\nFor your trading script, we recommend using:", recommended_pairs[1], "\n")
        cat("To use this pair, update your script with: local_symbol <- \"", recommended_pairs[1], "\"\n")
    } else {
        cat("\nCouldn't find any suitable trading pairs for your current balances.\n")
    }
})

# Execute the async function
cat("Starting KuCoin Market Explorer...\n")
main_async()

# Run the event loop until all tasks are completed
cat("Waiting for all async operations to complete...\n")
while (!later::loop_empty()) {
    later::run_now(timeoutSecs = 1, all = TRUE)
}
cat("Script execution completed.\n")