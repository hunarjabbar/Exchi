import {test} from 'node:test';
import assert from 'node:assert/strict';
import {mkdtempSync,mkdirSync,writeFileSync,rmSync,readFileSync} from 'node:fs';
import {tmpdir} from 'node:os';
import {join} from 'node:path';
import {fileURLToPath} from 'node:url';
import {spawnSync} from 'node:child_process';
const guard=fileURLToPath(new URL('../scripts/check-lock.mjs',import.meta.url));
function fixture(fn){const dir=mkdtempSync(join(tmpdir(),'wholesale-lock-test-'));try{const root={name:'synthetic',version:'1.0.0',workspaces:['apps/*','packages/*'],devDependencies:{typescript:'~5.8.3'}};const app={name:'synthetic-app',version:'1.0.0',dependencies:{next:'^15.5.0'}};mkdirSync(join(dir,'apps/app'),{recursive:true});mkdirSync(join(dir,'packages'));writeFileSync(join(dir,'package.json'),JSON.stringify(root));writeFileSync(join(dir,'apps/app/package.json'),JSON.stringify(app));const lock={lockfileVersion:3,packages:{'':root,'apps/app':app,'node_modules/next':{version:'15.5.0'}}};fn(dir,lock);}finally{rmSync(dir,{recursive:true,force:true});}}
const run=(cwd)=>spawnSync(process.execPath,[guard],{cwd,encoding:'utf8'});
const save=(dir,lock)=>writeFileSync(join(dir,'package-lock.json'),JSON.stringify(lock));
test('missing lockfile fails closed',()=>fixture(dir=>{const r=run(dir);assert.equal(r.status,2);assert.match(r.stderr,/CERTIFICATION BLOCKED/)}));
test('matching synthetic workspace manifest passes structural guard',()=>fixture((dir,lock)=>{save(dir,lock);assert.equal(run(dir).status,0)}));
test('dependency drift fails guard',()=>fixture((dir,lock)=>{lock.packages['apps/app'].dependencies.next='^16.0.0';save(dir,lock);assert.notEqual(run(dir).status,0)}));
test('missing workspace lock entry fails guard',()=>fixture((dir,lock)=>{delete lock.packages['apps/app'];save(dir,lock);assert.notEqual(run(dir).status,0)}));
test('empty dependency graph fails guard',()=>fixture((dir,lock)=>{delete lock.packages['node_modules/next'];save(dir,lock);assert.notEqual(run(dir).status,0)}));
test('CI uses full runtime suite and does not regenerate lockfile',()=>{const ci=readFileSync(new URL('../.github/workflows/acceptance.yml',import.meta.url),'utf8');const bootstrap=readFileSync(new URL('../scripts/bootstrap-step-ab.sh',import.meta.url),'utf8');const runner=readFileSync(new URL('../scripts/certify-step-ab.sh',import.meta.url),'utf8');assert.match(ci,/git ls-files --error-unmatch package-lock.json/);assert.match(ci,/npm run test:step-ab:fresh/);assert.match(bootstrap,/npm ci/);assert.doesNotMatch(bootstrap,/npm install/);assert.match(bootstrap,/concurrency-step-ab\.py/);for(const s of ['test:step-ab:smoke','test:step-ab:browser','browser-offline.py'])assert.ok(runner.includes(s));});
test('browser fixture upgrade preserves pre-existing local credentials and is idempotent',()=>{
 const dir=mkdtempSync(join(tmpdir(),'wholesale-fixture-test-'));
 try {
  const env=join(dir,'.local-stepab.env');
  const initial="AUTH_MODE='dev'\nALLOW_LOCAL_DEV_OTP='YES'\nAUTH_RETAILER_SIGNUP_TENANT='wholesale-local'\nRUNTIME_DATABASE_URL='postgresql://wholesale_stepab_login:abcd@127.0.0.1:55432/wholesale_test'\nAUTH_STAFF_TOTP_JSON='{\"+9647500000003\":\""+'1'.repeat(40)+"\"}'\n";
  writeFileSync(env,initial,{mode:0o600});const script=fileURLToPath(new URL('../scripts/add-browser-fixture.mjs',import.meta.url));
  assert.equal(spawnSync(process.execPath,[script],{cwd:dir}).status,0);const updated=readFileSync(env,'utf8');const map=JSON.parse(updated.match(/^AUTH_STAFF_TOTP_JSON='([^']+)'$/m)[1]);assert.equal(map['+9647500000003'],'1'.repeat(40));assert.match(map['+9647500000008'],/^[a-f0-9]{40}$/);assert.equal(updated.replace(/^AUTH_STAFF_TOTP_JSON=.*$/m,''),initial.replace(/^AUTH_STAFF_TOTP_JSON=.*$/m,''));assert.equal(spawnSync(process.execPath,[script],{cwd:dir}).status,0);assert.equal(readFileSync(env,'utf8'),updated);
 }finally{rmSync(dir,{recursive:true,force:true});}
});

test('isolated runner refuses absent tracked lockfile, clears stale marker and leaves source intact',()=>{
 const dir=mkdtempSync(join(tmpdir(),'wholesale-fresh-test-'));
 try{
  mkdirSync(join(dir,'scripts'));mkdirSync(join(dir,'acceptance-evidence'));
  writeFileSync(join(dir,'.gitignore'),'acceptance-evidence/\n');
  const script=readFileSync(new URL('../scripts/isolated-certification.mjs',import.meta.url),'utf8');writeFileSync(join(dir,'scripts/isolated-certification.mjs'),script);
  const git=(...args)=>{const r=spawnSync('git',args,{cwd:dir,encoding:'utf8'});assert.equal(r.status,0,r.stderr);return r.stdout.trim();};
  git('init','-q');git('add','.');git('-c','user.name=Test','-c','user.email=test@example.invalid','commit','-qm','fixture');
  writeFileSync(join(dir,'acceptance-evidence/runtime-result.txt'),'PASS stale');
  const r=spawnSync(process.execPath,['scripts/isolated-certification.mjs'],{cwd:dir,encoding:'utf8'});
  assert.equal(r.status,2);assert.match(r.stderr,/lockfile|package-lock/);const report=JSON.parse(readFileSync(join(dir,'acceptance-evidence/isolated-run.json'),'utf8'));
  assert.equal(report.status,'BLOCKED');assert.equal(report.stage,'preflight');assert.equal(report.cleanup,'not-needed');assert.match(report.project,/^wholesale-cert-[a-f0-9]{16}$/);assert.equal(report.commit,git('rev-parse','HEAD'));
  assert.throws(()=>readFileSync(join(dir,'acceptance-evidence/runtime-result.txt')),{code:'ENOENT'});assert.equal(git('status','--porcelain'),'');
  assert.equal(git('worktree','list','--porcelain').split('\n').filter(x=>x.startsWith('worktree ')).length,1);
 }finally{rmSync(dir,{recursive:true,force:true});}
});
test('fresh certification uses a unique worktree and project; CI does not clean the persistent local project',()=>{
 const script=readFileSync(new URL('../scripts/isolated-certification.mjs',import.meta.url),'utf8');const ci=readFileSync(new URL('../.github/workflows/acceptance.yml',import.meta.url),'utf8');const bootstrap=readFileSync(new URL('../scripts/bootstrap-step-ab.sh',import.meta.url),'utf8');
 assert.match(script,/randomBytes\(8\)/);assert.match(script,/worktree','add','--detach/);assert.match(script,/--env-file/);assert.match(script,/'-p',project/);assert.match(script,/Refusing non-local Docker endpoint/);assert.match(bootstrap,/WHOLESALE_CERT_PROJECT/);assert.doesNotMatch(ci,/down -v/);assert.match(ci,/isolated-run\.json/);
});

test('connected runner can produce a review-only lockfile candidate without branch writes or package lifecycle scripts',()=>{
 const workflow=readFileSync(new URL('../.github/workflows/dependency-lock-candidate.yml',import.meta.url),'utf8');
 assert.match(workflow,/workflow_dispatch:/);assert.match(workflow,/contents: read/);assert.match(workflow,/persist-credentials: false/);
 assert.match(workflow,/npm install --package-lock-only --ignore-scripts/);assert.match(workflow,/npm ci --ignore-scripts/);
 assert.match(workflow,/npm run check:lock/);assert.match(workflow,/git diff --exit-code -- package.json apps packages/);
 assert.match(workflow,/source-commit\.txt/);assert.match(workflow,/sha256sum package-lock\.json/);assert.match(workflow,/npm audit --audit-level=high --json/);
 assert.match(workflow,/if: always\(\)/);assert.match(workflow,/exit "\$result"/);
 assert.doesNotMatch(workflow,/git (push|commit)|contents: write|deploy|test:step-ab:fresh/);
});
