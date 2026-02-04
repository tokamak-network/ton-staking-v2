"""
E2E Test with automatic port selection
"""
import subprocess
import time
import os
import sys
import socket

def find_free_port(start=3001, end=3010):
    for port in range(start, end):
        try:
            sock = socket.socket(socket.AF_INET, socket.SOCK_STREAM)
            sock.bind(('127.0.0.1', port))
            sock.close()
            return port
        except:
            continue
    return None

def wait_for_server(port, timeout=60):
    import requests
    start = time.time()
    while time.time() - start < timeout:
        try:
            response = requests.get(f'http://127.0.0.1:{port}', timeout=2)
            if response.status_code == 200:
                return True
        except:
            pass
        time.sleep(1)
    return False

def run_tests():
    project_dir = os.path.dirname(os.path.dirname(os.path.dirname(os.path.abspath(__file__))))
    os.chdir(project_dir)
    os.makedirs("tests/e2e/screenshots", exist_ok=True)

    print("=" * 60)
    print("E2E TEST")
    print("=" * 60)

    # Find free port
    port = find_free_port()
    if not port:
        print("ERROR: No free port found")
        return 1

    print(f"Using port: {port}")

    # Start server
    print("Starting Next.js server...")
    server = subprocess.Popen(
        f"npx next dev -p {port}",
        shell=True,
        stdout=subprocess.PIPE,
        stderr=subprocess.STDOUT,
        cwd=project_dir
    )

    try:
        print("Waiting for server...")
        if not wait_for_server(port, timeout=90):
            print("ERROR: Server did not start")
            return 1

        print("Server ready!")
        base_url = f"http://127.0.0.1:{port}"

        # Run Playwright
        from playwright.sync_api import sync_playwright

        with sync_playwright() as p:
            print("Launching Chromium...")
            browser = p.chromium.launch(headless=True)
            page = browser.new_page()

            console_logs = []
            page.on("console", lambda msg: console_logs.append(f"[{msg.type}] {msg.text}"))

            # Test 1: Sequencers
            print("\n[TEST 1] Sequencers page...")
            page.goto(f"{base_url}/sequencers", timeout=30000, wait_until='domcontentloaded')
            time.sleep(3)
            page.screenshot(path='tests/e2e/screenshots/01_sequencers.png', full_page=True)
            print("  Screenshot: 01_sequencers.png")

            content = page.content()
            if "No sequencers" in content:
                print("  WARNING: No sequencers found")

            links = page.locator('a[href*="/sequencers/0x"]').all()
            print(f"  Found {len(links)} sequencer links")

            # Test 2: Dashboard
            print("\n[TEST 2] Dashboard page...")
            page.goto(f"{base_url}/dashboard", timeout=30000, wait_until='domcontentloaded')
            time.sleep(3)
            page.screenshot(path='tests/e2e/screenshots/02_dashboard.png', full_page=True)
            print("  Screenshot: 02_dashboard.png")

            # Test 3: Sequencer detail
            if links:
                print("\n[TEST 3] Sequencer detail...")
                href = links[0].get_attribute('href')
                page.goto(f"{base_url}{href}", timeout=30000, wait_until='domcontentloaded')
                time.sleep(3)
                page.screenshot(path='tests/e2e/screenshots/03_detail.png', full_page=True)
                print("  Screenshot: 03_detail.png")

            # Check errors
            errors = [l for l in console_logs if l.startswith("[error]")]
            print(f"\nConsole errors: {len(errors)}")
            for e in errors[:5]:
                print(f"  {e[:100]}")

            browser.close()

        print("\n" + "=" * 60)
        print("TEST COMPLETED - Screenshots in tests/e2e/screenshots/")
        print("=" * 60)
        return 0

    finally:
        print("\nStopping server...")
        server.terminate()
        try:
            server.wait(timeout=5)
        except:
            server.kill()

if __name__ == "__main__":
    sys.exit(run_tests())
