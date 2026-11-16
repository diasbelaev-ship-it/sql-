import {test} from 'node:test';
import assert from 'node:assert/strict';
import {getSiteOrigin,isSecureSiteOrigin} from '../src/lib/runtime-origin';

test('explicit site origin wins and is normalized to an origin',()=>{
  assert.equal(getSiteOrigin({APP_ORIGIN:'https://gymfinder.example/path/','RENDER_EXTERNAL_URL':'https://gymfinder.onrender.com'}),'https://gymfinder.example');
});

test('Render external URL is used when APP_ORIGIN is unset or invalid',()=>{
  assert.equal(getSiteOrigin({RENDER_EXTERNAL_URL:'https://gymfinder.onrender.com/'}),'https://gymfinder.onrender.com');
  assert.equal(getSiteOrigin({APP_ORIGIN:'not a URL','RENDER_EXTERNAL_URL':'https://gymfinder.onrender.com'}),'https://gymfinder.onrender.com');
});

test('local origin is the fallback outside a hosted environment',()=>{
  assert.equal(getSiteOrigin({}),'http://127.0.0.1:3000');
});

test('cookie security follows the resolved site protocol',()=>{
  assert.equal(isSecureSiteOrigin({RENDER_EXTERNAL_URL:'https://gymfinder.onrender.com'}),true);
  assert.equal(isSecureSiteOrigin({}),false);
});
