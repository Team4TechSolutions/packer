
echo "========================================="
echo "Verifying Spectrum Backend Status"
echo "========================================="
echo ""

# Check if backend directory exists
echo "1. Checking backend deployment..."
echo "----------------------------------------"
if [ -d "/opt/tomcat/webapps/spectrum-server" ]; then
    echo "✓ Backend directory exists"
else
    echo "✗ Backend directory not found"
    exit 1
fi
echo ""

# Check if Spring Boot started successfully
echo "2. Checking for successful Spring Boot startup..."
echo "----------------------------------------"
if sudo grep -q "Started.*Application" /opt/tomcat/logs/catalina.out 2>/dev/null; then
    echo "✓ Spring Boot application started successfully"
    sudo grep "Started.*Application" /opt/tomcat/logs/catalina.out | tail -1
else
    echo "⚠ Spring Boot may still be starting or encountered an error"
    echo "  Check logs: sudo tail -50 /opt/tomcat/logs/catalina.out"
fi
echo ""

# Test backend endpoints
echo "3. Testing backend endpoints..."
echo "----------------------------------------"
echo "  Testing /spectrum-server/:"
HTTP_CODE=$(curl -s -o /dev/null -w "%{http_code}" http://localhost:8080/spectrum-server/)
echo "    HTTP Status: $HTTP_CODE"
if [ "$HTTP_CODE" = "200" ] || [ "$HTTP_CODE" = "302" ] || [ "$HTTP_CODE" = "401" ]; then
    echo "    ✓ Backend is responding!"
elif [ "$HTTP_CODE" = "404" ]; then
    echo "    ✗ Backend not found - may still be starting"
else
    echo "    ? Backend returned: $HTTP_CODE"
fi
echo ""

# Check for common API endpoints
echo "4. Testing common API endpoints..."
echo "----------------------------------------"
ENDPOINTS=("/spectrum-server/api" "/spectrum-server/api/health" "/spectrum-server/actuator/health")
for endpoint in "${ENDPOINTS[@]}"; do
    HTTP_CODE=$(curl -s -o /dev/null -w "%{http_code}" http://localhost:8080$endpoint)
    echo "  $endpoint: $HTTP_CODE"
done
echo ""

# Check for errors in recent logs
echo "5. Recent errors (if any)..."
echo "----------------------------------------"
sudo tail -100 /opt/tomcat/logs/catalina.out | grep -i "error\|exception\|failed" | tail -5 || echo "No recent errors found"
echo ""

echo "========================================="
echo "Summary"
echo "========================================="
echo "If Spring Boot started successfully, you should see:"
echo "  - 'Started SpectrumApplication' or similar in logs"
echo "  - HTTP 200/302/401 response from /spectrum-server/"
echo ""
echo "Frontend: http://INSTANCE-IP:8080/spectrum/"
echo "Backend:  http://INSTANCE-IP:8080/spectrum-server/"
echo ""
