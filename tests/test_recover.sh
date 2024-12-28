RESPONSE=$(curl -s -v -X POST http://143.198.177.105:3000/api/form-submit -H "Content-Type: application/json" -d '{"body": { "query": "SELECT * FROM users WHERE email = \"johndoe@example.com\"}}')
echo "{Response: $RESPONSE}"
