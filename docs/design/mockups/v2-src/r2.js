const {chromium}=require('/opt/node22/lib/node_modules/playwright');
(async()=>{const b=await chromium.launch({executablePath:'/opt/pw-browsers/chromium-1194/chrome-linux/chrome'});
const p=await b.newPage({viewport:{width:390,height:+process.argv[4]},deviceScaleFactor:2});
await p.goto('file://'+process.argv[2]);await p.waitForTimeout(600);await p.screenshot({path:process.argv[3]});await b.close()})()
