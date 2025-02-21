# Simulate an asynchronous API call that returns a promise after a delay
get_data_async <- function(url) {
    promises::promise(function(resolve, reject) {
        # Simulate network delay of 1 second
        later::later(function() {
            resolve(paste("Data from", url))
        }, delay = 10)
    })
}

# Define an asynchronous main function
async_main <- coro::async(function() {
    # Await the asynchronous API call
    data <- await(get_data_async("http://example.com/api"))
    cat("Received:", data, "\n")
})

# Kick off the asynchronous main function
async_main()

# Process the event loop until all tasks are completed
while (!later::loop_empty()) {
    later::run_now(timeoutSecs = Inf, all = TRUE)
}