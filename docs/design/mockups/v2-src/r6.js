const {chromium}=require('/opt/node22/lib/node_modules/playwright');
(async()=>{const b=await chromium.launch({executablePath:'/opt/pw-browsers/chromium-1194/chrome-linux/chrome'});
const q=await b.newPage({viewport:{width:1250,height:1900},deviceScaleFactor:1});
await q.goto('file://'+process.cwd()+'/v2-grunddesign-uebersicht.html');await q.waitForTimeout(600);await q.screenshot({path:'../v2-grunddesign-uebersicht.png',fullPage:true});await b.close()})()
