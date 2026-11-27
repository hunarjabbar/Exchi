import {readFileSync, existsSync, readdirSync} from 'node:fs';
import {join} from 'node:path';
import assert from 'node:assert/strict';
if (!existsSync('package-lock.json')) {
  console.error('CERTIFICATION BLOCKED: package-lock.json is missing. Generate with npm install --package-lock-only --ignore-scripts, review and commit; then run npm ci.');
  process.exit(2);
}
const root = JSON.parse(readFileSync('package.json','utf8'));
const lock = JSON.parse(readFileSync('package-lock.json','utf8'));
assert.equal(lock.lockfileVersion,3,'Expected npm lockfile v3');
assert.ok(lock.packages && lock.packages[''],'Lockfile package graph missing');
function verify(path) {
  const manifest = JSON.parse(readFileSync(join(path,'package.json'),'utf8'));
  const entry = lock.packages[path];
  assert.ok(entry,`Missing workspace lock entry: ${path||'root'}`);
  assert.equal(entry.version,manifest.version,`Version drift: ${path||'root'}`);
  for (const key of ['dependencies','devDependencies','peerDependencies','optionalDependencies']) {
    assert.deepEqual(entry[key]??{},manifest[key]??{},`Dependency drift: ${path||'root'} ${key}`);
  }
}
verify('');
for (const pattern of root.workspaces) {
  assert.match(pattern,/^(apps|packages)\/\*$/);
  const base=pattern.slice(0,-2);
  for (const item of readdirSync(base,{withFileTypes:true})) {
    const path=join(base,item.name);
    if(item.isDirectory()&&existsSync(join(path,'package.json')))verify(path);
  }
}
assert.ok(Object.keys(lock.packages).some(k=>k.startsWith('node_modules/')&&!lock.packages[k].link),'No external packages in lockfile');
console.log('PASS: lockfile v3 and workspace manifests agree; npm ci must still validate the complete graph.');
