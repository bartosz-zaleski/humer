from flask import Flask
import sys

app = Flask(__name__)

@app.route('/Bathroom')
def bathroom():
    
    out = ""
    
    with open("/home/bzaleski/.humer/Bathroom", 'r') as fin:
        out += fin.read()
    
    return out

@app.route('/Kitchen')
def kitchen():
    
    out = ""
    
    with open("/home/bzaleski/.humer/Kitchen", 'r') as fin:
        out += fin.read()
    
    return out

@app.route('/Livingroom')
def livingroom():
    
    out = ""
    
    with open("/home/bzaleski/.humer/Livingroom", 'r') as fin:
        out += fin.read()
    
    return out
    
@app.route('/Bedroom')
def bedroom():
    
    out = ""
    
    with open("/home/bzaleski/.humer/Bedroom", 'r') as fin:
        out += fin.read()
    
    return out

if __name__ == '__main__':
    app.run()
