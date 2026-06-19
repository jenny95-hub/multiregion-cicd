from flask import Flask, render_template
from datetime import datetime
import os

app = Flask(__name__)

@app.route("/")
def home():

    data = {
        "application": "CloudOps Dashboard",
        "environment": "Production",
        "region": os.getenv("AWS_REGION", "ap-south-1"),
        "version": "v1.0.0",
        "deployment_time": datetime.now().strftime("%Y-%m-%d %H:%M:%S"),
        "status": "Healthy",
        "pipeline": "Successful"
    }

    return render_template("index.html", data=data)

if __name__ == "__main__":

    app.run(host="0.0.0.0", port=5000)
