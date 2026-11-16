import { pool } from './db';
import type {PoolClient} from 'pg';
import type { Filters } from './filters';
import { getTermBounds } from './subscription-terms';
export async function searchGyms(f:Filters,accountId?:string,favoritesOnly=false,db:Pick<PoolClient,'query'>=pool,mapAll=false){
 const params=[f.audience,f.term,f.q,f.zone,f.band,f.max,f.published,accountId??null,f.lat??null,f.lng??null,favoritesOnly,...getTermBounds(f.term)];
 const cte=`WITH chosen AS (
 SELECT g.*,p.id plan_id,p.name plan_name,p.price_kzt,p.duration_days,p.price_basis,p.price_source_url,p.price_checked_on,
 round(p.price_kzt*30.0/p.duration_days)::int monthly,
 EXISTS(SELECT 1 FROM gym_web.favorites x WHERE x.gym_id=g.id AND x.account_id=$8::bigint) favorite,
 CASE WHEN $9::float8 IS NOT NULL AND g.geo_accuracy_m<=1000 THEN 6371*2*asin(sqrt(least(1.0,power(sin(radians(g.latitude::float8-$9::float8)/2),2)+cos(radians($9::float8))*cos(radians(g.latitude::float8))*power(sin(radians(g.longitude::float8-$10::float8)/2),2)))) END distance
 FROM almaty_gym.gyms g CROSS JOIN LATERAL (
 SELECT * FROM almaty_gym.plans p WHERE p.gym_id=g.id AND p.audience=$1
 AND ($2='any' OR p.duration_days BETWEEN $12::integer AND $13::integer)
 AND ($7='' OR p.price_basis='published') AND round(p.price_kzt*30.0/p.duration_days)<=$6
 ORDER BY p.price_kzt*30.0/p.duration_days,p.id LIMIT 1) p
 WHERE ($3='' OR g.name ILIKE '%'||$3||'%' OR g.address ILIKE '%'||$3||'%')
 AND ($4='' OR g.city_zone=$4) AND ($5='' OR g.price_band=$5)
 AND (NOT $11::boolean OR EXISTS(SELECT 1 FROM gym_web.favorites fav WHERE fav.gym_id=g.id AND fav.account_id=$8::bigint)))`;
 const orders={verified:"CASE WHEN price_basis='published' THEN 0 ELSE 1 END,monthly,id",price:'monthly,id',price_desc:'monthly DESC,id',name:'name,id',distance:'distance NULLS LAST,id',distance_desc:'distance DESC NULLS LAST,id'};
 const withinRadius='($14::float8 IS NULL OR (distance IS NOT NULL AND distance<=$14::float8))';
 const total=await db.query(cte+` SELECT count(*)::int total FROM chosen WHERE ${withinRadius}`,[...params,f.radiusKm??null]);
 const rows=await db.query(cte+` SELECT * FROM chosen WHERE ${withinRadius} ORDER BY ${orders[f.sort]} LIMIT $15 OFFSET $16`,[...params,f.radiusKm??null,mapAll?100:20,mapAll?0:(f.page-1)*20]);
 return {gyms:rows.rows,total:total.rows[0].total,page:f.page};
}
