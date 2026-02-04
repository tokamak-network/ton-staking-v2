"""Debug script to check dashboard data"""
from playwright.sync_api import sync_playwright
import time

BASE = "http://127.0.0.1:3000"

def debug_dashboard():
    print("Starting debug session...")

    with sync_playwright() as p:
        browser = p.chromium.launch(headless=True)
        context = browser.new_context(
            viewport={"width": 1280, "height": 720}
        )
        page = context.new_page()

        # Enable console logging
        page.on("console", lambda msg: print(f"[CONSOLE] {msg.type}: {msg.text}"))
        page.on("pageerror", lambda err: print(f"[PAGE ERROR] {err}"))

        try:
            # Go to dashboard
            print("\n[1] Going to dashboard...")
            page.goto(f"{BASE}/dashboard", wait_until='networkidle', timeout=30000)
            time.sleep(2)

            # Check if wallet connect prompt is showing
            page.screenshot(path="tests/e2e/screenshots/debug_01_dashboard.png")
            print("Screenshot saved: debug_01_dashboard.png")

            # Check page content
            content = page.content()
            if "Connect Your Wallet" in content:
                print("[INFO] Dashboard shows 'Connect Your Wallet' - not connected")

            # Go to sequencers page
            print("\n[2] Going to sequencers page...")
            page.goto(f"{BASE}/sequencers", wait_until='networkidle', timeout=30000)
            time.sleep(2)
            page.screenshot(path="tests/e2e/screenshots/debug_02_sequencers.png")
            print("Screenshot saved: debug_02_sequencers.png")

            # Find sequencer links
            sequencer_links = page.locator('a[href*="/sequencers/0x"]').all()
            print(f"[INFO] Found {len(sequencer_links)} sequencer links")

            if sequencer_links:
                # Click first sequencer
                print("\n[3] Going to first sequencer detail...")
                sequencer_links[0].click()
                page.wait_for_load_state('networkidle')
                time.sleep(2)
                page.screenshot(path="tests/e2e/screenshots/debug_03_sequencer_detail.png")
                print("Screenshot saved: debug_03_sequencer_detail.png")

                # Check the URL
                print(f"[INFO] Current URL: {page.url}")

                # Look for staking data in the page
                page_text = page.inner_text('body')
                if "Total Staked" in page_text:
                    print("[INFO] 'Total Staked' text found on page")
                if "Your Position" in page_text:
                    print("[INFO] 'Your Position' text found on page")
                if "Estimated Seigniorage" in page_text:
                    print("[INFO] 'Estimated Seigniorage' text found on page")

            print("\nDebug session completed.")

        except Exception as e:
            print(f"Error: {e}")
            page.screenshot(path="tests/e2e/screenshots/debug_error.png")

        finally:
            context.close()
            browser.close()

if __name__ == "__main__":
    debug_dashboard()
