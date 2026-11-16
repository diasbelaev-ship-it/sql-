'use client';
import {useEffect,useRef,useState} from 'react';
import type {Gym} from '@/lib/client';
import 'leaflet/dist/leaflet.css';

export default function GymMap({gyms,onSelect,userLat,userLng,radiusKm}:{gyms:Gym[];onSelect:(id:string)=>void;userLat?:number;userLng?:number;radiusKm?:number}){
 const ref=useRef<HTMLDivElement>(null);
 const [tilesUnavailable,setTilesUnavailable]=useState(false);
 useEffect(()=>{
  let disposed=false;
  let map:import('leaflet').Map|undefined;
  import('leaflet').then(L=>{
   if(disposed||!ref.current)return;
   const leafletMap=L.map(ref.current,{zoomAnimation:false,fadeAnimation:false}).setView([43.25,76.90],12);
   map=leafletMap;
   let loadedTiles=0;
   L.tileLayer('https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png',{attribution:'© OpenStreetMap',maxZoom:16})
    .on('tileload',()=>{loadedTiles++;if(!disposed)setTilesUnavailable(false);})
    .on('tileerror',()=>{if(!disposed&&!loadedTiles)setTilesUnavailable(true);})
    .addTo(leafletMap);
   const visible=gyms.filter(g=>g.geo_accuracy_m<=1000);
   const layer=L.layerGroup().addTo(leafletMap);
   const points:[number,number][] = visible.map(g=>[+g.latitude,+g.longitude]);
   if(userLat!==undefined&&userLng!==undefined){
    const userPoint:[number,number]=[userLat,userLng];points.push(userPoint);
    const userLayer=L.layerGroup().addTo(leafletMap);
    if(radiusKm){
     const circle=L.circle(userPoint,{radius:radiusKm*1000,color:'#1b6e66',weight:2,fillColor:'#1b6e66',fillOpacity:.08});
     userLayer.addLayer(circle);
     const bounds=circle.getBounds();points.push([bounds.getNorthEast().lat,bounds.getNorthEast().lng],[bounds.getSouthWest().lat,bounds.getSouthWest().lng]);
    }
    L.marker(userPoint,{icon:L.divIcon({className:'user-location-marker',html:'<span>Вы</span>',iconSize:[42,42]})}).bindTooltip('Ваше местоположение').addTo(userLayer);
   }
   if(points.length)leafletMap.fitBounds(L.latLngBounds(points),{padding:[35,35],maxZoom:userLat!==undefined?15:13});
   const render=()=>{
    layer.clearLayers();
    const groups:{x:number;y:number;items:{gym:Gym;number:number}[]}[]=[];
    visible.forEach((gym,i)=>{
     const point=leafletMap.project([+gym.latitude,+gym.longitude]);
     const group=groups.find(group=>(group.x-point.x)**2+(group.y-point.y)**2<48**2);
     if(group){group.items.push({gym,number:i+1});group.x=(group.x*(group.items.length-1)+point.x)/group.items.length;group.y=(group.y*(group.items.length-1)+point.y)/group.items.length;}
     else groups.push({x:point.x,y:point.y,items:[{gym,number:i+1}]});
    });
    for(const group of groups){
     const first=group.items[0].gym;
     const cluster=group.items.length>1;
     const anchor=leafletMap.unproject([group.x,group.y]);
     const marker=L.marker(anchor,{icon:L.divIcon({className:cluster?'gym-marker gym-cluster':'gym-marker',html:`<span>${cluster?group.items.length:group.items[0].number}</span>`,iconSize:[36,36]})}).addTo(layer);
     marker.bindTooltip(cluster?`${group.items.length} залов`:first.name);
     marker.on('click',()=>{
      if(!cluster){onSelect(first.id);return;}
      if(leafletMap.getZoom()<16){leafletMap.fitBounds(L.latLngBounds(group.items.map(({gym})=>[+gym.latitude,+gym.longitude] as [number,number])),{padding:[50,50],maxZoom:Math.min(leafletMap.getZoom()+2,16)});return;}
      const list=document.createElement('div');list.className='map-cluster-list';
      for(const {gym} of group.items){const button=document.createElement('button');button.type='button';button.textContent=gym.name;button.addEventListener('click',()=>onSelect(gym.id));list.append(button);}
      marker.bindPopup(list).openPopup();
     });
    }
   };
   leafletMap.on('zoomend',render);render();
  });
  return()=>{disposed=true;map?.stop();map?.remove();};
 },[gyms,onSelect,userLat,userLng,radiusKm]);
 return <div className={tilesUnavailable?'map-frame offline-map':'map-frame'}><div ref={ref} className="map" aria-label="Карта залов"/></div>;
}
