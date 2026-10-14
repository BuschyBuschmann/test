const {chromium}=require('/opt/node22/lib/node_modules/playwright');
(async()=>{const b=await chromium.launch({executablePath:'/opt/pw-browsers/chromium-1194/chrome-linux/chrome'});
const p=await b.newPage({viewport:{width:390,height:844},deviceScaleFactor:2});
for(const k of ['heute','session','checkup','profil','chats','physio']){await p.goto('file://'+process.cwd()+`/v2-${k}.html`);await p.waitForTimeout(400);await p.screenshot({path:`../v2-${k}.png`});}
await b.close()})()
