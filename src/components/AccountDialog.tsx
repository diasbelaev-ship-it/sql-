'use client';
import {useState} from 'react';
import {api,Account} from '@/lib/client';
export default function AccountDialog({onDone}:{onDone:(a:Account)=>void}){
 const [register,setRegister]=useState(false),[error,setError]=useState(''),[busy,setBusy]=useState(false);
 return <><h2>{register?'Создайте аккаунт':'С возвращением'}</h2><p className="muted">Сохраняйте залы и делитесь впечатлениями.</p><form onSubmit={async e=>{e.preventDefault();setBusy(true);setError('');const fd=new FormData(e.currentTarget);try{const d=await api(register?'auth/register':'auth/login','POST',Object.fromEntries(fd));onDone(d.user);}catch(e){setError((e as Error).message);}finally{setBusy(false);}}}>
 {register&&<label>Имя<input name="name" minLength={2} required autoComplete="name"/></label>}
 <label>Email<input name="email" type="email" required autoComplete="email"/></label><label>Пароль<input name="password" type="password" minLength={8} maxLength={100} required autoComplete={register?'new-password':'current-password'}/></label>
 {error&&<p role="alert" className="error">{error}</p>}<button className="primary" disabled={busy}>{busy?'Подождите…':register?'Зарегистрироваться':'Войти'}</button></form>
 <button className="text-button" onClick={()=>{setRegister(!register);setError('');}}>{register?'Уже есть аккаунт? Войти':'Создать аккаунт'}</button></>;
}
