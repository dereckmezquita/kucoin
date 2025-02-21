# -----------------------------------------------------------------------------
# minimal_promise() demonstrates a promise function that uses tryCatch to
# either resolve or reject. Here we use rlang::abort to signal errors.
#
# IMPORTANT:
# - Calling resolve() or reject() does NOT automatically exit the executor
#   function. You must explicitly return() if you want to stop further execution.
#
# - rlang::abort() immediately signals an error (like stop()), but when used
#   inside tryCatch the error is caught. We then pass the caught error to reject().
# -----------------------------------------------------------------------------
minimal_promise <- function(should_succeed = TRUE) {
    promises::promise(function(resolve, reject) {
        tryCatch({
            # Simulate an asynchronous operation.
            if (should_succeed) {
                # If the condition is met, resolve the promise.
                resolve("Operation succeeded!")
                # Explicit return to stop further execution in this branch.
                return()
            }
            # Otherwise, signal an error using rlang::abort.
            # Because abort() immediately throws an error, execution jumps to the
            # error handler below. (No further code in this block will run.)
            rlang::abort("Operation failed!")
            # (This code is never reached.)
        }, error = function(e) {
            # The error thrown by rlang::abort() is caught here.
            # We then call reject() with the caught error object.
            reject(e)
        })
    })
}

# -----------------------------------------------------------------------------
# minimal_promise_throw() demonstrates a promise that immediately throws an error.
# Instead of using stop(), we use rlang::abort. Here we do not wrap it in a tryCatch;
# the promise infrastructure automatically catches the error and rejects the promise.
# -----------------------------------------------------------------------------
minimal_promise_throw <- function() {
    promises::promise(function(resolve, reject) {
        # This call to rlang::abort() immediately signals an error.
        # The error is automatically caught by the promise system.
        rlang::abort("This error is thrown immediately!")
        # (Execution stops here; this resolve() is never reached.)
        resolve("This will never be reached.")
    })
}

# -----------------------------------------------------------------------------
# Demonstration of usage:
#
# The following cat() calls run synchronously.
# The promise callbacks (in then() and catch()) run asynchronously
# once the event loop is processed.
# -----------------------------------------------------------------------------

cat("Calling minimal_promise with should_succeed = TRUE\n")
minimal_promise(TRUE)$then(function(value) {
    # This callback runs asynchronously when the promise resolves.
    cat("Success:", value, "\n")
})$catch(function(error) {
    # This callback runs if the promise is rejected.
    cat("Error:", conditionMessage(error), "\n")
})

cat("Calling minimal_promise with should_succeed = FALSE\n")
minimal_promise(FALSE)$then(function(value) {
    cat("Success:", value, "\n")
})$catch(function(error) {
    cat("Error:", conditionMessage(error), "\n")
})

cat("Calling minimal_promise_throw\n")
minimal_promise_throw()$then(function(value) {
    cat("Success:", value, "\n")
})$catch(function(error) {
    cat("Error:", conditionMessage(error), "\n")
})

# -----------------------------------------------------------------------------
# Run the event loop until all asynchronous tasks have been processed.
#
# Because promise resolution happens asynchronously, the then() and catch()
# callbacks will only be called once later::run_now() processes them.
# -----------------------------------------------------------------------------
while (!later::loop_empty()) {
    later::run_now(timeoutSecs = 0.1, all = TRUE)
}