const {chromium}=require('/opt/node22/lib/node_modules/playwright');
(async()=>{const b=await chromium.launch({executablePath:'/opt/pw-browsers/chromium-1194/chrome-linux/chrome'});
const p=await b.newPage({viewport:{width:390,height:844},deviceScaleFactor:2});
for(const k of ['codestart-look','codestart-code','einwilligung','checkup-schwellung','checkup-einschraenkung','frage-physio','hinweis-heute','kachel2','pfad-ausgelassen']){await p.goto('file://'+process.cwd()+`/v2-e2-${k}.html`);await p.waitForTimeout(500);await p.screenshot({path:`../v2-e2-${k}.png`});}
await b.close()})()
