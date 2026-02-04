"""
E2E Test for Dashboard and Sequencer pages
Tests data loading, wallet connection, and staking functionality
"""
from playwright.sync_api import sync_playwright, expect
import time
import json

def test_dashboard_and_sequencers():
    with sync_playwright() as p:
        browser = p.chromium.launch(headless=True)
        context = browser.new_context()

        # Capture console logs
        console_logs = []
        page = context.new_page()
        page.on("console", lambda msg: console_logs.append(f"[{msg.type}] {msg.text}"))

        print("\n" + "="*60)
        print("E2E TEST: Dashboard and Sequencers")
        print("="*60)

        # Test 1: Home page loads
        print("\n[TEST 1] Home page loads...")
        page.goto('http://localhost:3000', timeout=60000, wait_until='domcontentloaded')
        time.sleep(3)
        page.screenshot(path='tests/e2e/screenshots/01_home.png', full_page=True)
        print("  ✓ Home page loaded - screenshot saved")

        # Test 2: Sequencers page
        print("\n[TEST 2] Sequencers page loads...")
        page.goto('http://localhost:3000/sequencers', timeout=60000, wait_until='domcontentloaded')
        time.sleep(3)
        page.screenshot(path='tests/e2e/screenshots/02_sequencers.png', full_page=True)

        # Check for sequencer cards
        sequencer_cards = page.locator('[class*="SequencerCard"], .bg-slate-900\\/50').all()
        print(f"  Found {len(sequencer_cards)} sequencer cards")

        # Check page content
        page_content = page.content()
        if "No sequencers" in page_content:
            print("  ⚠ WARNING: No sequencers found - check if contract is deployed")
        else:
            print("  ✓ Sequencers page has content")

        # Test 3: Dashboard page (without wallet)
        print("\n[TEST 3] Dashboard page (no wallet)...")
        page.goto('http://localhost:3000/dashboard', timeout=60000, wait_until='domcontentloaded')
        time.sleep(3)
        page.screenshot(path='tests/e2e/screenshots/03_dashboard_no_wallet.png', full_page=True)

        # Check for wallet connect message
        if "Connect Your Wallet" in page.content():
            print("  ✓ Shows 'Connect Your Wallet' message correctly")
        else:
            print("  ⚠ Dashboard showing content without wallet connection")

        # Test 4: Check console for errors
        print("\n[TEST 4] Checking console logs...")
        errors = [log for log in console_logs if log.startswith("[error]")]
        warnings = [log for log in console_logs if log.startswith("[warning]")]

        if errors:
            print(f"  ⚠ Found {len(errors)} console errors:")
            for err in errors[:5]:  # Show first 5
                print(f"    - {err[:100]}...")
        else:
            print("  ✓ No console errors")

        if warnings:
            print(f"  ⚠ Found {len(warnings)} console warnings")

        # Test 5: Check network requests
        print("\n[TEST 5] Checking network requests to contracts...")

        # Reload with network monitoring
        requests_made = []
        page.on("request", lambda req: requests_made.append(req.url) if "localhost:8545" in req.url else None)

        page.goto('http://localhost:3000/sequencers', timeout=60000, wait_until='domcontentloaded')
        time.sleep(3)

        rpc_requests = [r for r in requests_made if "8545" in r]
        print(f"  Found {len(rpc_requests)} RPC requests to localhost:8545")

        if len(rpc_requests) == 0:
            print("  ⚠ WARNING: No RPC requests made - check wagmi config")

        # Test 6: Inspect DOM for data display
        print("\n[TEST 6] Inspecting DOM elements...")

        # Check for loading skeletons vs actual data
        skeletons = page.locator('.animate-pulse, [class*="Skeleton"]').all()
        print(f"  Found {len(skeletons)} skeleton/loading elements")

        # Check for specific data elements
        ton_values = page.locator('text=/\\d+(\\.\\d+)?\\s*TON/').all()
        print(f"  Found {len(ton_values)} TON value displays")

        # Test 7: Get page HTML structure for debugging
        print("\n[TEST 7] Page structure analysis...")

        # Check for specific components
        cards = page.locator('.bg-slate-900\\/50').all()
        print(f"  Card components: {len(cards)}")

        buttons = page.locator('button').all()
        print(f"  Button elements: {len(buttons)}")

        # Get text content of main area
        main_text = page.locator('main, [class*="container"]').first.text_content() if page.locator('main, [class*="container"]').count() > 0 else "No main container"
        print(f"  Main content preview: {main_text[:200] if main_text else 'Empty'}...")

        # Test 8: Try clicking a sequencer if available
        print("\n[TEST 8] Testing sequencer detail page...")

        # Look for links to sequencer detail
        sequencer_links = page.locator('a[href*="/sequencers/0x"]').all()
        if sequencer_links:
            print(f"  Found {len(sequencer_links)} sequencer links")
            first_link = sequencer_links[0]
            href = first_link.get_attribute('href')
            print(f"  Navigating to: {href}")

            page.goto(f'http://localhost:3000{href}', timeout=60000, wait_until='domcontentloaded')
            time.sleep(3)
            page.screenshot(path='tests/e2e/screenshots/04_sequencer_detail.png', full_page=True)

            # Check Your Position section
            your_position = page.locator('text="Your Position"').count()
            if your_position > 0:
                print("  ✓ 'Your Position' section found")

                # Check the values in Your Position
                position_section = page.locator('text="Your Position"').locator('..').locator('..')
                position_text = position_section.text_content() if position_section.count() > 0 else ""
                print(f"  Position content: {position_text[:150] if position_text else 'Empty'}...")
            else:
                print("  ⚠ 'Your Position' section not found")

            # Check Economics section
            economics = page.locator('text="Economics"').count()
            if economics > 0:
                print("  ✓ 'Economics' section found")
            else:
                print("  ⚠ 'Economics' section not found")
        else:
            print("  ⚠ No sequencer links found to test")

        # Summary
        print("\n" + "="*60)
        print("TEST SUMMARY")
        print("="*60)
        print(f"Console errors: {len(errors)}")
        print(f"Console warnings: {len(warnings)}")
        print(f"RPC requests: {len(rpc_requests)}")
        print("\nScreenshots saved to tests/e2e/screenshots/")
        print("="*60)

        # Print all console logs for debugging
        print("\n[DEBUG] All console logs:")
        for log in console_logs[-20:]:  # Last 20 logs
            print(f"  {log[:150]}")

        browser.close()

        return {
            "errors": len(errors),
            "warnings": len(warnings),
            "rpc_requests": len(rpc_requests),
        }

if __name__ == "__main__":
    import os
    os.makedirs("tests/e2e/screenshots", exist_ok=True)
    result = test_dashboard_and_sequencers()

    # Exit with error code if there are critical issues
    if result["rpc_requests"] == 0:
        print("\n❌ CRITICAL: No RPC requests made - wagmi config issue")
        exit(1)

    print("\n✓ Tests completed")
