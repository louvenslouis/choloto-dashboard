import assert from 'node:assert/strict';
const project = process.env.GCLOUD_PROJECT || 'demo-choloto';
const root = `http://${process.env.FIRESTORE_EMULATOR_HOST || '127.0.0.1:8080'}/v1/projects/${project}/databases/(default)/documents`;
async function user(email) {
  const r = await fetch(`http://${process.env.FIREBASE_AUTH_EMULATOR_HOST || '127.0.0.1:9099'}/identitytoolkit.googleapis.com/v1/accounts:signUp?key=fake`, {method:'POST',headers:{'content-type':'application/json'},body:JSON.stringify({email,password:'bot-test-password',returnSecureToken:true})});
  assert.equal(r.status,200); return (await r.json()).idToken;
}
function value(v) {
  if (typeof v === 'boolean') return {booleanValue:v};
  if (typeof v === 'number') return {integerValue:String(v)};
  if (typeof v === 'string') return {stringValue:v};
  if (Array.isArray(v)) return {arrayValue:{values:v.map(value)}};
  return {mapValue:{fields:Object.fromEntries(Object.entries(v).map(([k,v])=>[k,value(v)]))}};
}
const config={enabled:true,greeting:'Bonjou',nodes:[{id:'vip',parent:'',label:'VIP',answer:'Byenveni'}],revision:1};
async function req(method,token,body,path='support_bot/config') {
 const r=await fetch(`${root}/${path}`,{method,headers:{'content-type':'application/json',...(token?{authorization:`Bearer ${token}`}:{})},...(body?{body:JSON.stringify(value(body).mapValue)}:{})});
 return r.status;
}
const admin=await user('sanonmaeva064@gmail.com');
const member=await user('bot-member@test.example');
assert.equal(await req('PATCH',undefined,config),403,'guest write');
assert.equal(await req('PATCH',member,config),403,'member write');
assert.equal(await req('PATCH',admin,config),200,'admin publish');
assert.equal(await req('GET'),200,'guest read');
assert.equal(await req('GET',member),200,'member read');
assert.equal(await req('PATCH',admin,config),403,'stale revision');
assert.equal(await req('PATCH',admin,{...config,revision:2,enabled:false}),200,'admin disable');
assert.equal(await req('PATCH',admin,{...config,revision:3,nodes:[]}),403,'empty tree');
assert.equal(await req('PATCH',admin,{...config,revision:3,greeting:9}),403,'malformed greeting');
assert.equal(await req('PATCH',admin,{...config,revision:3,extra:true}),403,'unexpected field');
assert.equal(await req('PATCH',member,{...config,revision:3}),403,'member update');
assert.equal(await req('DELETE',admin),403,'disable instead of delete');
assert.equal(await req('PATCH',admin,config,'support_bot/other'),403,'unknown document');
console.log('Support bot: 13 access and validation checks passed.');
