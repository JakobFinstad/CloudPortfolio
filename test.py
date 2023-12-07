import unittest
from app import app

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

    def test_web_service_connection(self):
        # Ensure the Flask app is running and responds to requests
        response = self.app.get('/')
        self.assertEqual(response.status_code, 200)
        self.assertEqual(b'Hello World!  Im running inside a Docker container.', response.data)

if __name__ == '__main__':
    unittest.main()
