from app import app

def test_health():
    client = app.test_client()
    r = client.get('/healthz')
    assert r.status_code == 200