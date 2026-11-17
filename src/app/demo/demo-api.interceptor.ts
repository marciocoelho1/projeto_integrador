import {
  HttpErrorResponse,
  HttpInterceptorFn,
  HttpRequest,
  HttpResponse,
} from '@angular/common/http';
import { delay, of, throwError } from 'rxjs';
import {
  agoraIso,
  calcularIndicadores,
  criarEstadoDemo,
  diasFrente,
  hojeIso,
  relatorioCsv,
  serializarCertificacao,
  serializarEntrega,
  serializarLnt,
  serializarLntColaboradores,
  serializarReciclagens,
  serializarVinculo,
  type EstadoDemo,
  type LogDemo,
} from './demo-dados';

/**
 * API em memória do modo demonstração.
 *
 * O build `demo` (ver `npm run demo`) troca o `environment` por `environment.demo.ts` e registra
 * este interceptor no lugar do backend: cada rota de `/api/**` é respondida aqui, com os mesmos
 * formatos de JSON do Spring Boot, para que todas as telas possam ser navegadas sem banco, sem
 * Java e sem PostgreSQL. O estado vive na memória do navegador, então incluir, editar e excluir
 * funcionam durante a sessão e tudo volta ao começo quando a página é recarregada.
 */

const LATENCIA_MS = 180;

let estado: EstadoDemo = criarEstadoDemo();

/** Volta os dados de exemplo ao estado inicial (usado pelos testes). */
export function reiniciarDemo(): void {
  estado = criarEstadoDemo();
}

interface Resposta {
  status: number;
  corpo: unknown;
}

type Tratar = (casamento: RegExpMatchArray, requisicao: HttpRequest<unknown>) => Resposta;

interface Rota {
  metodo: string;
  padrao: RegExp;
  tratar: Tratar;
}

function ok(corpo: unknown): Resposta {
  return { status: 200, corpo };
}

function criado(corpo: unknown): Resposta {
  return { status: 201, corpo };
}

function semConteudo(): Resposta {
  return { status: 204, corpo: null };
}

function naoEncontrado(mensagem: string): Resposta {
  return { status: 404, corpo: { mensagem } };
}

function proximoId(itens: Array<{ id: number }>): number {
  return itens.reduce((maior, item) => Math.max(maior, item.id), 0) + 1;
}

function parametros(requisicao: HttpRequest<unknown>): URLSearchParams {
  const url = requisicao.urlWithParams;
  const indice = url.indexOf('?');

  return new URLSearchParams(indice >= 0 ? url.slice(indice) : '');
}

function corpoDe<T>(requisicao: HttpRequest<unknown>): T {
  return (requisicao.body ?? {}) as T;
}

/* =======================================================
   Gerador das rotas CRUD
   ======================================================= */

interface ConfigCrud<T extends { id: number }> {
  rota: string;
  colecao: () => T[];
  novo: (dados: Record<string, unknown>, itens: T[]) => T;
  alterar: (existente: T, dados: Record<string, unknown>) => T;
  paraApi?: (item: T) => unknown;
  filtrar?: (itens: T[], busca: URLSearchParams) => T[];
}

function rotasDe<T extends { id: number }>(config: ConfigCrud<T>): Rota[] {
  const paraApi = (item: T) => (config.paraApi ? config.paraApi(item) : item);
  const semId = new RegExp(`^/${config.rota}$`);
  const comId = new RegExp(`^/${config.rota}/(\\d+)$`);

  return [
    {
      metodo: 'GET',
      padrao: semId,
      tratar: (_casamento, requisicao) => {
        const itens = config.filtrar
          ? config.filtrar(config.colecao(), parametros(requisicao))
          : config.colecao();

        return ok(itens.map(paraApi));
      },
    },
    {
      metodo: 'GET',
      padrao: comId,
      tratar: (casamento) => {
        const item = config.colecao().find((atual) => atual.id === Number(casamento[1]));

        return item
          ? ok(paraApi(item))
          : naoEncontrado('Registro não encontrado no modo demonstração.');
      },
    },
    {
      metodo: 'POST',
      padrao: semId,
      tratar: (_casamento, requisicao) => {
        const item = config.novo(corpoDe<Record<string, unknown>>(requisicao), config.colecao());
        config.colecao().push(item);

        return criado(paraApi(item));
      },
    },
    {
      metodo: 'PUT',
      padrao: comId,
      tratar: (casamento, requisicao) => {
        const itens = config.colecao();
        const indice = itens.findIndex((atual) => atual.id === Number(casamento[1]));

        if (indice < 0) return naoEncontrado('Registro não encontrado no modo demonstração.');

        itens[indice] = config.alterar(itens[indice], corpoDe<Record<string, unknown>>(requisicao));

        return ok(paraApi(itens[indice]));
      },
    },
    {
      metodo: 'DELETE',
      padrao: comId,
      tratar: (casamento) => {
        const itens = config.colecao();
        const indice = itens.findIndex((atual) => atual.id === Number(casamento[1]));

        if (indice < 0) return naoEncontrado('Registro não encontrado no modo demonstração.');

        itens.splice(indice, 1);

        return semConteudo();
      },
    },
  ];
}

/* =======================================================
   Rotas específicas (autenticação, indicadores, derivados, importação)
   ======================================================= */

function rotasEspecificas(): Rota[] {
  return [
    /* --- Autenticação --- */
    {
      metodo: 'POST',
      padrao: /^\/auth\/login$/,
      tratar: (_casamento, requisicao) => {
        const dados = corpoDe<{ login?: string; senha?: string }>(requisicao);
        const login = (dados.login ?? '').trim().toLowerCase();
        const senha = dados.senha ?? '';

        if (senha !== '123456' || (login !== 'admin' && login !== 'colaborador')) {
          return {
            status: 401,
            corpo: {
              mensagem:
                'Login ou senha inválidos. No modo demonstração use admin/123456 ou colaborador/123456.',
            },
          };
        }

        const usuario = login === 'admin' ? estado.usuarios[0] : estado.usuarios[3];

        return ok({
          token: `demo-${login}-${Date.now()}`,
          expiraEm: new Date(Date.now() + 8 * 3600 * 1000).toISOString(),
          usuario: {
            id: usuario.id,
            login: usuario.login,
            nomeCompleto: usuario.nomeCompleto,
            grupo: usuario.grupo,
            modulos: usuario.modulos,
          },
        });
      },
    },
    { metodo: 'POST', padrao: /^\/auth\/logout$/, tratar: () => semConteudo() },
    {
      metodo: 'GET',
      padrao: /^\/auth\/sessao$/,
      tratar: (_casamento, requisicao) => {
        const usuario = estado.usuarios[0];

        return requisicao.headers.has('Authorization')
          ? ok({
              id: usuario.id,
              login: usuario.login,
              nomeCompleto: usuario.nomeCompleto,
              grupo: usuario.grupo,
              modulos: usuario.modulos,
            })
          : { status: 401, corpo: { mensagem: 'Sessão ausente ou expirada. Entre novamente.' } };
      },
    },
    {
      metodo: 'POST',
      padrao: /^\/auth\/recuperar-senha$/,
      tratar: (_casamento, requisicao) => {
        const dados = corpoDe<{ login?: string }>(requisicao);
        const token = Math.random().toString(16).slice(2, 10).toUpperCase();

        estado.redefinicoes.push({
          id: proximoId(estado.redefinicoes),
          usuario: 'Administrador do Sistema',
          login: dados.login ?? 'admin',
          token,
          criadoEm: agoraIso(),
          expiraEm: new Date(Date.now() + 3600 * 1000).toISOString(),
        });

        return ok({
          mensagem:
            'Se houver uma conta com esse login, um token de recuperação será gerado e ficará disponível para o administrador.',
        });
      },
    },
    {
      metodo: 'POST',
      padrao: /^\/auth\/redefinir-senha$/,
      tratar: () => ok({ mensagem: 'Senha redefinida no modo demonstração.' }),
    },
    { metodo: 'GET', padrao: /^\/auth\/redefinicoes$/, tratar: () => ok(estado.redefinicoes) },

    /* --- Indicadores, relatórios e saúde --- */
    {
      metodo: 'GET',
      padrao: /^\/dashboard\/indicadores$/,
      tratar: () => ok(calcularIndicadores(estado)),
    },
    {
      metodo: 'GET',
      padrao: /^\/relatorios\/([\w-]+)\.csv$/,
      tratar: (casamento) => {
        const conteudo = relatorioCsv(estado, casamento[1]);

        return conteudo === null
          ? naoEncontrado('Relatório não disponível no modo demonstração.')
          : ok(new Blob([conteudo], { type: 'text/csv;charset=UTF-8' }));
      },
    },
    {
      metodo: 'GET',
      padrao: /^\/health$/,
      tratar: () => ok({ status: 'UP', banco: 'UP', modo: 'demonstração' }),
    },

    /* --- Matriz de treinamentos: derivados e LNT --- */
    { metodo: 'GET', padrao: /^\/reciclagens$/, tratar: () => ok(serializarReciclagens(estado)) },
    { metodo: 'GET', padrao: /^\/lnt$/, tratar: () => ok(serializarLnt(estado)) },
    {
      metodo: 'GET',
      padrao: /^\/lnt\/colaboradores$/,
      tratar: () => ok(serializarLntColaboradores(estado)),
    },
    {
      metodo: 'PUT',
      padrao: /^\/cargos\/(\d+)\/treinamentos$/,
      tratar: (casamento, requisicao) => {
        const cargoId = Number(casamento[1]);
        const dados = corpoDe<{
          treinamentos?: Array<{ treinamentoId: number; obrigatorio: boolean }>;
        }>(requisicao);

        estado.cargoTreinamentos = estado.cargoTreinamentos.filter(
          (item) => item.cargoId !== cargoId,
        );

        let id = proximoId(estado.cargoTreinamentos);
        for (const item of dados.treinamentos ?? []) {
          estado.cargoTreinamentos.push({
            id: id++,
            cargoId,
            treinamentoId: item.treinamentoId,
            obrigatorio: item.obrigatorio,
          });
        }

        return ok(serializarLnt(estado).find((cargo) => cargo.id === cargoId) ?? null);
      },
    },

    /* --- Importação em massa --- */
    {
      metodo: 'POST',
      padrao: /^\/importacao\/(\w+)$/,
      tratar: (casamento, requisicao) => ok(importar(casamento[1], requisicao)),
    },

    /* --- Parâmetros, regras de alerta e módulos --- */
    { metodo: 'GET', padrao: /^\/modulos$/, tratar: () => ok(estado.modulos) },
    { metodo: 'GET', padrao: /^\/parametros$/, tratar: () => ok(estado.parametros) },
    { metodo: 'GET', padrao: /^\/regras-alerta$/, tratar: () => ok(estado.regrasAlerta) },
    {
      metodo: 'GET',
      padrao: /^\/regras-alerta\/([\w-]+)$/,
      tratar: (casamento) => {
        const regra = estado.regrasAlerta.find((item) => item.codigo === casamento[1]);

        return regra ? ok(regra) : naoEncontrado('Regra não encontrada.');
      },
    },
    {
      metodo: 'GET',
      padrao: /^\/parametros\/([\w.]+)$/,
      tratar: (casamento) => {
        const parametro = estado.parametros.find((item) => item.chave === casamento[1]);

        return parametro ? ok(parametro) : naoEncontrado('Parâmetro não encontrado.');
      },
    },
    {
      metodo: 'PUT',
      padrao: /^\/parametros\/([\w.]+)$/,
      tratar: (casamento, requisicao) => {
        const parametro = estado.parametros.find((item) => item.chave === casamento[1]);

        if (!parametro) return naoEncontrado('Parâmetro não encontrado.');

        parametro.valor = corpoDe<{ valor?: string }>(requisicao).valor ?? parametro.valor;

        return ok(parametro);
      },
    },
    {
      metodo: 'PUT',
      padrao: /^\/regras-alerta\/([\w-]+)$/,
      tratar: (casamento, requisicao) => {
        const regra = estado.regrasAlerta.find((item) => item.codigo === casamento[1]);

        if (!regra) return naoEncontrado('Regra não encontrada.');

        regra.ativa = corpoDe<{ ativa?: boolean }>(requisicao).ativa ?? regra.ativa;

        return ok(regra);
      },
    },

    /* --- Acesso: senha do usuário e módulos do grupo --- */
    { metodo: 'PUT', padrao: /^\/usuarios\/(\d+)\/senha$/, tratar: () => semConteudo() },
    {
      metodo: 'PUT',
      padrao: /^\/grupos\/(\d+)\/modulos$/,
      tratar: (casamento, requisicao) => {
        const grupo = estado.grupos.find((item) => item.id === Number(casamento[1]));

        if (!grupo) return naoEncontrado('Grupo não encontrado.');

        grupo.modulos = corpoDe<{ modulos?: string[] }>(requisicao).modulos ?? [];

        return ok(grupo);
      },
    },

    /* --- Auditoria --- */
    {
      metodo: 'GET',
      padrao: /^\/auditoria$/,
      tratar: (_casamento, requisicao) => {
        const busca = parametros(requisicao);
        const termo = (busca.get('termo') ?? '').toLowerCase();
        const inicio = busca.get('inicio');
        const fim = busca.get('fim');

        const logs = estado.logs
          .filter((log) => {
            const dia = log.dataHora.slice(0, 10);

            if (inicio && dia < inicio) return false;
            if (fim && dia > fim) return false;
            if (!termo) return true;

            return `${log.usuario} ${log.modulo} ${log.acao} ${log.descricao}`
              .toLowerCase()
              .includes(termo);
          })
          .sort((a, b) => b.dataHora.localeCompare(a.dataHora));

        return ok(logs);
      },
    },
    {
      metodo: 'POST',
      padrao: /^\/auditoria$/,
      tratar: (_casamento, requisicao) => {
        const dados = corpoDe<{
          usuario?: string;
          modulo?: string;
          acao?: string;
          descricao?: string;
        }>(requisicao);
        const log: LogDemo = {
          id: proximoId(estado.logs),
          dataHora: agoraIso(),
          usuarioId: 1,
          usuario: dados.usuario ?? 'Administrador',
          modulo: dados.modulo ?? 'sistema',
          acao: (dados.acao ?? 'ACESSO') as LogDemo['acao'],
          descricao: dados.descricao ?? '',
          metodo: 'POST',
          caminho: '/api/auditoria',
          statusHttp: 201,
        };

        estado.logs.unshift(log);

        return criado(log);
      },
    },
  ];
}

/* =======================================================
   Coleções com CRUD completo
   ======================================================= */

function comId<T extends object>(dados: Record<string, unknown>, itens: Array<{ id: number }>): T {
  return { ...dados, id: proximoId(itens) } as T;
}

function rotasDeColecoes(): Rota[] {
  return [
    ...rotasDe({
      rota: 'colaboradores',
      colecao: () => estado.colaboradores,
      novo: (dados, itens) => comId(dados, itens),
      alterar: (existente, dados) => ({ ...existente, ...dados }),
    }),
    ...rotasDe({
      rota: 'treinamentos',
      colecao: () => estado.treinamentos,
      novo: (dados, itens) => comId(dados, itens),
      alterar: (existente, dados) => ({ ...existente, ...dados }),
    }),
    ...rotasDe({
      rota: 'epis',
      colecao: () => estado.epis,
      novo: (dados, itens) => comId(dados, itens),
      alterar: (existente, dados) => ({ ...existente, ...dados }),
    }),
    ...rotasDe({
      rota: 'entregas-epis',
      colecao: () => estado.entregasEpis,
      filtrar: (itens, busca) => {
        const colaboradorId = busca.get('colaboradorId');

        return colaboradorId
          ? itens.filter((item) => item.colaboradorId === Number(colaboradorId))
          : itens;
      },
      novo: (dados, itens) => {
        const epi = estado.epis.find((item) => item.id === Number(dados['epiId']));

        return {
          id: proximoId(itens),
          colaboradorId: Number(dados['colaboradorId']),
          epiId: Number(dados['epiId']),
          quantidade: Number(dados['quantidade'] ?? 1),
          dataEntrega: String(dados['dataEntrega'] ?? hojeIso()),
          assinatura: String(dados['assinatura'] ?? ''),
          registradoEm: agoraIso(),
          caNoAto: epi?.ca ?? '-',
        };
      },
      alterar: (existente, dados) => ({ ...existente, ...dados }),
      paraApi: (item) => serializarEntrega(estado, item),
    }),
    ...rotasDe({
      rota: 'vinculos',
      colecao: () => estado.vinculos,
      filtrar: (itens, busca) => {
        const colaboradorId = busca.get('colaboradorId');

        return colaboradorId
          ? itens.filter((item) => item.colaboradorId === Number(colaboradorId))
          : itens;
      },
      novo: (dados, itens) => comId(dados, itens),
      alterar: (existente, dados) => ({ ...existente, ...dados }),
      paraApi: (item) => serializarVinculo(estado, item),
    }),
    ...rotasDe({
      rota: 'certificacoes',
      colecao: () => estado.certificacoes,
      filtrar: (itens, busca) => {
        const colaboradorId = busca.get('colaboradorId');

        return colaboradorId
          ? itens.filter((item) => item.colaboradorId === Number(colaboradorId))
          : itens;
      },
      novo: (dados, itens) => comId(dados, itens),
      alterar: (existente, dados) => ({ ...existente, ...dados }),
      paraApi: (item) => serializarCertificacao(estado, item),
    }),
    ...rotasDe({
      rota: 'cargos',
      colecao: () => estado.cargos,
      novo: (dados, itens) => comId(dados, itens),
      alterar: (existente, dados) => ({ ...existente, ...dados }),
    }),
    ...rotasDe({
      rota: 'turmas-reciclagem',
      colecao: () => estado.turmasReciclagem,
      filtrar: (itens, busca) => {
        const treinamentoId = busca.get('treinamentoId');

        return treinamentoId
          ? itens.filter((item) => item.treinamentoId === Number(treinamentoId))
          : itens;
      },
      novo: (dados, itens) => comId(dados, itens),
      alterar: (existente, dados) => ({ ...existente, ...dados }),
      paraApi: (item) => ({
        ...item,
        treinamento:
          estado.treinamentos.find((treinamento) => treinamento.id === item.treinamentoId)?.nome ??
          'Treinamento removido',
      }),
    }),
    ...rotasDe({
      rota: 'usuarios',
      colecao: () => estado.usuarios,
      novo: (dados, itens) => {
        const grupo = estado.grupos.find((item) => item.id === Number(dados['grupoId']));

        return {
          id: proximoId(itens),
          nomeCompleto: String(dados['nomeCompleto'] ?? ''),
          login: String(dados['login'] ?? ''),
          email: String(dados['email'] ?? ''),
          cpf: String(dados['cpf'] ?? ''),
          grupoId: Number(dados['grupoId']),
          grupo: grupo?.nomenclatura ?? 'Colaborador',
          status: (dados['status'] ?? 'Ativo') as 'Ativo' | 'Inativo',
          modulos: grupo?.modulos ?? [],
          criadoEm: agoraIso(),
        };
      },
      alterar: (existente, dados) => {
        const grupoId = Number(dados['grupoId'] ?? existente.grupoId);
        const grupo = estado.grupos.find((item) => item.id === grupoId);

        return {
          ...existente,
          ...dados,
          grupoId,
          grupo: grupo?.nomenclatura ?? existente.grupo,
          modulos: grupo?.modulos ?? existente.modulos,
        };
      },
    }),
    ...rotasDe({
      rota: 'grupos',
      colecao: () => estado.grupos,
      novo: (dados, itens) => comId(dados, itens),
      alterar: (existente, dados) => ({ ...existente, ...dados }),
    }),
    ...rotasDe({
      rota: 'chamados',
      colecao: () => estado.chamados,
      filtrar: (itens, busca) => {
        const status = busca.get('status');
        // A conta "colaborador" do modo demo é o usuário 4: é dela a visão "meus chamados".
        const meus =
          busca.get('meus') === 'true' ? itens.filter((item) => item.usuarioId === 4) : itens;

        return status ? meus.filter((item) => item.status === status) : meus;
      },
      novo: (dados, itens) => ({
        id: proximoId(itens),
        tipo: (dados['tipo'] ?? 'Ajuda') as 'Ajuda' | 'Erro',
        descricao: String(dados['descricao'] ?? ''),
        usuarioId: 1,
        solicitante: String(dados['solicitante'] ?? 'Administrador'),
        status: 'Em andamento' as const,
        abertoEm: agoraIso(),
        concluidoEm: null,
      }),
      alterar: (existente, dados) => {
        const status = (dados['status'] ?? existente.status) as typeof existente.status;

        return {
          ...existente,
          ...dados,
          status,
          concluidoEm: status === 'Concluída' ? agoraIso() : existente.concluidoEm,
        };
      },
    }),
  ];
}

/* =======================================================
   Importação em massa
   ======================================================= */

const CAMPOS_OBRIGATORIOS: Record<string, string[]> = {
  colaboradores: ['matricula', 'nome'],
  treinamentos: ['codigo', 'nome'],
  epis: ['descricao', 'ca'],
};

function importar(recurso: string, requisicao: HttpRequest<unknown>): unknown {
  const linhas = corpoDe<{ linhas?: Array<Record<string, string>> }>(requisicao).linhas ?? [];
  const obrigatorios = CAMPOS_OBRIGATORIOS[recurso];
  const erros: Array<{ linha: number; mensagem: string }> = [];

  if (!obrigatorios) {
    return {
      total: linhas.length,
      importados: 0,
      ignorados: 0,
      erros: [{ linha: 0, mensagem: 'Recurso não aceito na importação.' }],
    };
  }

  let importados = 0;
  let ignorados = 0;

  linhas.forEach((linha, indice) => {
    const faltando = obrigatorios.filter((campo) => !String(linha[campo] ?? '').trim());

    if (faltando.length > 0) {
      erros.push({
        linha: indice + 2,
        mensagem: `Campos obrigatórios ausentes: ${faltando.join(', ')}.`,
      });

      return;
    }

    const chave = String(linha[obrigatorios[0]]).trim();
    const jaExiste =
      recurso === 'colaboradores'
        ? estado.colaboradores.some((item) => item.matricula === chave)
        : recurso === 'treinamentos'
          ? estado.treinamentos.some((item) => item.codigo === chave)
          : estado.epis.some((item) => item.ca === chave);

    if (jaExiste) {
      ignorados += 1;

      return;
    }

    importados += 1;

    if (recurso === 'colaboradores') {
      estado.colaboradores.push({
        id: proximoId(estado.colaboradores),
        matricula: chave,
        nome: String(linha['nome'] ?? '').trim(),
        cpf: String(linha['cpf'] ?? '').trim(),
        email: String(linha['email'] ?? '').trim(),
        cargo: String(linha['cargo'] ?? 'Auxiliar').trim(),
        setor: String(linha['setor'] ?? 'Frente de Loja').trim(),
        status: 'Ativo',
      });
    } else if (recurso === 'treinamentos') {
      const validade = Number(linha['validadeMeses'] ?? 0);

      estado.treinamentos.push({
        id: proximoId(estado.treinamentos),
        codigo: chave,
        nome: String(linha['nome'] ?? '').trim(),
        classificacao: String(linha['classificacao'] ?? 'Interno').trim(),
        nr: String(linha['nr'] ?? '').trim() || null,
        cargaHoraria: String(linha['cargaHoraria'] ?? '4h').trim(),
        validadeMeses: validade > 0 ? validade : null,
        status: 'Ativo',
      });
    } else {
      estado.epis.push({
        id: proximoId(estado.epis),
        descricao: String(linha['descricao'] ?? '').trim(),
        ca: chave,
        inclusao: hojeIso(),
        validade: String(linha['validade'] ?? '').trim() || diasFrente(365),
        quantidade: Number(linha['quantidade'] ?? 0),
      });
    }
  });

  return { total: linhas.length, importados, ignorados, erros };
}

/* =======================================================
   Interceptor
   ======================================================= */

let cacheDeRotas: Rota[] | null = null;

function tabelaDeRotas(): Rota[] {
  cacheDeRotas ??= [...rotasEspecificas(), ...rotasDeColecoes()];

  return cacheDeRotas;
}

/**
 * Extrai o caminho da API (com a barra inicial, ex.: `/auth/login`) ou `null` quando a URL não
 * é da API. As rotas da tabela são declaradas a partir da barra: `/^\/auth\/login$/`.
 */
function caminhoDaApi(url: string): string | null {
  const indice = url.indexOf('/api');

  return indice < 0 ? null : url.slice(indice + '/api'.length);
}

/**
 * Interceptor do modo demonstração: responde `/api/**` a partir da API em memória e deixa passar
 * qualquer outra requisição (arquivos de `public/`, por exemplo).
 */
export const demoApiInterceptor: HttpInterceptorFn = (requisicao, proximo) => {
  const caminho = caminhoDaApi(requisicao.url);

  if (!caminho) return proximo(requisicao);

  let resposta: Resposta;

  try {
    const rota = tabelaDeRotas().find(
      (atual) => atual.metodo === requisicao.method && atual.padrao.test(caminho),
    );

    if (rota) {
      resposta = rota.tratar(caminho.match(rota.padrao) as RegExpMatchArray, requisicao);
    } else {
      console.warn(`[demo] rota não atendida: ${requisicao.method} ${caminho}`);
      resposta = naoEncontrado(
        `A rota ${requisicao.method} ${caminho} não existe no modo demonstração.`,
      );
    }
  } catch (erro) {
    console.error('[demo] falha ao montar a resposta', erro);
    resposta = { status: 500, corpo: { mensagem: 'Falha no modo demonstração.' } };
  }

  // Como no backend, status de erro chega ao serviço pela via de erro do HttpClient.
  if (resposta.status >= 400) {
    return throwError(
      () =>
        new HttpErrorResponse({
          status: resposta.status,
          statusText: resposta.status === 404 ? 'Not Found' : 'Bad Request',
          url: requisicao.urlWithParams,
          error: resposta.corpo,
        }),
    ).pipe(delay(LATENCIA_MS));
  }

  return of(new HttpResponse<unknown>({ status: resposta.status, body: resposta.corpo })).pipe(
    delay(LATENCIA_MS),
  );
};
