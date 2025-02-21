get_data_async <- function(url, should_fail = FALSE) {
    promises::promise(function(resolve, reject) {
        # Simulate different response scenarios using httr::response()
        res <- httr::response(
            status_code = 400,
            content = charToRaw('{"error": "Bad Request"}'),
            url = url
        )
        # Handle HTTP status codes directly - these are expected outcomes
        if (httr::status_code(res) >= 400) {
            reject(list(
                message = sprintf("Server returned status code %d", httr::status_code(res)),
                status = httr::status_code(res),
                url = url
            ))
        }
        # Use tryCatch only for unexpected errors in content parsing
        content <- tryCatch({
            jsonlite::fromJSON(rawToChar(res$content))
        }, error = function(e) {
            reject(list(
                message = "Failed to parse server response",
                original_error = e,
                url = url
            ))
        })
        resolve(content)
    })
}

# Test successful request
cat("Testing successful request:\n")
get_data_async("https://api.example.com/data")$
    then(function(data) {
        print(data)
    })$
    catch(function(err) {
        message("Error handled: ", err$message)
    })

# Run the event loop
while(!later::loop_empty()) {
    later::run_now()
}

# Test failed request
cat("\nTesting failed request:\n")
get_data_async("https://api.example.com/data", should_fail = TRUE)$
    then(function(data) {
        print(data)
    })$
    catch(function(err) {
        message("Error handled: ", err$message)
        if (inherits(err, "http_error")) {
            message("Status: ", err$status)
            message("URL: ", err$url)
        }
    })

while(!later::loop_empty()) {
    later::run_now()
}