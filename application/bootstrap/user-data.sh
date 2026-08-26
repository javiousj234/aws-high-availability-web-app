#!/bin/bash
set -e

# ----------------------------
# 1. Install required packages
# ----------------------------
dnf update -y
dnf install -y nginx python3-pip

pip3 install flask boto3 psycopg2-binary

# ----------------------------
# 2. Create application environment
# ----------------------------
cat > /etc/jvs-app.env <<'ENVVARS'
SECRET_ARN=YOUR_SECRET_ARN
AWS_REGION=us-east-1
DB_HOST=YOUR_RDS_ENDPOINT
DB_NAME=postgres
ENVVARS

chmod 600 /etc/jvs-app.env

# ----------------------------
# 3. Create Flask application
# ----------------------------
cat > /home/ec2-user/app.py <<'PYTHON'
from flask import Flask
import boto3
import json
import psycopg2
import socket
import os

app = Flask(__name__)

SECRET_ARN = os.environ.get("SECRET_ARN")
REGION = os.environ.get("AWS_REGION", "us-east-1")
DB_HOST = os.environ.get("DB_HOST")
DB_NAME = os.environ.get("DB_NAME", "postgres")


def get_db_secret():
    client = boto3.client("secretsmanager", region_name=REGION)
    response = client.get_secret_value(SecretId=SECRET_ARN)
    return json.loads(response["SecretString"])


@app.route("/")
def index():
    secret = get_db_secret()

    conn = psycopg2.connect(
        host=DB_HOST,
        port=5432,
        dbname=DB_NAME,
        user=secret["username"],
        password=secret["password"]
    )

    cur = conn.cursor()
    cur.execute("SELECT id, name, email FROM users;")
    rows = cur.fetchall()

    cur.close()
    conn.close()

    hostname = socket.gethostname()

    output = "<h1>Cloud Architecture Project</h1>"
    output += f"<p>Served by: {hostname}</p>"
    output += "<h2>Database Users</h2>"

    for row in rows:
        output += f"<p>{row[0]} - {row[1]} - {row[2]}</p>"

    return output


if __name__ == "__main__":
    app.run(host="127.0.0.1", port=8080)
PYTHON

chown ec2-user:ec2-user /home/ec2-user/app.py

# ----------------------------
# 4. Create systemd service
# ----------------------------
cat > /etc/systemd/system/jvs-app.service <<'SERVICE'
[Unit]
Description=JVS Flask Application
After=network-online.target
Wants=network-online.target

[Service]
User=ec2-user
WorkingDirectory=/home/ec2-user
EnvironmentFile=/etc/jvs-app.env
ExecStart=/usr/bin/python3 /home/ec2-user/app.py
Restart=always
RestartSec=5

[Install]
WantedBy=multi-user.target
SERVICE

# ----------------------------
# 5. Configure Nginx
# ----------------------------
cat > /etc/nginx/conf.d/jvs-app.conf <<'NGINX'
server {
    listen 80;
    server_name _;

    location / {
        proxy_pass http://127.0.0.1:8080;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
    }
}
NGINX

sed -i '/^    server {/,/^    }/d' /etc/nginx/nginx.conf || true

# ----------------------------
# 6. Start application services
# ----------------------------
systemctl daemon-reload

systemctl enable jvs-app
systemctl start jvs-app

nginx -t

systemctl enable nginx
systemctl restart nginx
