import type { Metadata } from 'next';
import '@fontsource/manrope/cyrillic-400.css';
import '@fontsource/manrope/cyrillic-600.css';
import '@fontsource/manrope/latin-400.css';
import '@fontsource/manrope/latin-600.css';
import './globals.css';
import './refinements.css';
import './assistant.css';
import './assistant-dock.css';
export const metadata:Metadata={title:'GymFinder — залы Алматы',description:'Каталог залов Алматы, тарифы и карта.'};
export default function Layout({children}:{children:React.ReactNode}){return <html lang="ru"><body>{children}</body></html>;}
