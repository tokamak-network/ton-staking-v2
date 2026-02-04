import csv
from datetime import datetime
import os

csv_path = r"c:\Users\cd476\Downloads\custom_export_2026-02-01_2026-02-04.csv"

if not os.path.exists(csv_path):
    print(f"File not found: {csv_path}")
    exit(1)

stats = {}

with open(csv_path, 'r', encoding='utf-8') as f:
    reader = csv.DictReader(f)
    for row in reader:
        # Check if type is commit
        if row.get('type') != 'commit':
            continue
            
        timestamp_str = row.get('timestamp')
        if not timestamp_str:
            continue

        try:
            # Format: 2026-02-01 12:33:42
            dt = datetime.strptime(timestamp_str, "%Y-%m-%d %H:%M:%S")
        except ValueError:
            continue
            
        # Filter for February 2026
        if dt.year == 2026 and dt.month == 2:
            name = row.get('member_name')
            if not name:
                name = "Unknown"
            
            try:
                additions = int(row.get('additions', 0))
            except ValueError:
                additions = 0
            
            try:
                deletions = int(row.get('deletions', 0))
            except ValueError:
                deletions = 0
                
            if name not in stats:
                stats[name] = {'commits': 0, 'additions': 0, 'deletions': 0}
            
            stats[name]['commits'] += 1
            stats[name]['additions'] += additions
            stats[name]['deletions'] += deletions

# Sort by additions desc
sorted_stats = sorted(stats.items(), key=lambda item: item[1]['additions'], reverse=True)

print("| Member Name | Feb Commits | Line Additions | Line Deletions |")
print("|---|---|---|---|")
for name, data in sorted_stats:
    print(f"| {name} | {data['commits']} | {data['additions']} | {data['deletions']} |")
