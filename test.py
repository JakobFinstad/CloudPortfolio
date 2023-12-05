import unittest
from app import app, redis

class TestApp(unittest.TestCase):

    def setUp(self):
        # Create a test client
        self.app = app.test_client()
        # Create a test context
        self.app_context = app.app_context()
        self.app_context.push()

    def tearDown(self):
        # Clean up the test context
        self.app_context.pop()

    def test_database_connection(self):
        # Ensure the connection to the Redis database is successful
        response = self.app.get('/')
        self.assertEqual(response.status_code, 200)
        self.assertIn(b'This webpage has been viewed', response.data)

    def test_web_service_connection(self):
        # Ensure the Flask app is running and responds to requests
        response = self.app.get('/')
        self.assertEqual(response.status_code, 200)
        self.assertIn(b'This webpage has been viewed', response.data)

if __name__ == '__main__':
    unittest.main()
