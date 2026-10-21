const {chromium}=require('/opt/node22/lib/node_modules/playwright');
(async()=>{const b=await chromium.launch({executablePath:'/opt/pw-browsers/chromium-1194/chrome-linux/chrome'});
const p=await b.newPage({viewport:{width:390,height:844},deviceScaleFactor:2});
for(const k of ['morgen','mittag','abend','nacht']){await p.goto('file://'+process.cwd()+`/v2-ansatz3-${k}.html`);await p.waitForTimeout(500);await p.screenshot({path:`../v2-ansatz3-${k}.png`});}
const q=await b.newPage({viewport:{width:1640,height:900},deviceScaleFactor:1});
await q.goto('file://'+process.cwd()+'/v2-ansatz3-tageszeiten.html');await q.waitForTimeout(500);await q.screenshot({path:'../v2-ansatz3-tageszeiten.png'});await b.close()})()
