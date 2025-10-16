#!/bin/bash

echo "🧪 Testing All TechCommerce Microservices"
echo "========================================"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Test results
TOTAL_TESTS=0
PASSED_TESTS=0

echo
echo "📦 Frontend Service Tests:"
echo "-------------------------"
cd services/frontend
npm test
if [ $? -eq 0 ]; then
    echo -e "${GREEN}✅ Frontend: PASSED${NC}"
    PASSED_TESTS=$((PASSED_TESTS + 1))
else
    echo -e "${RED}❌ Frontend: FAILED${NC}"
fi
TOTAL_TESTS=$((TOTAL_TESTS + 1))

echo
echo "📦 Order API Service Tests:"
echo "--------------------------"
cd ../order-api
npm test
if [ $? -eq 0 ]; then
    echo -e "${GREEN}✅ Order API: PASSED${NC}"
    PASSED_TESTS=$((PASSED_TESTS + 1))
else
    echo -e "${RED}❌ Order API: FAILED${NC}"
fi
TOTAL_TESTS=$((TOTAL_TESTS + 1))

echo
echo "🐍 Product API Service Tests:"
echo "-----------------------------"
cd ../product-api
pytest -v
if [ $? -eq 0 ]; then
    echo -e "${GREEN}✅ Product API: PASSED${NC}"
    PASSED_TESTS=$((PASSED_TESTS + 1))
else
    echo -e "${RED}❌ Product API: FAILED${NC}"
fi
TOTAL_TESTS=$((TOTAL_TESTS + 1))

echo
echo "📊 Test Summary:"
echo "==============="
echo -e "Total Services: ${TOTAL_TESTS}"
echo -e "Passed: ${GREEN}${PASSED_TESTS}${NC}"
echo -e "Failed: ${RED}$((TOTAL_TESTS - PASSED_TESTS))${NC}"

if [ $PASSED_TESTS -eq $TOTAL_TESTS ]; then
    echo -e "${GREEN}🎉 ALL TESTS PASSED!${NC}"
    exit 0
else
    echo -e "${RED}💥 Some tests failed${NC}"
    exit 1
fi