box::use(fs)
box::use(uuid)

files <- fs$dir_ls(fs$path_abs("./api-responses"), recurse = TRUE, glob = "*.Rds")

# Get the sensitive data file (assuming there's only one .ignore.Rds file)
api_keys_file <- files[grepl("*.ignore.Rds", files)][[1]]
sensitive_data <- readRDS(api_keys_file)

# Function to recursively check for API keys - returns TRUE if found
check_for_api_keys <- function(data, path = "") {
    has_keys <- FALSE
    if (is.list(data)) {
        for (name in names(data)) {
            # Check specific known API key fields
            if (grepl("api[-_]?key|kc-api", tolower(name))) {
                has_keys <- TRUE
                cat(sprintf("WARNING: API key found at path: %s$%s\n", path, name))
                # Don't return immediately - check entire structure
            }

            # Check for suspicious string patterns that might be API keys
            if (
                is.character(data[[name]]) &&
                nchar(data[[name]]) > 20 &&
                grepl("[A-Za-z0-9_-]{20,}", data[[name]])
            ) {
                has_keys <- TRUE
                cat(sprintf("WARNING: Potential API key found at path: %s$%s\n", path, name))
            }

            # Recursively check nested lists
            new_path <- paste0(path, "$", name)
            if (path == "") {
                new_path <- name
            } 
            if (check_for_api_keys(data[[name]], new_path)) {
                has_keys <- TRUE
            }
        }
    }
    return(has_keys)
}

# List to store all data with potential sensitive information
all_sensitive_data <- list()

# Process all files
for (i in seq_along(files)) {
    file <- files[[i]]
    if (grepl("*.ignore.Rds", file)) next

    data <- readRDS(file)
    cat(sprintf("Checking file: %s\n", file))

    # Check for API keys and store data if found
    if (check_for_api_keys(data)) {
        cat("WARNING: This file contains potential sensitive data\n")
        all_sensitive_data[[file]] <- data
    }
    str(data, max.level = 1)
    cat("\n")  # Add spacing between files
}

# Print summary
if (length(all_sensitive_data) > 0) {
    cat("Summary: Found potential sensitive data in", length(all_sensitive_data), "files\n")
    cat("Sensitive data is stored in 'all_sensitive_data' for inspection\n")
    cat("Files with sensitive data:\n")
    cat(paste(" -", names(all_sensitive_data), "\n"))
} else {
    cat("Summary: No potential sensitive data found in any files.\n")
}

sensitive_file_name <- "./api-responses/impl_account_account_and_funding/parsed_response-get_apikey_info_impl.Rds"
sensitive_data <- readRDS(sensitive_file_name)

# set the key to something random
sensitive_data$data$apiKey <- uuid$UUIDgenerate()
sensitive_data$data$uid <- uuid$UUIDgenerate()

# save the file
saveRDS(sensitive_data, sensitive_file_name)
