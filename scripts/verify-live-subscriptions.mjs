import assert from 'node:assert/strict';
const base='http://127.0.0.1:3000';
let cookie='';
async function ask(message,sessionId){
  const response=await fetch(base+'/api/chat',{
    method:'POST',headers:{Origin:base,'Content-Type':'application/json',Cookie:cookie},
    body:JSON.stringify({message,sessionId}),signal:AbortSignal.timeout(90000),
  });
  for(const value of response.headers.getSetCookie()){
    const pair=value.split(';')[0],name=pair.split('=')[0];
    cookie=cookie.split('; ').filter(item=>item&&!item.startsWith(name+'=')).concat(pair).join('; ');
  }
  const data=await response.json();
  assert.equal(response.status,200);
  assert.equal(data.provider,'gemini',data.providerNotice??'Live Gemini is required');
  console.log(JSON.stringify({message,provider:data.provider,term:data.filters?.term,
    gyms:data.gyms?.map(gym=>({name:gym.name,days:gym.duration_days,price:gym.price_kzt})),actions:data.actions}));
  return data;
}
const found=await ask('Найди взрослому залы на два месяца до 20к за 30 дней');
assert.equal(found.filters.term,'2months');
assert.equal(found.filters.max,20000);
assert.ok(found.gyms.length>=3);
assert.ok(found.gyms.every(gym=>gym.duration_days===60&&gym.monthly<=20000&&gym.price_basis==='model_estimate'));
const compared=await ask('Сравни первый и третий',found.sessionId);
assert.equal(compared.filters.term,'2months');
const action=compared.actions.find(action=>action.type==='compare');
assert.deepEqual(action?.gymIds,[String(found.gyms[0].id),String(found.gyms[2].id)]);
assert.ok(compared.gyms.every(gym=>gym.duration_days===60));
console.log('PASS live Gemini: two-month search and ordinal comparison keep the chosen duration');
