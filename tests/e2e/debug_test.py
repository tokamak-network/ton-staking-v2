"""
Debug test to understand server and Playwright connectivity
"""
import subprocess
import time
import os
import requests
import socket

def check_port(host, port):
    """Check if a port is open"""
    try:
        sock = socket.socket(socket.AF_INET, socket.SOCK_STREAM)
        sock.settimeout(2)
        result = sock.connect_ex((host, port))
        sock.close()
        return result == 0
    except Exception as e:
        return False

def test_connectivity():
    project_dir = os.path.dirname(os.path.dirname(os.path.dirname(os.path.abspath(__file__))))
    os.chdir(project_dir)

    print("="*60)
    print("DEBUG: Connectivity Test")
    print("="*60)

    # Check if port 3000 is already in use
    print("\n[1] Checking if port 3000 is already in use...")
    if check_port('127.0.0.1', 3000):
        print("  [OK] Port 3000 is open (server may already be running)")

        # Test with requests
        print("\n[2] Testing HTTP connection with requests...")
        try:
            response = requests.get('http://127.0.0.1:3000', timeout=5)
            print(f"  [OK] Requests: Status {response.status_code}")
        except Exception as e:
            print(f"  [FAIL] Requests failed: {e}")

        # Test with Playwright
        print("\n[3] Testing Playwright connection...")
        try:
            from playwright.sync_api import sync_playwright
            with sync_playwright() as p:
                print("  - Launching browser...")
                browser = p.firefox.launch(headless=True)
                page = browser.new_page()

                print("  - Attempting navigation...")
                try:
                    page.goto('http://127.0.0.1:3000', timeout=10000, wait_until='commit')
                    print("  [OK] Playwright navigation successful!")
                    page.screenshot(path='tests/e2e/screenshots/debug.png')
                    print("  [OK] Screenshot saved")
                except Exception as e:
                    print(f"  [FAIL] Playwright navigation failed: {e}")

                browser.close()
        except Exception as e:
            print(f"  [FAIL] Playwright error: {e}")

    else:
        print("  [FAIL] Port 3000 is not open")
        print("\n[2] Starting server...")

        # Start server
        server = subprocess.Popen(
            "npm run dev",
            shell=True,
            stdout=subprocess.PIPE,
            stderr=subprocess.STDOUT,
            cwd=project_dir
        )

        print("  Waiting for server...")
        for i in range(60):
            if check_port('127.0.0.1', 3000):
                print(f"  [OK] Server started after {i+1} seconds")
                break
            time.sleep(1)
        else:
            print("  [FAIL] Server did not start in 60 seconds")
            server.terminate()
            return

        # Give it extra time to fully initialize
        time.sleep(5)

        # Test with requests
        print("\n[3] Testing HTTP connection...")
        try:
            response = requests.get('http://127.0.0.1:3000', timeout=10)
            print(f"  [OK] Requests: Status {response.status_code}")
            print(f"  Response length: {len(response.text)} bytes")
        except Exception as e:
            print(f"  [FAIL] Requests failed: {e}")

        # Clean up
        server.terminate()
        try:
            server.wait(timeout=5)
        except:
            server.kill()
        print("\n[CLEANUP] Server stopped")

    print("\n" + "="*60)

if __name__ == "__main__":
    import os
    os.makedirs("tests/e2e/screenshots", exist_ok=True)
    test_connectivity()
