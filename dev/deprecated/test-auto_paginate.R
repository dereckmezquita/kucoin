if (interactive()) setwd("./tests/testthat")

box::use(
  testthat[test_that, expect_equal, expect_error],
  later,
  coro[async, await],
  ../../R/helpers_api[ auto_paginate ]
)

# Define an asynchronous main function for testing auto_paginate.
async_main <- async(function() {

  ## Test 1: Multiple pages are aggregated correctly.
  res1 <- await(async(function() {
    # Simulate three paginated responses.
    pages <- list(
      list(items = 1:3, currentPage = 1, totalPage = 3),
      list(items = 4:6, currentPage = 2, totalPage = 3),
      list(items = 7:9, currentPage = 3, totalPage = 3)
    )
    counter <- 0
    fetch_page <- async(function(query) {
      counter <<- counter + 1
      return(pages[[counter]])
    })
    
    # Call auto_paginate with our simulated fetch_page.
    result <- await(auto_paginate(
      fetch_page = fetch_page,
      query = list(currentPage = 1, pageSize = 50)
    ))
    return(result)
  }))
  
  test_that("auto_paginate paginates through multiple pages", {
    # We expect three pages aggregated.
    expect_equal(length(res1), 3)
    combined_items <- unlist(lapply(res1, function(page) page$items))
    expect_equal(combined_items, 1:9)
  })
  
  ## Test 2: Single page response.
  res2 <- await(async(function(){
    single_page <- list(items = 11:15, currentPage = 1, totalPage = 1)
    fetch_page <- async(function(query) {
      return(single_page)
    })
    result <- await(auto_paginate(
      fetch_page = fetch_page,
      query = list(currentPage = 1, pageSize = 50)
    ))
    return(result)
  }))
  
  test_that("auto_paginate stops when only one page is present", {
    expect_equal(length(res2), 1)
    expect_equal(res2[[1]]$items, 11:15)
  })
  
  ## Test 3: Respecting the max_pages parameter.
  res3 <- await(async(function(){
    pages <- list(
      list(items = 101:103, currentPage = 1, totalPage = 4),
      list(items = 104:106, currentPage = 2, totalPage = 4),
      list(items = 107:109, currentPage = 3, totalPage = 4),
      list(items = 110:112, currentPage = 4, totalPage = 4)
    )
    counter <- 0
    fetch_page <- async(function(query) {
      counter <<- counter + 1
      return(pages[[counter]])
    })
    # Limit to 2 pages.
    result <- await(auto_paginate(
      fetch_page = fetch_page,
      query = list(currentPage = 1, pageSize = 50),
      max_pages = 2
    ))
    return(result)
  }))
  
  test_that("auto_paginate respects the max_pages parameter", {
    expect_equal(length(res3), 2)
    combined_items <- unlist(lapply(res3, function(page) page$items))
    expect_equal(combined_items, 101:106)
  })
  
  ## Test 4: Error propagation.
  err <- tryCatch({
    await(async(function(){
      fetch_page_error <- async(function(query) {
        stop("Simulated fetch error")
      })
      await(auto_paginate(
        fetch_page = fetch_page_error,
        query = list(currentPage = 1, pageSize = 50)
      ))
    }))
    NULL
  }, error = function(e) e)
  
  test_that("auto_paginate propagates errors", {
    expect_error(stop(err$message), "Simulated fetch error")
  })
  
  return("All tests passed")
})

# Launch the async main function.
async_main()$
    then(function(result) {
        print(result)
    })$
    catch(function(err) {
        print(err$message)
    })

# Run the event loop until all asynchronous tasks complete.
while (!later::loop_empty()) {
  later::run_now()
}
