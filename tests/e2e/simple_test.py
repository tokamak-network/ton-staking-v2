from playwright.sync_api import sync_playwright

print("Starting Playwright test...")

with sync_playwright() as p:
    print("Launching browser...")
    browser = p.chromium.launch(headless=True)
    print("Browser launched")

    page = browser.new_page()
    print("Page created")

    try:
        print("Navigating to localhost:3000...")
        response = page.goto('http://localhost:3000', timeout=30000, wait_until='commit')
        print(f"Response status: {response.status if response else 'No response'}")

        print("Taking screenshot...")
        page.screenshot(path='tests/e2e/screenshots/simple_test.png')
        print("Screenshot saved")

    except Exception as e:
        print(f"Error: {e}")

        # Try with 127.0.0.1 instead
        print("\nTrying with 127.0.0.1...")
        try:
            response = page.goto('http://127.0.0.1:3000', timeout=30000, wait_until='commit')
            print(f"Response status: {response.status if response else 'No response'}")
            page.screenshot(path='tests/e2e/screenshots/simple_test_127.png')
            print("Screenshot saved")
        except Exception as e2:
            print(f"Error with 127.0.0.1: {e2}")

    browser.close()
    print("Test complete")
