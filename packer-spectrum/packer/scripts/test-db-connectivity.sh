#!/bin/bash

echo "========================================="
echo "Testing Database Connectivity"
echo "========================================="
echo ""

DB_HOST="database-1.cdq6ga82mq0v.ca-central-1.rds.amazonaws.com"
DB_PORT="3306"

# Test 1: Basic network connectivity
echo "1. Testing network connectivity to database..."
echo "----------------------------------------"
if command -v nc &> /dev/null || command -v telnet &> /dev/null; then
    if command -v nc &> /dev/null; then
        echo "  Using netcat (nc) to test port $DB_PORT..."
        if timeout 5 nc -zv $DB_HOST $DB_PORT 2>&1; then
            echo "  ✓ Port $DB_PORT is reachable"
        else
            echo "  ✗ Cannot reach port $DB_PORT (connection timeout or refused)"
        fi
    else
        echo "  Using telnet to test port $DB_PORT..."
        timeout 5 bash -c "echo > /dev/tcp/$DB_HOST/$DB_PORT" 2>/dev/null
        if [ $? -eq 0 ]; then
            echo "  ✓ Port $DB_PORT is reachable"
        else
            echo "  ✗ Cannot reach port $DB_PORT"
        fi
    fi
else
    echo "  Testing with timeout and bash..."
    timeout 5 bash -c "echo > /dev/tcp/$DB_HOST/$DB_PORT" 2>/dev/null
    if [ $? -eq 0 ]; then
        echo "  ✓ Port $DB_PORT is reachable"
    else
        echo "  ✗ Cannot reach port $DB_PORT (connection timeout)"
    fi
fi
echo ""

# Test 2: DNS resolution
echo "2. Testing DNS resolution..."
echo "----------------------------------------"
if host $DB_HOST &> /dev/null || nslookup $DB_HOST &> /dev/null; then
    echo "  ✓ DNS resolution works"
    if command -v host &> /dev/null; then
        host $DB_HOST | head -3
    else
        nslookup $DB_HOST | head -5
    fi
else
    echo "  ✗ DNS resolution failed"
fi
echo ""

# Test 3: MySQL client test (if available)
echo "3. Testing MySQL connection..."
echo "----------------------------------------"
if command -v mysql &> /dev/null; then
    echo "  Attempting MySQL connection..."
    OUTPUT=$(timeout 10 mysql -h $DB_HOST -P $DB_PORT -u admin -pwelcome1 -e "SELECT 1;" 2>&1)
    MYSQL_EXIT=$?
    echo "$OUTPUT" | head -5
    if [ $MYSQL_EXIT -eq 0 ]; then
        echo "  ✓ MySQL connection successful"
    else
        echo "  ✗ MySQL connection failed"
    fi
else
    echo "  MySQL client not installed (this is OK, we're just testing connectivity)"
fi
echo ""

# Test 4: Check security groups (if AWS CLI available)
echo "4. Checking EC2 instance information..."
echo "----------------------------------------"
if command -v aws &> /dev/null; then
    INSTANCE_ID=$(curl -s http://169.254.169.254/latest/meta-data/instance-id 2>/dev/null)
    if [ -n "$INSTANCE_ID" ]; then
        echo "  Instance ID: $INSTANCE_ID"
        echo "  Security Groups:"
        aws ec2 describe-instances --instance-ids $INSTANCE_ID --query 'Reservations[0].Instances[0].SecurityGroups[*].[GroupId,GroupName]' --output table 2>/dev/null || echo "  (Could not retrieve security groups)"
    fi
else
    echo "  AWS CLI not available"
fi
echo ""

# Test 5: Check route to database
echo "5. Checking network route..."
echo "----------------------------------------"
echo "  Testing traceroute (first 3 hops)..."
if command -v traceroute &> /dev/null; then
    timeout 10 traceroute -m 3 $DB_HOST 2>&1 | head -5
elif command -v tracepath &> /dev/null; then
    timeout 10 tracepath $DB_HOST 2>&1 | head -5
else
    echo "  Traceroute not available"
fi
echo ""

echo "========================================="
echo "Diagnosis"
echo "========================================="
echo "If connection timeout occurs, check:"
echo ""
echo "1. RDS Security Group:"
echo "   - Must allow inbound MySQL (port 3306) from EC2 security group"
echo "   - Source should be EC2 security group ID, not IP address"
echo ""
echo "2. EC2 Security Group:"
echo "   - Must allow outbound to RDS (port 3306)"
echo "   - Or allow all outbound traffic"
echo ""
echo "3. Network ACLs:"
echo "   - Check if network ACLs are blocking traffic"
echo ""
echo "4. VPC/Subnet:"
echo "   - EC2 and RDS must be in same VPC or have VPC peering"
echo "   - Check route tables"
echo ""
echo "5. RDS Status:"
echo "   - Verify RDS instance is running and accessible"
echo "   - Check RDS endpoint is correct: $DB_HOST"
echo ""

