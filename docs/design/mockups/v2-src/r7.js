const {chromium}=require('/opt/node22/lib/node_modules/playwright');
(async()=>{const b=await chromium.launch({executablePath:'/opt/pw-browsers/chromium-1194/chrome-linux/chrome'});
const q=await b.newPage({viewport:{width:1300,height:790},deviceScaleFactor:1.5});
await q.goto('file://'+process.cwd()+'/v2-manny-varianten.html');await q.waitForTimeout(500);await q.screenshot({path:'../v2-manny-varianten.png'});await b.close()})()
