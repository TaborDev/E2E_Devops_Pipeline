import AWS from 'aws-sdk';

const s3 = new AWS.S3({
  endpoint: process.env.AWS_ENDPOINT || 'http://localhost:4566',
  s3ForcePathStyle: true,
  accessKeyId: 'test',
  secretAccessKey: 'test'
});
const BUCKET_NAME = process.env.ORDERS_BUCKET || 'techcommerce-dev-orders';

export async function saveOrder(order) {
  const params = {
    Bucket: BUCKET_NAME,
    Key: `order-${Date.now()}.json`,
    Body: JSON.stringify(order),
    ContentType: 'application/json'
  };
  return s3.upload(params).promise();
}

export async function getOrder(orderId) {
  const params = {
    Bucket: BUCKET_NAME,
    Key: orderId
  };
  const data = await s3.getObject(params).promise();
  return JSON.parse(data.Body.toString());
}
