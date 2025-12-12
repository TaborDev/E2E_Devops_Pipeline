import os
import boto3
from botocore.exceptions import ClientError
from datetime import datetime
from decimal import Decimal
import json

# Custom JSON encoder to handle Decimal types
class DecimalEncoder(json.JSONEncoder):
    def default(self, obj):
        if isinstance(obj, Decimal):
            return float(obj)
        return super(DecimalEncoder, self).default(obj)

# Initialize DynamoDB client
dynamodb = boto3.resource(
    'dynamodb',
    endpoint_url=os.getenv('DYNAMODB_ENDPOINT', 'http://localhost:4566'),
    region_name='us-east-1',
    aws_access_key_id='test',
    aws_secret_access_key='test'
)

# Get the table name from environment variables
TABLE_NAME = os.getenv('PRODUCTS_TABLE', 'techcommerce-products-dev')

# Initialize the table
table = dynamodb.Table(TABLE_NAME)

def convert_floats_to_decimals(obj):
    """Recursively convert float values to Decimal for DynamoDB"""
    if isinstance(obj, dict):
        return {k: convert_floats_to_decimals(v) for k, v in obj.items()}
    elif isinstance(obj, list):
        return [convert_floats_to_decimals(v) for v in obj]
    elif isinstance(obj, float):
        return Decimal(str(obj))
    return obj

def create_product(product_data):
    """Create a new product in DynamoDB"""
    try:
        # Convert any float values to Decimal
        product_data = convert_floats_to_decimals(product_data)
        
        # Add timestamps
        now = datetime.utcnow().isoformat()
        product_data['createdAt'] = now
        product_data['updatedAt'] = now
        
        # Ensure required fields
        if 'id' not in product_data:
            raise ValueError("Product ID is required")
            
        response = table.put_item(Item=product_data)
        return product_data
    except ClientError as e:
        raise Exception(f"DynamoDB error: {e.response['Error']['Message']}")
    except Exception as e:
        raise Exception(f"Error creating product: {str(e)}")

def get_product(product_id):
    """Get a product by ID"""
    try:
        response = table.get_item(Key={'id': product_id})
        item = response.get('Item')
        # Convert Decimal to float for JSON serialization
        if item:
            return json.loads(json.dumps(item, cls=DecimalEncoder))
        return None
    except ClientError as e:
        if e.response['Error']['Code'] == 'ResourceNotFoundException':
            return None
        raise Exception(f"DynamoDB error: {e.response['Error']['Message']}")

def list_products():
    """List all products"""
    try:
        response = table.scan()
        items = response.get('Items', [])
        # Convert Decimal to float for JSON serialization
        return json.loads(json.dumps(items, cls=DecimalEncoder))
    except ClientError as e:
        raise Exception(f"DynamoDB error: {e.response['Error']['Message']}")

def update_product(product_id, update_data):
    """Update a product"""
    try:
        # Convert any float values to Decimal
        update_data = convert_floats_to_decimals(update_data)
        
        # Update timestamps
        update_data['updatedAt'] = datetime.utcnow().isoformat()
        
        # Prepare update expression
        update_expression = "SET " + ", ".join([f"#{k} = :{k}" for k in update_data.keys()])
        expression_attribute_names = {f"#{k}": k for k in update_data.keys()}
        expression_attribute_values = {f":{k}": v for k, v in update_data.items()}
        
        response = table.update_item(
            Key={'id': product_id},
            UpdateExpression=update_expression,
            ExpressionAttributeNames=expression_attribute_names,
            ExpressionAttributeValues=expression_attribute_values,
            ReturnValues="ALL_NEW"
        )
        # Convert Decimal to float for JSON serialization
        if 'Attributes' in response:
            return json.loads(json.dumps(response['Attributes'], cls=DecimalEncoder))
        return None
    except ClientError as e:
        if e.response['Error']['Code'] == 'ResourceNotFoundException':
            return None
        raise Exception(f"DynamoDB error: {e.response['Error']['Message']}")

def delete_product(product_id):
    """Delete a product"""
    try:
        response = table.delete_item(
            Key={'id': product_id},
            ReturnValues="ALL_OLD"
        )
        # Convert Decimal to float for JSON serialization
        if 'Attributes' in response:
            return json.loads(json.dumps(response['Attributes'], cls=DecimalEncoder))
        return None
    except ClientError as e:
        if e.response['Error']['Code'] == 'ResourceNotFoundException':
            return None
        raise Exception(f"DynamoDB error: {e.response['Error']['Message']}")
