fn <- function(x = c("foo", "bar")) {
    rlang::arg_match(x)
}
fn("bar2")
