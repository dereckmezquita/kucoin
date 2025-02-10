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

# Create configuration (or source from environment variables)
config <- list(
    api_key = Sys.getenv("KC-API-KEY"),
    api_secret = Sys.getenv("KC-API-SECRET"),
    api_passphrase = Sys.getenv("KC-API-PASSPHRASE"),
    base_url = Sys.getenv("KC-API-ENDPOINT"),
    key_version = "2"
)

# Create a new instance of the class
api <- KucoinAccountsBasicInfo$new(config)

cat("Testing: Get Account Summary Info\n")
api$getAccountSummaryInfo()$
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
