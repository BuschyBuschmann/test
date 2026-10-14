const {chromium}=require('/opt/node22/lib/node_modules/playwright');
(async()=>{const b=await chromium.launch({executablePath:'/opt/pw-browsers/chromium-1194/chrome-linux/chrome'});
let p=await b.newPage({viewport:{width:780,height:920},deviceScaleFactor:1.5});
await p.goto('file://'+process.cwd()+'/v2-manny-sticker.html');await p.waitForTimeout(400);await p.screenshot({path:'../v2-manny-sticker.png'});
p=await b.newPage({viewport:{width:390,height:844},deviceScaleFactor:2});
await p.goto('file://'+process.cwd()+'/v2-ansatz4-abend.html');await p.waitForTimeout(400);await p.screenshot({path:'../v2-ansatz4-abend.png'});await b.close()})()
