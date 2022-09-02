from flask import Flask
import sys

app = Flask(__name__)

@app.route('/')
def hello_world():
    
    out = ""
    
    with open("/home/bzaleski/.humer/readings", 'r') as fin:
        out += fin.read()
    
    return out

if __name__ == '__main__':
    app.run()
