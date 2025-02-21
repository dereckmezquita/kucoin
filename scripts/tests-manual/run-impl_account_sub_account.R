if (interactive()) setwd("./scripts")

box::use(
    ../R/impl_account_sub_account[
        add_subaccount_impl,
        get_subaccount_list_summary_impl,
        get_subaccount_detail_balance_impl,
        get_subaccount_spot_v2_impl
    ],
    ../R/utils[get_api_keys, get_base_url],
    coro[async, await],
    later[loop_empty, run_now]
)

# Define the asynchronous main function
main_async <- async(function() {
    # Obtain API keys and base URL
    keys <- get_api_keys()
    base_url <- get_base_url()

    # 1. Add a subaccount
    # subaccount <- await(add_subaccount_impl(
    #     keys = keys,
    #     base_url = base_url
    #     password = "some69superComplexS3cr3tP@ssw0rd",
    #     subName = "someSuper69s3cretTestSubAccountName",
    #     access = "Spot",
    #     remark = "Some super genius remark"
    # ))

    # 2. Get the list of subaccounts
    subaccount_list <- await(get_subaccount_list_summary_impl(
        keys = keys,
        base_url = base_url
    ))
    cat("Subaccount List:\n")
    print(subaccount_list)

    # 3. Get the balance of a subaccount
    subaccount_balance <- await(get_subaccount_detail_balance_impl(
        keys = keys,
        base_url = base_url,
        subUserId = subaccount_list$userId[2]
    ))
    cat("Subaccount Balance:\n")
    print(subaccount_balance)

    # 4. Get the spot account information for a subaccount
    subaccount_spot <- await(get_subaccount_spot_v2_impl(
        keys = keys,
        base_url = base_url
    ))

    cat("Subaccount Spot Account Information:\n")
    print(subaccount_spot)
})

# Run the main async function
main_async()

# Run the event loop until all tasks are completed
while (!later::loop_empty()) {
  later::run_now()
}
