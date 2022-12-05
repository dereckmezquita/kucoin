
# check our balances
kucoin::get_account_balances()

# submit an order to sell 1 ETH for USDT at price of 100000
order_id <- kucoin::submit_limit_order(
    symbol = "ETH/USDT",
    side = "sell",
    base_size = 1,
    price = 100000
); order_id

# submit an order to buy 1 ETH for USDT at price of 0.01
order_id <- kucoin::submit_limit_order(
    symbol = "ETH/USDT",
    side = "buy",
    base_size = 1,
    price = 0.01
); order_id
