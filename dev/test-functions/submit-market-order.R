# check our balances
kucoin::get_account_balances()

# post a market order: buy 1 ETH
order_id <- kucoin::submit_market_order(
    symbol = "ETH/BTC",
    side = "buy",
    base_size = 1
); order_id

# post a market order: sell 1 ETH
order_id <- kucoin::submit_market_order(
    symbol = "ETH/BTC",
    side = "sell",
    base_size = 1
); order_id

# post a market order: buy ETH worth 0.0001 BTC
order_id <- kucoin::submit_market_order(
    symbol = "ETH/BTC",
    side = "buy",
    quote_size = 0.0001
); order_id

# post a market order: sell ETH worth 0.0001 BTC
order_id <- kucoin::submit_market_order(
    symbol = "ETH/BTC",
    side = "sell",
    quote_size = 0.0001
); order_id