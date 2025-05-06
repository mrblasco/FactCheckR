# FactCheckR

**FactCheckR** is an R data package providing access to summarized data from the *Fact Check Insights* project. It includes counts of fact-checked claims over time, categorized by reviewer and rating type.

## Overview

This dataset offers a structured summary of 74,232 fact-checked claims x reviewer x date, enabling users to explore trends in misinformation detection, reviewer activity, and claim ratings. It is especially useful for researchers, journalists, and developers interested in media literacy, misinformation studies, and time series analysis of fact-checking data.

## Dataset Description

The core dataset, `fact_check_insights`, is a data frame with the following structure:

| Column               | Description                                               | Type      |
| -------------------- | --------------------------------------------------------- | --------- |
| `date_published`     | Date the claim was published and reviewed                 | `Date`    |
| `author_name`        | Name of the fact-checking author or organization          | `factor`  |
| `review_rating_type` | Classification or rating of the claim (e.g., False, True) | `factor`  |
| `n`                  | Number of claims matching the above criteria              | `integer` |

## Installation

You can install the development version of `FactCheckR` from [GitHub](https://github.com/mrblasco/FactCheckR) using:

```r
# install.packages("devtools")
devtools::install_github("mrblasco/FactCheckR")
```

## Usage

```r
library(FactCheckR)
library(dplyr)
library(ggplot2)

# Load dataset
data("fact_check_insights")

# Quick overview
head(fact_check_insights)

# Example: Count of claims over time
fact_check_insights %>%
  group_by(date_published) %>%
  summarise(total_claims = sum(n)) %>%
  ggplot(aes(x = date_published, y = total_claims)) +
  geom_line() +
  labs(title = "Fact-Checked Claims Over Time", x = "Date", y = "Number of Claims")
```

## License

This project is licensed under the MIT License. See the `LICENSE` file for details.

## Author

Andrea Blasco  
[mrblasco@gmail.com](mailto:mrblasco@gmail.com)


## Contributions

Issues, suggestions, and contributions are welcome via [GitHub Issues](https://github.com/mrblasco/FactCheckR/issues).
