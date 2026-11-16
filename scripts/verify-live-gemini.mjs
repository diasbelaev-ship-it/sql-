import assert from 'node:assert/strict';
const base='http://127.0.0.1:3000';let cookie='';
async function ask(message,sessionId,context){const started=Date.now();const r=await fetch(base+'/api/chat',{method:'POST',headers:{Origin:base,'Content-Type':'application/json',Cookie:cookie},body:JSON.stringify({message,sessionId,context}),signal:AbortSignal.timeout(90000)});const d=await r.json();for(const s of r.headers.getSetCookie()){const part=s.split(';')[0],name=part.split('=')[0];cookie=cookie.split('; ').filter(v=>v&&!v.startsWith(name+'=')).concat(part).join('; ');}assert.equal(r.status,200,JSON.stringify(d));console.log(JSON.stringify({message,provider:d.provider,notice:d.providerNotice,answer:d.answer,actions:d.actions,gyms:d.gyms?.map(g=>g.name),elapsed:Date.now()-started}));return d;}
// Reproduce an already-open catalog: IDs alone must never become invented "Зал №12" recommendations.
const initial=await ask('какие залы порекомендуешь',undefined,{filters:{audience:'student',zone:'west',max:20000},view:'list',resultIds:['12','48','42']});assert.equal(initial.provider,'gemini');assert.ok(initial.answer.length>20);assert.ok(initial.gyms?.length);
assert.ok(initial.gyms.some(g=>initial.answer.includes(g.name)),'answer must name real database gyms');
assert.match(initial.answer,/учебн|оценк/i,'estimated prices must be labeled');
assert.ok(!/Зал\s*№\s*\d/i.test(initial.answer),'database IDs are not gym names');
const comparison=await ask('Сравни первый и третий',initial.sessionId);assert.equal(comparison.provider,'gemini');assert.ok(comparison.actions.some(a=>a.type==='compare'&&a.gymIds.length===2));
console.log('LIVE GEMINI PASS: grounded recommendations and ordinal comparison');
