import { Component, inject, signal } from '@angular/core';
import { CommonModule } from '@angular/common';
import { FormsModule } from '@angular/forms';
import { ToastService } from '../service/toast.service';
import { AuditService } from '../service/audit.service';
import { ImportacaoService, TipoImportacao } from '../service/importacao.service';
import * as XLSX from 'xlsx';

/**
 * Descrição de uma coluna do contrato da API dentro da planilha.
 * `aliases` guarda as variações aceitas de cabeçalho já normalizadas
 * (sem acento, minúsculas, sem separadores) — inclui os nomes antigos
 * dos modelos que a tela baixava antes.
 */
interface CampoPlanilha {
  campo: string;
  obrigatorio: boolean;
  aliases: string[];
}

/** Colunas do contrato atual, por tipo de importação. */
const COLUNAS: Record<TipoImportacao, CampoPlanilha[]> = {
  colaborador: [
    { campo: 'matricula', obrigatorio: true, aliases: ['matricula'] },
    { campo: 'nome', obrigatorio: true, aliases: ['nome'] },
    { campo: 'cpf', obrigatorio: true, aliases: ['cpf'] },
    { campo: 'email', obrigatorio: true, aliases: ['email'] },
    { campo: 'cargo', obrigatorio: true, aliases: ['cargo'] },
    { campo: 'setor', obrigatorio: true, aliases: ['setor'] },
    { campo: 'status', obrigatorio: true, aliases: ['status', 'situacao'] },
  ],
  treinamento: [
    { campo: 'codigo', obrigatorio: true, aliases: ['codigo'] },
    { campo: 'nome', obrigatorio: true, aliases: ['nome', 'nometreinamento'] },
    { campo: 'classificacao', obrigatorio: true, aliases: ['classificacao'] },
    { campo: 'nr', obrigatorio: false, aliases: ['nr', 'nrreferente', 'norma'] },
    { campo: 'cargaHoraria', obrigatorio: true, aliases: ['cargahoraria'] },
    {
      campo: 'validadeMeses',
      obrigatorio: false,
      aliases: ['validademeses', 'validade'],
    },
    { campo: 'status', obrigatorio: true, aliases: ['status', 'situacao'] },
  ],
  epi: [
    {
      campo: 'descricao',
      obrigatorio: true,
      aliases: ['descricao', 'nomeequipamento', 'equipamento', 'nome'],
    },
    { campo: 'ca', obrigatorio: true, aliases: ['ca', 'numeroca'] },
    { campo: 'inclusao', obrigatorio: true, aliases: ['inclusao', 'datainclusao'] },
    { campo: 'validade', obrigatorio: true, aliases: ['validade', 'datavalidade'] },
    { campo: 'quantidade', obrigatorio: true, aliases: ['quantidade', 'qtd'] },
  ],
};

/** Modelos CSV alinhados ao contrato da API (exatamente estas colunas). */
const MODELOS: Record<TipoImportacao, { arquivo: string; conteudo: string }> = {
  colaborador: {
    arquivo: 'template_colaboradores.csv',
    conteudo:
      'Matricula,Nome,CPF,Email,Cargo,Setor,Status\n' +
      'MAT-001,João da Silva,11122233344,joao.silva@empresa.com,Operador de Caixa,Frente de Loja,Ativo\n',
  },
  treinamento: {
    arquivo: 'template_treinamentos.csv',
    conteudo:
      'Codigo,Nome,Classificacao,NR,Carga_Horaria,Validade_Meses,Status\n' +
      'TRN-001,NR-35 Trabalho em Altura,Norma Regulamentadora,NR-35,8,24,Ativo\n',
  },
  epi: {
    arquivo: 'template_epis.csv',
    conteudo:
      'Descricao,CA,Inclusao,Validade,Quantidade\n' +
      'Capacete de Segurança,12345,2026-01-01,2027-01-01,10\n',
  },
};

interface ErroLinha {
  linha: number;
  mensagem: string;
}

interface LinhaMapeada {
  dados?: Record<string, unknown>;
  erro?: string;
}

@Component({
  selector: 'app-importacao-massa',
  standalone: true,
  imports: [CommonModule, FormsModule],
  templateUrl: './importacao-massa.html',
  styleUrls: ['./importacao-massa.scss'],
})
export class ImportacaoMassa {
  private toast = inject(ToastService);
  private audit = inject(AuditService);
  private importacao = inject(ImportacaoService);

  tipoImportacao = signal<string>('');
  cabecalhos = signal<string[]>([]);
  linhasPreview = signal<string[][]>([]);
  arquivoNome = signal<string>('');

  importando = signal<boolean>(false);
  resultadoTotal = signal<number | null>(null);
  resultadoImportados = signal<number | null>(null);
  resultadoIgnorados = signal<number | null>(null);
  erros = signal<ErroLinha[]>([]);

  baixarTemplate() {
    const tipo = this.tipoImportacao() as TipoImportacao;
    const modelo = MODELOS[tipo];

    if (!modelo) {
      this.toast.warning('Selecione o tipo de importação.');
      return;
    }

    const blob = new Blob([modelo.conteudo], {
      type: 'text/csv;charset=utf-8;',
    });
    const url = URL.createObjectURL(blob);
    const link = document.createElement('a');

    link.setAttribute('href', url);
    link.setAttribute('download', modelo.arquivo);
    document.body.appendChild(link);
    link.click();
    document.body.removeChild(link);

    this.toast.success('Planilha de exemplo baixada com sucesso!');
  }

  onFileChange(event: Event) {
    const input = event.target as HTMLInputElement;
    if (!input.files || input.files.length === 0) return;

    const file = input.files[0];
    this.arquivoNome.set(file.name);

    const reader = new FileReader();

    reader.onload = (e: any) => {
      try {
        const bstr: string = e.target.result;
        const workbook: XLSX.WorkBook = XLSX.read(bstr, { type: 'binary' });

        const primeiraAbaNome = workbook.SheetNames[0];
        const worksheet: XLSX.WorkSheet = workbook.Sheets[primeiraAbaNome];

        const dadosMatriz = XLSX.utils.sheet_to_json<string[]>(worksheet, {
          header: 1,
        });

        if (dadosMatriz && dadosMatriz.length > 0) {
          const cabecalhoOriginal = (dadosMatriz[0] as any[]).map((c) =>
            String(c || ''),
          );
          this.cabecalhos.set(cabecalhoOriginal);

          const linhasDados = dadosMatriz
            .slice(1)
            .map((row: any[]) =>
              row.map((cell) =>
                String(cell !== undefined && cell !== null ? cell : ''),
              ),
            )
            .filter((row) => row.some((cell) => cell.trim() !== ''));

          this.linhasPreview.set(linhasDados);
          this.limparResultado();
          this.toast.success('Planilha carregada com sucesso! Revise os dados.');
        }
      } catch (error) {
        console.error(error);
        this.toast.error(
          'Erro ao ler o arquivo. Certifique-se de que é uma planilha válida.',
        );
      }
    };

    reader.readAsBinaryString(file);
  }

  confirmarImportacao() {
    const tipo = this.tipoImportacao() as TipoImportacao;
    const qtd = this.linhasPreview().length;

    if (!tipo) {
      this.toast.warning('Selecione o tipo de importação.');
      return;
    }

    if (qtd === 0) {
      this.toast.warning('Nenhum dado encontrado para importar.');
      return;
    }

    const mapeamento = this.mapearLinhas(tipo);

    if (mapeamento.dados.length === 0) {
      this.erros.set(mapeamento.erros);
      this.resultadoTotal.set(qtd);
      this.resultadoImportados.set(0);
      this.resultadoIgnorados.set(qtd);
      this.toast.error(
        'Nenhuma linha pôde ser mapeada. Confira os cabeçalhos da planilha.',
      );
      return;
    }

    this.importando.set(true);

    this.importacao.importar(tipo, mapeamento.dados).subscribe({
      next: (resultado) => {
        this.importando.set(false);
        this.resultadoTotal.set(resultado.total);
        this.resultadoImportados.set(resultado.importados);
        this.resultadoIgnorados.set(resultado.ignorados);
        this.erros.set([...mapeamento.erros, ...resultado.erros]);

        if (resultado.importados > 0) {
          this.toast.success(
            `${resultado.importados} de ${resultado.total} linha(s) importada(s) com sucesso.`,
          );
        } else {
          this.toast.error('Nenhuma linha foi importada.');
        }

        if (resultado.erros.length > 0) {
          this.toast.warning(
            `${resultado.erros.length} linha(s) com erro. Veja o detalhamento na tela.`,
          );
        }

        this.audit.registrarAcao(
          'Marcio Coelho',
          'Importação',
          'CRIACAO',
          `Importou ${resultado.importados} registro(s) via planilha Excel/CSV`,
        );
      },
      error: (erro) => {
        this.importando.set(false);
        const mensagem =
          erro?.error?.mensagem ?? 'Não foi possível concluir a importação.';
        this.toast.error(mensagem);
      },
    });
  }

  /** Monta as linhas do contrato a partir dos cabeçalhos da planilha. */
  private mapearLinhas(tipo: TipoImportacao): {
    dados: Record<string, unknown>[];
    erros: ErroLinha[];
  } {
    const campos = COLUNAS[tipo];
    const colunas = this.resolverColunas(campos, this.cabecalhos());
    const dados: Record<string, unknown>[] = [];
    const erros: ErroLinha[] = [];

    this.linhasPreview().forEach((linha, indice) => {
      const numeroLinha = indice + 2;

      if (linha.every((celula) => !String(celula).trim())) return;

      const ausentes = campos
        .filter((campo) => colunas[campo.campo] === undefined)
        .map((campo) => campo.campo);

      if (ausentes.length > 0) {
        erros.push({
          linha: numeroLinha,
          mensagem: `Coluna(s) não reconhecida(s) no cabeçalho: ${ausentes.join(', ')}.`,
        });
        return;
      }

      const mapeada = this.montarLinha(tipo, colunas, linha);

      if (mapeada.erro) {
        erros.push({ linha: numeroLinha, mensagem: mapeada.erro });
        return;
      }

      dados.push(mapeada.dados!);
    });

    return { dados, erros };
  }

  private resolverColunas(
    campos: CampoPlanilha[],
    cabecalhos: string[],
  ): Record<string, number | undefined> {
    const normalizados = cabecalhos.map((cabecalho) => this.normalizar(cabecalho));
    const colunas: Record<string, number | undefined> = {};

    campos.forEach((campo) => {
      const indice = normalizados.findIndex((cabecalho) =>
        campo.aliases.includes(cabecalho),
      );
      colunas[campo.campo] = indice >= 0 ? indice : undefined;
    });

    return colunas;
  }

  private montarLinha(
    tipo: TipoImportacao,
    colunas: Record<string, number | undefined>,
    linha: string[],
  ): LinhaMapeada {
    const texto = (campo: string): string => {
      const indice = colunas[campo];
      if (indice === undefined) return '';
      return String(linha[indice] ?? '').trim();
    };

    if (tipo === 'colaborador') {
      return {
        dados: {
          matricula: texto('matricula'),
          nome: texto('nome'),
          cpf: texto('cpf'),
          email: texto('email'),
          cargo: texto('cargo'),
          setor: texto('setor'),
          status: texto('status'),
        },
      };
    }

    if (tipo === 'treinamento') {
      const validadeMeses = this.parsearInteiro(texto('validadeMeses'));

      if (validadeMeses === undefined) {
        return { erro: 'Validade em meses deve ser um número inteiro.' };
      }

      return {
        dados: {
          codigo: texto('codigo'),
          nome: texto('nome'),
          classificacao: texto('classificacao'),
          nr: texto('nr') || null,
          cargaHoraria: texto('cargaHoraria'),
          validadeMeses,
          status: texto('status'),
        },
      };
    }

    const quantidade = this.parsearInteiro(texto('quantidade'));

    if (quantidade === undefined) {
      return { erro: 'Quantidade deve ser um número inteiro.' };
    }

    const inclusao = this.parsearData(texto('inclusao'));
    const validade = this.parsearData(texto('validade'));

    if (!inclusao.ok) {
      return { erro: 'Data de inclusão inválida (use AAAA-MM-DD ou DD/MM/AAAA).' };
    }

    if (!validade.ok) {
      return { erro: 'Data de validade inválida (use AAAA-MM-DD ou DD/MM/AAAA).' };
    }

    return {
      dados: {
        descricao: texto('descricao'),
        ca: texto('ca'),
        inclusao: inclusao.valor,
        validade: validade.valor,
        quantidade,
      },
    };
  }

  /** `undefined` = valor não numérico, `null` = célula vazia. */
  private parsearInteiro(valor: string): number | null | undefined {
    if (valor === '') return null;

    const numero = Number(valor.replace(',', '.'));

    if (!Number.isFinite(numero) || !Number.isInteger(numero)) return undefined;

    return numero;
  }

  /** Converte a célula para data ISO (AAAA-MM-DD). */
  private parsearData(valor: string): { ok: boolean; valor: string | null } {
    if (valor === '') return { ok: true, valor: null };

    const iso = /^(\d{4})-(\d{2})-(\d{2})$/;
    const brasileira = /^(\d{1,2})[/.\-](\d{1,2})[/.\-](\d{4})$/;

    let ano: number;
    let mes: number;
    let dia: number;

    if (iso.test(valor)) {
      const partes = valor.split('-').map(Number);
      ano = partes[0];
      mes = partes[1];
      dia = partes[2];
    } else if (brasileira.test(valor)) {
      const partes = valor.split(/[/.\-]/).map(Number);
      dia = partes[0];
      mes = partes[1];
      ano = partes[2];
    } else if (/^\d+(\.\d+)?$/.test(valor)) {
      // Número de série do Excel (epoch 1899-12-30).
      const serie = Math.floor(Number(valor));
      if (serie < 1 || serie > 2958465) return { ok: false, valor: null };

      const data = new Date(Date.UTC(1899, 11, 30) + serie * 86400000);
      ano = data.getUTCFullYear();
      mes = data.getUTCMonth() + 1;
      dia = data.getUTCDate();
    } else {
      return { ok: false, valor: null };
    }

    const data = new Date(Date.UTC(ano, mes - 1, dia));

    if (
      data.getUTCFullYear() !== ano ||
      data.getUTCMonth() !== mes - 1 ||
      data.getUTCDate() !== dia
    ) {
      return { ok: false, valor: null };
    }

    const pad = (numero: number) => String(numero).padStart(2, '0');

    return {
      ok: true,
      valor: `${ano}-${pad(mes)}-${pad(dia)}`,
    };
  }

  /** Normaliza cabeçalho: sem acento, minúsculo e sem separadores. */
  private normalizar(valor: string): string {
    return String(valor ?? '')
      .normalize('NFD')
      .replace(/[\u0300-\u036f]/g, '')
      .toLowerCase()
      .replace(/[^a-z0-9]/g, '');
  }

  private limparResultado() {
    this.resultadoTotal.set(null);
    this.resultadoImportados.set(null);
    this.resultadoIgnorados.set(null);
    this.erros.set([]);
  }
}
