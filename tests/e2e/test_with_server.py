"""
E2E Test that manages its own server
"""
import subprocess
import time
import sys
import os
import signal
import requests
from playwright.sync_api import sync_playwright

def wait_for_server(url, timeout=60):
    """Wait for server to be ready"""
    start = time.time()
    while time.time() - start < timeout:
        try:
            response = requests.get(url, timeout=2)
            if response.status_code == 200:
                return True
        except:
            pass
        time.sleep(1)
    return False

def run_tests():
    # Change to project directory
    project_dir = os.path.dirname(os.path.dirname(os.path.dirname(os.path.abspath(__file__))))
    os.chdir(project_dir)

    print("="*60)
    print("E2E TEST: Dashboard and Sequencers")
    print("="*60)
    print(f"\nProject directory: {project_dir}")

    # Start the server
    print("\n[SETUP] Starting Next.js dev server...")

    # Use shell=True on Windows for npm commands
    server_process = subprocess.Popen(
        "npm run dev",
        shell=True,
        stdout=subprocess.PIPE,
        stderr=subprocess.STDOUT,
        cwd=project_dir,
    )

    try:
        # Wait for server
        print("[SETUP] Waiting for server to be ready...")
        if not wait_for_server("http://127.0.0.1:3000", timeout=60):
            print("ERROR: Server did not start in time")
            return 1

        print("[SETUP] Server is ready!")

        # Run Playwright tests
        with sync_playwright() as p:
            # Try Firefox instead of Chromium for better localhost handling
            print("[SETUP] Launching Firefox browser...")
            browser = p.firefox.launch(headless=True)
            context = browser.new_context()

            # Capture console logs
            console_logs = []
            page = context.new_page()
            page.on("console", lambda msg: console_logs.append(f"[{msg.type}] {msg.text}"))

            # Test 1: Sequencers page
            print("\n[TEST 1] Loading Sequencers page...")
            page.goto('http://127.0.0.1:3000/sequencers', timeout=30000, wait_until='domcontentloaded')
            time.sleep(3)

            os.makedirs("tests/e2e/screenshots", exist_ok=True)
            page.screenshot(path='tests/e2e/screenshots/01_sequencers.png', full_page=True)
            print("  Screenshot saved: 01_sequencers.png")

            # Check for sequencer content
            page_content = page.content()
            if "No sequencers" in page_content:
                print("  ⚠ No sequencers found - contract may not be deployed")
            else:
                print("  ✓ Page loaded with content")

            # Check for sequencer addresses
            sequencer_links = page.locator('a[href*="/sequencers/0x"]').all()
            print(f"  Found {len(sequencer_links)} sequencer links")

            # Test 2: Dashboard page
            print("\n[TEST 2] Loading Dashboard page...")
            page.goto('http://127.0.0.1:3000/dashboard', timeout=30000, wait_until='domcontentloaded')
            time.sleep(3)
            page.screenshot(path='tests/e2e/screenshots/02_dashboard.png', full_page=True)
            print("  Screenshot saved: 02_dashboard.png")

            # Check dashboard content
            dashboard_content = page.content()
            if "Connect Your Wallet" in dashboard_content:
                print("  ✓ Shows 'Connect Your Wallet' message (no wallet connected)")
            elif "Total Staked" in dashboard_content:
                print("  ✓ Dashboard showing staking data")

            # Test 3: Sequencer detail page (if available)
            if sequencer_links:
                print("\n[TEST 3] Loading Sequencer detail page...")
                first_link = sequencer_links[0]
                href = first_link.get_attribute('href')
                print(f"  Navigating to: {href}")

                page.goto(f'http://127.0.0.1:3000{href}', timeout=30000, wait_until='domcontentloaded')
                time.sleep(3)
                page.screenshot(path='tests/e2e/screenshots/03_sequencer_detail.png', full_page=True)
                print("  Screenshot saved: 03_sequencer_detail.png")

                detail_content = page.content()
                if "Your Position" in detail_content:
                    print("  ✓ 'Your Position' section found")
                if "Economics" in detail_content:
                    print("  ✓ 'Economics' section found")
                if "Total Staked" in detail_content:
                    print("  ✓ 'Total Staked' info found")
            else:
                print("\n[TEST 3] Skipped - no sequencers available")

            # Test 4: Check console errors
            print("\n[TEST 4] Checking console logs...")
            errors = [log for log in console_logs if log.startswith("[error]")]
            if errors:
                print(f"  ⚠ Found {len(errors)} console errors:")
                for err in errors[:5]:
                    print(f"    - {err[:100]}")
            else:
                print("  ✓ No console errors")

            # Print all console logs for debugging
            print("\n[DEBUG] Recent console logs:")
            for log in console_logs[-15:]:
                print(f"  {log[:150]}")

            browser.close()

        print("\n" + "="*60)
        print("TEST COMPLETED")
        print("Screenshots saved to tests/e2e/screenshots/")
        print("="*60)
        return 0

    finally:
        # Stop the server
        print("\n[CLEANUP] Stopping server...")
        server_process.terminate()
        try:
            server_process.wait(timeout=5)
        except subprocess.TimeoutExpired:
            server_process.kill()
        print("[CLEANUP] Server stopped")

if __name__ == "__main__":
    sys.exit(run_tests())
