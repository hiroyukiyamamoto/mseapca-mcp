fetch('config.json').then(r=>{if(!r.ok)throw Error('config');return r.json()}).then(c=>{
 const node=document.getElementById('endpoint');
 if(c.endpoint){const u=new URL(c.endpoint);if(u.protocol!=='https:'||!u.pathname.endsWith('/mcp'))throw Error('endpoint');node.textContent=c.endpoint;
 document.getElementById('claude-command').textContent=c.access==='private'?'Hosted endpoint is private (Google Cloud IAM). See local setup in the repository.':'claude mcp add --transport http mseapca-mcp '+c.endpoint;}
 else{node.textContent='Not deployed yet';document.getElementById('claude-command').textContent='Remote endpoint pending. See local setup in the repository.';}
}).catch(()=>{document.getElementById('endpoint').textContent='Endpoint configuration unavailable';});
