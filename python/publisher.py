from flask import Flask
import sys

app = Flask(__name__)

@app.route('/bathroom')
def hello_world():
    
    out = ""
    
    with open("/home/bzaleski/.humer/bathroom", 'r') as fin:
        out += fin.read()
    
    return out

if __name__ == '__main__':
    app.run()
