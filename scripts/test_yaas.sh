#!/bin/bash
# test_yaas.sh - YaaS Service Test Suite

# Colors for better output
GREEN='\033[0;32m'
RED='\033[0;31m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

API_URL="https://yaasservice.io"

echo -e "${BLUE}🔍 Running YaaS Service Test Suite${NC}"

# 1. Health Check Test
echo -e "${BLUE}Testing Health Endpoint...${NC}"
HEALTH_RESPONSE=$(curl -s $API_URL/api/v1/health)

if [[ "$HEALTH_RESPONSE" == *"Operational"* ]]; then
    echo -e "${GREEN}✅ Health check passed!${NC}"
    echo "$HEALTH_RESPONSE" | jq
else
    echo -e "${RED}❌ Health check failed!${NC}"
    echo "$HEALTH_RESPONSE"
fi

# 2. Positive Sentiment Test
echo -e "\n${BLUE}Testing Positive Sentiment Analysis...${NC}"
POSITIVE_TEXT="I love this amazing service, it works great!"
POSITIVE_RESPONSE=$(curl -s -X POST $API_URL/api/v1/analyze \
  -H "Content-Type: application/json" \
  -d "{\"text\": \"$POSITIVE_TEXT\"}")

if [[ "$POSITIVE_RESPONSE" == *"positive"* ]]; then
    echo -e "${GREEN}✅ Positive sentiment test passed!${NC}"
    echo "$POSITIVE_RESPONSE" | jq
else
    echo -e "${RED}❌ Positive sentiment test failed!${NC}"
    echo "$POSITIVE_RESPONSE"
fi

# 3. Negative Sentiment Test
echo -e "\n${BLUE}Testing Negative Sentiment Analysis...${NC}"
NEGATIVE_TEXT="This is terrible and I hate it."
NEGATIVE_RESPONSE=$(curl -s -X POST $API_URL/api/v1/analyze \
  -H "Content-Type: application/json" \
  -d "{\"text\": \"$NEGATIVE_TEXT\"}")

if [[ "$NEGATIVE_RESPONSE" == *"negative"* ]]; then
    echo -e "${GREEN}✅ Negative sentiment test passed!${NC}"
    echo "$NEGATIVE_RESPONSE" | jq
else
    echo -e "${RED}❌ Negative sentiment test failed!${NC}"
    echo "$NEGATIVE_RESPONSE"
fi

# 4. Error Handling Test
echo -e "\n${BLUE}Testing Error Handling...${NC}"
ERROR_RESPONSE=$(curl -s -X POST $API_URL/api/v1/analyze \
  -H "Content-Type: application/json" \
  -d "{\"wrong_field\": \"test\"}")

if [[ "$ERROR_RESPONSE" == *"error"* ]]; then
    echo -e "${GREEN}✅ Error handling test passed!${NC}"
    echo "$ERROR_RESPONSE" | jq
else
    echo -e "${RED}❌ Error handling test failed!${NC}"
    echo "$ERROR_RESPONSE"
fi

echo -e "\n${BLUE}🎉 Test Suite Completed${NC}"
