import type {Gym} from './client';
import type {Filters} from './filters';

export type AssistantAction =
  | {type:'open_gym';gymId:string}
  | {type:'view';view:'catalog'|'favorites'|'map'|'list'|'sql'}
  | {type:'compare';gymIds:string[]}
  | {type:'login'}
  | {type:'favorites_changed'};

export type PendingReview = {
  confirmationId:string; gymId:string; gymName:string; rating:number; content:string;
};

export type AssistantResponse = {
  sessionId:string; answer:string; filters?:Filters; gyms?:Gym[];
  actions?:AssistantAction[]; provider?:'gemini'|'local'; providerNotice?:string; pendingReview?:PendingReview;
};

export type AssistantPageContext = {filters:Filters;view:string;resultIds?:string[]};
