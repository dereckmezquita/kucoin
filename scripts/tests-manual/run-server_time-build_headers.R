if (interactive()) setwd("./tests-manual")

#!/usr/bin/env Rscript
box::use(
    later[run_now, loop_empty],
    ../R/helpers_api[get_server_time, build_headers],
    ../R/utils[get_base_url, get_api_keys]
)

# -----------------------------------------------------------------------------
# Test 1: Testing get_server_time()
#
# We call get_server_time() with a fake base URL. Since the URL is fake,
# we expect the promise to be rejected.
# -----------------------------------------------------------------------------

base_url <- get_base_url()

cat("Testing get_server_time()\n", base_url, "\n")

# Call get_server_time with a fake URL.
p_time <- get_server_time(base_url)
p_time$
    then(function(timestamp) {
        cat("get_server_time resolved to:", timestamp, "\n")
        print(timestamp)
    })$
    catch(function(e) {
        cat("get_server_time rejected with error:", conditionMessage(e), "\n")
    })

# -----------------------------------------------------------------------------
# Test 2: Testing build_headers()
#
# We provide a dummy configuration. Since get_server_time() is used inside
# build_headers(), and our fake base URL is used there as well,
# we expect build_headers() to fail.
# -----------------------------------------------------------------------------
cat("Testing build_headers() with dummy configuration...\n")

# Dummy configuration for testing.
config <- get_api_keys()

# Call build_headers() with a GET method, an example endpoint, and an empty body.
p_headers <- build_headers("GET", "/api/v1/test", "", config)
p_headers$
    then(function(headers) {
        cat("build_headers resolved to headers:\n")
        print(headers)
    })$
    catch(function(e) {
        cat("build_headers rejected with error:", conditionMessage(e), "\n")
    })

# -----------------------------------------------------------------------------
# Run the event loop until all asynchronous tasks are processed.
#
# Because these functions are asynchronous, their then()/catch() callbacks will be
# executed only when later::run_now() processes the scheduled events.
# -----------------------------------------------------------------------------
while (!loop_empty()) {
    run_now(timeoutSecs = 0.1, all = TRUE)
}

cat("Testing complete.\n")