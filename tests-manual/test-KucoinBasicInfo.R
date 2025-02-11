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
    ../R/KucoinAccountAndFunding[ KucoinAccountAndFunding ]
)

basic_info <- KucoinAccountAndFunding$new()

cat("Testing: Get Account Summary Info\n")
basic_info$get_account_summary_info()$
    then(function(dt) {
        cat("Account Summary Info:\n")
        print(dt)
    })$
    catch(function(e) {
        message("Error: ", conditionMessage(e))
        rlang::last_error()
    })

cat("Testing: Get API Key Info\n")
basic_info$get_apikey_info()$
    then(function(dt) {
        cat("API Key Info:\n")
        print(dt)
    })$
    catch(function(e) {
        message("Error: ", conditionMessage(e))
        rlang::last_error()
    })

cat("Testing: Get Spot Account Summary Info\n")
basic_info$get_spot_account_type()$
    then(function(data) {
        cat("Spot Account Summary Info:\n")
        print(data)
    })$
    catch(function(e) {
        message("Error: ", conditionMessage(e))
        rlang::last_error()
    })

while (!later::loop_empty()) {
    later::run_now(timeoutSecs = Inf, all = TRUE)
}