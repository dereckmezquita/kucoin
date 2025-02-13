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
    ../R/KuCoinSubAccount[ KuCoinSubAccount ]
)

subAcc <- KuCoinSubAccount$new()

async_main <- coro::async(function() {
    # result <- await(subAcc$add_subaccount(
    #     password = "Thmydoes1@",
    #     subName  = "Name12345678",
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
})

async_main()

while (!later::loop_empty()) {
    later::run_now(timeoutSecs = Inf, all = TRUE)
}