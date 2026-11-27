import {test} from 'node:test';import assert from 'node:assert/strict';import {audience,bearer,master,fields,revision,uuid,normalize,validateDraft,parseBulkDraft,estimateBonus,executionGates,requireCommand,Fault} from '../packages/core/index.ts';
const fault=(fn:()=>unknown,code:string)=>assert.throws(fn,e=>e instanceof Fault&&e.code===code);
test('valid audiences and unknown rejected',()=>{assert.equal(audience('command'),'command');fault(()=>audience('admin'),'INVALID_AUDIENCE')});
test('bearer requires high entropy token shape',()=>{assert.equal(bearer('Bearer '+'a'.repeat(43)),'a'.repeat(43));fault(()=>bearer('Bearer abc'),'SESSION_REQUIRED')});
test('non-command cannot mutate master data',()=>{for(const a of ['retailer','supplier','driver','field','public'] as const)fault(()=>requireCommand(a),'COMMAND_ONLY');requireCommand('command')});
test('protected records have no generic mutation route',()=>{for(const s of ['accounting.journal','credit.facility','payments.payment_intent','__proto__','catalog.product;DROP TABLE'])fault(()=>master(s),'PROTECTED_RESOURCE')});
test('catalog master create validates required fields',()=>{assert.deepEqual(fields('catalog.brand',{code:' A ',name_en:' A '},true),{code:'A',name_en:'A'});fault(()=>fields('catalog.category',{code:'a',name_en:'A'},true),'MISSING_FIELDS')});
test('reject scope spoof and privilege escalation fields',()=>{for(const k of ['tenant_id','scope_id','version','status','archived_at','regulated'])fault(()=>fields('catalog.product',{[k]:'x'},false),'FIELD_NOT_ALLOWED')});
test('validate IDs and revisions',()=>{assert.equal(revision(1),1);for(const v of [0,-1,'1',1.3,Infinity])fault(()=>revision(v),'REVISION_REQUIRED');fault(()=>uuid('malformed'),'INVALID_ID')});
test('product references checked by field validator',()=>{fault(()=>fields('catalog.product',{category_id:'x'},false),'INVALID_ID')});
test('Eastern numerals normalize correctly',()=>{assert.equal(normalize('٦٢٨۰۰۰۰۰۰۰۰۱۱'),'6280000000011');assert.equal(normalize('أَكْرَم'),'اکرم')});
test('draft accepts only SKU and positive carton count',()=>{assert.deepEqual(validateDraft([{sku:'BEV-001',cartons:20}]),[{sku:'BEV-001',cartons:20}]);for(const v of [0,-1,1.5,100001])fault(()=>validateDraft([{sku:'X',cartons:v}]),'INVALID_DRAFT_LINE')});
test('draft denies prices, credentials and duplicate normalized SKUs',()=>{fault(()=>validateDraft([{sku:'X',cartons:1,price:100}]),'INVALID_DRAFT_LINE');fault(()=>validateDraft([{sku:'A1',cartons:1},{sku:'a١',cartons:1}]),'INVALID_DRAFT_LINE')});
test('bigint promotion and hybrid estimate matches approved example',()=>{assert.deepEqual(estimateBonus(20n,10n,1n,24000n,1500n),{total:480000n,bonus:2n,shipped:22n,deposit:72000n,cod:408000n})});
test('financial gates closed and immutable',()=>{assert.ok(Object.values(executionGates).every(v=>v===false));assert.ok(Object.isFrozen(executionGates))});

test('bulk paste parses 50 localized quantity lines',()=>{const input=Array.from({length:50},(_,i)=>`SKU-${i}\t٢٠`).join("\n");const rows=parseBulkDraft(input);assert.equal(rows.length,50);assert.ok(rows.every(r=>r.cartons===20));});
test('bulk paste rejects decimal, malformed and duplicate rows',()=>{for(const v of ["A,1.5","A,1,2","A,0","A,1\na,2"])fault(()=>parseBulkDraft(v),"INVALID_DRAFT_LINE");});
