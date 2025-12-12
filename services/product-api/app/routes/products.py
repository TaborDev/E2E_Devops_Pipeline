from flask import Blueprint, request, jsonify
from app.services import product_service

bp = Blueprint('products', __name__)

@bp.route('/products', methods=['POST'])
def create_product():
    try:
        product = request.get_json()
        if not product:
            return jsonify({'error': 'No product data provided'}), 400
            
        result = product_service.create_product(product)
        return jsonify(result), 201
    except Exception as e:
        return jsonify({'error': str(e)}), 400

@bp.route('/products/<product_id>', methods=['GET'])
def get_product(product_id):
    try:
        product = product_service.get_product(product_id)
        if product:
            return jsonify(product)
        return jsonify({'error': 'Product not found'}), 404
    except Exception as e:
        return jsonify({'error': str(e)}), 400

@bp.route('/products', methods=['GET'])
def list_products():
    try:
        products = product_service.list_products()
        return jsonify(products)
    except Exception as e:
        return jsonify({'error': str(e)}), 400

@bp.route('/products/<product_id>', methods=['PUT'])
def update_product(product_id):
    try:
        update_data = request.get_json()
        if not update_data:
            return jsonify({'error': 'No update data provided'}), 400
            
        updated = product_service.update_product(product_id, update_data)
        if updated:
            return jsonify(updated)
        return jsonify({'error': 'Product not found'}), 404
    except Exception as e:
        return jsonify({'error': str(e)}), 400

@bp.route('/products/<product_id>', methods=['DELETE'])
def delete_product(product_id):
    try:
        deleted = product_service.delete_product(product_id)
        if deleted:
            return jsonify({'message': 'Product deleted successfully'})
        return jsonify({'error': 'Product not found'}), 404
    except Exception as e:
        return jsonify({'error': str(e)}), 400
