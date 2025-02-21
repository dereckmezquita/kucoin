# KuCoin API R Package Development Specification

## Technical Requirements

### Core Technologies
- Language: R
- Package Structure: R6 classes with composition pattern
- Primary Dependencies:
  - data.table (for all data operations)
  - lubridate (date handling)
  - rlang (error handling)
  - R6 (class system)
  - promises (async operations)
  - later (event loop handling)

The package should return promises that the user will have to handle.

### Asynchronous Implementation

The package should use asynchronous programming following JavaScript-like patterns - do not use the pipe operators these are unclear and it is bad practice.

```r
# Example async pattern to follow:
getData <- function() {
    promises$promise(function(resolve, reject) {
        later$later(function() {
            tryCatch({
                # API call or operation here
                resolve(result)
            }, error = function(e) {
                reject(e)
            })
        })
    })
}

# Usage example:
getData()$
    then(function(data) {
        # Handle success
    })$
    catch(function(error) {
        # Handle error
    })
```

- Use promises package for Promise-like functionality
- Structure async code similar to JavaScript's Promise pattern
- Methods should return promises that can be chained with $then() and $catch()
- API calls should be non-blocking

### Code Style
- Indentation: 4 spaces
- Style: C-style R code
- Documentation: Full Roxygen2 with markdown support
- Error Handling: Use rlang::abort() and rlang::warn() with detailed user messages

### Design Patterns
- Modular architecture using class composition
- Main class that integrates all submodules
- Independent, usable subclasses for different API segments
- Helper functions where appropriate
- Async operations should follow JavaScript Promise patterns

### Package Structure
- All code files in R/ directory
- Each module should handle distinct API functionality
- Full documentation for all public functions and classes
- Include examples of async usage in documentation

## Deliverables
1. Complete, production-ready R package
2. All code must be copy-paste ready
3. Professional-grade implementation
4. Full documentation
5. Proper dependency management via Roxygen2 imports
6. Comprehensive error handling
7. Async implementation following JavaScript patterns

## Additional Notes
- Users should be able to use submodules independently
- Code should be modular and reusable
- Focus on maintainability and clarity
- Error messages should be user-friendly and informative
- All API calls should be asynchronous and return promises
- The package should handle the event loop appropriately

Would you like me to provide any examples of specific async patterns or clarify any points?