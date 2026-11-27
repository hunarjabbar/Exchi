import copy
import importlib.util
import json
import unittest
from pathlib import Path
ROOT=Path(__file__).resolve().parents[1]
spec=importlib.util.spec_from_file_location('drift',ROOT/'scripts/release/check-schema-drift.py')
drift=importlib.util.module_from_spec(spec);spec.loader.exec_module(drift)
BASE=json.loads((ROOT/'packages/database/sql-managed-drift.json').read_text())
SQL=(ROOT/'tests/fixtures/reviewed-prisma-diff.sql').read_text()
class DriftTests(unittest.TestCase):
    def test_reviewed_diff(self): drift.verify_diff(SQL,BASE)
    def test_unexpected_drop(self):
        with self.assertRaises(ValueError): drift.verify_diff(SQL+'\nDROP TABLE "public"."x";',BASE)
    def test_new_index(self):
        with self.assertRaises(ValueError): drift.verify_diff(SQL+'\nDROP INDEX "public"."new_index";',BASE)
    def test_missing_index(self):
        with self.assertRaises(ValueError): drift.verify_diff(SQL.replace('DROP INDEX "accounting"."ix_account_ledger_id";',''),BASE)
    def test_duplicate(self):
        with self.assertRaises(ValueError): drift.verify_diff(SQL+'\nDROP INDEX "accounting"."ix_account_ledger_id";',BASE)
    def test_live_valid(self): drift.verify_live(BASE,BASE['indexes'],BASE['foreign_keys'])
    def test_invalid_index(self):
        i=copy.deepcopy(BASE['indexes']);i[0]['valid']=False
        with self.assertRaises(ValueError): drift.verify_live(BASE,i,BASE['foreign_keys'])
    def test_changed_fk(self):
        k=copy.deepcopy(BASE['foreign_keys']);k[0]['definition']+=' ON DELETE CASCADE'
        with self.assertRaises(ValueError): drift.verify_live(BASE,BASE['indexes'],k)
    def test_missing_fk(self):
        with self.assertRaises(ValueError): drift.verify_live(BASE,BASE['indexes'],BASE['foreign_keys'][1:])
if __name__=='__main__': unittest.main()
