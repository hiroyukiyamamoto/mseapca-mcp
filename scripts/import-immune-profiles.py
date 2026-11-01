"""Append filtered immune UP/DOWN sets from the authorized local web snapshot."""
import argparse
from collections import Counter
import gzip
import hashlib
import json
from pathlib import Path
import re

ROOT = Path(__file__).resolve().parents[1]
SOURCE = 'ImmuneCellMetabolomics'
RESTRICTED = re.compile(r'kegg|\b[CDGR][0-9]{5}\b|\b(?:hsa|map|ko)[0-9]{5}\b', re.I)

def audit(value):
    if isinstance(value, dict):
        for key, child in value.items():
            audit(key)
            audit(child)
    elif isinstance(value, list):
        for child in value:
            audit(child)
    elif isinstance(value, str) and RESTRICTED.search(value):
        raise ValueError('Excluded reference in input')

def build(source, destination):
    packed = source.read_bytes()
    provenance = json.loads(source.with_name('manifest.json').read_text(encoding='utf8'))
    digest = hashlib.sha256(packed).hexdigest()
    if digest != provenance['catalog_sha256'] or provenance['profile'] != 'no-kegg':
        raise ValueError('Source integrity/profile mismatch')
    incoming = [p for p in json.loads(gzip.decompress(packed)) if p['source_db'] == SOURCE]
    if not incoming or len(incoming) != provenance['source_counts'][SOURCE]:
        raise ValueError('Missing or inconsistent immune source')
    for record in incoming:
        audit(record)
        if not record['id'].endswith(('_UP', '_DOWN')) or not record['metabolites']:
            raise ValueError('Expected nonempty direction-specific sets')
    target = destination / 'catalog.json.gz'
    existing = json.loads(gzip.decompress(target.read_bytes()))
    records = [p for p in existing if p['source_db'] != SOURCE] + incoming
    if len({p['id'] for p in records}) != len(records):
        raise ValueError('Duplicate set IDs')
    audit(records)
    manifest_path = destination / 'manifest.json'
    manifest = json.loads(manifest_path.read_text(encoding='utf8'))
    payload = gzip.compress(json.dumps(records, ensure_ascii=False, separators=(',', ':')).encode(), mtime=0)
    manifest.update(retained_records=len(records), source_counts=dict(sorted(Counter(p['source_db'] for p in records).items())),
                    catalog_sha256=hashlib.sha256(payload).hexdigest())
    manifest['immune_profiles'] = dict(provenance['immune_profiles'],
        web_catalog_sha256=digest, web_catalog_path='apps/mseapca-db-web-no-kegg/seed_data/catalog.json.gz')
    temporary = target.with_suffix('.tmp')
    temporary.write_bytes(payload)
    temporary.replace(target)
    manifest_path.write_text(json.dumps(manifest, ensure_ascii=False, indent=2)+'\n', encoding='utf8')
    print(json.dumps({'sets':len(records), 'immune_sets':len(incoming), 'catalog_sha256':manifest['catalog_sha256']}))

if __name__ == '__main__':
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('source', type=Path)
    parser.add_argument('--destination', type=Path, default=ROOT/'data')
    args = parser.parse_args()
    build(args.source, args.destination)
