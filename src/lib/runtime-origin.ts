type RuntimeEnvironment = Record<string,string|undefined>;

const LOCAL_ORIGIN='http://127.0.0.1:3000';

export function getSiteOrigin(env:RuntimeEnvironment=process.env):string{
  for(const candidate of [env.APP_ORIGIN,env.RENDER_EXTERNAL_URL]){
    const value=candidate?.trim();
    if(!value)continue;
    try{
      const url=new URL(value);
      if(url.protocol==='http:'||url.protocol==='https:')return url.origin;
    }catch{
      // Try the next configured source, then fall back to local development.
    }
  }
  return LOCAL_ORIGIN;
}

export function isSecureSiteOrigin(env:RuntimeEnvironment=process.env):boolean{
  return new URL(getSiteOrigin(env)).protocol==='https:';
}
