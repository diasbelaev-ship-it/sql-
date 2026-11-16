'use client';
import {use,useEffect,useState} from 'react';
import Link from 'next/link';
import GymDetail from '@/components/GymDetail';
import AccountDialog from '@/components/AccountDialog';
import {api,Account} from '@/lib/client';
export default function GymPage({params}:{params:Promise<{id:string}>}){const {id}=use(params);const [me,setMe]=useState<Account|null>(null),[login,setLogin]=useState(false);useEffect(()=>{api('auth/me').then(d=>setMe(d.user)).catch(()=>{});},[]);return <main className="sql-page"><Link href="/">← К каталогу</Link>{login?<AccountDialog onDone={a=>{setMe(a);setLogin(false);}}/>:<GymDetail id={id} me={me} onLogin={()=>setLogin(true)}/>}</main>;}
