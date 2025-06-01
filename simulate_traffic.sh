#!/bin/bash

GATEWAY_IP="http://192.168.56.91"

simulate_users() {
  USER=$1       # e.g., "6" for v1, "10" for v2
  VERSION=$2    # e.g., "v1" or "v2"
  NUM_REQUESTS=$3
  RESTAURANT="KFC"
  REVIEW_TEXT="Fantastic atmosphere and delicious food!"

  curl -s -H "user: $USER" "$GATEWAY_IP/env-config.js" > /dev/null

  for i in $(seq 1 $NUM_REQUESTS); do
    echo "[User $USER] Sending request $i to $VERSION..."

    # 1. Predict sentiment
    PREDICTION_RESPONSE=$(curl -s -H "Content-Type: application/json" \
      -H "app-version: $VERSION" \
      -X POST "$GATEWAY_IP/predict" \
      -d "{\"data\": \"$REVIEW_TEXT\"}")

    echo "$PREDICTION_RESPONSE" | grep -q '"prediction": 1' && SENTIMENT="positive" || SENTIMENT="negative"

    sleep $((RANDOM % 10 + 5))

    RATING=$((RANDOM % 5 + 1))

    # 2. Submit rating
    curl -s -H "Content-Type: application/json" \
      -H "app-version: $VERSION" \
      -X POST "$GATEWAY_IP/submit-rating" \
      -d "{
        \"review_text\": \"$REVIEW_TEXT\",
        \"rating\": $RATING,
        \"sentiment\": \"$SENTIMENT\",
        \"restaurant\": \"$RESTAURANT\"
      }" > /dev/null

    echo "[User $USER] Rated $RATING ($SENTIMENT)"
  done
}

simulate_users 6 "v1" 50
simulate_users 10 "v2" 50
