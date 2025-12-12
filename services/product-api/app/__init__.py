from flask import Flask
from flask_cors import CORS
from .routes.products import bp as products_bp

def create_app():
    app = Flask(__name__)
    
    # Enable CORS
    CORS(app)
    
    # Register blueprints
    app.register_blueprint(products_bp, url_prefix='/api')
    
    # Health check endpoint
    @app.route('/health')
    def health_check():
        return {'status': 'OK'}, 200
    
    return app
