import {test} from 'node:test';
import assert from 'node:assert/strict';
import {existsSync} from 'node:fs';
import {getRenderCommand,getRenderPort,getRenderStartArgs} from '../scripts/start-render.mjs';

test('Render port parser accepts valid integer ports',()=>{
  assert.equal(getRenderPort('10000'),10000);
  assert.equal(getRenderPort('65535'),65535);
});

test('Render port parser falls back for missing or invalid values',()=>{
  for (const value of [undefined,'','abc','0','65536','1.5','-1']) {
    assert.equal(getRenderPort(value),3000);
  }
});

test('hosted Next.js arguments bind to the public interface and selected port',()=>{
  assert.deepEqual(getRenderStartArgs({PORT:'10000'}),['start','-H','0.0.0.0','-p','10000']);
  assert.deepEqual(getRenderStartArgs({}),['start','-H','0.0.0.0','-p','3000']);
});

test('hosted launcher runs the installed Next.js CLI with Node',()=>{
  const command=getRenderCommand({PORT:'10000'});
  assert.equal(command.command,process.execPath);
  assert.equal(existsSync(command.args[0] as string),true);
  assert.deepEqual(command.args.slice(1),['start','-H','0.0.0.0','-p','10000']);
});
