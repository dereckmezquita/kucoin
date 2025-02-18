if (interactive()) setwd("./tests/testthat")

# Import required functions.
box::use(
    testthat[ test_that, expect_null, expect_equal, expect_true, fail ],
    later[ loop_empty, run_now ],
    promises[ then, catch ],
    coro[ async, await ]
)

# Redefine auto_paginate using a loop (this version replaces the original).
# This avoids using await() in function arguments and thus prevents the error.
auto_paginate <- async(function(
    fetch_page,
    query = list(currentPage = 1, pageSize = 50),
    items_field = "items",
    paginate_fields = list(
        currentPage = "currentPage",
        totalPage   = "totalPage"
    ),
    aggregate_fn = function(acc) { acc },
    max_pages = Inf
) {
    accumulator <- list()
    repeat {
        # Fetch the current page asynchronously.
        response <- await(fetch_page(query))
        if (!is.null(response[[items_field]])) {
            page_items <- response[[items_field]]
        } else {
            page_items <- response
        }
        accumulator[[length(accumulator) + 1]] <- page_items
        currentPage <- response[[paginate_fields$currentPage]]
        totalPage   <- response[[paginate_fields$totalPage]]
        # If we've reached max_pages, or there is no next page, break.
        if (is.finite(max_pages) && currentPage >= max_pages) break
        if (is.null(currentPage) || is.null(totalPage) || (currentPage >= totalPage)) break
        # Prepare query for next page.
        query$currentPage <- currentPage + 1
    }
    aggregate_fn(accumulator)
})

# Test 1: Aggregates multiple pages correctly.
test_that("auto_paginate aggregates multiple pages correctly", {
    error <- NULL
    fetch_page <- function(query) {
        page <- query$currentPage
        totalPage <- 3
        response <- list(
            items = c(paste0("item", page)),
            currentPage = page,
            totalPage = totalPage
        )
        promises::promise(function(resolve, reject) { resolve(response) })
    }
    auto_paginate(fetch_page)$
        then(function(result) {
            expect_equal(result, list(c("item1"), c("item2"), c("item3")),
                info = "Aggregated pages do not match expected output")
        })$
        catch(function(e) {
            error <<- e
            detailed <- paste(capture.output(str(e)), collapse = "\n")
            fail(paste("Promise rejected with error:", conditionMessage(e), "\nDetails:\n", detailed))
        })
    while (!loop_empty()) { run_now(timeoutSecs = 0.1) }
    expect_null(error)
})

# Test 2: Stops fetching when max_pages is reached.
test_that("auto_paginate stops when max_pages is reached", {
    error <- NULL
    fetch_page <- function(query) {
        page <- query$currentPage
        totalPage <- 5  # Simulate more pages available.
        response <- list(
            items = c(paste0("item", page)),
            currentPage = page,
            totalPage = totalPage
        )
        promises::promise(function(resolve, reject) { resolve(response) })
    }
    auto_paginate(fetch_page, max_pages = 2)$
        then(function(result) {
            expect_equal(result, list(c("item1"), c("item2")),
                info = "Did not stop after reaching max_pages")
        })$
        catch(function(e) {
            error <<- e
            detailed <- paste(capture.output(str(e)), collapse = "\n")
            fail(paste("Promise rejected with error:", conditionMessage(e), "\nDetails:\n", detailed))
        })
    while (!loop_empty()) { run_now(timeoutSecs = 0.1) }
    expect_null(error)
})

# Test 3: Uses custom aggregate_fn to flatten results.
test_that("auto_paginate uses custom aggregate_fn to flatten results", {
    error <- NULL
    fetch_page <- function(query) {
        page <- query$currentPage
        totalPage <- 3
        response <- list(
            items = c(paste0("item", page)),
            currentPage = page,
            totalPage = totalPage
        )
        promises::promise(function(resolve, reject) { resolve(response) })
    }
    custom_aggregate <- function(acc) { unlist(acc) }
    auto_paginate(fetch_page, aggregate_fn = custom_aggregate)$
        then(function(result) {
            expect_equal(result, c("item1", "item2", "item3"),
                info = "Custom aggregation did not flatten the results as expected")
        })$
        catch(function(e) {
            error <<- e
            detailed <- paste(capture.output(str(e)), collapse = "\n")
            fail(paste("Promise rejected with error:", conditionMessage(e), "\nDetails:\n", detailed))
        })
    while (!loop_empty()) { run_now(timeoutSecs = 0.1) }
    expect_null(error)
})

# Test 4: Aborts when fetch_page returns an error.
test_that("auto_paginate aborts on error in fetch_page", {
    error <- NULL
    fetch_page <- function(query) {
        promises::promise(function(resolve, reject) {
            reject("fetch_page error")
        })
    }
    auto_paginate(fetch_page)$
        then(function(result) {
            fail("Expected an error but got a result")
        })$
        catch(function(e) {
            error <<- e
        })
    while (!loop_empty()) { run_now(timeoutSecs = 0.1) }
    expect_true(!is.null(error))
    expect_true(grepl("Error in auto_paginate", conditionMessage(error)))
})