#!/usr/bin/env Rscript
if (interactive()) {
    setwd("./tests-manual")
}

options(error = function() {
    rlang::entrace()
    rlang::last_trace()
    traceback()
})

box::use(
    rlang,
    later,
    coro,
    ../R/KucoinAccountAndFunding[ KucoinAccountAndFunding ]
)

# Create an instance of the class (credentials are loaded from the environment by default)
account <- KucoinAccountAndFunding$new()

# Define a main asynchronous function that calls all endpoints
async_main <- coro::async(function() {
    # Retrieve account summary info
    dt_summary <- await(account$get_account_summary_info())
    cat("Account Summary Info (data.table):\n")
    print(dt_summary)

    # Retrieve API key info
    dt_apikey <- await(account$get_apikey_info())
    cat("API Key Info (data.table):\n")
    print(dt_apikey)

    # Retrieve spot account type (a boolean)
    is_high_freq <- await(account$get_spot_account_type())
    cat("Spot Account Type (boolean):\n")
    print(is_high_freq)

    # Retrieve spot account list (as a data.table)
    dt_spot <- await(account$get_spot_account_dt())
    cat("Spot Account DT (data.table):\n")
    print(dt_spot)

    # Optionally, retrieve spot account detail for a specific account
    if (nrow(dt_spot) > 0) {
        account_id <- dt_spot$id[1]
        cat("Retrieving spot account detail for account", account_id, "...\n")
        dt_detail <- await(account$get_spot_account_detail(account_id))
        cat("Spot Account Detail (data.table) for account", account_id, ":\n")
        print(dt_detail)
    } else {
        cat("No spot accounts available for detail retrieval.\n")
    }

    # Retrieve cross margin account info using the new method.
    query_cm <- list(quoteCurrency = "USDT", queryType = "MARGIN")
    dt_cross_margin <- await(account$get_cross_margin_account(query_cm))
    cat("Cross Margin Account Info (data.table):\n")
    print(dt_cross_margin)

    # Retrieve isolated margin account info with optional query parameters
    query_im <- list(quoteCurrency = "USDT", queryType = "ISOLATED")
    dt_isolated <- await(account$get_isolated_margin_account(query_im))
    cat("Isolated Margin Account Info (data.table):\n")
    print(dt_isolated)

    # Retrieve futures account info using the new method.
    query_futures <- list(currency = "USDT")
    dt_futures <- await(account$get_futures_account(query_futures))
    cat("Futures Account Info (data.table):\n")
    print(dt_futures)
})

async_main()

# Keep the event loop running until all asynchronous tasks have completed.
while (!later::loop_empty()) {
    later::run_now(timeoutSecs = Inf, all = TRUE)
}