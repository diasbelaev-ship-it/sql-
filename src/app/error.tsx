'use client';
export default function ErrorPage({reset}:{reset:()=>void}){return <main className="sql-page"><h1>Не удалось загрузить страницу</h1><p>Проверьте подключение PostgreSQL. Для локального запуска выполните npm run db:setup.</p><button onClick={reset}>Повторить загрузку</button></main>;}
