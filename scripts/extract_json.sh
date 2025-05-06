#!/bin/bash
NUM=$1

echo "Extract $NUM rows from the json data"
jq ".claimReviews[]" -c \
  data-raw/fact_check_insights.json | \
  head -n $NUM > data-raw/test.json

