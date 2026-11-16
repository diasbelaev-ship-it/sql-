import {chromium} from 'playwright';
import assert from 'node:assert/strict';
const browser=await chromium.launch({channel:'chrome',headless:true});
try{
 for(const size of [{width:1440,height:1000},{width:390,height:844}]){
  const page=await browser.newPage({viewport:size});
  await page.goto('http://127.0.0.1:3000');
  await page.locator('.gym-row').first().waitFor();
  await page.getByRole('button',{name:'Помочь с выбором',exact:true}).click();
  await page.getByLabel('Сообщение',{exact:true}).fill('какие залы порекомендуешь');
  const reply=page.waitForResponse(response=>response.url().endsWith('/api/chat')&&response.request().method()==='POST');
  await page.getByRole('button',{name:'Отправить',exact:true}).click();
  const data=await (await reply).json();
  assert.equal(data.provider,'gemini');
  assert.ok(data.gyms?.some(gym=>data.answer.includes(gym.name)));
  await page.locator('.assistant-working').waitFor({state:'hidden',timeout:90000});
  const answerPosition=await page.locator('.assistant-log').evaluate(log=>{
    const answer=log.querySelector('.assistant-message:last-child');
    return answer.getBoundingClientRect().top-log.getBoundingClientRect().top;
  });
  assert.ok(answerPosition>=-2&&answerPosition<40,'The start of the answer must be visible without scrolling');
  const dimensions=await page.evaluate(()=>({width:innerWidth,scroll:document.documentElement.scrollWidth}));
  if(dimensions.scroll>dimensions.width)throw Error('Horizontal overflow: '+JSON.stringify(dimensions));
  await page.screenshot({path:`docs/design/assistant-${size.width}.png`});
  console.log('Captured '+size.width+'px, no horizontal overflow');
  await page.close();
 }
}finally{await browser.close();}
