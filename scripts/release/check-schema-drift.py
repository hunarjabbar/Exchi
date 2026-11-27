#!/usr/bin/env python3
"""Verify reviewed SQL-managed Prisma differences against live PostgreSQL. Never execute diff SQL."""
import argparse
import json
import os
import re
import subprocess
from pathlib import Path

ROOT = Path(__file__).resolve().parents[2]
INDEX = re.compile(r'DROP INDEX "([a-z0-9_]+)"\."([a-z0-9_]+)";')
FK = re.compile(r'ALTER TABLE "([a-z0-9_]+)"\."([a-z0-9_]+)" DROP CONSTRAINT "([a-z0-9_]+)";')


def diff_objects(sql):
    indexes, keys = set(), set()
    for line in sql.splitlines():
        line = line.strip()
        if not line or line.startswith('--'):
            continue
        match = INDEX.fullmatch(line)
        if match:
            target, item = indexes, match.groups()
        else:
            match = FK.fullmatch(line)
            if not match:
                raise ValueError(f'Unexpected Prisma operation: {line[:160]}')
            target, item = keys, match.groups()
        if item in target:
            raise ValueError(f'Duplicate diff operation: {item}')
        target.add(item)
    return indexes, keys


def verify_diff(sql, baseline):
    indexes, keys = diff_objects(sql)
    expected = ({(x['schema'], x['name']) for x in baseline['indexes']},
                {(x['schema'], x['table'], x['name']) for x in baseline['foreign_keys']})
    for label, actual, wanted in zip(('indexes', 'foreign keys'), (indexes, keys), expected):
        if actual != wanted:
            raise ValueError(f'{label} drift mismatch: added={sorted(actual-wanted)}, missing={sorted(wanted-actual)}')


def query(url, sql):
    result = subprocess.run(['psql', url, '-X', '-qAt', '-v', 'ON_ERROR_STOP=1', '-c', sql],
                            capture_output=True, text=True, check=True)
    return json.loads(result.stdout)


def verify_live(baseline, indexes, keys):
    actual_i = {(x['schema'], x['name']): x for x in indexes}
    actual_k = {(x['schema'], x['table'], x['name']): x for x in keys}
    for wanted in baseline['indexes']:
        item = (wanted['schema'], wanted['name'])
        if actual_i.get(item) != wanted:
            raise ValueError(f'Index definition or validity mismatch: {item}')
    for wanted in baseline['foreign_keys']:
        item = (wanted['schema'], wanted['table'], wanted['name'])
        if actual_k.get(item) != wanted:
            raise ValueError(f'Foreign-key definition or validation mismatch: {item}')


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('diff', type=Path)
    parser.add_argument('--output', type=Path, required=True)
    args = parser.parse_args()
    args.output.unlink(missing_ok=True)
    baseline = json.loads((ROOT / 'packages/database/sql-managed-drift.json').read_text())
    verify_diff(args.diff.read_text(), baseline)
    url = os.environ['DATABASE_URL'].split('?', 1)[0]
    indexes = query(url, """SET search_path = pg_catalog, public;
      SELECT coalesce(json_agg(json_build_object('schema', n.nspname, 'name', c.relname,
      'ready', i.indisready, 'valid', i.indisvalid, 'definition', pg_get_indexdef(c.oid))), '[]'::json)
      FROM pg_index i JOIN pg_class c ON c.oid=i.indexrelid JOIN pg_namespace n ON n.oid=c.relnamespace;""")
    keys = query(url, """SET search_path = pg_catalog, public;
      SELECT coalesce(json_agg(json_build_object('schema', n.nspname, 'table', t.relname,
      'name', c.conname, 'validated', c.convalidated, 'definition', pg_get_constraintdef(c.oid))), '[]'::json)
      FROM pg_constraint c JOIN pg_class t ON t.oid=c.conrelid JOIN pg_namespace n ON n.oid=t.relnamespace WHERE c.contype='f';""")
    verify_live(baseline, indexes, keys)
    report = {'status': 'PASS', 'policy': 'SQL migrations authoritative; diff never executed',
              'indexes': len(baseline['indexes']), 'foreign_keys': len(baseline['foreign_keys']), 'unexpected_operations': 0}
    args.output.parent.mkdir(parents=True, exist_ok=True)
    args.output.write_text(json.dumps(report, indent=2)+'\n')
    print(json.dumps(report))


if __name__ == '__main__':
    try:
        main()
    except (ValueError, KeyError, OSError, subprocess.CalledProcessError) as e:
        # Database errors may contain sensitive connection details; do not emit subprocess arguments.
        raise SystemExit('SCHEMA DRIFT BLOCKED: '+ ('PostgreSQL query failed' if isinstance(e, subprocess.CalledProcessError) else str(e))) from None
