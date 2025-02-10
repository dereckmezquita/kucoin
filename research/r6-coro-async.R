#!/usr/bin/env Rscript
options(error = function() {
    rlang::entrace()
    rlang::last_trace()
})

sessionInfo()
print(paste("coro: ", packageVersion("coro")))
print(paste("promises: ", packageVersion("promises")))
print(paste("later: ", packageVersion("later")))
print(paste("rlang: ", packageVersion("rlang")))
print(paste("R6: ", packageVersion("R6")))

api_data <- function() {
    return(promises::promise(function(resolve, reject) {
        later::later(function() {
            resolve("Hello, API!")
        }, delay = 3)
    }))
}

MyAPI <- R6::R6Class("MyAPI",
    public = list(
        getData = coro::async(function() {
            message("Simulating API call...")
            result <- await(api_data())
            return(result)
        })
    )
)

# Create an instance and call the asynchronous method.
api <- MyAPI$new()

api$getData()$
    then(function(data) {
        message("Data received: ", data)
    })$
    catch(function(e) {
        message("Error: ", conditionMessage(e))
    })

# Run the later event loop until all asynchronous tasks are complete.
while (!later::loop_empty()) {
    later::run_now()
}

