box::use(kucoin[ get_currency_details ])
box::use(testthat[ expect_equal, test_that ])

currencies <- get_currency_details("BTC")

test_that("all columns from currency data returned completely", {
    expected_columns <- c(
        "currency", "name", "full_name", "precision", "is_margin_enabled",
        "is_debit_enabled", "chain_name", "chain", "withdrawal_min_size",
        "deposit_min_size", "withdraw_fee_rate", "withdraw_max_fee", 
        "withdrawal_min_fee", "is_withdraw_enabled", "is_deposit_enabled",
        "confirms", "pre_confirms", "contract_address"
    )

    expect_equal(colnames(currencies), expected_columns)
})
