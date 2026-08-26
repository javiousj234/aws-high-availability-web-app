from flask import Flask
import boto3
import json
import psycopg2
import socket
import os

app = Flask(__name__)

# Environment-specific configuration
SECRET_ARN = os.environ.get("SECRET_ARN")
REGION = os.environ.get("AWS_REGION", "us-east-1")
DB_HOST = os.environ.get("DB_HOST")
DB_NAME = os.environ.get("DB_NAME", "postgres")


def get_db_secret():
    """Retrieve PostgreSQL credentials from AWS Secrets Manager."""
    client = boto3.client("secretsmanager", region_name=REGION)

    response = client.get_secret_value(
        SecretId=SECRET_ARN
    )

    return json.loads(response["SecretString"])


@app.route("/")
def index():
    """Retrieve users from PostgreSQL and display them on the webpage."""

    secret = get_db_secret()

    conn = psycopg2.connect(
        host=DB_HOST,
        port=5432,
        dbname=DB_NAME,
        user=secret["username"],
        password=secret["password"]
    )

    cur = conn.cursor()

    cur.execute(
        "SELECT id, name, email FROM users;"
    )

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
