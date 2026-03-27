from flask import Flask
app = Flask(__name__)

@app.route("/")
def hello();
  return "Welcome to my world"

if __name__ == "__main__":
  appp.run(host="0.0.0.0", port=80)