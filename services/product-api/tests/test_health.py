import sys
import os
sys.path.append(os.path.dirname(os.path.dirname(os.path.abspath(__file__))))

from app import app

def test_health():
    client = app.test_client()
    r = client.get('/healthz')
    assert r.status_code == 200