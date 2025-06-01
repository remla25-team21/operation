#!/bin/bash

# URL of Istio ingress gateway
GATEWAY_IP="http://192.168.56.91"

# Static review text
REVIEW_TEXT="Fantastic atmosphere and delicious food!"
RESTAURANT="Pizza Planet"

simulate_users() {
  USER_HEADER=$1  # e.g., "6" for v1, "10" for v2
  NUM_REQUESTS=$2

  for i in $(seq 1 $NUM_REQUESTS); do
    echo "[User $USER_HEADER] Sending request $i..."

    # Record session start time
    START_TIME=$(date +%s)

    # Step 1: Simulate a prediction request
    curl -s -H "user: $USER_HEADER" \
         -H "Content-Type: application/json" \
         -X POST "$GATEWAY_IP/predict" \
         -d "{\"data\": \"$REVIEW_TEXT\"}" > /dev/null

    # Simulate user dwell time on the page
    SLEEP_TIME=$((RANDOM % 10 + 5))
    sleep $SLEEP_TIME

    # Step 2: Simulate a star rating submission
    END_TIME=$(date +%s)
    DURATION=$((END_TIME - START_TIME))
    RATING=$((RANDOM % 5 + 1))
    SENTIMENT="positive"  # or you can randomize this if needed

    curl -s -H "user: $USER_HEADER" \
         -H "Content-Type: application/json" \
         -X POST "$GATEWAY_IP/submit-rating" \
         -d "{
           \"review_text\": \"$REVIEW_TEXT\",
           \"rating\": $RATING,
           \"sentiment\": \"$SENTIMENT\",
           \"restaurant\": \"$RESTAURANT\"
         }" > /dev/null

    echo "[User $USER_HEADER] Submitted rating $RATING after ${DURATION}s"
  done
}

# Simulate traffic for both versions
simulate_users 6 50   # v1
simulate_users 10 10  # v2
