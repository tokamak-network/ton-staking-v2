"""Demo video recording script using Playwright"""
import time
from playwright.sync_api import sync_playwright

BASE = "http://127.0.0.1:3000"
VIDEO_DIR = "tests/e2e/videos"

def record_demo():
    print("Starting demo video recording...")
    print(f"Video will be saved to: {VIDEO_DIR}/")

    with sync_playwright() as p:
        # Launch browser with video recording
        browser = p.chromium.launch(
            headless=True,
            args=['--no-sandbox', '--disable-setuid-sandbox']
        )

        # Create context with video recording
        context = browser.new_context(
            record_video_dir=VIDEO_DIR,
            record_video_size={"width": 1280, "height": 720},
            viewport={"width": 1280, "height": 720}
        )

        page = context.new_page()

        try:
            # Scene 1: Home page
            print("\n[Scene 1] Home page...")
            page.goto(f"{BASE}/", wait_until='networkidle', timeout=30000)
            time.sleep(2)

            # Scene 2: Navigate to Sequencers
            print("[Scene 2] Sequencers page...")
            page.click('text=Sequencers')
            page.wait_for_load_state('networkidle')
            time.sleep(3)

            # Scroll to show content
            page.evaluate("window.scrollBy(0, 300)")
            time.sleep(1)
            page.evaluate("window.scrollBy(0, -300)")
            time.sleep(1)

            # Scene 3: Click on first sequencer
            print("[Scene 3] Sequencer detail page...")
            sequencer_links = page.locator('a[href*="/sequencers/0x"]').all()
            if sequencer_links:
                sequencer_links[0].click()
                page.wait_for_load_state('networkidle')
                time.sleep(2)

                # Scroll to show all sections
                page.evaluate("window.scrollBy(0, 400)")
                time.sleep(2)
                page.evaluate("window.scrollBy(0, 400)")
                time.sleep(2)
                page.evaluate("window.scrollTo(0, 0)")
                time.sleep(1)

            # Scene 4: Dashboard
            print("[Scene 4] Dashboard page...")
            page.click('text=Dashboard')
            page.wait_for_load_state('networkidle')
            time.sleep(3)

            # Scene 5: Back to Sequencers and show second one
            print("[Scene 5] Second sequencer...")
            page.click('text=Sequencers')
            page.wait_for_load_state('networkidle')
            time.sleep(2)

            sequencer_links = page.locator('a[href*="/sequencers/0x"]').all()
            if len(sequencer_links) > 1:
                sequencer_links[1].click()
                page.wait_for_load_state('networkidle')
                time.sleep(2)
                page.evaluate("window.scrollBy(0, 500)")
                time.sleep(2)

            # Final pause
            time.sleep(2)

            print("\nRecording completed!")

        except Exception as e:
            print(f"Error during recording: {e}")

        finally:
            # Close context to save video
            context.close()
            browser.close()

    print(f"\nVideo saved to: {VIDEO_DIR}/")
    print("Note: Video file will have a random name like '*.webm'")

if __name__ == "__main__":
    record_demo()
