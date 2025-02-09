box::use(coro, later, promises)

getDataAsync <- function() {
    return(promises$promise(function(resolve, reject) {
        later$later(function() {
            resolve(list(a = 1, b = 2))
        }, delay = 5)
    }))
}

main <- coro$async(function() {
    data <- await(getDataAsync())
    cat("Inside async function:\n")
    print(data)
    return(data)
})

main()$then(function(data) {
    cat("Main function completed\n")
    cat("Data from main function:\n")
    print(data)
})

cat("This print is synchronous\n")

# Run the event loop until all scheduled tasks have been processed.
while (!later$loop_empty()) {
    later$run_now(timeout = 0.1)
}