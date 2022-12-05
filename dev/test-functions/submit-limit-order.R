
# check our balances
kucoin::get_account_balances()

## -------
# to avoid errors we will calculate our price and order size
# kucoin accepts these values in specific increments per ticker symbol

# get the market metadata
ticker <- "BTC/USDT"
price_per_coin <- 10000
amount_to_spend <- 300

metadata <- kucoin::get_market_metadata.deprecated()[symbol == ticker, ]
price_increment <- metadata[symbol == ticker, ]$price_increment
size_increment <- metadata[symbol == ticker, ]$base_increment

# calculate size and price
size <- floor(amount_to_spend / price_per_coin / size_increment) * size_increment
price <- floor(price_per_coin / price_increment) * price_increment

## ----
# submit order
message(stringr::str_interp('${ticker}: selling ${size} ${gsub("\\\\/.*", "", ticker)} @ ${price} ${gsub(".*\\\\/", "", ticker)}.'))
order_id1 <- kucoin::submit_limit_order(
    symbol = ticker,
    side = "sell",
    base_size = size,
    price = price
); order_id1


## ----
# buying asset so recalculate
price_per_coin <- 0.0005
amount_to_spend <- 300

# calculate size and price
size <- floor(amount_to_spend / price_per_coin / size_increment) * size_increment
price <- floor(price_per_coin / price_increment) * price_increment

message(stringr::str_interp('${ticker}: buying ${size} ${gsub("\\\\/.*", "", ticker)} @ ${price} ${gsub(".*\\\\/", "", ticker)}.'))
order_id2 <- kucoin::submit_limit_order(
    symbol = ticker,
    side = "buy",
    base_size = size,
    price = price
); order_id2

kucoin::get_orders_by_id(c(order_id1, order_id2))


## ----
# cancel orders by id
kucoin::cancel_orders_by_id(order_id1)

# cancel all orders by ticker
kucoin::cancel_all_orders(ticker)
