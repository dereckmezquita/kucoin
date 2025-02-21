#!/usr/bin/env Rscript
# Import modules using box::use
box::use(
    promises,
    later,
    rlang[abort],
    coro
)

# Define an asynchronous function that returns a promise.
# This simulates an API call that resolves after 2 seconds.
getDataAsync <- function() {
    return(promises$promise(function(resolve, reject) {
        cat("Simulating API call, waiting 2 seconds...\n")
        later$later(function() {
            resolve("Data received")
        }, delay = 2)
    }))
}

cat("Before API call\n")

# Call getDataAsync() and chain with $then() and $catch(), similar to JavaScript.
getDataAsync()$then(function(data) {
    cat("Inside then: ", data, "\n")
})$catch(function(err) {
    abort("Error fetching data", parent = err)
})

cat("After API call\n")

# Define an async main function using coro::async.
# Inside the function, use await() (without the coro$ prefix) to wait for the promise.
main <- coro$async(function() {
    tryCatch({
        data <- await(getDataAsync()) # Use await() directly!
        cat("Inside async function: ", data, "\n")
    }, error = function(err) {
        cat("Error fetching data: ", err$message, "\n")
    })
})

# Call the main function and attach a then handler.
main()$then(function() {
    cat("Main function completed\n")
})

# In a non-interactive script, run the event loop until all tasks are complete.
while (!later$loop_empty()) {
    later$run_now(timeout = 0.1)
}
