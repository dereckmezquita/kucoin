
box::use(
    ./modules/utils[build_query, get_base_url],
    ./modules/api[get_server_time, build_headers],
    ./modules/account[getAccountSummaryInfo],
    ./modules/config[create_config],
    ./modules/errors[kucoin_error]
)

# File: main.R
#!/usr/bin/env Rscript
options(error = function() {
    rlang::entrace()
    rlang::last_trace()
})

box::use(
    rlang,
    later,
    ./modules/utils[build_query, get_base_url],
    ./modules/api[get_server_time, build_headers],
    ./modules/account[getAccountSummaryInfo],
    ./modules/config[create_config],
    ./modules/errors[kucoin_error, http_error, api_error]
)

# Create configuration
config <- create_config()

cat("Testing: Get Account Summary Info\n")
getAccountSummaryInfo(config)$
    then(function(dt) {
        cat("Account Summary Info (data.table):\n")
        print(dt)
    })$
    catch(function(e) {
        if (inherits(e, "kucoin_error")) {
            message("KuCoin API Error: ", conditionMessage(e))
            if (!is.null(e$parent)) {
                message("Caused by: ", conditionMessage(e$parent))
            }
        } else {
            message("Unexpected error: ", conditionMessage(e))
        }
        rlang::last_error()
    })

# Run the later event loop until all async tasks are processed
while (!later::loop_empty()) {
    later::run_now(timeout = 0.1)
}