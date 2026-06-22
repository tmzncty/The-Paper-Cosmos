import { readFileSync, readdirSync, writeFileSync } from 'fs';
import { join } from 'path';

const draftsDir = 'C:/Users/Administrator/Documents/纸上宇宙/drafts';

const allFiles = readdirSync(draftsDir)
  .filter(f => /^ch\d+_/.test(f) && f.endsWith('.md') && !f.includes('review') && !f.includes('fix') && !f.includes('repetition') && !f.includes('density') && !f.includes('cjk') && !f.includes('.bak'))
  .sort((a, b) => {
    const na = parseInt(a.match(/^ch(\d+)/)[1]);
    const nb = parseInt(b.match(/^ch(\d+)/)[1]);
    return na - nb;
  });

const chapterMap = new Map();
for (const f of allFiles) {
  const chNum = parseInt(f.match(/^ch(\d+)/)[1]);
  if (f.includes('_v2')) chapterMap.set(chNum, f);
  else if (!chapterMap.has(chNum)) chapterMap.set(chNum, f);
}

const chapters = [...chapterMap.entries()].sort((a, b) => a[0] - b[0]);

function countCJK(text) {
  return (text.match(/[\u4e00-\u9fff\u3400-\u4dbf]/g) || []).length;
}

const results = [];

for (const [chNum, fileName] of chapters) {
  const content = readFileSync(join(draftsDir, fileName), 'utf-8');
  const cjkCount = countCJK(content);
  const paragraphs = content.split(/\n\s*\n/).filter(p => p.trim().length > 0);
  const paraLengths = paragraphs.map(p => countCJK(p)).filter(l => l > 0);
  
  const gouleCount = (content.match(/够了/g) || []).length;
  const zuiShiCount = (content.match(/是最/g) || []).length;
  const buXuyaoCount = (content.match(/不需要/g) || []).length;
  const jiuShiCount = (content.match(/就是/g) || []).length;
  const bushiShiMatches = content.match(/不是.{0,10}是/g) || [];
  const meanPattern = (content.match(/意味着/g) || []).length;
  const dashCount = (content.match(/——/g) || []).length;
  
  const avgParaLen = paraLengths.length > 0 ? paraLengths.reduce((a, b) => a + b, 0) / paraLengths.length : 0;
  const maxParaLen = paraLengths.length > 0 ? Math.max(...paraLengths) : 0;
  const minParaLen = paraLengths.length > 0 ? Math.min(...paraLengths) : 0;
  
  let maxCL = 0, curCL = 0, maxCS = 0, curCS = 0;
  for (const len of paraLengths) {
    if (len > 200) { curCL++; maxCL = Math.max(maxCL, curCL); } else curCL = 0;
    if (len < 50) { curCS++; maxCS = Math.max(maxCS, curCS); } else curCS = 0;
  }
  
  const factor = cjkCount > 0 ? 1000 / cjkCount : 0;
  
  results.push({
    ch: chNum, file: fileName, cjk: cjkCount, paragraphs: paraLengths.length,
    avgParaLen: Math.round(avgParaLen), maxParaLen, minParaLen,
    maxCL, maxCS,
    goule: gouleCount, gouleD: +(gouleCount * factor).toFixed(2),
    zuiShi: zuiShiCount, zuiShiD: +(zuiShiCount * factor).toFixed(2),
    buXuyao: buXuyaoCount, buXuyaoD: +(buXuyaoCount * factor).toFixed(2),
    jiuShi: jiuShiCount, jiuShiD: +(jiuShiCount * factor).toFixed(2),
    bushiShi: bushiShiMatches.length, bushiShiD: +(bushiShiMatches.length * factor).toFixed(2),
    meanYiwei: meanPattern, dashes: dashCount
  });
}

const avg = (arr, key) => (arr.reduce((a, b) => a + b[key], 0) / arr.length).toFixed(2);

console.log(`Total chapters: ${results.length}`);
console.log(`Total CJK: ${results.reduce((a, b) => a + b.cjk, 0)}`);

console.log('\n=== Avg Density /1000CJK ===');
console.log(`够了: ${avg(results, 'gouleD')} | 是最: ${avg(results, 'zuiShiD')} | 不需要: ${avg(results, 'buXuyaoD')} | 就是: ${avg(results, 'jiuShiD')} | 不是...是: ${avg(results, 'bushiShiD')} | 意味着: ${avg(results, 'meanYiwei')}`);

console.log('\n=== TOP 10 "够了" density ===');
[...results].sort((a,b) => b.gouleD - a.gouleD).slice(0,10).forEach(r => 
  console.log(`  ch${String(r.ch).padStart(3,'0')}: ${r.gouleD}‰ (${r.goule}次,${r.cjk}字)`));

console.log('\n=== TOP 10 "是最" density ===');
[...results].sort((a,b) => b.zuiShiD - a.zuiShiD).slice(0,10).forEach(r => 
  console.log(`  ch${String(r.ch).padStart(3,'0')}: ${r.zuiShiD}‰ (${r.zuiShi}次,${r.cjk}字)`));

console.log('\n=== TOP 10 "就是" density ===');
[...results].sort((a,b) => b.jiuShiD - a.jiuShiD).slice(0,10).forEach(r => 
  console.log(`  ch${String(r.ch).padStart(3,'0')}: ${r.jiuShiD}‰ (${r.jiuShi}次,${r.cjk}字)`));

console.log('\n=== TOP 10 "不是...是" density ===');
[...results].sort((a,b) => b.bushiShiD - a.bushiShiD).slice(0,10).forEach(r => 
  console.log(`  ch${String(r.ch).padStart(3,'0')}: ${r.bushiShiD}‰ (${r.bushiShi}次,${r.cjk}字)`));

console.log('\n=== TOP 10 "意味着" count ===');
[...results].sort((a,b) => b.meanYiwei - a.meanYiwei).slice(0,10).forEach(r => 
  console.log(`  ch${String(r.ch).padStart(3,'0')}: ${r.meanYiwei}次 (${r.cjk}字)`));

console.log('\n=== Para rhythm: 10+ consecutive long (>200 CJK) ===');
results.filter(r => r.maxCL >= 10).forEach(r => 
  console.log(`  ch${String(r.ch).padStart(3,'0')}: max ${r.maxCL} consecutive long`));

console.log('\n=== Para rhythm: 10+ consecutive short (<50 CJK) ===');
results.filter(r => r.maxCS >= 10).forEach(r => 
  console.log(`  ch${String(r.ch).padStart(3,'0')}: max ${r.maxCS} consecutive short`));

console.log('\n=== Per-chapter paragraph stats ===');
results.forEach(r => {
  console.log(`ch${String(r.ch).padStart(3,'0')}: ${r.cjk}字 ${r.paragraphs}段 avg${r.avgParaLen} max${r.maxParaLen} 长连${r.maxCL} 短连${r.maxCS}`);
});

const arcs = [
  { name: 'Arc1 (01-30)', s: 1, e: 30 },
  { name: 'Arc2 (31-60)', s: 31, e: 60 },
  { name: 'Arc3 (61-80)', s: 61, e: 80 },
  { name: 'Arc4a (81-100)', s: 81, e: 100 },
  { name: 'Arc4b (101-120)', s: 101, e: 120 }
];

console.log('\n=== Arc Summary ===');
for (const arc of arcs) {
  const a = results.filter(r => r.ch >= arc.s && r.ch <= arc.e);
  console.log(`\n${arc.name} (${a.length}ch, ${a.reduce((x,y) => x+y.cjk, 0)}字):`);
  console.log(`  够了:${avg(a,'gouleD')} 是最:${avg(a,'zuiShiD')} 就是:${avg(a,'jiuShiD')} 不是..是:${avg(a,'bushiShiD')} 意味着:${avg(a,'meanYiwei')}`);
  console.log(`  段落avg:${Math.round(a.reduce((x,y)=>x+y.avgParaLen,0)/a.length)} | 长连max:${Math.max(...a.map(r=>r.maxCL))} | 短连max:${Math.max(...a.map(r=>r.maxCS))}`);
}

writeFileSync(join(draftsDir, '_style_analysis_data.json'), JSON.stringify(results, null, 2));
console.log('\nData saved.');
