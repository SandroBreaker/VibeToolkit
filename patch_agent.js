const fs = require('fs');
const nodePath = require('path');

const agentPath = nodePath.join(__dirname, 'groq-agent.ts');

function assertFileExists(filePath) {
    if (!fs.existsSync(filePath)) {
        throw new Error(`Arquivo não encontrado: ${filePath}`);
    }
}

function replaceRange(lines, startLine, endLine, newLines) {
    lines.splice(startLine - 1, endLine - startLine + 1, ...newLines);
}

function applyKnownSafeRepairs(code) {
    const lines = code.split(/\r?\n/);

    replaceRange(lines, 1988, 1990, ['    ].join("\\n");', '}']);
    replaceRange(lines, 1860, 1862, ['    ].join("\\n");', '}']);
    replaceRange(lines, 1539, 1541, ['    ].join("\\n");', '}']);
    replaceRange(lines, 1439, 1442, ['        .join("\\n\\n");', '}']);
    replaceRange(lines, 1422, 1424, ['    ].join("\\n");', '}']);
    replaceRange(lines, 1385, 1387, ['    return lines.join("\\n");', '}']);

    let output = lines.join('\n');

    output = output.replace(
        '    process.exit(getExitCodeForErrorType(classified.errorType));\n})\nfunction assertDeterministicTemplateLoaded',
        '    process.exit(getExitCodeForErrorType(classified.errorType));\n});\n\nfunction assertDeterministicTemplateLoaded'
    );

    return output;
}

function validatePatchedCode(code) {
    const invalidFragments = [
        'return lines.join("\n");',
        '].join("\n");',
        '.join("\n\n");'
    ];

    for (const fragment of invalidFragments) {
        if (code.includes(fragment)) {
            throw new Error(`Padrão inválido detectado após patch: ${fragment}`);
        }
    }

    if (code.includes('process.exit(getExitCodeForErrorType(classified.errorType));\n})\nfunction assertDeterministicTemplateLoaded')) {
        throw new Error('Terminação do main().catch ainda está sem separação segura.');
    }
}

assertFileExists(agentPath);

const original = fs.readFileSync(agentPath, 'utf8');
const patched = applyKnownSafeRepairs(original);
validatePatchedCode(patched);

if (patched !== original) {
    fs.writeFileSync(agentPath + '.bak', original, 'utf8');
    fs.writeFileSync(agentPath, patched, 'utf8');
    console.log('Patch seguro aplicado em groq-agent.ts.');
    console.log(`Backup salvo em: ${agentPath}.bak`);
} else {
    console.log('Nenhuma reparação necessária. groq-agent.ts já está íntegro.');
}
