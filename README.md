# Use Cursor with a local LLM model

- If a Cursor Pro subscription is not available, you can use a local LLM model with Cursor.
- This setup requires a local LLM model, [ollama](https://ollama.com/), and [ngrok](https://ngrok.com/).

# Caveats and Limitations

Please note that this setup has some caveats:
- You can only the chat and the inline chat features (this includes the `Debug with AI` shortcut). However, keep in mind that your usage will be limited by the resources available on your local machine
- Special cursor-based interactions (like tab completion, composer, etc.) are not available in this setup.
- For tab completion, please see the [Continue project](https://github.com/continuedev/continue), as it might provide a solution for this issue.
- With the free version of ngrok, you will add the new subdomain to the Cursor settings every time you restart ngrok.

# LLM Installation

```bash
# Configuration
PROXY_PORT=11435
OLLAMA_PORT=11434
MODEL_NAME=llama3.1
NGROK_TOKEN=<ngrok_token>

# Install utilities
sudo apt install curl jq screen nginx

# Install ollama
curl -fsSL https://ollama.com/install.sh | sh    
# disable automatic start
sudo systemctl disable ollama
sudo systemctl stop ollama
# set the port if different from 11434
sudo nano /etc/systemd/system/ollama.service
# and add ENVIRONMENT="OLLAMA_HOST=127.0.0.1:<ollama_port (11434)>"

# Install ngrok
curl -sSL https://ngrok-agent.s3.amazonaws.com/ngrok.asc | gpg --dearmor | sudo tee /usr/share/keyrings/ngrok.gpg >/dev/null
echo "deb [signed-by=/usr/share/keyrings/ngrok.gpg] https://ngrok-agent.s3.amazonaws.com buster main" | sudo tee /etc/apt/sources.list.d/ngrok.list
sudo apt update
sudo apt install ngrok

# Reverse proxy for CORS support
cat <<EOF > /etc/nginx/sites-available/llm_proxy
server {
    listen $PROXY_PORT;
    location / {
        # Handle preflight OPTIONS requests
        if (\$request_method = OPTIONS) {
            add_header Allow "POST, OPTIONS";
            add_header Access-Control-Allow-Origin "*";
            add_header Access-Control-Allow-Headers "authorization, content-type";
            add_header Access-Control-Allow-Methods "POST, OPTIONS";
            add_header Access-Control-Max-Age 86400;
            return 204;
        }

        # Remove or modify the Origin header before forwarding the request
        proxy_set_header Origin "";

        # Forward other requests to backend server
        proxy_pass http://localhost:$OLLAMA_PORT;
        
        # Include additional headers for CORS support in normal requests
        add_header Access-Control-Allow-Origin "*";
        add_header Access-Control-Allow-Headers "authorization, content-type";
        add_header Access-Control-Allow-Methods "POST, OPTIONS";
    }
}
EOF
sudo ln -s /etc/nginx/sites-available/llm_proxy /etc/nginx/sites-enabled/llm_proxy

sudo nginx -t
sudo systemctl restart nginx

# add token to ngrok
ngrok config add-authtoken $NGROK_TOKEN

# download the model
ollama pull $MODEL_NAME
```

# Start the setup

```bash
# Start a model
sudo systemctl start ollama

# Start ngrok (in a detached screen)
screen -S ngroky -d -m ngrok http $PROXY_PORT --host-header="localhost:$OLLAMA_PORT"

# test the llm and get the public URL
bash test_llm.sh

# add the public URL to Cursor -> see Cursor Configuration
```

# Cursor Configuration

1. Cursor Settings > Models > Model Names > Add `$MODEL_NAME` as model to Cursor
2. Cursor Settings > OpenAI API Key > Enable
3. Cursor Settings > OpenAI API Key > Override OpenAI Base URL > Add `$PUBLIC_URL` > Save
4. Cursor Settings > OpenAI API Key > Add arbitrary string as OpenAI API key > Verify
5. Use `$MODEL_NAME` as Chat Model

# Stop the setup

```bash
# to stop ngrok
screen -S ngroky -X quit

# to stop ollama
sudo systemctl stop ollama
```

# TODO

- reimplement the security features of the CORS proxy
- write start and stop as service or cli tool