import {createServer} from 'node:http';
import {readFile} from 'node:fs/promises';
import {resolve,extname} from 'node:path';
const root=resolve('docs');
createServer(async(req,res)=>{try{const path=resolve(root,'.'+decodeURIComponent(new URL(req.url,'http://localhost').pathname));if(!path.startsWith(root+'/')&&!path.startsWith(root+'\\')&&path!==root)throw Error('path');const file=path===root?path+'/index.html':path;const data=await readFile(file);res.setHeader('Content-Type',({'.html':'text/html','.json':'application/json','.js':'text/javascript','.css':'text/css','.svg':'image/svg+xml'})[extname(file)]||'text/plain');res.end(data)}catch{res.writeHead(404);res.end('Not found')}}).listen(8765,'127.0.0.1');
