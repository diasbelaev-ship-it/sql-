import Link from 'next/link';
import {ArrowUpRight,MapPin,Mountain} from 'lucide-react';
import './guide.css';

const searches=[
  {label:'Студент · до 20 000 ₸',href:'/?audience=student&max=20000&sort=price&page=1'},
  {label:'Взрослый · центр',href:'/?audience=adult&zone=center&sort=verified&page=1'},
  {label:'Премиум · запад',href:'/?audience=premium&zone=west&sort=verified&page=1'},
];

export default function GuidePage(){
  return <>
    <header className="guide-header">
      <Link className="brand" href="/" aria-label="GymFinder, каталог"><Mountain size={35} strokeWidth={1.7}/><strong>GymFinder</strong></Link>
      <span className="city"><MapPin size={17}/> Алматы</span>
      <nav aria-label="Основная навигация"><Link href="/">Каталог</Link><Link href="/guide" aria-current="page" className="active">Возможности</Link></nav>
    </header>
    <main className="guide-page">
      <section className="guide-hero">
        <div className="guide-intro">
          <h1>Что умеет GymFinder</h1>
          <p>Найдите зал в Алматы, сравните тарифы и выберите удобное место.</p>
          <Link className="guide-primary" href="/">Открыть каталог <ArrowUpRight size={16}/></Link>
        </div>
        <section className="guide-quick" data-ui aria-labelledby="guide-quick-title">
          <h2 id="guide-quick-title">Начать с готового поиска</h2>
          <p>Выберите запрос — каталог откроется с фильтрами.</p>
          <div className="guide-shortcuts">{searches.map(search=><Link key={search.label} href={search.href}>{search.label}<ArrowUpRight size={15}/></Link>)}</div>
        </section>
      </section>

      <section className="guide-section" id="catalog">
        <div><h2>Подбор по параметрам</h2><p>Ищите зал по названию или адресу. Фильтруйте по категории, бюджету за 30 дней, сроку абонемента, району и ценовому сегменту.</p></div>
        <div className="guide-detail" data-ui><h3>В каталоге</h3><ul><li>Список и карта</li><li>Сортировка по цене и расстоянию</li><li>Фильтр опубликованных тарифов</li></ul></div>
      </section>

      <section className="guide-section" id="map">
        <div><h2>Карта и залы рядом</h2><p>Переключитесь на карту или нажмите «Найти залы рядом». После разрешения браузера выберите радиус от 1 до 20 км.</p></div>
        <div className="guide-detail guide-detail-wide" data-ui><h3>Расстояние до зала</h3><p>Каталог отсортирует подходящие места ближе к вам. Геолокация нужна только для поиска рядом.</p><Link href="/">Перейти к карте <ArrowUpRight size={15}/></Link></div>
      </section>

      <section className="guide-section" id="compare">
        <div><h2>Сравнение и избранное</h2><p>Отметьте до трёх залов и сравните цены выбранной категории и срока. Сохраняйте варианты в избранное, чтобы быстро вернуться к ним.</p></div>
        <div className="guide-detail guide-detail-lines" data-ui><h3>В карточке зала</h3><p>Адрес, тарифы, ссылки на источники цен и отзывы.</p><p>Чтобы сохранять залы и оставлять отзывы, войдите в аккаунт.</p></div>
      </section>

      <section className="guide-section guide-assistant" id="assistant">
        <div><h2>Помощник GymFinder</h2><p>Пишите обычным языком. Помощник подберёт варианты, применит фильтры, откроет карту или карточку, сравнит и сохранит выбранные залы.</p><Link href="/">Открыть каталог и помощника <ArrowUpRight size={15}/></Link></div>
        <div className="guide-examples" data-ui><p>«Я студент, до 20 тысяч на западе»</p><p>«Сравни первый и третий зал»</p><p>«Покажи карту и добавь первый зал в избранное»</p></div>
      </section>
    </main>
  </>;
}
