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
    ../R/KucoinSubAccount[ KucoinSubAccount ]
)

subAcc <- KucoinSubAccount$new()

async_main <- coro::async(function() {
    # result <- await(subAcc$add_subaccount(
    #     password = "SomeStrongPass123456789",
    #     subName  = "Name6969696969696",
    #     access   = "Spot",
    #     remarks  = "Test sub-account"
    # ))
    # cat("SubAccount Creation Result:\n")
    # print(result)

    # Retrieve sub-account list summary.
    # Here we fetch 3 pages with a page size of 50.
    dt_summary <- await(subAcc$get_subaccount_list_summary(
        page_size = 50,
        max_pages = 3
    ))
    cat("SubAccount List Summary:\n")
    print(dt_summary)

    # # Example: Retrieve sub-account detail (balance) for a given subUserId.
    # dt_balance <- await(subAcc$get_subaccount_detail_balance("some-accout-num", includeBaseAmount = FALSE))
    # cat("SubAccount Detail - Balance:\n")
    # print(dt_balance)
})

async_main()

while (!later::loop_empty()) {
    later::run_now(timeoutSecs = Inf, all = TRUE)
}