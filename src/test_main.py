from src.main import app
from fastapi.testclient import TestClient

# Create a TestClient instance
client = TestClient(app)

def test_read_root():
    # Send a GET request to the root endpoint
    response = client.get("/")
    
    # Assert the status code is 200 OK
    assert response.status_code == 200
    
    # Assert the returned JSON is correct
    assert response.json() == {"message": "Hello, World!"}

def test_greet():
    # Test the /greet/{name} endpoint with a dynamic name
    response = client.get("/greet/John")
    
    # Assert the status code is 200 OK
    assert response.status_code == 200
    
    # Assert the returned JSON is correct
    assert response.json() == {"message": "Hello, John!"}
