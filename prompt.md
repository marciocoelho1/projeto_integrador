Tarefa: ajustes de usabilidade e dados de colaboradores

Objetivo

Corrigir o comportamento dos modais de EPIs e Colaboradores e completar os campos de
colaborador nas telas de consulta, edição e cadastro, preservando as convenções definidas no
AGENTS.md.

Escopo funcional

1. Módulo EPIs

Na janela Registrar Entrega de EPI:

permitir que o usuário feche a janela clicando na área externa ao modal (overlay), retornando
à tela Gestão de EPIs;

impedir que cliques dentro do conteúdo do modal fechem a janela;

preservar o mecanismo de fechamento já existente, caso haja botão de fechar ou cancelar.

2. Módulo Colaboradores

Na janela Detalhes e edição:

permitir que o usuário feche a janela clicando na área externa ao modal (overlay), retornando
à tela Gestão de Colaboradores;

impedir que cliques dentro do conteúdo do modal fechem a janela;

preservar o mecanismo de fechamento já existente, caso haja botão de fechar ou cancelar.

Nos dados dos colaboradores:

adicionar a propriedade obrigatória de e-mail ao tipo/interface que representa um colaborador;

garantir que todos os dados simulados existentes possuam e-mails corporativos fictícios e
válidos;

adicionar a coluna E-mail à tabela principal de colaboradores, em posição coerente com os
demais dados pessoais;

exibir o e-mail correspondente em cada linha da tabela;

adicionar o campo E-mail ao formulário de edição;

usar type="email", vincular o campo ao colaborador em edição e torná-lo obrigatório;

impedir a conclusão da edição quando o e-mail estiver ausente ou for inválido, seguindo o
padrão de validação e feedback já utilizado pelo projeto.

3. Módulo Cadastramentos — aba Novo Colaborador

adicionar o campo obrigatório E-mail ao formulário;

usar type="email" e aplicar o padrão visual e de validação dos demais campos;

substituir os campos de entrada livre Cargo, Setor e Grupo de Acesso por listas
suspensas;

impedir a digitação de valores arbitrários nesses três campos;

carregar as opções a partir das fontes de dados já existentes no projeto para cargos, setores
e grupos de acesso;

incluir uma opção inicial sem valor, como Selecione..., que não possa ser submetida como
valor válido;

não duplicar listas nem criar uma nova fonte de dados se já existir serviço, Signal, coleção ou
configuração responsável por essas opções.

Arquivos inicialmente relacionados

Investigue pelo menos estes arquivos e seus consumidores antes de editar:

src/app/tela-epis/epis.html

src/app/tela-epis/epis.ts

src/app/tela-colaboradores/colaboradores.html

src/app/tela-colaboradores/colaboradores.ts

src/app/tela-cadastramentos/cadastramentos.html

src/app/tela-cadastramentos/cadastramentos.ts

serviços ou tipos que forneçam colaboradores, cargos, setores e grupos de acesso

A lista é uma orientação, não uma autorização para ampliar o escopo indiscriminadamente.

Restrições

siga integralmente o AGENTS.md;

não altere dependências, configurações, rotas, autenticação, guards, contratos HTTP, estilos
globais ou ativos de marca;

não realize refatorações sem relação direta com esta tarefa;

não substitua dados dinâmicos por listas hardcoded se já houver uma fonte de dados apropriada;

não invente endpoints ou contratos de backend;

preserve o layout, o padrão BEM e o comportamento atual das telas fora do escopo descrito;

não edite o próprio prompt.md durante a implementação.

Processo obrigatório

Leia o AGENTS.md e este prompt.md por completo.

Inspecione o estado atual dos arquivos, inclusive mudanças não commitadas.

Compare cada requisito com a implementação existente e classifique-o como:

já implementado corretamente;

parcialmente implementado;

não implementado;

implementado com possível problema.

Identifique a fonte atual das opções de Cargo, Setor e Grupo de Acesso. Se não existir uma
fonte utilizável sem alterar contratos ou arquitetura protegida pelo AGENTS.md, explique o
bloqueio e peça autorização em vez de inventar uma solução.

Antes de editar, apresente um plano curto com os arquivos que pretende modificar e aguarde
aprovação explícita.

Após a aprovação, implemente apenas o que estiver ausente ou incorreto; não duplique o que já
estiver funcionando.

Adicione ou atualize testes relevantes para os comportamentos alterados quando isso for viável
dentro do escopo.

Formate somente os arquivos modificados.

Execute as validações definidas abaixo.

Apresente um resumo dos arquivos alterados, requisitos atendidos, validações executadas e
qualquer risco ou pendência remanescente.

Critérios de aceitação

clicar no overlay fecha o modal de entrega de EPI;

clicar dentro desse modal não o fecha;

clicar no overlay fecha o modal de detalhes e edição de colaborador;

clicar dentro desse modal não o fecha;

a tabela de colaboradores exibe uma coluna E-mail com valor para todos os registros;

a edição de colaborador exige um e-mail válido;

o cadastro de colaborador exige um e-mail válido;

Cargo, Setor e Grupo de Acesso são seleções fechadas, sem entrada livre;

as opções desses seletores refletem as fontes de dados já existentes no sistema;

nenhuma funcionalidade externa ao escopo sofre regressão conhecida;

o projeto compila e os testes relevantes passam.

Validação

Execute, ao final:

npx prettier --check <arquivos-alterados>
npm run build
npm test -- --watch=false

Se o comando de testes não aceitar --watch=false, use o comando não interativo compatível com
o builder configurado no projeto. Não altere configurações apenas para adequar o comando. Registre
separadamente falhas preexistentes e falhas causadas pela alteração.