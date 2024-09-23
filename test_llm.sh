if [ "$#" -ne 1 ]; then
    echo "Usage: test_llm.sh <model_name>"
    exit 1
fi

MODEL_NAME=$1

NGROK_URL=$(curl -sS http://127.0.0.1:4040/api/tunnels | jq -r ".tunnels[0].public_url")

if [ -z "$NGROK_URL" ]; then
    echo "Failed to get the ngrok URL!"
    exit 1
fi

response=$(curl -sS $NGROK_URL/v1/chat/completions -H "Content-Type: application/json" -H "Authorization: Bearer 0000" \
-d '{
    "model":"'$MODEL_NAME'",
    "messages":[
        {
            "role":"system",
            "content":"You are a helpful assistant."
        },{
            "role":"user",
            "content":"Test prompt."}
        ],
        "temperature":1,
        "max_tokens":10,
        "stream":false
}' 2>&1)

if [ $? -ne 0 ]; then
    echo "Failed to send a test request!"
    echo $response
    exit 1
fi

echo "Test request sent successfully!"
echo "Caveats: If only one model is available, any model name will work."
echo "Add the following URL to the Cursor app:"
echo $NGROK_URL/v1