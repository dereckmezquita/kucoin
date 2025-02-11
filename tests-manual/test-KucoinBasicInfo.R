#!/usr/bin/env Rscript
options(error = function() {
    rlang::entrace()
    rlang::last_trace()
})

# Import modules and local packages using box.
box::use(
    rlang,
    later,
    ./R/KucoinBasicInfo[ KucoinAccountsBasicInfo ]
)   

# Create a new instance of the class
basic_info <- KucoinAccountsBasicInfo$new()

cat("Testing: Get Account Summary Info\n")
basic_info$getAccountSummaryInfo()$
    then(function(dt) {
        cat("Account Summary Info (data.table):\n")
        print(dt)
    })$
    catch(function(e) {
        message("Error: ", conditionMessage(e))
        rlang::last_error()
    })

# Run the later event loop until all async tasks are processed
while (!later::loop_empty()) {
    later::run_now(timeoutSecs = Inf, all = TRUE)
}
