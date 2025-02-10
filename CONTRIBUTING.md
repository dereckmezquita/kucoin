# Contributing to kucoin

Thank you for your interest in contributing to kucoin!

## Code of Conduct

Please read and adhere to our [Code of Conduct](CODE_OF_CONDUCT.md).

## How to Contribute

1. **Report bugs** or **suggest enhancements** by opening an issue.
   - Use a clear, descriptive title.
   - Provide detailed steps to reproduce or implement.

2. **Submit pull requests** for bug fixes or new features.
   - Fill in the PR template.
   - Include tests and documentation.

3. **Improve documentation** by submitting PRs for clarifications or additions.

## Development Guidelines

- Use 4 spaces for indentation.
- Use [box](https://github.com/klmr/box) for imports.
- Prefer base R functions and avoid unnecessary dependencies.
- We aim to minimise external dependencies, including tidyverse packages.
- Write clear, efficient, and maintainable code.

When writing async code we either use `promises` or `async/await` syntax. We never use the pipe operators, instead we use the `then` method to chain promises.

```R
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
```

## Commit Messages

- Use present tense ("Add feature", not "Added feature")
- Be concise but descriptive

## Need Help?

Check out issues labeled `good first issue` or `help wanted`.

Thank you for contributing to Logger!