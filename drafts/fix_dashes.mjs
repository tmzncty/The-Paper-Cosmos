import fs from 'fs';
import path from 'path';

const baseDir = 'C:\\Users\\Administrator\\Documents\\纸上宇宙\\drafts';

const fixes = [
  { file: 'spinoff1_ch1_浪漫之晨.md', limit: 15 },
  { file: 'spinoff1_ch2_雪与火.md', limit: 15 },
  { file: 'spinoff1_ch3_人间喜剧.md', limit: 15 },
];

for (const { file, limit } of fixes) {
  const filePath = path.join(baseDir, file);
  let text = fs.readFileSync(filePath, 'utf-8');
  
  const knowIdx = text.indexOf('知识清单');
  let story = knowIdx > 0 ? text.substring(0, knowIdx) : text;
  const knowledge = knowIdx > 0 ? text.substring(knowIdx) : '';
  
  const dashPattern = /——/g;
  let matches = [];
  let m;
  while ((m = dashPattern.exec(story)) !== null) {
    matches.push(m.index);
  }
  
  console.log(`${file}: ${matches.length} dashes, need to remove ${matches.length - limit}`);
  
  if (matches.length <= limit) {
    console.log('  Already within limit');
    continue;
  }
  
  let result = '';
  let lastIdx = 0;
  let dashCount = 0;
  let removed = 0;
  
  for (const pos of matches) {
    if (dashCount >= limit) {
      // Replace this dash with a comma or nothing
      const before = story.substring(Math.max(0, pos - 20), pos);
      const after = story.substring(pos + 2, pos + 20);
      
      let replacement = '，';
      // If the dash is at a sentence-like boundary, just remove it
      if (/。$/.test(before.trim()) || /^[她他我你它她们他们她们]/.test(after.trim())) {
        replacement = '';
      }
      
      result += story.substring(lastIdx, pos) + replacement;
      lastIdx = pos + 2;
      removed++;
    }
    dashCount++;
  }
  result += story.substring(lastIdx);
  
  fs.writeFileSync(filePath, result + knowledge, 'utf-8');
  
  // Verify
  const verifyText = fs.readFileSync(filePath, 'utf-8');
  const verifyStory = knowIdx > 0 ? verifyText.substring(0, verifyText.indexOf('知识清单')) : verifyText;
  const finalDashes = (verifyStory.match(/——/g) || []).length;
  console.log(`  After: ${finalDashes} dashes, removed ${removed}`);
}
