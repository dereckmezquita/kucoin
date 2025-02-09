#!/usr/bin/env Rscript
#!/usr/bin/env Rscript
options(error = function() {
    traceback(2)
})

# test_box_kucoin_basic_info.R

# Import modules and local packages using box.
box::use(
  coro,
  httr,
  data.table,
  rlang,
  ./R/helpers,
  ./R/KucoinBasicInfo[ KucoinBasicInfo ]
)

# Build the configuration list from environment variables.
config <- list(
  api_key        = Sys.getenv("KC-API-KEY"),
  api_secret     = Sys.getenv("KC-API-SECRET"),
  api_passphrase = Sys.getenv("KC-API-PASSPHRASE"),
  base_url       = Sys.getenv("KC-API-ENDPOINT"),  # e.g., "https://api.kucoin.com"
  key_version    = "2"  # Default key version.
)

# Instantiate the Basic Info module.
basic_info <- KucoinBasicInfo$new(config)

cat("Testing: Get Account Summary Info\n")
basic_info$getAccountSummaryInfo()$
    then(function(dt) {
        cat("Account Summary Info (data.table):\n")
        print(dt)
    })$
    catch(function(e) {
        message("Error in getAccountSummaryInfo: ", e$message)
    })

# Since async operations use an event loop,
# ensure that the event loop runs long enough to process callbacks.
coro::loop()  # This will run the event loop until all tasks are complete.