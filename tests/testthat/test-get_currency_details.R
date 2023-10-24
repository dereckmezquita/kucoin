
currencies <- kucoin::get_currency_details("BTC")

colnames(currencies)

testthat::test_that("all columns from currency data returned completely", {
    testthat::expect_equal(colnames(currencies), c("currency", "name", "full_name", "precision", "is_margin_enabled", "is_debit_enabled", "chain_name", "chain", "withdrawal_min_size", "withdrawal_min_fee", "is_withdraw_enabled", "is_deposit_enabled", "confirms", "pre_confirms", "contract_address"))
})
