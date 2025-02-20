box::use(fs)

files <- fs$dir_ls(fs$path_abs("./api-responses"), recurse = TRUE, glob = "*.Rds")

# Get the sensitive data file (assuming there's only one .ignore.Rds file)
api_keys_file <- files[grepl("*.ignore.Rds", files)][[1]]
sensitive_data <- readRDS(api_keys_file)

# Function to recursively check for API keys and collect full data
check_for_api_keys <- function(data, path = "") {
    findings <- list()
    if (is.list(data)) {
        for (name in names(data)) {
            # Check specific known API key fields
            if (grepl("api[-_]?key|kc-api", tolower(name))) {
                finding_path <- sprintf("API key found at path: %s$%s", path, name)
                cat(sprintf("WARNING: %s\n", finding_path))
                findings[[finding_path]] <- data  # Store the full data object
            }

            # Check for suspicious string patterns that might be API keys
            if (
                is.character(data[[name]]) &&
                nchar(data[[name]]) > 20 &&
                grepl("[A-Za-z0-9_-]{20,}", data[[name]])
            ) {
                finding_path <- sprintf("Potential API key found at path: %s$%s", path, name)
                cat(sprintf("WARNING: %s\n", finding_path))
                findings[[finding_path]] <- data  # Store the full data object
            }

            # Recursively check nested lists
            new_path <- paste0(path, "$", name)
            if (path == "") {
                new_path <- name
            } 
            nested_findings <- check_for_api_keys(data[[name]], new_path)
            findings <- c(findings, nested_findings)
        }
    }
    return(findings)
}

# List to store all data with potential sensitive information
all_sensitive_data <- list()

# Process all files
for (i in seq_along(files)) {
    file <- files[[i]]
    if (grepl("*.ignore.Rds", file)) next

    data <- readRDS(file)
    cat(sprintf("Checking file: %s\n", file))

    # Check for API keys and store full data if found
    file_findings <- check_for_api_keys(data)
    if (length(file_findings) > 0) {
        cat("WARNING: This file contains potential sensitive data\n")
        all_sensitive_data[[basename(file)]] <- file_findings
    }
    str(data, max.level = 1)
}

# Print summary
if (length(all_sensitive_data) > 0) {
    cat("\nSummary: Found potential sensitive data in", length(all_sensitive_data), "files\n")
    cat("Sensitive data is stored in 'all_sensitive_data' for inspection\n")
} else {
    cat("\nNo potential sensitive data found in any files.\n")
}
