#!/usr/bin/env Rscript
# test_box_kucoin_basic_info.R

# Use box to import modules and packages.
box::use(
    httr,
    promises,
    later,
    data.table,
    rlang,
    ./R/helpers,
    ./R/KucoinBasicInfo[ KucoinBasicInfo ]
)

# Build the configuration list from environment variables.
# (If an environment variable is missing, Sys.getenv() returns an empty string.)
config <- list(
    api_key        = Sys.getenv("KC-API-KEY"),
    api_secret     = Sys.getenv("KC-API-SECRET"),
    api_passphrase = Sys.getenv("KC-API-PASSPHRASE"),
    base_url       = Sys.getenv("KC-API-ENDPOINT"),  # For Spot endpoints.
    key_version    = "2"  # Default key version.
)

# Instantiate the Basic Info module.
basic_info <- KucoinBasicInfo$new(config)

# --- Test: Get Account Summary Info -------------------------------------------
cat("Testing: Get Account Summary Info\n")
basic_info$getAccountSummaryInfo()$
  then(function(dt) {
    cat("Account Summary Info (data.table):\n")
    print(dt)
    # For example, dt might look like:
    #    level subQuantity maxDefaultSubQuantity maxSubQuantity spotSubQuantity
    # 1:     0           5                    5              5                5
    #    marginSubQuantity futuresSubQuantity maxSpotSubQuantity maxMarginSubQuantity
    # 1:                 5                  5                   0                   0
    #    maxFuturesSubQuantity
    # 1:                   0
  })$
  catch(function(e) {
    message("Error in getAccountSummaryInfo: ", e$message)
  })

# --- Test: Get Account List -----------------------------------------------------
cat("Testing: Get Account List\n")
basic_info$getAccountList(currency = "BTC", type = "trade")$
  then(function(dt) {
    cat("Account List (data.table):\n")
    print(dt)
    # Each row represents an account. Expected columns: id, currency, type, balance, available, holds.
  })$
  catch(function(e) {
    message("Error in getAccountList: ", e$message)
  })

# --- Test: Get Account Detail ---------------------------------------------------
account_id <- "5bd6e9286d99522a52e458de"  # Replace with a valid account ID from your account list.
cat("Testing: Get Account Detail for accountId =", account_id, "\n")
basic_info$getAccountDetail(account_id)$
  then(function(dt) {
    cat("Account Detail (data.table):\n")
    print(dt)
    # Expected columns: currency, balance, available, holds.
  })$
  catch(function(e) {
    message("Error in getAccountDetail: ", e$message)
  })

# --- Test: Get Account Ledgers (Spot/Margin) ------------------------------------
cat("Testing: Get Account Ledgers (Spot/Margin)\n")
basic_info$getAccountLedgers(currency = "BTC", startAt = 1601395200000)$
  then(function(dt) {
    cat("Account Ledgers (Spot/Margin) (data.table):\n")
    print(dt)
    # Each row represents a ledger record (e.g., with columns id, currency, amount, fee, balance, etc.).
  })$
  catch(function(e) {
    message("Error in getAccountLedgers: ", e$message)
  })

# --- Test: Get Account Ledgers - trade_hf ---------------------------------------
cat("Testing: Get Account Ledgers - trade_hf\n")
basic_info$getAccountLedgersTradeHF(currency = "CSP", lastId = 123456, limit = 100)$
  then(function(dt) {
    cat("Account Ledgers - trade_hf (data.table):\n")
    print(dt)
  })$
  catch(function(e) {
    message("Error in getAccountLedgersTradeHF: ", e$message)
  })

# --- Test: Get Account Ledgers - margin_hf --------------------------------------
cat("Testing: Get Account Ledgers - margin_hf\n")
basic_info$getAccountLedgersMarginHF(currency = "CSP", limit = 100)$
  then(function(dt) {
    cat("Account Ledgers - margin_hf (data.table):\n")
    print(dt)
  })$
  catch(function(e) {
    message("Error in getAccountLedgersMarginHF: ", e$message)
  })

# --- Test: Get Account Ledgers - Futures ----------------------------------------
cat("Testing: Get Account Ledgers - Futures\n")
basic_info$getAccountLedgersFutures(offset = 1, maxCount = 50)$
  then(function(dt) {
    cat("Account Ledgers - Futures (data.table):\n")
    print(dt)
  })$
  catch(function(e) {
    message("Error in getAccountLedgersFutures: ", e$message)
  })

# --- Run the Event Loop ---------------------------------------------------------
# Allow time for asynchronous operations to complete.
cat("Running event loop...\n")
later::run_now(timeout = 5)
cat("Event loop completed.\n")