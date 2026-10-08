import { ChangeDetectionStrategy, Component, computed, inject, signal } from '@angular/core';
import { CommonModule, TitleCasePipe } from '@angular/common';
import { FormsModule } from '@angular/forms';
import { Router } from '@angular/router';
import { AuditService } from '../service/audit.service';
import { type ChaveModulo, DadosReferenciaService } from '../service/dados-referencia.service';
import { ToastService } from '../service/toast.service';

const ROTAS_SISTEMA = {
  novoUsuario: '/cadastramentos/novo-usuario',
  detalhesUsuario: (id: string) => `/cadastramentos/usuario/${id}`,
  editarUsuario: (id: string) => `/cadastramentos/editar-usuario/${id}`,
  resetarSenha: (id: string) => `/cadastramentos/usuario/${id}/senha`,
  matrizAcesso: (id: string) => `/cadastramentos/usuario/${id}/acessos`,
} as const;

type StatusUsuario = 'ativo' | 'inativo';

interface UsuarioSst {
  id: string;
  nomeCompleto: string;
  emailCorporativo: string;
  cpf: string;
  grupoId: string;
  status: StatusUsuario;
}

interface ModuloSistema {
  chave: ChaveModulo;
  titulo: string;
  detalhe: string;
}

interface RegraAlerta {
  codigo: 'estoqueEpi' | 'vencimentoEpi' | 'treinamentoVencido';
  nomeRegra: string;
  descricaoRegra: string;
  isAtiva: boolean;
}

type GuiaConfiguracao = 'usuarios' | 'grupos' | 'matriz' | 'globais' | 'logs';

@Component({
  selector: 'app-configuracoes',
  standalone: true,
  imports: [CommonModule, FormsModule, TitleCasePipe],
  templateUrl: './configuracoes.html',
  styleUrl: './configuracoes.scss',
  changeDetection: ChangeDetectionStrategy.OnPush,
})
export class Configuracoes {
  private readonly router = inject(Router);
  protected readonly rotas = ROTAS_SISTEMA;
  private toastService = inject(ToastService);
  private auditService = inject(AuditService);
  private dadosReferencia = inject(DadosReferenciaService);

  protected mostrarModalEdicaoUsuario = signal<boolean>(false);
  protected usuarioEmEdicao = signal<UsuarioSst | null>(null);

  protected readonly guiasNavegacao: { id: GuiaConfiguracao; titulo: string }[] = [
    { id: 'usuarios', titulo: 'Usuários do Sistema' },
    { id: 'grupos', titulo: 'Grupos de Usuários' },
    { id: 'matriz', titulo: 'Matriz de Acessos' },
    { id: 'globais', titulo: 'Configurações Globais' },
    { id: 'logs', titulo: 'Logs de Auditoria' },
  ];

  protected readonly guiaAtual = signal<GuiaConfiguracao>('usuarios');

  protected readonly modulosDisponiveis: ModuloSistema[] = [
    {
      chave: 'sgst_dashboard',
      titulo: 'Dashboard SST',
      detalhe: 'Visão geral e indicadores de saúde e segurança.',
    },
    {
      chave: 'sgst_colaboradores',
      titulo: 'Gestão de Colaboradores',
      detalhe: 'Acesso à lista e prontuários dos funcionários.',
    },
    {
      chave: 'sgst_epis',
      titulo: 'Controle de EPIs',
      detalhe: 'Entrega, devolução e gestão de estoque de EPIs.',
    },
    {
      chave: 'sgst_treinamentos',
      titulo: 'Matriz de Treinamentos',
      detalhe: 'Controle de NRs e capacitações.',
    },
    {
      chave: 'sgst_relatorios',
      titulo: 'Relatórios Gerenciais',
      detalhe: 'Extração de dados e auditorias.',
    },
    {
      chave: 'sgst_config',
      titulo: 'Administração do Sistema',
      detalhe: 'Controle total de parâmetros e acessos.',
    },
  ];

  protected readonly gruposSst = this.dadosReferencia.gruposAcesso;

  protected filtroLogTermo = signal('');
  protected filtroLogDataInicio = signal('');
  protected filtroLogDataFim = signal('');

  protected readonly logsFiltrados = computed(() => {
    let logs = this.auditService.logs();
    const termo = this.filtroLogTermo().trim().toLowerCase();
    const dataInicio = this.filtroLogDataInicio();
    const dataFim = this.filtroLogDataFim();

    if (termo) {
      logs = logs.filter(
        (l) =>
          l.usuario.toLowerCase().includes(termo) ||
          l.modulo.toLowerCase().includes(termo) ||
          l.descricao.toLowerCase().includes(termo),
      );
    }

    if (dataInicio) {
      const inicio = new Date(dataInicio + 'T00:00:00').getTime();
      logs = logs.filter((l) => new Date(l.dataHora).getTime() >= inicio);
    }

    if (dataFim) {
      const fim = new Date(dataFim + 'T23:59:59').getTime();
      logs = logs.filter((l) => new Date(l.dataHora).getTime() <= fim);
    }

    return logs;
  });

  protected readonly usuariosCadastrados = signal<UsuarioSst[]>([
    {
      id: 'c1',
      nomeCompleto: 'Clara Aragão',
      emailCorporativo: 'clara.aragao@essenza.com.br',
      cpf: '123.456.789-00',
      grupoId: 'admin_tst',
      status: 'ativo',
    },
    {
      id: 'c2',
      nomeCompleto: 'Simão Ngombo',
      emailCorporativo: 'simao.n@essenza.com.br',
      cpf: '111.222.333-44',
      grupoId: 'admin_tst',
      status: 'ativo',
    },
    {
      id: 'c3',
      nomeCompleto: 'Marcio Coelho',
      emailCorporativo: 'marcio.c@essenza.com.br',
      cpf: '999.888.777-66',
      grupoId: 'colaborador',
      status: 'inativo',
    },
  ]);

  protected readonly termoBusca = signal('');

  protected readonly usuariosFiltrados = computed(() => {
    const termo = this.termoBusca().trim().toLowerCase();
    if (!termo) return this.usuariosCadastrados();

    return this.usuariosCadastrados().filter((usuario) => {
      const nome = usuario.nomeCompleto.toLowerCase();
      const cpfMatricula = usuario.cpf.toLowerCase();
      const status = usuario.status.toLowerCase();
      const grupoNome = this.getNomeGrupo(usuario.grupoId).toLowerCase();

      return (
        nome.includes(termo) ||
        cpfMatricula.includes(termo) ||
        status.includes(termo) ||
        grupoNome.includes(termo)
      );
    });
  });

  protected readonly grupoSelecionadoId = signal<string>('admin_tst');

  protected readonly grupoEmEdicao = computed(
    () => this.gruposSst().find((g) => g.id === this.grupoSelecionadoId()) ?? this.gruposSst()[0],
  );

  protected readonly regrasAlertas = signal<RegraAlerta[]>([
    {
      codigo: 'estoqueEpi',
      nomeRegra: 'Ruptura de Estoque (EPI)',
      descricaoRegra: 'Notificar quando luvas, botas, etc., atingirem estoque mínimo.',
      isAtiva: true,
    },
    {
      codigo: 'vencimentoEpi',
      nomeRegra: 'Validade de CA',
      descricaoRegra: 'Aviso de vencimento do Certificado de Aprovação (30 dias).',
      isAtiva: true,
    },
    {
      codigo: 'treinamentoVencido',
      nomeRegra: 'Reciclagem de NRs',
      descricaoRegra: 'Aviso sobre vencimento de NR-35, NR-10, etc.',
      isAtiva: false,
    },
  ]);

  protected navegarGuia(guia: GuiaConfiguracao): void {
    this.guiaAtual.set(guia);
  }

  protected getNomeGrupo(grupoId: string): string {
    return this.gruposSst().find((g) => g.id === grupoId)?.nomenclatura || 'Indefinido';
  }

  protected irParaMatrizDoGrupo(grupoId: string): void {
    this.grupoSelecionadoId.set(grupoId);
    this.guiaAtual.set('matriz');
  }

  protected alternarAcessoModulo(chave: ChaveModulo): void {
    this.gruposSst.update((lista) =>
      lista.map((grupo) => {
        if (grupo.id !== this.grupoSelecionadoId()) return grupo;

        const possui = grupo.modulosLiberados.includes(chave);
        const modulosLiberados = possui
          ? grupo.modulosLiberados.filter((c) => c !== chave)
          : [...grupo.modulosLiberados, chave];

        return { ...grupo, modulosLiberados };
      }),
    );
  }

  protected alternarRegra(codigo: RegraAlerta['codigo']): void {
    this.regrasAlertas.update((lista) =>
      lista.map((regra) =>
        regra.codigo === codigo ? { ...regra, isAtiva: !regra.isAtiva } : regra,
      ),
    );
  }

  protected gravarAlteracoesGlobais(): void {
    console.log('Salvando preferências SST...', this.regrasAlertas());
  }

  actionNovoUsuario(): void {
    console.log('Botão Novo Usuário clicado! Redirecionando...');
    this.router.navigate(['/cadastramentos'], { queryParams: { aba: 'colaborador' } });
  }

  protected actionEditarUsuario(usuario: UsuarioSst): void {
    this.usuarioEmEdicao.set({ ...usuario });
    this.mostrarModalEdicaoUsuario.set(true);
  }

  protected fecharModalEdicaoUsuario(): void {
    this.mostrarModalEdicaoUsuario.set(false);
    this.usuarioEmEdicao.set(null);
  }

  protected salvarEdicaoUsuario(): void {
    const usuarioAtualizado = this.usuarioEmEdicao();
    if (!usuarioAtualizado) return;

    this.usuariosCadastrados.update((lista) =>
      lista.map((u) => (u.id === usuarioAtualizado.id ? { ...usuarioAtualizado } : u)),
    );
    this.toastService.success(
      `Usuário "${usuarioAtualizado.nomeCompleto}" atualizado com sucesso!`,
    );
    this.auditService.registrarAcao(
      'Administrador',
      'Configurações',
      'EDICAO',
      `Atualizou usuário ${usuarioAtualizado.nomeCompleto}`,
    );
    this.fecharModalEdicaoUsuario();
  }
}
