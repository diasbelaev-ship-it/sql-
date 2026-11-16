import {chromium} from 'playwright';
import {expect} from '@playwright/test';
import assert from 'node:assert/strict';
const browser=await chromium.launch({channel:'chrome',headless:true});
try{
  for(const width of [1440,1024,768,390,320]){
    const page=await browser.newPage({viewport:{width,height:width>=768?1000:844}});
    const errors=[];
    page.on('pageerror',error=>errors.push(error.stack??error.message));
    await page.goto('http://127.0.0.1:3000');
    await page.locator('.gym-row').first().waitFor();
    const toggle=page.getByRole('button',{name:'Фильтры',exact:true});
    if(await toggle.isVisible())await toggle.click();
    const term=page.getByRole('combobox',{name:'Срок абонемента',exact:true});
    assert.deepEqual(await term.locator('option').evaluateAll(options=>options.map(option=>option.value)),
      ['month','2months','3months','6months','9months','year','any']);
    const response=page.waitForResponse(response=>response.url().includes('/api/gyms?')&&response.url().includes('term=2months'));
    await term.selectOption('2months');
    const data=await (await response).json();
    assert.equal(data.total,70);
    assert.ok(data.gyms.every(gym=>gym.duration_days===60));
    await expect(page.locator('.gym-row').first()).toContainText('2 месяца · 60 дней');
    await expect(page).toHaveURL(/term=2months/);
    const dimensions=await page.evaluate(()=>({width:innerWidth,scroll:document.documentElement.scrollWidth}));
    assert.ok(dimensions.scroll<=dimensions.width,'Horizontal overflow at '+width);
    if(width===390)await term.scrollIntoViewIfNeeded();
    if(width===1440||width===390)await page.screenshot({path:`docs/design/subscriptions-${width}.png`});

    // Manual comparison must keep the same selected duration as the catalog.
    await page.locator('.gym-row').nth(0).getByRole('checkbox',{name:'Сравнить',exact:true}).check();
    await page.locator('.gym-row').nth(2).getByRole('checkbox',{name:'Сравнить',exact:true}).check();
    await page.getByRole('button',{name:'Сравнить залы',exact:true}).click();
    const dialog=page.getByRole('dialog');
    await expect(dialog).toContainText('2 месяца · 60 дней');
    await expect(dialog).toContainText(data.gyms[0].name);
    await expect(dialog).toContainText(data.gyms[2].name);
    await dialog.getByRole('button',{name:'Закрыть',exact:true}).click();

    // Previously selected gyms must use the new term when comparison is reopened.
    await term.selectOption('3months');
    await expect(page.locator('.gym-row').first()).toContainText('3 месяца · 90 дней');
    await page.getByRole('button',{name:'Сравнить залы',exact:true}).click();
    await expect(dialog).toContainText('3 месяца · 90 дней');
    await expect(dialog).not.toContainText('2 месяца · 60 дней');
    await dialog.getByRole('button',{name:'Закрыть',exact:true}).click();
    await term.selectOption('2months');
    await expect(page.locator('.gym-row').first()).toContainText('2 месяца · 60 дней');

    // Estimate-only periods explain why a published-only search is empty.
    await page.getByRole('checkbox',{name:'Только опубликованные цены',exact:true}).check();
    await expect(page.getByRole('heading',{name:'Нет опубликованных тарифов по этим условиям',exact:true})).toBeVisible();
    await page.getByRole('button',{name:'Показать учебные расчёты',exact:true}).click();
    await expect(page.locator('.gym-row').first()).toContainText('2 месяца · 60 дней');
    if(width===1440){
      const mapResponse=page.waitForResponse(response=>response.url().includes('/api/gyms?')&&response.url().includes('map=1'));
      await page.getByRole('button',{name:'Карта',exact:true}).click();
      assert.equal((await (await mapResponse).json()).gyms.length,70);
      await expect(page.locator('.map-frame p')).toContainText('67 из 70');
      await expect(page.locator('.gym-cluster').first()).toBeVisible();
      await expect.poll(async()=>await page.locator('.leaflet-tile-loaded,.offline-map').count(),{timeout:8000}).toBeGreaterThan(0);
      await page.screenshot({path:'docs/design/map-all-1440.png'});
      await page.locator('.gym-cluster').first().click();
      await page.getByRole('button',{name:'Список',exact:true}).click();
      await expect(page.locator('.gym-row')).toHaveCount(20);
    }
    assert.deepEqual(errors,[]);
    console.log(`PASS ${width}px: 7 terms, two-month results, full price, comparison, source filter, no overflow/errors`);
    await page.close();
  }
}finally{await browser.close();}
