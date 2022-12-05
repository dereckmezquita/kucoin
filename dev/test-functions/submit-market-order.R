# check our balances
kucoin::get_account_balances()

## -------
# to avoid errors we will calculate our price and order size
# kucoin accepts these values in specific increments per ticker symbol

# get the market metadata
ticker <- "BTC/USDT"
base_to_buy <- 0.0001 # amount of btc
quote_to_spend <- 1 # 1 usdt

metadata <- kucoin::get_market_metadata.deprecated()[symbol == ticker, ]
base_size_increment <- metadata[symbol == ticker, ]$base_increment
quote_size_increment <- metadata[symbol == ticker, ]$quote_increment

# calculate size
base_size <- floor(amount_to_buy / base_size_increment) * base_size_increment
quote_size <- floor(amount_to_spend / quote_size_increment) * quote_size_increment

# post a market order: buy 1 ETH
order_id1 <- kucoin::submit_market_order(
    symbol = ticker,
    side = "buy",
    base_size = base_size
); order_id1

# post a market order: sell 1 ETH
order_id2 <- kucoin::submit_market_order(
    symbol = ticker,
    side = "sell",
    base_size = base_size
); order_id2

# post a market order: buy ETH worth 0.0001 BTC
order_id3 <- kucoin::submit_market_order(
    symbol = ticker,
    side = "buy",
    quote_size = quote_size
); order_id3

# post a market order: sell ETH worth 0.0001 BTC
order_id4 <- kucoin::submit_market_order(
    symbol = ticker,
    side = "sell",
    quote_size = quote_size
); order_id4

kucoin::get_orders_by_id(c(order_id1, order_id2, order_id3, order_id4))
