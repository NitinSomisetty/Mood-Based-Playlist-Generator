// This offline fallback uses the same eight 48-dimension mood regions as the
// seed vectors, so pgvector still produces meaningful query-dependent rankings.
// Production deployments can replace it with all-MiniLM-L6-v2 inference.
export async function embedText(text:string):Promise<number[]>{
  const lower=text.toLowerCase();
  const groups=[
    ["happy","joy","bright","fun","celebrate","party"],
    ["calm","rain","peaceful","relax","quiet","sleep"],
    ["energy","energetic","workout","run","hype","dance"],
    ["sad","blue","heartbreak","lonely","emotional","cry"],
    ["focus","study","concentrate","coding","work","deep"],
    ["romantic","love","date","warm","intimate","kiss"],
    ["nostalgic","memory","retro","throwback","familiar","old"],
    ["chill","laid-back","mellow","breeze","sunset","easy"]
  ];
  const weights=groups.map(words=>words.reduce((score,word)=>score+(lower.includes(word)?1:0),0));
  if(!weights.some(Boolean)) weights[7]=1;
  const values=Array.from({length:384},(_,index)=>{
    const cluster=Math.floor(index/48);
    const weight=weights[cluster];
    return weight+0.02*Math.sin(index+text.length);
  });
  const norm=Math.sqrt(values.reduce((sum,value)=>sum+value*value,0));
  return values.map(value=>value/norm);
}
