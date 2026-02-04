"""Quick E2E test for port 4000"""
import time
import os
from playwright.sync_api import sync_playwright

os.makedirs("tests/e2e/screenshots", exist_ok=True)
BASE = "http://127.0.0.1:4000"

print("Starting E2E test on port 4000...")

with sync_playwright() as p:
    # Use chromium with no-sandbox for Windows compatibility
    browser = p.chromium.launch(
        headless=True,
        args=['--no-sandbox', '--disable-setuid-sandbox', '--disable-dev-shm-usage']
    )
    page = browser.new_page()

    logs = []
    page.on("console", lambda m: logs.append(f"[{m.type}] {m.text}"))

    # Test 1: Sequencers
    print("\n[1] Sequencers page...")
    page.goto(f"{BASE}/sequencers", timeout=30000, wait_until='domcontentloaded')
    time.sleep(3)
    page.screenshot(path='tests/e2e/screenshots/01_sequencers.png', full_page=True)

    links = page.locator('a[href*="/sequencers/0x"]').all()
    print(f"    Found {len(links)} sequencer links")

    # Store the href before navigating away
    first_sequencer_href = links[0].get_attribute('href') if links else None

    # Test 2: Dashboard
    print("[2] Dashboard page...")
    page.goto(f"{BASE}/dashboard", timeout=30000, wait_until='domcontentloaded')
    time.sleep(3)
    page.screenshot(path='tests/e2e/screenshots/02_dashboard.png', full_page=True)

    # Test 3: Sequencer detail
    if first_sequencer_href:
        print("[3] Sequencer detail...")
        page.goto(f"{BASE}{first_sequencer_href}", timeout=30000, wait_until='domcontentloaded')
        time.sleep(3)
        page.screenshot(path='tests/e2e/screenshots/03_detail.png', full_page=True)

    # Errors
    errors = [l for l in logs if "[error]" in l.lower()]
    print(f"\nConsole errors: {len(errors)}")
    for e in errors[:5]:
        print(f"  {e[:100]}")

    browser.close()

print("\nDone! Screenshots in tests/e2e/screenshots/")
