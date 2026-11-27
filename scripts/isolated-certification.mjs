import {spawnSync} from 'node:child_process';
import {mkdtempSync, mkdirSync, existsSync, writeFileSync, copyFileSync, rmSync} from 'node:fs';
import {tmpdir} from 'node:os';
import {join, resolve} from 'node:path';
import {randomBytes} from 'node:crypto';
import {fileURLToPath} from 'node:url';
const root=resolve(fileURLToPath(new URL('..',import.meta.url)));
const project='wholesale-cert-'+randomBytes(8).toString('hex');
const evidence=join(root,'acceptance-evidence');
const report=join(evidence,'isolated-run.json');
const artifacts=['commit.txt','git-status.txt','lockfile-sha256.txt','readiness.json','runtime-result.txt','prisma-diff.sql','schema-drift-result.json'];
mkdirSync(evidence,{recursive:true});
for(const f of [...artifacts,'isolated-run.json','bootstrap.log','http-smoke.log','browser-auth.log','browser-offline.log'])rmSync(join(evidence,f),{force:true});
const result={project,commit:null,status:'BLOCKED',stage:'preflight',exitCode:2,cleanup:'not-needed'};
const save=()=>writeFileSync(report,JSON.stringify(result,null,2)+'\n');
function run(cmd,args,{cwd=root,env=process.env,quiet=false}={}){
 const r=spawnSync(cmd,args,{cwd,env,encoding:'utf8',stdio:quiet?['ignore','pipe','pipe']:'inherit'});
 if(r.error||r.status!==0)throw new Error(`${cmd} ${args[0]??''} failed (exit ${r.status??'unavailable'})`);
 return quiet?r.stdout.trim():'';
}
let dir,tree,runEnv,added=false,composeTouched=false;
// The worktree is newly allocated by this process. Never adopt or reset an existing project.
try {
 result.commit=run('git',['rev-parse','HEAD'],{quiet:true});
 if(run('git',['status','--porcelain'],{quiet:true}))throw new Error('Commit or stash source changes before certification.');
 if(!existsSync(join(root,'package-lock.json')))throw new Error('Reviewed package-lock.json is missing. Generate and commit it before certification.');
 run('git',['ls-files','--error-unmatch','package-lock.json'],{quiet:true});
 run(process.execPath,['scripts/check-lock.mjs']);
 if(process.env.DOCKER_HOST||process.env.DOCKER_CONTEXT)throw new Error('Refusing externally selected Docker host/context. Use the local default context.');
 if(run('docker',['context','show'],{quiet:true})!=='default')throw new Error('Use the local default Docker context for isolated certification.');
 const endpoint=run('docker',['context','inspect','default','--format','{{.Endpoints.docker.Host}}'],{quiet:true});
 if(!endpoint.startsWith('unix:///'))throw new Error('Refusing non-local Docker endpoint');
 for(const [cmd,args] of [['docker',['compose','version']],['docker',['info','--format','{{.ServerVersion}}']],['psql',['--version']],['python3',['-c','import playwright.sync_api']],['curl',['--version']],['setsid',['--version']]])run(cmd,args,{quiet:true});
 // Refuse occupied loopback ports before starting anything; do not kill or replace services.
 run('python3',['-c',`import socket\nfor p in [*range(3000,3006),4000,55432]:\n with socket.socket() as s:\n  s.bind(('127.0.0.1',p))`],{quiet:true});
 // Unique project name + absence check ensures cleanup is never directed at an existing deployment.
 const projects=JSON.parse(run('docker',['compose','ls','--all','--format','json'],{quiet:true}));
 if(projects.some(p=>p.Name===project))throw new Error('Unexpected Compose project collision');
 dir=mkdtempSync(join(tmpdir(),'wholesale-cert-'));tree=join(dir,'worktree');
 result.stage='worktree';run('git',['worktree','add','--detach',tree,result.commit]);added=true;
 // Drop external database/provider configuration. Only allow the local fixture generator to provide it.
 const env=Object.fromEntries(Object.entries(process.env).filter(([k])=>! /^(DATABASE_URL|PSQL_DATABASE_URL|RUNTIME_DATABASE_URL|PG.*|WHOLESALE_.*|AUTH_.*|ALLOW_.*|META_.*|TWILIO_.*|ENTERPRISE_API_URL|APP_ORIGIN|PORT|COMPOSE_.*|DOCKER_HOST|DOCKER_CONTEXT)$/.test(k)));
 env.WHOLESALE_CERT_PROJECT=project;env.RELEASE_ENV='local';env.FINANCIAL_EXECUTION='LOCKED';runEnv=env;
 result.stage='runtime';composeTouched=true;
 run('bash',['scripts/certify-step-ab.sh'],{cwd:tree,env});
 result.status='PASS';result.exitCode=0;result.stage='complete';
} catch(e){result.message=e.message;console.error('CERTIFICATION:',e.message);if(result.stage!=='preflight'){result.status='FAILED';result.exitCode=1;}}
finally {
 if(added){
  // Copy only explicit non-secret metadata; raw logs stay out of shared evidence.
  for(const f of artifacts){const p=join(tree,'acceptance-evidence',f);if(existsSync(p)&&f!=='runtime-result.txt')copyFileSync(p,join(evidence,f));}
  if(composeTouched&&existsSync(join(tree,'.local-stepab.env'))){
   try{run('docker',['compose','--env-file',join(tree,'.local-stepab.env'),'-p',project,'-f',join(tree,'compose.step-ab.yaml'),'down','-v','--remove-orphans'],{cwd:tree,env:runEnv});result.cleanup='complete';}
   catch(e){result.cleanup='failed';result.status='FAILED';result.exitCode=1;result.message='Owned test project cleanup failed; inspect '+project;}
  }
  // Preserve the worktree if cleanup failed, so the operator can inspect and recover the exact owned project.
  if(result.cleanup!=='failed'){
   try{run('git',['worktree','remove','--force',tree]);rmSync(dir,{recursive:true,force:true});}
   catch(e){result.cleanup='failed';result.status='FAILED';result.exitCode=1;result.message='Owned worktree cleanup failed';}
  }else result.worktree=tree;
 }
 if(result.status==='PASS')writeFileSync(join(evidence,'runtime-result.txt'),'PASS: isolated runtime suite and cleanup completed; review drift and dependency evidence before Step C.\n');
 save();console.log(JSON.stringify(result,null,2));
}
process.exitCode=result.exitCode;
