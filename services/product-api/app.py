from flask import Flask, jsonify
import os, time

app = Flask(__name__)

@app.get('/healthz')
def health():
    return jsonify({ 'status': 'ok' })

@app.get('/livez')
def live():
    return jsonify({ 'live': True })

@app.get('/products')
def products():
    # placeholder data
    return jsonify([
        { 'id': 1, 'name': 'Widget', 'price': 9.99 },
        { 'id': 2, 'name': 'Gadget', 'price': 14.99 }
    ])

if __name__ == '__main__':
    port = int(os.getenv('PORT', 5000))
    app.run(host='0.0.0.0', port=port)