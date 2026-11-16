import Link from 'next/link';
import Image from 'next/image';
import {pool} from '@/lib/db';
export const dynamic='force-dynamic';
export default async function SQL(){
 const stats=await pool.query(`SELECT 'gyms' name,count(*)::int count FROM almaty_gym.gyms UNION ALL SELECT 'plans',count(*)::int FROM almaty_gym.plans UNION ALL SELECT 'clients',count(*)::int FROM almaty_gym.clients`);
 const zones=await pool.query('SELECT * FROM almaty_gym.v_zone_summary ORDER BY city_zone,price_band');
 return <main className="sql-page"><Link href="/">← К каталогу</Link><h1>Город, залы и открытый SQL</h1><p>GymFinder — учебный проект на PostgreSQL и Next.js. Каталог загружается из базы: 10 таблиц SQL-кейса и отдельная схема служебных данных сайта.</p><div className="sql-stats">{stats.rows.map(s=><div key={s.name}><strong>{s.count}</strong><span>{({gyms:'залов',plans:'тарифов',clients:'клиентов'} as Record<string,string>)[s.name]}</span></div>)}</div><h2>Аналитика из представления</h2><pre>SELECT * FROM almaty_gym.v_zone_summary;</pre><div className="table-wrap"><table><thead><tr><th>Зона</th><th>Сегмент</th><th>Залы</th><th>Средняя цена взрослого</th></tr></thead><tbody>{zones.rows.map((z,i)=><tr key={i}><td>{z.city_zone}</td><td>{z.price_band}</td><td>{z.gym_count}</td><td>{Number(z.avg_adult_month_kzt).toLocaleString('ru-RU')} ₸</td></tr>)}</tbody></table></div><h2>Связи таблиц</h2><Image unoptimized src="/er-diagram.png" alt="ER-диаграмма десяти связанных таблиц базы Алматы" width="1600" height="1080"/><p>SQL-запросы и миграции — в db и docs.</p></main>;
}
