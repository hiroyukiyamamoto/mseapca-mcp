"""Read-only live MCP checks for immune catalog and direction-specific ORA."""
import json
import os
from pathlib import Path
import time
import urllib.request

endpoint = os.environ.get('MCP_ENDPOINT', 'https://mseapca-mcp-121643671058.asia-northeast1.run.app/mcp')

def call(name, arguments):
    time.sleep(1.1)
    payload = dict(jsonrpc='2.0', id=1, method='tools/call', params=dict(name=name, arguments=arguments))
    request = urllib.request.Request(endpoint, data=json.dumps(payload).encode(),
        headers={'Content-Type':'application/json', 'Accept':'application/json, text/event-stream'})
    with urllib.request.urlopen(request, timeout=35) as response:
        result = json.load(response)
    assert 'error' not in result, result
    result = result['result']
    assert not result.get('isError'), result
    decoded = json.loads(result['content'][0]['text'])
    assert decoded['ok'], decoded
    return decoded

catalog = call('catalog_info', {})['database']
assert catalog['retained_records'] == 5324
assert catalog['source_counts']['ImmuneCellMetabolomics'] == 583
found = call('search_sets', {'source':'ImmuneCellMetabolomics', 'limit':2})
assert found['total'] == 583
ids = ['IMMUNE_ST001283_AN002127_C180_UP', 'IMMUNE_ST001283_AN002127_C180_DOWN']
sets = call('get_sets', {'set_ids':ids, 'identifier':'name', 'max_members':500})['sets']
detected = sorted({member for record in sets for member in record['members']})
up = ['glucose-6-phosphate', 'glutamine', 'cystine']
down = ['aspartic acid', 'myo-inositol']
assert set(up) <= set(sets[0]['members'])
assert set(down) <= set(sets[1]['members'])
results = {}
for direction, significant in [('UP',up), ('DOWN',down)]:
    result = call('analyze_ora', dict(significant=significant, detected=detected, set_ids=ids, identifier='name'))
    assert len(result['results']) == 2
    overlaps = {row['set_id']:row['overlap_count'] for row in result['results']}
    assert overlaps[ids[0]] == (3 if direction == 'UP' else 0), overlaps
    assert overlaps[ids[1]] == (2 if direction == 'DOWN' else 0), overlaps
    results[direction] = result
report = dict(endpoint=endpoint, catalog_sets=5324, immune_sets=583,
    note='Test background is the union of these two sets, not a real measured experiment background.', ora=results)
Path('test-results').mkdir(exist_ok=True)
Path('test-results/immune-http.json').write_text(json.dumps(report, indent=2), encoding='utf8')
print(json.dumps(report, indent=2))
