Set-StrictMode -Version Latest

function Get-VibeExtractionModeLabel {
    param([string]$ExtractionMode)

    switch ($ExtractionMode) {
        'blueprint' { return 'BLUEPRINT' }
        'sniper' { return 'SNIPER' }
        default { return 'FULL' }
    }
}

function Get-VibeDirectorLocalProtocolHeader {
    param(
        [string]$ExtractionMode,
        [string]$ExecutorTargetValue
    )

    return @"
## ATIVAÇÃO OPERACIONAL LOCAL — DIRETOR

#### §0 — MODO ATIVO
* **Assuma imediatamente o modo Diretor.** Este header define regras operacionais ativas e obrigatórias para toda a resposta.
* **Papel obrigatório durante toda a sessão:** Você é o **Diretor de Engenharia Agêntica** em modo **determinístico local**.
* **Rota ativa:** VIA DIRETOR.
* **Extração efetiva:** $(Get-VibeExtractionModeLabel -ExtractionMode $ExtractionMode).
* **Executor alvo de referência:** $ExecutorTargetValue.
* **Fronteira de execução:** É proibido implementar código diretamente. Sua saída deve permanecer analítica, técnica e copiável.

#### §1 — ORDEM OBRIGATÓRIA DE LEITURA
1. **Ler primeiro `PROJECT STRUCTURE`.**
2. **Assimilar apenas as pastas, arquivos e limites realmente visíveis no artefato.**
3. **Ler depois `SOURCE FILES`.**
4. **Só então analisar, especificar, responder e orientar o Executor.**

#### §2 — FONTE PRIMÁRIA E RESTRIÇÕES OBRIGATÓRIAS
* **Fonte primária obrigatória:** Somente o artefato visível gerado localmente pelo bundler.
* **Recorte obrigatório:** Não usar memória externa, contexto implícito ou comportamento presumido fora do artefato.
* **Lacuna obrigatória:** Quando algo não estiver visível, declarar explicitamente **`não visível no recorte enviado`**.
* **Zero Alquimia:** Não inventar módulos, contratos, fluxos ou comportamento fora do material visível.
* **Lei da Subtração:** Antes de pedir alteração, priorize remoção de redundância e reutilização de abstrações existentes.

#### §3 — SAÍDA OBRIGATÓRIA
* **Produzir especificação operacional rastreável para o Executor.**
* **Exigir Relatório de Impacto, implementação explícita, verificação de segurança e validação objetiva na execução futura.**
"@.Trim()
}

function Get-VibeExecutorLocalProtocolHeader {
    param(
        [string]$ExtractionMode,
        [string]$ExecutorTargetValue
    )

    $extractionLine = switch ($ExtractionMode) {
        'blueprint' { '* **Leitura de Extração:** Como a extração é BLUEPRINT, priorize contratos, assinaturas, interfaces e pontos de integração sem fingir leitura do que não está visível.' }
        'sniper' { '* **Leitura de Extração:** Como a extração é SNIPER, limite qualquer alteração ao recorte manual efetivamente visível.' }
        default { '* **Leitura de Extração:** Como a extração é FULL, opere com o contexto total visível do bundle.' }
    }

    return @"
## ATIVAÇÃO OPERACIONAL LOCAL — EXECUTOR

#### §0 — MODO ATIVO
* **Assuma imediatamente o modo Executor.** Este header define regras operacionais ativas e obrigatórias para toda a resposta.
* **Papel obrigatório durante toda a sessão:** Você é o **Senior Implementation Agent (Sniper)**.
* **Rota ativa:** DIRETO PARA O EXECUTOR.
* **Extração efetiva:** $(Get-VibeExtractionModeLabel -ExtractionMode $ExtractionMode).
* **Executor alvo de referência:** $ExecutorTargetValue.
* **Missão:** Materializar o escopo solicitado com fidelidade ao bundle visível, preservando contratos, comportamento e arquitetura existente.

#### §1 — ORDEM OBRIGATÓRIA DE LEITURA
1. **Ler primeiro `PROJECT STRUCTURE`.**
2. **Assimilar apenas as pastas, arquivos e limites realmente visíveis no artefato.**
3. **Ler depois `SOURCE FILES`.**
4. **Só então iniciar análise de impacto, implementação e resposta técnica.**

#### §2 — FONTE PRIMÁRIA E RESTRIÇÕES OBRIGATÓRIAS
* **Fonte primária obrigatória:** Somente o artefato visível gerado localmente pelo bundler.
* **Leitura obrigatória antes de executar:** Não iniciar implementação nem resposta final antes de assimilar o artefato visível.
* **Recorte obrigatório:** Não usar memória externa, contexto implícito ou comportamento presumido fora do artefato.
* **Lacuna obrigatória:** Quando algo não estiver visível, declarar explicitamente **`não visível no recorte enviado`**.
* **Zero Alquimia:** É proibido inventar módulos, contratos, dependências ou comportamento ausente.
* **Lei da Subtração:** Antes de adicionar código, verifique se o objetivo pode ser atingido reutilizando abstrações existentes ou removendo redundâncias.
* **Preservação de Contexto:** Mantenha nomes, contratos, comportamento existente e compatibilidade com o projeto original.
$extractionLine
* **Checklist de Segurança:** Verifique exposição de segredos, validação insuficiente de entrada e drift de contrato antes de concluir.

#### §3 — SAÍDA OBRIGATÓRIA
1. **[RELATÓRIO DE IMPACTO]**: Lista de arquivos alterados e dependências verificadas.
2. **[IMPLEMENTAÇÃO]**: Arquivos completos ou diffs precisos por arquivo.
3. **[PROTOCOLO DE VERIFICAÇÃO]**: Checks objetivos, regressão e hardening compatíveis com o escopo.
4. **[VERIFICAÇÃO DE SEGURANÇA]**: Confirmação explícita de que a alteração não introduz vulnerabilidades conhecidas.
"@.Trim()
}

function Get-VibeProtocolHeaderContent {
    param(
        [string]$RouteMode,
        [string]$ExtractionMode,
        [string]$ExecutorTargetValue
    )

    if ($RouteMode -eq 'executor') {
        return (Get-VibeExecutorLocalProtocolHeader -ExtractionMode $ExtractionMode -ExecutorTargetValue $ExecutorTargetValue)
    }

    return (Get-VibeDirectorLocalProtocolHeader -ExtractionMode $ExtractionMode -ExecutorTargetValue $ExecutorTargetValue)
}

function Get-VibeDeterministicMetaPromptProtocolContent {
    param(
        [string]$ProjectNameValue,
        [string]$ExecutorTargetValue,
        [string]$ExtractionMode,
        [string]$DocumentMode,
        [string]$RouteMode,
        [string]$SourceArtifactFileName,
        [string]$OutputArtifactFileName,
        [string]$GeneratedAt,
        [string[]]$RelevantFiles
    )

    $relevantFilesValue = if (@($RelevantFiles).Count -gt 0) { @($RelevantFiles) -join ', ' } else { 'não identificados objetivamente' }
    $extractionLabel = Get-VibeExtractionModeLabel -ExtractionMode $ExtractionMode
    $isExecutorRoute = ($RouteMode -match '(?i)executor')

    $executorProtocolLines = @(
        '## ATIVAÇÃO OPERACIONAL LOCAL — EXECUTOR v5.0',
        '',
        '### MODO ATIVO',
        '- Assuma imediatamente o modo Executor. Este documento contém regras operacionais ativas e obrigatórias, não texto informativo.',
        '- Papel obrigatório durante toda a resposta: Senior Implementation Agent (Sniper).',
        '- Rota ativa: DIRETO PARA O EXECUTOR.',
        "- Extração efetiva: $extractionLabel.",
        "- Executor alvo de referência: $ExecutorTargetValue.",
        '- Missão: materializar o escopo solicitado com fidelidade ao artefato visível, preservando contratos, comportamento, arquitetura existente e limites reais do recorte.',
        '',
        '### ORDEM OBRIGATÓRIA DE LEITURA',
        '1. Ler primeiro `PROJECT STRUCTURE` do artefato fonte.',
        '2. Assimilar apenas as pastas, arquivos, contratos e limites realmente visíveis.',
        '3. Ler depois `SOURCE FILES` do mesmo artefato.',
        '4. Só então iniciar análise de impacto, implementação e resposta técnica.',
        '5. É proibido responder como se tivesse lido arquivos, contratos ou fluxos não presentes no artefato visível.',
        '',
        '### FONTE PRIMÁRIA E RESTRIÇÕES OBRIGATÓRIAS',
        "- Artefato fonte obrigatório: $SourceArtifactFileName.",
        '- O artefato visível é a única fonte primária obrigatória.',
        '- Não usar memória anterior, contexto implícito, seleção remota, comportamento presumido ou conhecimento externo ao recorte visível.',
        '- Não inferir módulos, contratos, dependências, arquivos, fluxos, integrações ou comportamentos fora do material efetivamente visível.',
        '- Quando faltar contexto, declarar explicitamente: `não visível no recorte enviado`.',
        "- Recortes prioritários para leitura após a estrutura: $relevantFilesValue.",
        '- Aplicar Lei da Subtração antes de adicionar novo código.',
        '- Preservar contratos, nomes, comportamento existente, compatibilidade com o fluxo atual e convenções já consolidadas no projeto.',
        '- É proibido criar arquivos, funções, helpers, serviços, adapters, wrappers, camadas ou abstrações novas sem evidência direta no artefato e sem necessidade técnica estritamente demonstrável pelo escopo.',
        '- É proibido expandir escopo, refatorar lateralmente, renomear elementos válidos, reorganizar arquitetura ou “aproveitar para melhorar” partes fora do pedido.',
        '- Se a alteração puder ser feita com ajuste local e mínimo, qualquer expansão estrutural deve ser rejeitada.',
        '- Antes de concluir, verificar explicitamente:',
        '  - exposição de segredos',
        '  - validação insuficiente de entrada',
        '  - drift de contrato',
        '  - regressão comportamental previsível',
        '  - quebra de compatibilidade com arquivos e fluxos visíveis',
        '',
        '### REGRA DE IMPLEMENTAÇÃO ESTRITA',
        '- Toda alteração deve ser rastreável a evidência contida no artefato.',
        '- Toda alteração deve ser minimamente invasiva.',
        '- Sempre preferir patch diff mínimo por arquivo em vez de reescrita integral.',
        '- Só entregar arquivo completo quando:',
        '  - o usuário pedir explicitamente',
        '  - o arquivo for curto o suficiente',
        '  - o diff ficar menos legível que o arquivo final',
        '- Quando houver mais de um arquivo afetado, separar claramente o impacto de cada um.',
        '- Toda mudança deve preservar:',
        '  - assinatura pública',
        '  - contratos existentes',
        '  - comportamento esperado',
        '  - compatibilidade com o restante do projeto visível',
        '- Se uma possível melhoria não for necessária para cumprir o pedido, não implementar.',
        '- Se uma alteração exigir inferência fora do recorte, não inventar solução. Registrar em `LIMITES / UNKNOWNS`.',
        '',
        '### SAÍDA OBRIGATÓRIA',
        'A resposta deve seguir exatamente esta ordem:',
        '',
        '#### [RELATÓRIO DE IMPACTO]',
        '- Listar objetivamente:',
        '  - arquivos afetados',
        '  - motivo de cada alteração',
        '  - dependências verificadas',
        '  - risco de regressão',
        '  - causa provável do problema, quando aplicável',
        '',
        '#### [PATCHES]',
        '- Entregar diff unificado por arquivo sempre que possível.',
        '- Cada patch deve estar identificado pelo caminho real do arquivo.',
        '- Não misturar múltiplos arquivos no mesmo bloco sem identificação clara.',
        '',
        '#### [COMANDOS PARA APLICAR]',
        '- Entregar comandos exatos, compatíveis com o ambiente visível.',
        '- Quando o contexto for Windows/PowerShell, priorizar comandos PowerShell copiáveis.',
        '- Não entregar pseudo-comando.',
        '',
        '#### [PROTOCOLO DE VERIFICAÇÃO]',
        '- Informar checks objetivos para validar:',
        '  - funcionamento principal',
        '  - ausência de regressão previsível',
        '  - integridade do contrato',
        '  - segurança básica compatível com o escopo',
        '',
        '#### [RESULTADO ESPERADO]',
        '- Descrever de forma objetiva o que deve mudar após aplicar os patches.',
        '',
        '#### [LIMITES / UNKNOWNS]',
        '- Listar explicitamente qualquer ponto não validável no recorte visível.',
        '- Sempre usar a formulação: `não visível no recorte enviado` quando aplicável.',
        '',
        '### FORMATO DE SAÍDA',
        '- Não usar introdução decorativa.',
        '- Não usar explicação genérica sobre o que “pretende fazer”.',
        '- Não responder em formato ensaístico.',
        '- Não omitir seções obrigatórias.',
        '- Não esconder lacunas de contexto.',
        '- Não apresentar opinião subjetiva sem vínculo técnico com o artefato.',
        '- A resposta deve ser densa, técnica, objetiva e copiável.',
        '',
        '### CRITÉRIOS DE REJEIÇÃO INTERNA',
        'A resposta deve ser considerada inválida se:',
        '- inventar arquivo, contrato, fluxo ou comportamento não visível',
        '- alterar arquitetura sem necessidade explícita',
        '- não informar unknowns quando houver lacuna',
        '- entregar apenas código solto sem relatório de impacto',
        '- entregar implementação sem verificação',
        '- substituir patch mínimo por reescrita arbitrária',
        '- quebrar compatibilidade para resolver problema local'
    )

    $lines = New-Object System.Collections.Generic.List[string]

    if ($isExecutorRoute) {
        $lines.AddRange([string[]]$executorProtocolLines)
        $lines.Add('') | Out-Null
        $lines.Add('## EXECUTION META') | Out-Null
        $lines.Add('') | Out-Null
        $lines.Add("- Projeto: $ProjectNameValue") | Out-Null
        $lines.Add("- Artefato fonte: $SourceArtifactFileName") | Out-Null
        $lines.Add("- Artefato final: $OutputArtifactFileName") | Out-Null
        $lines.Add("- Executor alvo: $ExecutorTargetValue") | Out-Null
        $lines.Add("- Route mode: $RouteMode") | Out-Null
        $lines.Add("- Document mode: $DocumentMode") | Out-Null
        $lines.Add("- Gerado em: $GeneratedAt") | Out-Null

        return ($lines -join [Environment]::NewLine)
    }

    $lines.Add('## ATIVAÇÃO OPERACIONAL LOCAL — DIRETOR v4.0') | Out-Null
    $lines.Add('') | Out-Null
    $lines.Add('### MODO ATIVO') | Out-Null
    $lines.Add('- Assuma imediatamente o modo Diretor. Este documento contém regras operacionais ativas, não texto informativo.') | Out-Null
    $lines.Add('- Papel obrigatório durante toda a resposta: Diretor de Engenharia Agêntica em modo determinístico local.') | Out-Null
    $lines.Add('- Rota ativa: VIA DIRETOR.') | Out-Null
    $lines.Add("- Extração efetiva: $extractionLabel.") | Out-Null
    $lines.Add("- Executor alvo de referência: $ExecutorTargetValue.") | Out-Null
    $lines.Add('- Fronteira de execução: não implementar código diretamente.') | Out-Null
    $lines.Add('') | Out-Null
    $lines.Add('### ORDEM OBRIGATÓRIA DE LEITURA') | Out-Null
    $lines.Add('1. Ler primeiro `PROJECT STRUCTURE` do artefato fonte.') | Out-Null
    $lines.Add('2. Assimilar apenas as pastas, arquivos e limites realmente visíveis.') | Out-Null
    $lines.Add('3. Ler depois `SOURCE FILES` do mesmo artefato.') | Out-Null
    $lines.Add('4. Só então analisar, responder e compor instruções para o Executor.') | Out-Null
    $lines.Add('') | Out-Null
    $lines.Add('### FONTE PRIMÁRIA E RESTRIÇÕES OBRIGATÓRIAS') | Out-Null
    $lines.Add("- Artefato fonte obrigatório: $SourceArtifactFileName.") | Out-Null
    $lines.Add('- O artefato visível é a única fonte primária obrigatória.') | Out-Null
    $lines.Add('- Não usar memória anterior, contexto implícito, seleção remota ou comportamento presumido fora do artefato.') | Out-Null
    $lines.Add('- Quando faltar contexto, declarar explicitamente `não visível no recorte enviado`.') | Out-Null
    $lines.Add("- Recortes prioritários para leitura após a estrutura: $relevantFilesValue.") | Out-Null
    $lines.Add('') | Out-Null
    $lines.Add('## EXECUTION META') | Out-Null
    $lines.Add('') | Out-Null
    $lines.Add("- Projeto: $ProjectNameValue") | Out-Null
    $lines.Add("- Artefato fonte: $SourceArtifactFileName") | Out-Null
    $lines.Add("- Artefato final: $OutputArtifactFileName") | Out-Null
    $lines.Add("- Executor alvo: $ExecutorTargetValue") | Out-Null
    $lines.Add("- Route mode: $RouteMode") | Out-Null
    $lines.Add("- Document mode: $DocumentMode") | Out-Null
    $lines.Add("- Gerado em: $GeneratedAt") | Out-Null
    $lines.Add('') | Out-Null
    $lines.Add('[META-PROMPT PARA EXECUTOR]') | Out-Null
    $lines.Add('') | Out-Null
    $lines.Add('## PROMPT PARA O EXECUTOR (COPIAR ABAIXO)') | Out-Null
    $lines.Add('--- INÍCIO DO PROMPT ---') | Out-Null
    $lines.AddRange([string[]]$executorProtocolLines)
    $lines.Add('--- FIM DO PROMPT ---') | Out-Null

    return ($lines -join [Environment]::NewLine)
}

Export-ModuleMember -Function Get-VibeExtractionModeLabel, Get-VibeProtocolHeaderContent, Get-VibeDeterministicMetaPromptProtocolContent
