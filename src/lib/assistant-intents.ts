/** Recommendations need fresh catalog facts, even when the browser already supplies result IDs. */
export function requestsRecommendations(message:string):boolean {
  return /порекоменду|рекоменду|посовет|совету|подбер|подбир|что\s+(?:мне\s+)?выбрать|какие?\s+зал|какой\s+зал|хорош(?:ий|ие)\s+зал|зал.*рядом/i.test(message);
}
