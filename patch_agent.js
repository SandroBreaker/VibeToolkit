const fs = require('fs');
const path = require('path');

const agentPath = path.join(__dirname, 'groq-agent.ts');

if (!fs.existsSync(agentPath)) {
  console.error('[patch] groq-agent.ts não encontrado.');
  process.exit(1);
}

let code = fs.readFileSync(agentPath, 'utf-8');
let mutated = false;

const replacements = [
  // Fix join("\n\n") -> join("\\n\\n")
  {
    search: /\.join\(\s*"\\n\\n"\s*\)/g,
    replace: '.join("\\n\\n")'
  },
  // Fix join("\n") -> join("\\n")
  {
    search: /\.join\(\s*"\\n"\s*\)/g,
    replace: '.join("\\n")'
  },
  // Fix missing closing brace on .catch block
  {
    search: /(process\.exit\(getExitCodeForErrorType\(classified\.errorType\)\);)\n\}\)\nfunction assertDeterministicTemplateLoaded/gs,
    replace: '$1\n});\n\nfunction assertDeterministicTemplateLoaded'
  }
];

for (const rule of replacements) {
  const before = code;
  code = code.replace(rule.search, rule.replace);
  if (code !== before) {
    mutated = true;
  }
}

// Validation
const forbidden = [/return lines\.join\("\\n"\);/, /]\.join\("\\n"\);/, /\.join\("\\n\\n"\);/];
for (const pattern of forbidden) {
  if (pattern.test(code)) {
    console.error('[patch] Padrão inválido persiste após aplicação. Abortando.');
    process.exit(2);
  }
}

if (mutated) {
  fs.writeFileSync(agentPath + '.bak', fs.readFileSync(agentPath, 'utf-8'), 'utf-8');
  fs.writeFileSync(agentPath, code, 'utf-8');
  console.log('[patch] Reparo seguro aplicado. Backup em groq-agent.ts.bak');
} else {
  console.log('[patch] Arquivo já está íntegro. Nenhuma mutação aplicada.');
}