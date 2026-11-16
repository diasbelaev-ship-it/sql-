const retryDelay:Record<string,number>={
  invalid_key:120_000,
  not_configured:120_000,
  model_not_available:120_000,
  invalid_request:60_000,
  quota:60_000,
  overloaded:20_000,
  network:20_000,
  timeout:20_000,
};

let lastFailure:{code:string;until:number}|undefined;

export function geminiCooldownCode(now=Date.now()):string|undefined{
  if(!lastFailure||lastFailure.until<=now){lastFailure=undefined;return undefined;}
  return lastFailure.code;
}

export function recordGeminiFailure(code:string,now=Date.now()):void{
  const delay=retryDelay[code];
  if(delay)lastFailure={code,until:now+delay};
}

export function clearGeminiCooldown():void{lastFailure=undefined;}
